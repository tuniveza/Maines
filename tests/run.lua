-- Offline test suite for Maines. Run from anywhere:  lua5.1 tests/run.lua
-- Env: MAINES_SV=<path to WTF/.../SavedVariables/Maines.lua> loads real saved variables first.
--      MAINES_ECHO=1 echoes the add-on's print() output and handled errors.
--      MAINES_VERBOSE=1 lists every auto-stubbed method / missing global at the end.

local scriptDir = (arg and arg[0] or ""):match("^(.*)[/\\][^/\\]*$") or "."
package.path = scriptDir .. "/?.lua;" .. package.path
local repoRoot = scriptDir .. "/.."

local mock = require("wowmock")
local out = mock.rawprint

-- ---------------------------------------------------------------- tiny test framework
local passed, failed = 0, 0
local function q(v) return type(v) == "string" and ("%q"):format(v) or tostring(v) end
-- Assertion failures are tables so the report shows "file:line: message" without a traceback.
local function fail(msg)
    local info = debug.getinfo(3, "Sl")
    error({ assertion = (info and (info.short_src .. ":" .. info.currentline .. ": ") or "") .. msg })
end
local function eq(actual, expected, what)
    if actual ~= expected then
        fail((what and (what .. ": ") or "") .. "expected " .. q(expected) .. ", got " .. q(actual))
    end
