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
                local want = btn.selected and 1 or 0.72
                ok(math.abs(vc[1] - want) < 1e-6, t .. " brightness " .. q(vc[1]) .. ", want " .. want)
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

test("16. a palette tones the title bands and swaps every grain/brushed overlay for its own", function()
    local ns = mock.ns
    slash("/maines"); slash("/mainnote")
    local base = "Interface\\AddOns\\Maines\\textures\\"
    local function lum(c) return 0.2126 * c[1] + 0.7152 * c[2] + 0.0722 * c[3] end
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
        for _, band in ipairs(bands) do
            local moved = math.abs(band.toneHigh[1] - brassHigh[1]) + math.abs(band.toneHigh[3] - brassHigh[3])
            ok(moved > 0.02, palette.name .. ": title band takes the palette color")
            -- the title's ink is fixed, so an unchanged band brightness = unchanged contrast
            ok(math.abs(lum(band.toneLow) - lum(brassLow)) < 1e-6, palette.name .. ": band low stop keeps its brightness")
            ok(math.abs(lum(band.toneHigh) - lum(brassHigh)) < 1e-6, palette.name .. ": band high stop keeps its brightness")
        end
    end
    -- no palette name: the start look's overlays come back
    ns.ApplyPaletteColor(0.70, 0.47, 0.18)
    for _, ov in ipairs(overlays) do
        eq(ov.tex._texture, base .. (ov.role == "metal" and "brushed.tga" or "grain.tga"), "start overlay restored")
    end
    note("(" .. #overlays .. " overlays, " .. #ns.Palettes .. " palettes checked)")
    Maines_NoteFrame:Hide()
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
