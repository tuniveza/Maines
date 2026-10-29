-- Drives the real Maines code offline (tests/wowmock.lua) and prints, as JSON, the exact chat
-- text it produces for the README media: animated tags, saved phrases and Textual Badges.
-- Used by tools/media_chat.py; run by hand with:  lua5.1 tools/media_chat.lua [widths.tsv]
-- widths.tsv (optional): "<symbol>\t<pixels>" per line, the chat font's glyph widths as
-- measured by the renderer, so badge fitting runs exactly as it would against that font.

local scriptDir = (arg and arg[0] or ""):match("^(.*)[/\\][^/\\]*$") or "."
local repoRoot = scriptDir .. "/.."
package.path = repoRoot .. "/tests/?.lua;" .. package.path

local mock = require("wowmock")
mock.install()
mock.loadAddon(repoRoot, "Maines", {})
if #mock.loadErrors > 0 then
    io.stderr:write("load error: " .. tostring(mock.loadErrors[1].err) .. "\n")
    os.exit(1)
end
local ns, slash, sendChat = mock.ns, mock.slash, mock.sendChat

local MAIN, ALT = "Tuniveza", "Fizzlebolt"

-- ---------------------------------------------------------------- tiny JSON writer
local function jstr(s)
    return '"' .. s:gsub('[%c"\\]', function(c)
        if c == '"' then return '\\"' elseif c == "\\" then return "\\\\"
        elseif c == "\n" then return "\\n" end
        return ("\\u%04x"):format(c:byte())
    end) .. '"'
end
local function json(v)
    local t = type(v)
    if t == "string" then return jstr(v)
    elseif t == "number" or t == "boolean" then return tostring(v)
    elseif t == "table" then
        if #v > 0 or next(v) == nil then
            local parts = {}
            for _, x in ipairs(v) do parts[#parts + 1] = json(x) end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = k end
        table.sort(keys)
        local parts = {}
        for _, k in ipairs(keys) do parts[#parts + 1] = jstr(k) .. ":" .. json(v[k]) end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "null"
end

-- ---------------------------------------------------------------- chat font widths
-- In game, badges.lua measures each symbol as width("x"..u.."x") - width("xx") on a hidden
-- FontString. The mock's FontString is 7px per byte, so give the measurer the real widths.
local widths = {}
if arg[1] then
    for line in io.lines(arg[1]) do
        local sym, w = line:match("^(.-)\t([%d%.]+)$")
        if sym then widths[sym] = tonumber(w) end
    end
end
if next(widths) then
    local function fake(self)
        local t = self._text or ""
        if t == "xx" then return 0 end
        local u = t:sub(2, -2)
        return widths[u] or error("no measured width for symbol " .. ("%q"):format(u))
    end
    local origCreateFrame = CreateFrame
    CreateFrame = function(...)
        local f = origCreateFrame(...)
        local origCFS = f.CreateFontString
        f.CreateFontString = function(self, ...)
            local fs = origCFS(self, ...)
            fs.GetUnboundedStringWidth, fs.GetStringWidth = fake, fake
            return fs
        end
        return f
    end
end

-- ---------------------------------------------------------------- setup: on an alt
mock.state.playerName = ALT
mock.state.inCombat = false
slash("/mainchat")                 -- no channel filter
slash("/mainchat mode include")
slash("/mains " .. MAIN .. " [")
local out = { main = MAIN, alt = ALT, setup = "/mains " .. MAIN .. " [" }

-- ---------------------------------------------------------------- animated tag
-- {text, chatType[, whisper target]} - a mix of channels, all tagged by default
local messages = {
    brackets = { { "anyone up for a key?", "GUILD" }, { "need 1 more, tank pls", "GUILD" },
                 { "inv sent, summoning", "PARTY" } },
    typewriter = { { "back, what did I miss", "GUILD" }, { "lol", "GUILD" }, { "gz on the mount!", "GUILD" } },
    wave = { { "brb, food", "PARTY" }, { "ok back", "PARTY" }, { "thanks for the buff!", "SAY" } },
    twinkle = { { "who has a spare flask?", "GUILD" }, { "ty <3", "WHISPER", "Thandrel" },
                { "gn all, see you tmrw", "GUILD" } },
}
slash("/mainphrase clear")
for _, p in ipairs({ "Looking for group!", "o/ hello everyone", "Thanks for the run, gg!" }) do
    slash("/mainphrase add " .. p)
end
out.phrases = {}
for i, p in ipairs(Maines_Phrases_DB.list) do out.phrases[i] = p end

out.anim = {}
for _, style in ipairs({ "brackets", "typewriter", "wave", "twinkle" }) do
    slash("/mainanim off")
    slash("/mainanim " .. style)
    slash("/mainanim message")
    Maines_Anim_DB.step = 0
    local sent = {}
    for i, m in ipairs(messages[style]) do
        sent[i] = { typed = m[1], chatType = m[2], target = m[3],
                    sent = sendChat(m[2], m[1], m[3] and { tellTarget = m[3] } or nil) }
    end
    out.anim[#out.anim + 1] = { style = style, sent = sent,
        frames = ns.AnimationFrames(style, "[", MAIN, "]") }
end
slash("/mainanim off")

-- ---------------------------------------------------------------- saved phrases
-- Chat closed: the key binding's action opens chat with phrase 1; with the chat box focused,
-- the box's own key hook catches the bound key and swaps in the next phrase.
mock.bindings = {}
SetBinding("CTRL-1", "MAINES_NEXT_PHRASE")
local box = ChatFrame1EditBox
box:SetText(""); box:ClearFocus()
Maines_Phrases_DB.index = 0
local steps = {}
Maines_CyclePhrase(1)
steps[#steps + 1] = { key = "CTRL-1", box = box:GetText() }
mock.state.ctrl = true
for _ = 1, 2 do
    mock.fireScript(box, "OnKeyDown", "1")
    steps[#steps + 1] = { key = "CTRL-1", box = box:GetText() }
end
mock.state.ctrl = false
local final = box:GetText()
steps[#steps + 1] = { key = "ENTER", box = final, sent = sendChat("GUILD", final) }
out.phraseSteps = steps

-- ---------------------------------------------------------------- Textual Badges
mock.state.inGuild = true
-- the built-in badges, as /mainbadge list prints them
local printedBefore = #mock.printed
slash("/mainbadge list")
local badgeList = {}
for i = printedBefore + 1, #mock.printed do
    local n, name = mock.printed[i]:match("^%s+(%d+)%. (.-) |c")
    if n then badgeList[#badgeList + 1] = { index = tonumber(n), name = name } end
end
-- Send each one the way a player would (/mainbadge send <number> guild) and record every chat
-- line it puts out, with the time it leaves.
local function captureSend(command)
    mock.advanceTime(181, 1)          -- past the 3-minute cooldown
    local t0, lines = GetTime(), {}
    local origSend = C_ChatInfo.SendChatMessage
    C_ChatInfo.SendChatMessage = function(msg, chatType, ...)
        lines[#lines + 1] = { msg = msg, chatType = chatType, t = GetTime() - t0 }
        return origSend(msg, chatType, ...)
    end
    slash(command)
    mock.advanceTime(3, 0.05)
    C_ChatInfo.SendChatMessage = origSend
    return lines
end
out.badges = {}
for _, b in ipairs(badgeList) do
    local command = "/mainbadge send " .. b.index .. " guild"
    out.badges[#out.badges + 1] = { name = b.name, index = b.index, command = command,
                                    lines = captureSend(command) }
end
out.fitted = next(widths) ~= nil

io.write(json(out), "\n")