end
local function ok(cond, what) if not cond then fail(what or "assertion failed") end end
local notes = {}
local function note(s) notes[#notes + 1] = s end   -- extra info printed under the test's PASS/FAIL line
local function test(name, fn)
    notes = {}
    local errorsBefore = #mock.errors
    local good, err = xpcall(fn, function(e)
        if type(e) == "table" and e.assertion then return e.assertion end
        return debug.traceback(tostring(e), 2)
    end)
    if good and #mock.errors > errorsBefore then
        good = false
        err = (#mock.errors - errorsBefore) .. " error(s) reached the WoW error handler; first:\n" .. mock.errors[errorsBefore + 1]
    end
    if good then
        passed = passed + 1
        out("PASS  " .. name)
    else
        failed = failed + 1
        out("FAIL  " .. name)
        out("      " .. tostring(err):gsub("\n", "\n      "))
    end
    for _, n in ipairs(notes) do out("      " .. n) end
end

-- ---------------------------------------------------------------- load the add-on
mock.install()
mock.trackMissingGlobals()
local sv = os.getenv("MAINES_SV")
if sv == "" then sv = nil end
out("== Maines offline tests (" .. (sv and "with real SavedVariables" or "fresh install, no SavedVariables") .. ")")

local loadOk, loadErr = pcall(mock.loadAddon, repoRoot, "Maines", { savedVariables = sv })

local slash, sendChat = mock.slash, mock.sendChat

-- Put tagging into a known state regardless of what the saved variables held.
local function resetTagging()
    mock.state.inCombat = false
    Maines_Debug = nil
    slash("/mains Radine [")
    slash("/mainchat")              -- clear filter
    slash("/mainchat mode include")
    Maines_HideOnMain_DB = true
    mock.state.playerName = "Altchar"
end

local function clickAllUnder(root)
    local n = 0
    for _, f in ipairs(mock.findFrames(function(o) return o._scripts and o._scripts.OnClick and mock.isDescendant(o, root) end)) do
        if not root:IsShown() then root:Show() end
        mock.click(f, "LeftButton", true)
        n = n + 1
    end
    return n
end

local ns = mock.ns

-- ---------------------------------------------------------------- tests
test("1. add-on loads, initializes, and /maines opens the window", function()
    ok(loadOk, "loadAddon raised: " .. tostring(loadErr))
    if #mock.loadErrors > 0 then
        local e = mock.loadErrors[1]
        error(#mock.loadErrors .. " file(s) failed to load; first: " .. e.file .. "\n" .. tostring(e.err))
    end
    ok(#mock.loadedFiles >= 2, "expected library + add-on files to load, got " .. #mock.loadedFiles)
    note("(" .. #mock.loadedFiles .. " Lua files loaded via Maines.toc)")
    if sv then
        local set, total = 0, 0
        for name in (mock.tocFields.SavedVariables or ""):gmatch("[%w_]+") do
            total = total + 1
            if rawget(_G, name) ~= nil then set = set + 1 end
        end
        note("(" .. set .. " of " .. total .. " saved variables present after loading MAINES_SV)")
    end
    local hookLine = false
    for _, l in ipairs(mock.printed) do if l:find("chat hook active (EventRegistry)", 1, true) then hookLine = true end end
    ok(hookLine, "OnInitialize did not run (no 'chat hook active' line)")
    ok(type(Maines_Frame) == "table", "Maines_Frame was not created")
    Maines_Frame:Hide()
    local refreshes = 0
    Maines_Frame:HookScript("OnShow", function() refreshes = refreshes + 1 end)
    slash("/maines")
    ok(Maines_Frame:IsShown(), "/maines did not show Maines_Frame")
    eq(refreshes, 1, "OnShow handler runs")
    ok(type(Maines_RefreshWindow) == "function", "Maines_RefreshWindow missing")
    Maines_RefreshWindow()
end)

test("2. /mains sets the name and GUILD chat gets tagged (alt) / untagged (main, hide on)", function()
    resetTagging()
    eq(Maines_Name_DB, "Radine", "Maines_Name_DB")
    eq(Maines_Bracket_Left_DB, "[", "left bracket")
    eq(Maines_Bracket_Right_DB, "]", "right bracket")
    eq(sendChat("GUILD", "hello"), "[Radine] hello", "alt, GUILD")
    eq(sendChat("GUILD", "[Radine] hello"), "[Radine] hello", "already tagged is not tagged twice")
    mock.state.playerName = "Radine"
    Maines_HideOnMain_DB = true
    eq(sendChat("GUILD", "hello"), "hello", "on main with Maines_HideOnMain_DB")
    slash("/mainshow")
    eq(sendChat("GUILD", "hello"), "[Radine] hello", "on main after /mainshow")
    slash("/mainhide")
    eq(Maines_HideOnMain_DB, true, "/mainhide sets Maines_HideOnMain_DB")
    mock.state.playerName = "Altchar"
    mock.state.inCombat = true
    eq(sendChat("GUILD", "hello"), "hello", "no tagging in combat lockdown")
    mock.state.inCombat = false
    eq(sendChat("WHISPER", ""), "", "empty message untouched")
    eq(sendChat("CHANNEL", "hi", { clubId = 42 }), "[Radine] hi", "community edit box (clubId)")
end)

test("3. /mainchat include/exclude filters and '-SAY,-YELL'", function()
    resetTagging()
    slash("/mainchat GUILD")
    eq(sendChat("PARTY", "hello"), "hello", "include GUILD: PARTY")
    eq(sendChat("GUILD", "hello"), "[Radine] hello", "include GUILD: GUILD")
    slash("/mainchat mode exclude")
    eq(Maines_ChatFilterMode_DB, "exclude", "mode saved")
    eq(sendChat("PARTY", "hello"), "[Radine] hello", "exclude GUILD: PARTY")
    eq(sendChat("GUILD", "hello"), "hello", "exclude GUILD: GUILD")
    eq(sendChat("NOT_A_CHANNEL", "hello"), "hello", "exclude mode: unknown chat type stays untagged")
    slash("/mainchat mode include")
    slash("/mainchat say, yell ,guild")
    eq(table.concat(Maines_Chat_Options_DB, ","), "SAY,YELL,GUILD", "list is trimmed + uppercased")
    slash("/mainchat -SAY,-YELL")
    eq(table.concat(Maines_Chat_Options_DB, ","), "GUILD", "after -SAY,-YELL")
    eq(sendChat("SAY", "hello"), "hello", "SAY removed")
    eq(sendChat("YELL", "hello"), "hello", "YELL removed")
    eq(sendChat("GUILD", "hello"), "[Radine] hello", "GUILD kept")
    slash("/mainchat +SAY,GUILD")
    eq(table.concat(Maines_Chat_Options_DB, ","), "GUILD", "mixed +X and plain names is rejected")
    slash("/mainchat +PARTY")
    eq(sendChat("PARTY", "hello"), "[Radine] hello", "+PARTY added")
    slash("/mainchat")
    eq(#Maines_Chat_Options_DB, 0, "empty /mainchat clears the filter")
    eq(sendChat("PARTY", "hello"), "[Radine] hello", "no filter: PARTY tagged")
end)

test("4. every slash command runs with an empty argument", function()
    local keys = {}
    for k in pairs(SlashCmdList) do keys[#keys + 1] = k end
    table.sort(keys)
    ok(#keys > 0, "no slash commands registered")
    for _, k in ipairs(keys) do
        local before = #mock.errors
        local good, err = pcall(SlashCmdList[k], "", ChatFrame1EditBox)
        if not good then error("SlashCmdList." .. k .. '("") raised: ' .. tostring(err)) end
        if #mock.errors > before then error("SlashCmdList." .. k .. '("") hit the error handler: ' .. mock.errors[before + 1]) end
    end
    note("(" .. #keys .. " commands: " .. table.concat(keys, " ") .. ")")
end)

test("5. every OnClick under Maines_Frame fires without error", function()
    resetTagging()
    Maines_Frame:Show()
    local n = clickAllUnder(Maines_Frame)
    ok(n > 0, "found no clickable frames under Maines_Frame")
    -- second pass with the window freshly shown, so tab switches / hides from pass 1 don't mask anything
    Maines_Frame:Hide(); Maines_Frame:Show()
    clickAllUnder(Maines_Frame)
    note("(" .. n .. " clickable frames)")
end)

test("5b. every OnClick under the /mainhelp window fires without error", function()
    local help = _G.Maines_Help_Frame
    if not help then note("(no Maines_Help_Frame - skipped)"); return end
    slash("/mainhelp")
    local n = clickAllUnder(help)
    note("(" .. n .. " clickable frames)")
end)

test("5c. minimap icon: left/right/middle click and tooltip", function()
    local btn = _G.LibDBIcon10_Maines
    if not btn then
        ok(Maines_DB and Maines_DB.minimap and Maines_DB.minimap.hide, "minimap button missing but not hidden")
        note("(minimap icon hidden in saved variables - skipped)"); return
    end
    Maines_Frame:Hide()
    mock.click(btn, "LeftButton")
    ok(Maines_Frame:IsShown(), "left click shows the window")
    mock.click(btn, "LeftButton")
    ok(not Maines_Frame:IsShown(), "second left click hides the window")
    mock.click(btn, "RightButton")
    mock.click(btn, "MiddleButton")
    mock.fireScript(btn, "OnEnter")
    mock.fireScript(btn, "OnLeave")
end)

test("6. timers, OnUpdate and animations run for 30s without error", function()
    slash("/maines")
    mock.advanceTime(30, 0.05)
end)

test("7. saved phrases: add, cycle into chat, swap on repeat press, keys from inside the chat box", function()
    slash("/mainphrase clear")
    slash("/mainphrase add Looking for group!")
    slash("/mainphrase add o/ hello || there")
    eq(#Maines_Phrases_DB.list, 2, "two phrases saved")
    ChatFrame1EditBox:SetText(""); ChatFrame1EditBox:ClearFocus()
    Maines_CyclePhrase(1)                       -- the key binding's action, chat closed
    eq(ChatFrame1EditBox:GetText(), "Looking for group!", "first press opens chat with phrase 1")
    -- now the chat box has the keyboard: the binding is caught by the box's own key hook
    mock.bindings = {}
    SetBinding("CTRL-1", "MAINES_NEXT_PHRASE")
    SetBinding("CTRL-2", "MAINES_PREV_PHRASE")
    mock.state.ctrl = true
    mock.fireScript(ChatFrame1EditBox, "OnKeyDown", "1")
    eq(ChatFrame1EditBox:GetText(), "o/ hello || there", "second press swaps in phrase 2")
    mock.fireScript(ChatFrame1EditBox, "OnKeyDown", "1")
    eq(ChatFrame1EditBox:GetText(), "Looking for group!", "wraps around to phrase 1")
    mock.fireScript(ChatFrame1EditBox, "OnKeyDown", "2")
    eq(ChatFrame1EditBox:GetText(), "o/ hello || there", "previous key goes back")
    mock.state.ctrl = false
    mock.fireScript(ChatFrame1EditBox, "OnKeyDown", "1")   -- plain "1" is not the binding
    eq(ChatFrame1EditBox:GetText(), "o/ hello || there", "unbound key does nothing")
    -- typed text stays; the phrase is added after it
    ChatFrame1EditBox:SetText("hi ")
    Maines_CyclePhrase(1)
    eq(ChatFrame1EditBox:GetText(), "hi Looking for group!", "phrase appended after typed text")
    ChatFrame1EditBox:ClearFocus()
    -- key capture from the Phrases page
    eq(ns.KeyCombo("LSHIFT"), nil, "lone modifier ignored")
    mock.state.alt, mock.state.shift = true, true
    eq(ns.KeyCombo("Q"), "ALT-SHIFT-Q", "binding spelling")
    mock.state.alt, mock.state.shift = false, false
    ok(ns.SetActionKey("MAINES_NEXT_PHRASE", "CTRL-9"), "SetActionKey")
    eq(ns.BindingText("MAINES_NEXT_PHRASE"), "CTRL-9", "old key replaced")
    mock.state.inCombat = true
    ok(not ns.SetActionKey("MAINES_NEXT_PHRASE", "CTRL-8"), "refused in combat")
    mock.state.inCombat = false
    -- "Set key" on the page: next key press (with modifiers) becomes the binding; the button
    -- label comes back afterwards; closing the window cancels the capture
    local btn = { label = "", SetText = function(self, t) self.label = t end }
    ns.StartKeyCapture(btn, "MAINES_PREV_PHRASE")
    ok(ns.KeyCaptureFrame:IsShown(), "capture frame shown")
    eq(btn.label, "Press a key...", "button prompts")
    mock.state.ctrl = true
    mock.fireScript(ns.KeyCaptureFrame, "OnKeyDown", "LCTRL")
    ok(ns.KeyCaptureFrame:IsShown(), "lone modifier keeps waiting")
    mock.fireScript(ns.KeyCaptureFrame, "OnKeyDown", "7")
    mock.state.ctrl = false
    eq(ns.BindingText("MAINES_PREV_PHRASE"), "CTRL-7", "captured key bound")
    ok(not ns.KeyCaptureFrame:IsShown(), "capture frame hidden")
    eq(btn.label, "Set key", "button label restored")
    Maines_Frame:Show()
    ns.StartKeyCapture(btn, "MAINES_PREV_PHRASE")
    Maines_Frame:Hide()
    ok(not ns.KeyCaptureFrame:IsShown(), "closing the window cancels capture")
    ns.StartKeyCapture(btn, "MAINES_PREV_PHRASE")
    mock.fireScript(ns.KeyCaptureFrame, "OnKeyDown", "ENTER")
    ok(ns.KeyCaptureFrame:IsShown(), "Enter refused, still waiting")
    mock.fireScript(ns.KeyCaptureFrame, "OnKeyDown", "ESCAPE")
    eq(ns.BindingText("MAINES_PREV_PHRASE"), "CTRL-7", "Escape cancels without binding")
    ns.StartKeyCapture(btn, "MAINES_PREV_PHRASE")
    mock.fireEvent("PLAYER_REGEN_DISABLED")
    ok(not ns.KeyCaptureFrame:IsShown(), "combat starting cancels capture")
    ok(not ns.AddPhrase(string.rep("y", 300)), "over-long phrase refused, not cut")
    slash("/mainphrase del 1")
    eq(#Maines_Phrases_DB.list, 1, "delete")
end)

test("8. animated tag: every style steps per message and never breaks plain tagging", function()
    resetTagging()
    slash("/mainanim off")
    eq(sendChat("GUILD", "a"), "[Radine] a", "off = plain tag")
    slash("/mainanim typewriter"); slash("/mainanim message")
    eq(sendChat("GUILD", "a"), "[R] a", "typewriter step 1")
    eq(sendChat("GUILD", "b"), "[Ra] b", "typewriter step 2")
    slash("/mainanim brackets")
    eq(sendChat("GUILD", "a"), "[Radine] a", "brackets start with your own")
    eq(sendChat("GUILD", "b"), "(Radine) b", "then the next style")
    slash("/mainanim wave")
    eq(sendChat("GUILD", "a"), "[Radine] a", "wave step 1 (R already capital)")
    eq(sendChat("GUILD", "b"), "[rAdine] b", "wave step 2")
    slash("/mainanim twinkle")
    eq(sendChat("GUILD", "a"), "[Radine *] a", "twinkle")
    slash("/mainanim phrases")
    eq(sendChat("GUILD", "a"), "[Radine] o/ hello || there a", "phrases style uses saved phrases")
    -- untagged channels/main character don't advance or change anything
    mock.state.playerName = "Radine"
    eq(sendChat("GUILD", "a"), "a", "still hidden on main")
    mock.state.playerName = "Altchar"
    slash("/mainanim time 60")
    local first = sendChat("GUILD", "x")
    eq(sendChat("GUILD", "x"), first, "time mode: same frame within the minute")
    -- UTF-8 names animate by letter, not by byte
    slash("/mains Lùna [")
    slash("/mainanim typewriter"); slash("/mainanim message")
    Maines_Anim_DB.step = 1
    eq(sendChat("GUILD", "x"), "[Lù] x", "UTF-8 letter kept whole")
    -- resent from chat history: an earlier frame at the start means don't tag again
    slash("/mains Radine [")
    Maines_Anim_DB.step = 3
    eq(sendChat("GUILD", "[Ra] hello again"), "[Ra] hello again", "earlier frame not tagged twice")
    eq(sendChat("GUILD", "hey [Radine] look"), "hey [Radine] look", "plain tag anywhere still counts")
    -- a long phrase frame that would overflow 255 bytes falls back to the plain tag
    slash("/mainphrase add " .. string.rep("z", 200))
    slash("/mainanim phrases")
    Maines_Anim_DB.step = #Maines_Phrases_DB.list - 1
    eq(sendChat("GUILD", string.rep("m", 60)), "[Radine] " .. string.rep("m", 60), "overflow -> plain tag")
    slash("/mainphrase del " .. #Maines_Phrases_DB.list)
    slash("/mainanim off")
    eq(sendChat("GUILD", "a"), "[Radine] a", "back to plain")
    slash("/maines"); Maines_RefreshWindow(); mock.advanceTime(5, 0.1)
end)

test("9. Textual Badges: send, 3-minute cooldown, channel checks, lockdown, custom badges", function()
    Maines_Badges_DB = nil
    mock.sentMessages = {}
    mock.state.inGuild = true
    ok(Maines_SendBadge("Heart", "GUILD"), "heart sent to guild")
    eq(#mock.sentMessages, 1, "first line goes out immediately")
    mock.advanceTime(1, 0.05)
    eq(#mock.sentMessages, 5, "one chat line per row, rest staggered")
    eq(mock.sentMessages[1].chatType, "GUILD", "channel")
    eq(mock.sentMessages[1].msg, "\194\160,d88b.d88b,", "leading space kept as a no-break space")
    ok(not Maines_SendBadge("Heart", "GUILD"), "second send within 3 minutes refused")
    eq(#mock.sentMessages, 5, "nothing extra sent during cooldown")
    mock.advanceTime(178, 1)   -- 1s already passed above: now at 2:59
    ok(not Maines_SendBadge("Sword", "GUILD"), "still refused at 2:59")
    mock.advanceTime(2, 1)
    ok(Maines_SendBadge("Sword", "GUILD"), "allowed after 3 minutes")
    mock.advanceTime(2, 0.05)
    local pipeLine
    for _, m in ipairs(mock.sentMessages) do if m.msg:find("^[\194\160]*o=+%[%]=+o$") then pipeLine = true end end
    ok(pipeLine, "sword hilt line sent")
    local escaped = false
    for _, m in ipairs(mock.sentMessages) do if m.msg:find("||||", 1, true) then escaped = true end end
    ok(escaped, "pipes are sent in WoW's escaped form")
    mock.advanceTime(181, 1)
    mock.state.inParty = false
    ok(not Maines_SendBadge("Heart", "PARTY"), "refused when not in a party")
    mock.state.inInstance = false
    ok(not Maines_SendBadge("Heart", "SAY"), "multi-line SAY refused outside instances")
    ok(Maines_SendBadge("Rose", "SAY"), "one-line badge allowed in SAY")
    mock.advanceTime(181, 1)
    mock.state.chatLockdown = true
    ok(not Maines_SendBadge("Heart", "GUILD"), "refused during chat lockdown")
    mock.state.chatLockdown = false
    -- your own badge, from the page's editor
    local before = #mock.sentMessages
    slash("/mainbadge list"); slash("/mainbadge show 1")
    eq(#mock.sentMessages, before, "list/show never send anything")
    slash("/mainbadge send 2 guild")
    mock.advanceTime(2, 0.05)
    eq(mock.sentMessages[#mock.sentMessages].chatType, "GUILD", "slash send")
    mock.advanceTime(181, 1)
    ok(not ns.SaveCustomBadge("Heart", "x"), "can't overwrite a built-in badge")
    ok(not ns.SaveCustomBadge("Tall", "1\n2\n3\n4\n5\n6\n7\n8\n9"), "more than 8 lines refused")
    ok(not ns.SaveCustomBadge("Empty", "\n  \n"), "empty refused")
    ok(ns.SaveCustomBadge("Wave", "\n o/\n\n \\o\n"), "custom saved")
    eq(Maines_Badges_DB.selected, "Wave", "new badge selected")
    before = #mock.sentMessages
    ok(Maines_SendBadge(nil, "GUILD"), "selected custom badge sent")
    mock.advanceTime(2, 0.05)
    eq(#mock.sentMessages - before, 3, "blank edge lines dropped, middle blank kept")
    eq(mock.sentMessages[before + 2].msg, "\194\160", "middle blank line sent as a no-break space")
    ok(ns.DeleteCustomBadge("Wave"), "deleted")
    -- lockdown starting mid-badge stops the remaining lines
    mock.advanceTime(181, 1)
    before = #mock.sentMessages
    ok(Maines_SendBadge("3D Cube", "GUILD"), "cube started")
    mock.state.chatLockdown = true
    mock.advanceTime(3, 0.05)
    mock.state.chatLockdown = false
    eq(#mock.sentMessages - before, 1, "only the first line went out before lockdown")
    ok(not ns.SaveCustomBadge("Wide", string.rep(" ", 150) .. string.rep("x", 60)), "line too long once spaces become no-break spaces")
    slash("/maines"); Maines_RefreshWindow(); mock.advanceTime(2, 0.25)
end)

test("9b. badge fitting: symbols land back on their columns in a proportional font", function()
    -- Rough FRIZQT-like widths: narrow space and pipe, wide plus/at.
    local W = { ["\194\160"] = 3.5, [" "] = 3.5, ["-"] = 4.5, ["+"] = 8, ["||"] = 3, ["/"] = 4.5,
                ["_"] = 6, ["@"] = 11, ["A"] = 8, [":"] = 3, ["\\"] = 4.5 }
    local function width(u) return W[u] or 7 end
    local function glyphs(line)
        local out, i = {}, 1
        while i <= #line do
            if line:sub(i, i + 1) == "||" then out[#out + 1] = "||"; i = i + 2
            elseif line:sub(i, i + 1) == "\194\160" then out[#out + 1] = "\194\160"; i = i + 2
            else out[#out + 1] = line:sub(i, i); i = i + 1 end
        end
        return out
    end
    local FILL = { ["-"] = true, ["_"] = true }
    local art = { "    +--------+", "   /        /||", "  /        / ||", " +--------+  ||",
                  " ||        ||  +", " ||        || /", " ||        ||/", " +--------+" }
    local fitted = ns.FitBadgeLines(art, width)
    local cell = 8
    local worst, checked = 0, 0
    for r, line in ipairs(art) do
        local og, fg = glyphs(line), glyphs(fitted[r])
        -- columns of the fixed symbols that follow a gap, in the original drawing
        local want = {}
        for c, u in ipairs(og) do
            local afterRun = FILL[og[c - 1] or ""] and og[c - 2] == og[c - 1]
            local STROKE = { ["/"] = true, ["\\"] = true, ["||"] = true }
            local touching = STROKE[u] and STROKE[og[c - 1] or ""]
            if u ~= " " and not FILL[u] and (og[c - 1] == " " or afterRun or touching) then want[#want + 1] = c - 1 end
        end
        -- centres of those same symbols in the fitted line
        local x, got = 0, {}
        for c, u in ipairs(fg) do
            local afterRun = FILL[fg[c - 1] or ""] and fg[c - 2] == fg[c - 1]
            if u ~= "\194\160" and not FILL[u] and (fg[c - 1] == "\194\160" or afterRun) then got[#got + 1] = x + width(u) / 2 end
            x = x + width(u)
        end
        eq(#got, #want, "row " .. r .. " keeps its symbols")
        for i, col in ipairs(want) do
            local err = math.abs(got[i] - (col * cell + cell / 2))
            worst = math.max(worst, err)
            checked = checked + 1
        end
    end
    -- within half a space (after a gap) or half a dash (after a stretched run)
    ok(worst <= 4.5 / 2 + 0.01, "every symbol within half a step of its column (worst " .. worst .. "px)")
    note("(" .. checked .. " symbols checked, worst " .. worst .. "px off)")
    -- even widths change nothing
    local same = ns.FitBadgeLines({ "  +--+", " /  /" }, function() return 7 end)
    eq(same[1], "\194\160\194\160+--+", "even font: row 1 unchanged")
    eq(same[2], "\194\160/\194\160\194\160/", "even font: row 2 unchanged")
    eq(ns.FitBadgeLines({ "a", " ", "b" }, width)[2], "\194\160", "blank middle row stays sendable")
    -- touching strokes get nudged apart onto their column; touching letters/brackets don't
    local nudged = ns.FitBadgeLines({ "+-+", "/||" }, width)[2]
    ok(nudged:find("/[\194\160]+||$"), "'/|' corner gets a gap: " .. nudged)
    eq(ns.FitBadgeLines({ "@@", "[]" }, width)[2], "[]", "brackets left touching")
    -- a one-row picture has nothing to line up with, so its runs aren't stretched
    eq(ns.FitBadgeLines({ "@}-,-'--" }, width)[1], "@}-,-'--", "one-row badge (Rose) sent as drawn")
    eq(ns.FitBadgeLines({ "  <3" }, width)[1], "\194\160\194\160<3", "one-row badge keeps its leading spaces")
end)

test("10. Bindings.xml: every binding's code compiles and its function and name exist", function()
    local f = assert(io.open(repoRoot .. "/Bindings.xml"))
    local xml = f:read("*a"); f:close()
    local n = 0
    for name, body in xml:gmatch('<Binding%s+name="([%w_]+)"[^>]*>(.-)</Binding>') do
        n = n + 1
        ok(loadstring(body), name .. " code compiles")
        local fn = body:match("([%w_]+)%(")
        ok(type(_G[fn]) == "function", name .. " calls missing function " .. tostring(fn))
        ok(type(_G["BINDING_NAME_" .. name]) == "string", "BINDING_NAME_" .. name .. " defined")
    end
    eq(n, 3, "three bindings")
    ok(type(BINDING_HEADER_MAINES) == "string", "header defined")
end)

test("11. TOC targets the current retail patch and saves the new settings", function()
    eq(mock.tocFields.Interface, "120105", "Interface")
    for _, v in ipairs({"Maines_Phrases_DB", "Maines_Anim_DB", "Maines_Badges_DB"}) do
        ok(mock.tocFields.SavedVariables:find(v, 1, true), v .. " in SavedVariables")
    end
end)

test("12. every Maines texture the UI uses exists on disk, and the TOC/minimap icon too", function()
    slash("/maines"); slash("/mainhelp")
    for _, key in ipairs({"main", "phrases", "animate", "badges", "filter", "behavior", "cosmetic", "help"}) do
        mock.ns.ShowPanel(key)
    end
    local paths = {}
    for _, o in ipairs(mock.objects) do
        local t = o._texture
        if type(t) == "string" and t:lower():find("^interface\\addons\\maines\\") then paths[t] = true end
    end
    -- icons drawn inline in help text
    for _, line in ipairs(mock.printed) do
        for t in line:gmatch("|T(Interface\\AddOns\\Maines\\[^:|]+)") do paths[t] = true end
    end
    paths[mock.tocFields.IconTexture .. ".tga"] = true
    local n, missing = 0, {}
    for t in pairs(paths) do
        n = n + 1
        local rel = t:gsub("^[Ii]nterface\\[Aa]dd[Oo]ns\\Maines\\", ""):gsub("\\", "/")
        if not rel:find("%.%w+$") then rel = rel .. ".tga" end
        local f = io.open(repoRoot .. "/" .. rel, "rb")
        if f then f:close() else missing[#missing + 1] = rel end
    end
    table.sort(missing)
    eq(#missing, 0, "missing texture files: " .. table.concat(missing, ", "))
    ok(n >= 12, "expected the grain/brushed/glow textures, 8 icons and the logo, saw " .. n)
    note("(" .. n .. " texture files checked)")
end)

test("13. author's note: pops up once after login for a new release, /mainnote reopens it", function()
    local note = _G.Maines_NoteFrame
    ok(note, "Maines_NoteFrame exists")
    -- the login in loadAddon scheduled it; it appears a few seconds later
    if not (Maines_DB and Maines_DB.noteSeen == "GLYPH") or note:IsShown() then
        mock.advanceTime(5, 0.1)
        ok(note:IsShown(), "shown a few seconds after the first login")
    end
    eq(Maines_DB.noteSeen, "GLYPH", "remembered as seen")
    note:Hide()
    mock.fireEvent("PLAYER_LOGIN")
    mock.advanceTime(6, 0.1)
    ok(not note:IsShown(), "not shown again on the next login")
    slash("/mainnote")
    ok(note:IsShown(), "/mainnote shows it")
    local mentions = false
    for _, o in ipairs(mock.objects) do
        if mock.isDescendant(o, note) or o._parent == note then
            local t = o._text
            if type(t) == "string" and t:find("/mainnote", 1, true) then mentions = true end
        end
    end
    ok(mentions, "the note tells players about /mainnote")
    clickAllUnder(note)
    ok(not note:IsShown(), "its buttons close it")
    note:Hide()
    note:SetPoint("CENTER")
    ok(note:GetHeight() > 300, "laid out to its text (" .. note:GetHeight() .. "px)")
end)

test("14. single-line input boxes centre their text; the badge drawing box stays left-aligned", function()
    local boxes, centred = 0, 0
    for _, o in ipairs(mock.objects) do
        if o._type == "EditBox" and o._template and o._template:find("InputBoxTemplate", 1, true) then
            boxes = boxes + 1
            local j = o._set.SetJustifyH and o._set.SetJustifyH[1]
            ok(j == "CENTER", (o:GetDebugName() or "input box") .. " is centred (got " .. tostring(j) .. ")")
            centred = centred + 1
        elseif o._type == "EditBox" and o._multiLine and o._parent and o._parent._type == "ScrollFrame" then
            local j = o._set.SetJustifyH and o._set.SetJustifyH[1]
            ok(j == nil or j == "LEFT", "multi-line drawing box keeps its rows left-aligned")
        end
    end
    ok(boxes >= 5, "found the input boxes (" .. boxes .. ")")
    note("(" .. centred .. " input boxes centred)")
end)

test("15. the full-colour icons are never tinted: tabs dim instead, /maincolor leaves them alone", function()
    slash("/maines"); ns.ShowPanel("main")
    for _ = 1, 3 do slash("/maincolor") end
    local tabs = 0
    for _, o in ipairs(mock.objects) do
        local t = o._texture
        if type(t) == "string" and t:find("\\icons\\", 1, true) then
            tabs = tabs + 1
            -- only ever neutral grey (a dim), never a colour; full white on the open tab
            local vc = o._set.SetVertexColor or {1, 1, 1}
            ok(vc[1] == vc[2] and vc[2] == vc[3],
                t .. " tinted to " .. q(vc[1]) .. "," .. q(vc[2]) .. "," .. q(vc[3]))
            local btn = o._parent
            if btn and btn.SetSelected then
                local want = btn.selected and 1 or 0.85
                ok(math.abs(vc[1] - want) < 1e-6, t .. " brightness " .. q(vc[1]) .. ", want " .. want)
                local ds = (o._set.SetDesaturation or {0})[1]
                local wantDs = btn.selected and 0 or 0.45
                ok(math.abs(ds - wantDs) < 1e-6, t .. " desaturation " .. q(ds) .. ", want " .. wantDs)
                ok((o._alpha or 1) == 1, t .. " alpha " .. q(o._alpha))
            end
        end
    end
    ok(tabs >= 8, "expected the 8 tab icons, saw " .. tabs)
    for _, line in ipairs(mock.printed) do
        for spec in line:gmatch("|T(Interface\\AddOns\\Maines\\textures\\icons\\[^|]+)|t") do
            ok(select(2, spec:gsub(":", "")) <= 2, "inline icon carries a tint: " .. spec)
        end
    end
end)

test("16. a palette tones the title bands, tab strip, footer and plates, and swaps every overlay and window frame", function()
    local ns = mock.ns
    slash("/maines"); slash("/mainnote"); slash("/mainhelp")
    for _, key in ipairs({"animate", "badges"}) do ns.ShowPanel(key) end
    local base = "Interface\\AddOns\\Maines\\textures\\"
    local function lum(c) return 0.2126 * c[1] + 0.7152 * c[2] + 0.0722 * c[3] end
    -- WCAG contrast ratio, from sRGB
    local function lin(x) return x <= 0.03928 and x / 12.92 or ((x + 0.055) / 1.055) ^ 2.4 end
    local function wlum(c) return 0.2126 * lin(c[1]) + 0.7152 * lin(c[2]) + 0.0722 * lin(c[3]) end
    local function contrast(a, b)
        local la, lb = wlum(a), wlum(b)
        return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05)
    end
    local CREAM, CREAM_SOFT = {0.96, 0.91, 0.78}, {0.78, 0.68, 0.52}   -- PLATE_TEXT, PLATE_TEXT_SOFT
    local windows = {Maines_Frame, Maines_NoteFrame, Maines_Help_Frame}
    for _, w in ipairs(windows) do ok(w.maines_frame, (w:GetName() or "?") .. " has a frame border") end
    local plates = {}
    for _, o in ipairs(mock.objects) do
        if type(o.tone) == "table" and o ~= ns.TabBar and o ~= ns.FooterBar and o._type ~= "Texture" then plates[#plates + 1] = o end
    end
    ok(#plates >= 2, "the feature pages' dark plates are toned too (" .. #plates .. ")")
    local worst = math.huge
    -- earlier tests clicked every swatch, so first put the start look back (no palette name)
    ns.ApplyPaletteColor(0.70, 0.47, 0.18)
    local overlays, bands = {}, {}
    for _, o in ipairs(mock.objects) do
        if o._texture == base .. "grain.tga" then overlays[#overlays + 1] = {tex = o, role = "paper"} end
        if o._texture == base .. "brushed.tga" then overlays[#overlays + 1] = {tex = o, role = "metal"} end
        if type(o.toneLow) == "table" then bands[#bands + 1] = o end
    end
    local metals = 0
    for _, ov in ipairs(overlays) do if ov.role == "metal" then metals = metals + 1 end end
    ok(#overlays > metals and metals >= 2, "found paper and metal overlays (" .. #overlays .. ", " .. metals .. " metal)")
    eq(#bands, 2, "two title bands (window header, note strip)")
    -- the start brass (Maines_DressBrassBand's BAND_LOW / BAND_HIGH)
    local brassLow, brassHigh = {0.60, 0.45, 0.24}, {0.82, 0.67, 0.42}

    local seen = {}
    for _, palette in ipairs(ns.Palettes) do
        ok(palette.surface, palette.name .. " names its surface")
        ok(not seen[palette.surface], "surface " .. tostring(palette.surface) .. " used once"); seen[palette.surface] = true
        local hex = palette.colors[1]
        local r, g, b = tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
        ns.ApplyPaletteColor(r, g, b, hex, palette.name)
        eq(ns.ActivePalette(), palette, "active palette")
        local want = {
            paper = base .. "palettes\\" .. palette.surface .. ".tga",
            metal = base .. "palettes\\" .. palette.surface .. "_band.tga",
        }
        for _, ov in ipairs(overlays) do
            eq(ov.tex._texture, want[ov.role], palette.name .. " " .. ov.role .. " overlay")
            ok(ov.tex._set.SetHorizTile and ov.tex._set.SetHorizTile[1], "overlay still tiles")
        end
        for _, path in pairs(want) do
            local f = io.open(repoRoot .. "/" .. path:gsub("^Interface\\AddOns\\Maines\\", ""):gsub("\\", "/"), "rb")
            ok(f, "texture on disk: " .. path)
            if f then f:close() end
        end
        -- tab strip, footer and page plates: toned, same brightness, cream text still readable
        for _, plate in ipairs({ns.TabBar, ns.FooterBar, unpack(plates)}) do
            for _, tone in ipairs(plate.tone) do
                for _, text in ipairs({CREAM, CREAM_SOFT}) do
                    worst = math.min(worst, contrast(text, tone))
                end
            end
        end
        local walnutHi = {0.24 * 1.2, 0.16 * 1.2, 0.09 * 1.2}
        ok(wlum(ns.TabBar.tone[2]) <= wlum(walnutHi) + 1e-9, palette.name .. ": tab strip no lighter than the walnut")
        local moved = math.abs(ns.TabBar.tone[2][1] - walnutHi[1]) + math.abs(ns.TabBar.tone[2][3] - walnutHi[3])
        ok(moved > 0.002, palette.name .. ": tab strip takes the palette color")
        -- the window frames: every piece swapped to the palette's frame, strips repeating whole
        for _, w in ipairs(windows) do
            for piece, tex in pairs(w.maines_frame) do
                if type(tex) == "table" then
                    local path = base .. "frames\\" .. palette.surface .. "\\" .. piece .. ".tga"
                    eq(tex._texture, path, palette.name .. " frame " .. piece)
                    local f = io.open(repoRoot .. "/" .. path:gsub("^Interface\\AddOns\\Maines\\", ""):gsub("\\", "/"), "rb")
                    ok(f, "frame texture on disk: " .. path)
                    if f then f:close() end
                end
            end
            local tc = w.maines_frame.top._set.SetTexCoord
            ok(tc and tc[2] >= 1 and tc[2] == math.floor(tc[2]), "top strip repeats a whole number of times")
            local lc = w.maines_frame.left._set.SetTexCoord
            ok(lc and lc[4] >= 1 and lc[4] == math.floor(lc[4]), "side strip repeats a whole number of times")
            -- about one repeat per 64 units, so rivets and tiles keep their shape
            ok(math.abs((w:GetWidth() + 26 - 32) / tc[2] - 64) < 12, "top strip repeat stays near 64 units")
            ok(math.abs((w:GetHeight() + 26 - 32) / lc[4] - 64) < 12, "side strip repeat stays near 64 units")
        end
        for _, band in ipairs(bands) do
            local moved = math.abs(band.toneHigh[1] - brassHigh[1]) + math.abs(band.toneHigh[3] - brassHigh[3])
            ok(moved > 0.02, palette.name .. ": title band takes the palette color")
            -- the title's ink is fixed: the band may only get lighter (to the eye), never darker
            ok(math.abs(lum(band.toneLow) - lum(brassLow)) < 0.06, palette.name .. ": band low stop keeps its brightness")
            ok(wlum(band.toneLow) >= wlum(brassLow) - 1e-9, palette.name .. ": band low stop no darker than brass")
            ok(wlum(band.toneHigh) >= wlum(brassHigh) - 1e-9, palette.name .. ": band high stop no darker than brass")
            local ink = {0.20, 0.11, 0.03}
            ok(contrast(ink, band.toneLow) >= contrast(ink, brassLow) - 1e-6, palette.name .. ": title contrast kept")
        end
    end
    -- every swatch of every palette (not just the first): plate text and the title stay readable
    local swatches, ink, worstTitle = 0, {0.20, 0.11, 0.03}, math.huge
    for _, palette in ipairs(ns.Palettes) do
        for _, hex in ipairs(palette.colors) do
            local r, g, b = tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
            ns.ApplyPaletteColor(r, g, b, hex, palette.name, true)
            swatches = swatches + 1
            for _, plate in ipairs({ns.TabBar, ns.FooterBar, unpack(plates)}) do
                for _, tone in ipairs(plate.tone) do
                    for _, text in ipairs({CREAM, CREAM_SOFT}) do worst = math.min(worst, contrast(text, tone)) end
                end
            end
            for _, band in ipairs(bands) do worstTitle = math.min(worstTitle, contrast(ink, band.toneLow), contrast(ink, band.toneHigh)) end
        end
    end
    ok(worstTitle >= contrast(ink, brassLow) - 1e-6, ("title ink contrast kept on every swatch (worst %.2f)"):format(worstTitle))
    note(("(%d swatches checked; worst title contrast %.2f)"):format(swatches, worstTitle))
    -- no palette name: the start look's overlays come back
    ns.ApplyPaletteColor(0.70, 0.47, 0.18)
    for _, ov in ipairs(overlays) do
        eq(ov.tex._texture, base .. (ov.role == "metal" and "brushed.tga" or "grain.tga"), "start overlay restored")
    end
    for _, w in ipairs(windows) do eq(w.maines_frame.tl._texture, base .. "frames\\brass\\tl.tga", "start frame restored") end
    -- the start look's weakest pair is the soft cream on the tab strip's light end, 5.6:1
    ok(worst >= 5.5, ("cream text on every toned plate keeps the start look's contrast (worst %.2f)"):format(worst))
    note(("(%d overlays, %d plates, 3 window frames, %d palettes checked; worst plate text contrast %.2f)"):format(
        #overlays, #plates + 2, #ns.Palettes, worst))
    Maines_NoteFrame:Hide(); Maines_Help_Frame:Hide()
end)

test("17. the chosen palette survives /reload; a removed palette falls back to the start look", function()
    local ns = mock.ns
    local function serialize(v, indent)
        if type(v) == "table" then
            local keys = {}
            for k in pairs(v) do keys[#keys + 1] = k end
            table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
            local parts = {}
            for _, k in ipairs(keys) do
                local key = type(k) == "string" and ("[%q]"):format(k) or ("[" .. tostring(k) .. "]")
                parts[#parts + 1] = indent .. "  " .. key .. " = " .. serialize(v[k], indent .. "  ") .. ","
            end
            return "{\n" .. table.concat(parts, "\n") .. "\n" .. indent .. "}"
        elseif type(v) == "string" then
            return ("%q"):format(v)
        else
            return tostring(v)
        end
    end
    -- a /reload: a fresh client process loading the add-on with what this session saved
    local function reload(db)
        local path = os.tmpname()
        local f = assert(io.open(path, "w"))
        f:write("Maines_DB = " .. serialize(db, "") .. "\n")
        f:close()
        local pipe = assert(io.popen('lua5.1 "' .. repoRoot .. '/tests/reload_probe.lua" "' .. path .. '" 2>&1'))
        local res = {}
        for line in pipe:lines() do
            local k, v = line:match("^(%w+)=(.*)$")
            if k then res[k] = v end
        end
        pipe:close()
        os.remove(path)
        return res
    end
    local pal = ns.Palettes[1]
    for _, p in ipairs(ns.Palettes) do if p.surface == "kiss" then pal = p end end
    local hex = pal.colors[2]
    local r, g, b = tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
    -- picking a swatch on the Cosmetic page saves it
    ns.ApplyPaletteColor(r, g, b, hex, pal.name)
    eq(Maines_DB.palette and Maines_DB.palette.name, pal.name, "saved in Maines_DB.palette")
    local expectBand
    for _, o in ipairs(mock.objects) do
        if type(o.toneHigh) == "table" and not expectBand then expectBand = o.toneHigh end
    end
    local expectTab = ns.TabBar.tone[2]
    local res = reload(Maines_DB)
    eq(res.errors, "0", "no errors after reload")
    eq(res.shown, "false", "restored before the window is first shown")
    eq(res.palette, pal.name, "palette back")
    eq(res.accent, ("%.4f,%.4f,%.4f"):format(r, g, b), "exact colour back")
    eq(res.band, ("%.4f,%.4f,%.4f"):format(expectBand[1], expectBand[2], expectBand[3]), "title band tone back")
    eq(res.tabbar, ("%.4f,%.4f,%.4f"):format(expectTab[1], expectTab[2], expectTab[3]), "tab strip tone back")
    eq(res.frame, "Interface\\AddOns\\Maines\\textures\\frames\\kiss\\tl.tga", "window frame back")
    eq(res.notefr, "Interface\\AddOns\\Maines\\textures\\frames\\kiss\\top.tga", "note frame back")
    eq(res.grain, "Interface\\AddOns\\Maines\\textures\\palettes\\kiss.tga", "surface textures back")
    eq(res.chatline, nil, "restored silently (no chat line on login)")

    -- /maincolor (the Random Palette button and the minimap right-click run it) saves too
    math.randomseed(5)
    slash("/maincolor")
    local rolled = ns.ActivePalette()
    ok(rolled, "/maincolor picked a palette")
    eq(Maines_DB.palette and Maines_DB.palette.name, rolled.name, "/maincolor roll saved")
    eq(reload(Maines_DB).palette, rolled.name, "rolled palette back after reload")

    -- a palette removed in a later version, or a damaged entry: start look, entry dropped
    for _, bad in ipairs({ {name = "A Palette That Was Removed", r = 0.5, g = 0.2, b = 0.1}, {name = pal.name, r = "x"}, "junk" }) do
        local res2 = reload({palette = bad})
        eq(res2.errors, "0", "no errors with a bad saved palette")
        eq(res2.palette, "nil", "falls back to the start look")
        eq(res2.frame, "Interface\\AddOns\\Maines\\textures\\frames\\brass\\tl.tga", "brass frame")
        eq(res2.grain, "Interface\\AddOns\\Maines\\textures\\grain.tga", "original grain")
        eq(res2.saved, "nil", "bad entry forgotten")
    end
    -- the start look itself: nothing saved, nothing applied
    ns.ApplyPaletteColor(0.70, 0.47, 0.18)
    eq(Maines_DB.palette, nil, "start look saves no palette")
    eq(reload(Maines_DB).palette, "nil", "start look after reload")
end)

test("18. status line: what Maines prints to chat also shows in the window; other add-ons' prints don't", function()
    local text = ns.StatusText
    ok(text and text.GetText, "the window has a status line (ns.StatusText)")
    ok(mock.isDescendant(text, Maines_Frame), "the status line is part of the Maines window")
    slash("/maines")
    local function status() return text:GetText() or "" end
    local function printedHas(s)
        for _, l in ipairs(mock.printed) do if l:find(s, 1, true) then return true end end
    end

    -- /mains: four chat lines as always, and the same facts on one line in the window
    slash("/mains Statusname (")
    ok(status():find("Statusname", 1, true), "/mains name in the status line, got " .. q(status()))
    ok(status():find("Main Name", 1, true) and status():find("Bracket Type", 1, true), "/mains labels in the status line")
    ok(printedHas("Statusname"), "/mains still prints to chat")

    -- a bracket button in the window says the same
    local braceBtn
    for _, b in ipairs(mock.findFrames(function(o) return o._type == "Button" and o.GetText and o:GetText() == "{Statusname}" end)) do braceBtn = b end
    ok(braceBtn, "found the {Statusname} bracket button")
    mock.click(braceBtn, "LeftButton", true)
    ok(status():find("{", 1, true) and status():find("Statusname", 1, true), "bracket button result in the status line, got " .. q(status()))

    -- a chat-filter change: same words as the chat line, without the green "Maines:" prefix
    local before = #mock.printed
    slash("/mainchat +SAY")
    local chatLine = mock.printed[#mock.printed]
    ok(#mock.printed > before and chatLine:find("added SAY to filter", 1, true), "/mainchat +SAY printed to chat")
    eq(status(), "Added SAY to filter", "filter change in the status line")
    ok(not status():find("Maines|r:", 1, true), "no chat prefix in the window")

    -- the feature files route through the same helper
    slash("/mainanim twinkle")
    ok(status():find("Twinkle", 1, true), "animation change in the status line, got " .. q(status()))
    slash("/mainphrase add status line phrase")
    ok(status():find("status line phrase", 1, true), "phrase added in the status line, got " .. q(status()))
    ns.SaveCustomBadge("Statusbadge", "o/")
    ok(status():find("Statusbadge", 1, true), "badge saved in the status line, got " .. q(status()))
    local pal = ns.Palettes[1]
    local hex = pal.colors[1]
    ns.ApplyPaletteColor(tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255, hex, pal.name)
    ok(status():find(pal.name, 1, true), "palette change in the status line, got " .. q(status()))

    -- someone else's print never lands in the Maines window
    local kept = status()
    print("OtherAddon: hello from somewhere else")
    eq(status(), kept, "another add-on's print leaves the status line alone")

    -- the line stays after the window closes and opens again, and is shown in full text
    Maines_Frame:Hide(); slash("/maines")
    eq(status(), kept, "status line kept across close/open")
    ok(text._set.SetWordWrap and text._set.SetWordWrap[1] == false, "one line (long messages are cut with ... and shown on hover)")

    -- tidy up for anything after this
    slash("/mainphrase del " .. #ns.PhrasesDB().list)
    ns.DeleteCustomBadge("Statusbadge")
    slash("/mainanim off")
    ns.ApplyPaletteColor(0.70, 0.47, 0.18)
    resetTagging()
end)

test("19. Maines' own close buttons (no WoW X) close their windows; Escape still closes; greyed buttons", function()
    for _, o in ipairs(mock.objects) do
        if o._template and o._template:find("UIPanelCloseButton", 1, true) then
            ok(not (mock.isDescendant(o, Maines_Frame) or mock.isDescendant(o, Maines_NoteFrame)
                or mock.isDescendant(o, Maines_Help_Frame)), "a WoW close button is still on a Maines window")
        end
    end
    local function closeOf(win)
        for _, b in ipairs(mock.findFrames(function(o) return o.tooltip == "Close" and mock.isDescendant(o, win) end)) do return b end
    end
    slash("/maines"); slash("/mainnote"); slash("/mainhelp")
    for _, win in ipairs({Maines_Frame, Maines_NoteFrame, Maines_Help_Frame}) do
        local b = closeOf(win)
        ok(b, (win:GetName() or "?") .. " has a Maines close button")
        ok(b.marks and #b.marks == 2, "the close button draws its own x")
        ok(win:IsShown(), (win:GetName() or "?") .. " open before the click")
        mock.click(b, "LeftButton")
        ok(not win:IsShown(), (win:GetName() or "?") .. " closed by its close button")
    end
    slash("/maines")
    mock.fireScript(Maines_Frame, "OnKeyDown", "ESCAPE")
    ok(not Maines_Frame:IsShown(), "Escape closes the window")

    -- Delete is greyed for a built-in badge and live for one of your own
    slash("/maines"); ns.ShowPanel("badges")
    local del
    for _, b in ipairs(mock.findFrames(function(o) return o._type == "Button" and o.GetText and o:GetText() == "Delete" end)) do del = b end
    ok(del and del.SetUnavailable, "found the Delete button")
    Maines_Badges_DB.selected = "Heart"; Maines_RefreshWindow()
    ok(del.unavailable, "Delete greyed for a built-in badge")
    ns.SaveCustomBadge("Greytest", "o/"); Maines_RefreshWindow()
    ok(not del.unavailable, "Delete live for your own badge")
    ns.DeleteCustomBadge("Greytest"); Maines_RefreshWindow()
    Maines_Frame:Hide()
end)

-- ---------------------------------------------------------------- summary
local function sortedKeys(t) local k = {}; for n in pairs(t) do k[#k + 1] = n end; table.sort(k); return k end
out(("== %d passed, %d failed"):format(passed, failed))
local stubs = mock.stubbedOrder
out("-- " .. #stubs .. " unknown methods were auto-stubbed as no-ops" ..
    (#stubs > 0 and (": " .. table.concat(stubs, " ")) or ""))
out("-- " .. #mock.recordedOrder .. " cosmetic setters only stored their values (nothing rendered)" ..
    (os.getenv("MAINES_VERBOSE") == "1" and (": " .. table.concat(mock.recordedOrder, " ")) or ""))
local tpl = sortedKeys(mock.unknownTemplates)
if #tpl > 0 then out("-- templates with no mock behaviour: " .. table.concat(tpl, " ")) end
for _, w in ipairs(mock.warnings) do out("-- warning: " .. w) end
if os.getenv("MAINES_VERBOSE") == "1" then
    out("-- globals read while undefined: " .. table.concat(sortedKeys(mock.missingGlobals), " "))
end
os.exit(failed == 0 and 0 or 1)
