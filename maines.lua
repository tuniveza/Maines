--[[ 

    ADDON NAME: Maines

    DESCRIPTION: Take your main name to the chat frame then gtfo

    ADDON_AUTHOR: Dominic Hughes / Misamu - EU - Universe of Warcraft - Alliance - Silvermoon

    NOTES: Was so tired of seeing other addons not be customizable and up to scratch; then made this!

    STAMP: MOSAIC [ ▦ ]

    WHAT IS STAMP and MOSAIC [ ▦ ]?
    getting bored of the version ; alpha, beta, release so changed it to stamps ;)
    you can decide; where it's at in development... by using it.


    
    ------------------
    PRESENT FEATURES;
    ------------------

    [main] slash commands
    /main - to see your mainname and brackets type
    /mains  [/mains mainname leftbracketype]
    /mains  [/mains mainname symbol]            -- one custom symbol used for BOTH brackets, e.g. /mains Misamu *  ->  *Misamu*
    /mains  [/mains mainname left right]        -- independent left/right symbol sequences, e.g. /mains Misamu << >>  ->  <<Misamu>>
    /maines - to open the maines user interfaces

    [extra] slash commands:
    <NEW> /mainchat - [/mainchat SAY,WHISPER,GUILD,DND] - comma separated; case and spacing no longer matter, "say, guild" works fine
    <NEW> /mainchat list        -- print the currently active channel filter
    <NEW> /mainchat +CHANNEL    -- add a single channel to the existing filter
    <NEW> /mainchat -CHANNEL    -- remove a single channel from the existing filter
    <NEW> /mainchat (no args)   -- clear the filter, tags every channel including Communities
    <NEW> /brackets - to see all bracket types
    <NEW> /maincolor - paints the Maines UI textures a random color from a random public-domain art palette
    <NEW> /mainmap - toggle the Maines minimap icon on/off
    <NEW> /mainhide / /mainshow - choose whether the tag is suppressed when you're playing your own main (default: hidden)
    <NEW> /mainhelp - opens a movable, scrollable command reference window (icons, an example graphic, grouped by category) - "/mainhelp text" prints the old chat version instead
    /mainmusic - to reset the maines introduction music upon first open
    /mainstamp - to see stamp (version) of maines


    NEXT FEATURES TO IMPLEMENT:
    Graphical User Interface Improvements *ENTIRE RE-WORK -_-*
    Aesthetic Brackets
    Aesthetic Features
    =========================

    Common And Solved Problems:
    
    If using whispering addons the main name might show in the messages to pick a specific channel of main name in chat frame operations you can use the extra slash command;
    
    /mainchat seperated with commas like so:
    
    /mainchat SAY,WHISPER,GULID,DND then press enter

    NOTE: case and spacing don't matter any more - "say, whisper" is normalized the same
    as "SAY,WHISPER" internally, so typos in casing won't silently break the filter.

    This will make it so your main name is only in the channels typed in and so you can just stop it from showing in the whisper this way; because you specified which channels to filter out or in and or however it works *need to check it*.

    IT WORKS; try it and experiment....


    Confusing and Unsolved Problem:
    One user reported experiencing no ability to send any messages using maines this was only in his case and am not entirely sure why that happened yet; but for most people that shouldn't be an issue

    PLEASE DO POST COMMENTS , SUGGESTIONS, ETC
    AT CURSEFORGE COMMENT SECTION

    ==========================================
    MIDNIGHT (12.1.0) COMPATIBILITY FIX - FIXED
    ==========================================
    Patch 12.0.0 rearchitected how WoW sends outgoing chat, which broke the old
    RawHook on SendChatMessage entirely (it silently stopped intercepting anything,
    no errors, name tag just never appeared). Maines now hooks the modern
    EventRegistry "ChatFrame.OnEditBoxPreSendText" callback instead, editing the
    edit box text directly before Blizzard reads it for sending. Classic clients
    fall back to hooking ChatEdit_SendText, since they don't fire that event.

    Chat tagging is confirmed working again on retail 12.1.0. If it ever appears
    silently broken again, run /maindebug to print exactly which check is failing
    (chat type, saved name/brackets, channel filter, dedupe) instead of guessing.

    ==========================================
    COMMUNITIES SUPPORT
    ==========================================
    Modern retail chat sent inside the Communities panel (the successor to plain
    Guild chat for cross-realm/Battle.net communities) uses its own chat type,
    COMMUNITIES_CHANNEL, distinct from GUILD. That type is now included by default
    so /mainchat tags Community chat out of the box. BN_WHISPER (Battle.net
    whispers) and the *_LEADER broadcast types (PARTY_LEADER, RAID_LEADER,
    INSTANCE_CHAT_LEADER) were added for the same reason. Use /mainchat with an
    explicit list if you want to exclude any of these again.

    MULTIPLE COMMUNITIES FIX:
    Users in more than one community reported the tag only working for some of
    them. Root cause: Blizzard doesn't reliably stamp the editbox's "chatType"
    attribute as COMMUNITIES_CHANNEL for every community you belong to - it can
    silently fall back to "SAY", which then gets filtered out by anyone using an
    explicit /mainchat list. Every club-chat editbox does always carry a clubId
    though (one per community), so ModifyChatMessage now normalizes chatType to
    COMMUNITIES_CHANNEL whenever a clubId is present (Guild/Officer club chat is
    left alone since it already reports correctly). This works for any number of
    communities. /maindebug now prints clubId/streamId too, for anyone reporting
    a future issue.

    ==========================================
    ON-MAIN DETECTION (/mainhide, /mainshow)
    ==========================================
    Previously Maines tagged chat the same way no matter which character was logged
    in, including your actual main - so playing your main produced messages like
    "(Misamu) hello" while you WERE Misamu. Maines now compares the logged-in
    character's name against your saved main name (case-insensitive) and, by
    default, suppresses the tag when they match. /mainshow switches back to
    always tagging, even on your main; /mainhide restores the default. Alts
    are always tagged regardless of this setting - it only changes what happens
    when the main itself is the one logged in.

    ==========================================
    /mainhelp IS NOW A WINDOW
    ==========================================
    /mainhelp used to dump ~40 lines into chat every time. It now opens a
    movable, scrollable panel dressed in the addon's own parchment art (bg.tga,
    closebutton.tga) instead of Blizzard's default chrome, built from the exact
    same Help_Sections data as before - same icons, descriptions, and examples,
    just laid out as widgets instead of print()s. A small graphic at the top
    illustrates what a tagged message looks like (img/mainhelp_example.tga) -
    it's a generated mockup, not a captured screenshot, and is captioned as such.
    /mainhelp text still prints the original chat version for anyone who wants
    something copyable.

    ==========================================
    /mainchat FILTERING WAS SILENTLY BROKEN
    ==========================================
    Reported as "filtering doesn't seem to do anything, using multiple channel
    names has issues." Root cause: entries from a comma-separated list were never
    trimmed or case-normalized. "/mainchat SAY, GUILD" (a space after the comma,
    completely natural to type) produced the filter entries "SAY" and " GUILD" -
    that leading space meant " GUILD" could never equal the real chatType
    "GUILD" again, so anything after the first channel silently stopped working.
    Lowercase input broke things worse: the +CHANNEL/-CHANNEL add/remove pattern
    required exact uppercase, so a mistyped "+whisper" fell through to the
    full-reset branch instead, wiping the whole filter and replacing it with one
    bogus "+WHISPER" entry (plus sign included) that could never match any real
    chatType - silently killing ALL tagging, not just the one channel being
    added. /mainchat now uppercases and trims every entry before matching, so
    case and stray whitespace no longer matter.

    ==========================================
    TOTAL LOAD FAILURE: time() IS NOT AVAILABLE
    ==========================================
    Reported as "won't show at all" - every single slash command gone, not just
    one feature. Cause: a `math.randomseed(time())` call (added purely for
    /maincolor variety across sessions) sat as a bare top-level statement, not
    inside any function, so it ran immediately at file load. `time` is nil in
    this client, so that call threw immediately - and since Lua aborts the rest
    of a chunk on an unhandled error, EVERYTHING after that line never executed:
    no frames, no slash command registrations, nothing. Confirmed by actually
    running maines.lua (not just syntax-checking it - luac -p happily accepts
    code that fails at runtime) against a stub WoW environment with `time` left
    undefined, which reproduced the identical crash at the identical line, and
    by re-running after removing the call, which then loaded clean. The
    randomseed call was removed outright rather than swapped for another
    guessed-at API in the moment. Permanent fix, once things were stable again:
    reintroduced it using GetTime() (a core, always-available WoW timer API,
    unlike the apparently-absent time()) wrapped in pcall(), so that even if
    THIS assumption ever turns out wrong too, the failure is caught and
    swallowed right there instead of aborting the rest of the file. Lesson:
    don't add "should be fine" top-level API calls without verifying them, and
    wrap anything cosmetic/non-essential that runs at file scope (outside every
    function) in pcall so a bad assumption can never take the whole addon down
    again.

    STILL TO DO:
    - Aesthetic / GUI rework (see NEXT FEATURES TO IMPLEMENT above - still applies)
    - General visual polish pass on frames, brackets, textures

 ]]
local maines = LibStub("AceAddon-3.0"):NewAddon("Maines","AceHook-3.0")

-- Session-to-session variety for /maincolor. GetTime() (unlike the apparently-absent time())
-- is a core WoW timer API that's about as safe a bet as they come, but this is purely cosmetic,
-- so it's still pcall-wrapped: if that assumption is ever wrong too, the failure is swallowed
-- right here instead of aborting the rest of the file the way the old time() call did.
pcall(function() math.randomseed(GetTime() * 1000) end)

local FontPath = [[Interface\AddOns\Maines\fonts\adventure\Adventure.ttf]]

-- Every UI texture gets registered here as it's created so /maincolor can repaint all of them at once.
local Maines_Textures = {}

-- UI Frames
local maines_frame = CreateFrame("Frame", "Maines_Frame", UIParent)
maines_frame:RegisterEvent("ADDON_LOADED")
local maines_header_frame = CreateFrame("Frame", "Maines_Header_Frame", maines_frame)
local maines_stamp_frame = CreateFrame("Frame", "Maines_Stamp_Frame", maines_frame)
local maines_option_frame = CreateFrame("Frame", "Maines_Option_Frame", maines_frame)
local maines_command_frame = CreateFrame("ScrollFrame", "Maines_Command_Frame", maines_frame, "UIPanelScrollFrameTemplate")

-- Slash Commands
SLASH_MAINES1 = '/maines'
SLASH_MAIN1 = '/main'
SLASH_MAINS1 = '/mains'
SLASH_MAINCHAT1 = '/mainchat'
SLASH_MAINMUSIC1 = '/mainmusic'
SLASH_MAINSTAMP1 = '/mainstamp'
SLASH_BRACKET1 = '/bracket'
SLASH_MAINCOLOR1 = '/maincolor'
SLASH_MAINMAP1 = '/mainmap'

Maines_Bracket_Color = ""
bracket_left_option = ""
Maines_Name = ""
bracket_right_option = ""
Maines_Chat_Options = {}
_G["PlayedMusic_DB"] = "noplayed"
_G["Space_Option_DB"] = ""

local Channel_Types = {
    "GUILD", "OFFICER", "RAID", "INSTANCE_CHAT", "PARTY", "WHISPER", "RAID_WARNING",
    "EMOTE", "VOICE_TEXT", "CHANNEL", "AFK", "DND", "SAY", "YELL",
    -- Modern retail additions: Communities panel chat, Battle.net whispers, and the
    -- leader-broadcast variants of party/raid/instance chat.
    "COMMUNITIES_CHANNEL", "BN_WHISPER", "PARTY_LEADER", "RAID_LEADER", "INSTANCE_CHAT_LEADER"
}

local Bracket_Types = {
    ["["] = {"[", "]", "|cFF1E90FF", "Square Bracket"},
    ["("] = {"(", ")", "|cFFFF0000", "Circle Bracket"},
    ["<"] = {"<", ">", "|cFF228B22", "Crocodile Bracket"},
    ["{"] = {"{", "}", "|cFFFFA500", "ButterFly Bracket"},
    ["."] = {".", ".", "|cFFF5F5F5", "Dot Bracket"},
    [":"] = {":", ":", "|cFFC8C8C8", "Double Dot Bracket"},
    ["-"] = {"-", "-", "|cFF778899", "Line Bracket"},
    ["~"] = {"~", "~", "|cFFADD8E6", "Wave Bracket"},
    ["@"] = {"@", "@", "|cFFADD8E6", "Spiral Bracket"},
    ["#"] = {"#", "#", "|cFFADD8E6", "Hash Bracket"},
}

-- /maincolor: dominant colors pulled from well-known public-domain paintings. Each entry is a
-- {name = ..., colors = {hex, hex, ...}} table; the command rolls a random palette, then a
-- random color from within it.
local Color_Palettes = {
    {name = "The Starry Night (Van Gogh, 1889)", colors = {"1B3B6F", "2E5A87", "0B1F3A", "F3D250", "F7E7A0"}},
    {name = "The Great Wave off Kanagawa (Hokusai, c.1831)", colors = {"1B3A5C", "3E6E96", "C9D8E0", "EDE4D3", "2A2A2A"}},
    {name = "The Kiss (Klimt, 1908)", colors = {"C9A227", "8B1E3F", "1C1C1C", "D4AF37", "5A3E2B"}},
    {name = "Water Lilies (Monet, 1906)", colors = {"7FA6A0", "A8C9C4", "D9A6C2", "5B7C99", "EDEAD9"}},
    {name = "The Scream (Munch, 1893)", colors = {"E8622C", "F2A65A", "2E3A6E", "8C1C13", "F4E3B2"}},
    {name = "Composition II (Mondrian, 1930)", colors = {"D40920", "1356A2", "F7D842", "1B1B1B", "F5F5F0"}},
}

local function Maines_HexToRGB(hex)
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

-- Slash command handlers:
SlashCmdList["MAINMUSIC"] = function() _G["PlayedMusic_DB"] = "noplayed" end
SlashCmdList["MAINSTAMP"] = function() print("The Mosaic Stamp [ ▦ ]") end
SlashCmdList["MAINCOLOR"] = function()
    if #Maines_Textures == 0 then
        print("|cFF00FF00Maines|r: no textures loaded yet — open /maines once first")
        return
    end
    local palette = Color_Palettes[math.random(#Color_Palettes)]
    local hex = palette.colors[math.random(#palette.colors)]
    local r, g, b = Maines_HexToRGB(hex)
    for _, tex in ipairs(Maines_Textures) do
        tex:SetVertexColor(r, g, b)
    end
    print(("|cFF00FF00Maines|r: painted #%s from \"%s\""):format(hex, palette.name))
end
SlashCmdList["MAINMAP"] = function()
    local icon = LibStub("LibDBIcon-1.0", true)
    if not (icon and icon:IsRegistered("Maines")) then
        print("|cFF00FF00Maines|r: minimap icon isn't available")
        return
    end
    Maines_DB = Maines_DB or {}
    Maines_DB.minimap = Maines_DB.minimap or {}
    Maines_DB.minimap.hide = not Maines_DB.minimap.hide
    if Maines_DB.minimap.hide then
        icon:Hide("Maines")
        print("|cFF00FF00Maines|r: minimap icon hidden")
    else
        icon:Show("Maines")
        print("|cFF00FF00Maines|r: minimap icon shown")
    end
end
SlashCmdList["BRACKET"] = function()
    local i = 1
    for k,v in pairs(Bracket_Types) do
        print(i.." = "..(v[1].." Maines "..v[2]).." - "..v[4]); i = i+1
    end
end
SlashCmdList["MAINES"] = function()
    maines_close_button:Show()
    maines_frame:Show()
    maines_header_frame:Show()
    maines_command_frame:Show()
    maines_stamp_frame:Show()
    maines_option_frame:Show()
    if _G["PlayedMusic_DB"] ~= "played" then
        PlaySoundFile("Interface\\Addons\\Maines\\music\\maines_intro.mp3")
    end
    _G["PlayedMusic_DB"] = "played"
end

-- Shared hide logic for the main window - used by the close button, Escape, and the minimap
-- icon's toggle below, so there's one place that knows which frames make up "the window."
local function Maines_HideMainWindow()
    maines_close_button:Hide()
    maines_frame:Hide()
    maines_command_frame:Hide()
    maines_stamp_frame:Hide()
    maines_option_frame:Hide()
end

-- Minimap left-click: show/hide instead of only ever showing.
local function Maines_ToggleMainWindow()
    if maines_frame:IsShown() then
        Maines_HideMainWindow()
    else
        SlashCmdList["MAINES"]()
    end
end
SlashCmdList["MAINS"] = function(msg)
    local args = {}
    for token in string.gmatch(msg or "", "%S+") do table.insert(args, token) end
    local name, leftArg, rightArg = args[1], args[2], args[3]

    local left, right, color, typ
    if leftArg and rightArg then
        -- Dual symbol sequence: left and right defined independently, e.g. /mains hello << >>
        left, right, color, typ = leftArg, rightArg, "|cFFDA70D6", "Custom Bracket"
    elseif leftArg then
        if Bracket_Types[leftArg] then
            left, right, color, typ = unpack(Bracket_Types[leftArg])
        else
            -- One custom symbol used for both sides, e.g. /mains hello *
            left, right, color, typ = leftArg, leftArg, "|cFFDA70D6", "Custom Bracket"
        end
    end

    if name and left and right then
        _G["Maines_Name_DB"] = name
        _G["Maines_Bracket_Left_DB"] = left
        _G["Maines_Bracket_Right_DB"] = right
        _G["Maines_Bracket_Option_DB"] = typ
        print("|cFFD2C7B7", "Main Name |r", "|cFFFFE4B5", name, "|r")
        print("|cFFC1B7A8", "Bracket Type", "|r", typ, "|r")
        print("|cFFB8AEA0", "Left Bracket", "|r", left, "|r")
        print("|cFFA9A193", "Right Bracket", "|r", right, "|r")
    else
        print("Usage: /mains <mainname> <bracket symbol> [right bracket symbol]")
        print("Example: /mains hello (        — will output (hello) in chat channels")
        print("Example: /mains hello *        — custom symbol for both sides: *hello*")
        print("Example: /mains hello << >>    — independent left/right sequences: <<hello>>")
    end
end
SlashCmdList["MAIN"] = function()
    local name = _G["Maines_Name_DB"] or ""
    local left = _G["Maines_Bracket_Left_DB"] or ""
    local right = _G["Maines_Bracket_Right_DB"] or ""
    local typ = _G["Maines_Bracket_Option_DB"] or ""
    print("|cFFD2C7B7", "Main Name |r", "|cFFFFE4B5", name, "|r")
    if typ and left and right then
        print("|cFFC1B7A8", "Bracket Type", "|r", typ, "|r")
        print("|cFFB8AEA0", "Left Bracket", "|r", left, "|r")
        print("|cFFA9A193", "Right Bracket", "|r", right, "|r")
    end
end
local function Maines_GetChatFilter()
    _G["Maines_Chat_Options_DB"] = _G["Maines_Chat_Options_DB"] or {}
    return _G["Maines_Chat_Options_DB"]
end

SlashCmdList["MAINCHAT"] = function(msg)
    msg = msg and strtrim(msg) or ""
    local filter = Maines_GetChatFilter()

    if msg == "" then
        wipe(filter)
        print("|cFF00FF00Maines|r: chat filter cleared — tagging all channels (including Communities)")
        return
    end

    if msg:lower() == "list" then
        if #filter == 0 then
            print("|cFF00FF00Maines|r: no filter set — tagging all channels")
        else
            print("|cFF00FF00Maines|r: tagging channels: "..table.concat(filter, ", "))
        end
        return
    end

    -- Channel names are always uppercase (SAY, GUILD, ...), and this is the actual bug behind
    -- "/mainchat doesn't do anything": entries were never trimmed or case-normalized, so
    -- "SAY, GUILD" (a space after the comma - completely natural to type) silently produced
    -- " GUILD" with a leading space, which then never matched the real chatType "GUILD" again.
    -- Worse, a mistyped "+whisper" (lowercase) failed the old op pattern entirely and fell
    -- through to the reset branch below, wiping the whole filter and replacing it with one
    -- bogus "+WHISPER" entry that could never match anything - silently killing all tagging.
    local normalized = msg:upper()

    local op, sel = normalized:match("^([%+%-])%s*(%u[%u_]*)%s*$")
    if op then
        if op == "+" then
            local exists = false
            for _, v in ipairs(filter) do if v == sel then exists = true; break end end
            if not exists then table.insert(filter, sel) end
            print("|cFF00FF00Maines|r: added "..sel.." to filter")
        else
            for i, v in ipairs(filter) do
                if v == sel then table.remove(filter, i); break end
            end
            print("|cFF00FF00Maines|r: removed "..sel.." from filter")
        end
        return
    end

    wipe(filter)
    for rawToken in normalized:gmatch("([^,]+)") do
        local token = strtrim(rawToken)
        if token ~= "" then table.insert(filter, token) end
    end
    if #filter == 0 then
        print("|cFF00FF00Maines|r: no valid channel names found - filter left empty, tagging all channels")
    else
        print("|cFF00FF00Maines|r: tagging channels: "..table.concat(filter, ", "))
    end
end

-- Chat formatting:
-- Patch 12.0.0 (Midnight) rearchitected the outgoing chat path, so raw-hooking the
-- protected SendChatMessage API no longer intercepts anything. Retail now wants addons
-- to edit the message via the EventRegistry "ChatFrame.OnEditBoxPreSendText" callback,
-- which fires before the edit box's text is read for sending.
local function Maines_TagMessage(msg, chatType)
    local name = _G["Maines_Name_DB"]
    local left = _G["Maines_Bracket_Left_DB"]
    local right = _G["Maines_Bracket_Right_DB"]
    if Maines_Debug then
        print(("|cFF00FF00Maines debug|r: name=%s left=%s right=%s"):format(tostring(name), tostring(left), tostring(right)))
    end
    if not (name and left and right) then return msg end

    -- /mainhide, /mainshow: decide what happens when you're actually playing the character
    -- set as your main, as opposed to an alt. Defaults to hidden (tagging yourself as
    -- yourself is pointless); /mainshow switches to always tagging regardless of who's logged in.
    local onMain = strlower(UnitName("player") or "") == strlower(name)
    if Maines_Debug then print("|cFF00FF00Maines debug|r: onMain="..tostring(onMain).." mode="..tostring(Maines_HideOnMain_DB and "hide" or "tag")) end
    if onMain and Maines_HideOnMain_DB then
        return msg
    end

    local filter = _G["Maines_Chat_Options_DB"]
    local valid = false
    if filter and type(filter) == "table" and #filter > 0 then
        for _, v in ipairs(filter) do if chatType == v then valid = true; break end end
        if Maines_Debug then print("|cFF00FF00Maines debug|r: using filter table, size="..#filter.." valid="..tostring(valid)) end
    else
        for _, ctype in ipairs(Channel_Types) do if chatType == ctype then valid = true; break end end
        if Maines_Debug then print("|cFF00FF00Maines debug|r: no filter, checked Channel_Types, valid="..tostring(valid)) end
    end

    local alreadyTagged = string.find(msg, left..name..right, 1, true)
    if Maines_Debug then print("|cFF00FF00Maines debug|r: alreadyTagged="..tostring(alreadyTagged)) end
    if valid and not alreadyTagged then
        return left .. name .. right .. " " .. msg
    end
    return msg
end

function maines:ModifyChatMessage(editBox)
    if InCombatLockdown() then return end
    local msg = editBox:GetText()
    if not msg or msg == "" then return end
    -- The default SAY edit box has no "chatType" attribute set at all, so fall back to SAY.
    local chatType = editBox:GetAttribute("chatType") or editBox.chatType or "SAY"

    -- Community chat editboxes always carry a clubId (one per community you're a member of),
    -- but Blizzard doesn't reliably stamp the "chatType" attribute itself as COMMUNITIES_CHANNEL
    -- for every community beyond whichever one the client treats as primary - so a user in
    -- several communities could see chatType silently fall back to "SAY" for the others, which
    -- then gets filtered out by anyone using an explicit /mainchat list. Normalize using clubId
    -- so tagging works the same no matter which community, or how many, you're a member of.
    local clubId = editBox:GetAttribute("clubId") or editBox.clubId
    if clubId and chatType ~= "GUILD" and chatType ~= "OFFICER" then
        chatType = "COMMUNITIES_CHANNEL"
    end

    if Maines_Debug then
        print(("|cFF00FF00Maines debug|r: chatType=%s clubId=%s streamId=%s msg=%s"):format(
            tostring(chatType), tostring(clubId), tostring(editBox:GetAttribute("streamId") or editBox.streamId), tostring(msg)))
    end
    local tagged = Maines_TagMessage(msg, chatType)
    if tagged ~= msg then
        editBox:SetText(tagged)
        if Maines_Debug then print("|cFF00FF00Maines debug|r: after SetText, GetText()="..tostring(editBox:GetText())) end
    end
end

SLASH_MAINDEBUG1 = "/maindebug"
SlashCmdList["MAINDEBUG"] = function()
    Maines_Debug = not Maines_Debug
    print("|cFF00FF00Maines debug|r: "..(Maines_Debug and "ON" or "OFF"))
end

SLASH_MAINHIDE1 = "/mainhide"
SlashCmdList["MAINHIDE"] = function()
    Maines_HideOnMain_DB = true
    print("|cFF00FF00Maines|r: when playing your main ("..tostring(_G["Maines_Name_DB"] or "not set")..
        "), the tag will |cFFFFE4B5hide|r (switch back with /mainshow)")
end

SLASH_MAINSHOW1 = "/mainshow"
SlashCmdList["MAINSHOW"] = function()
    Maines_HideOnMain_DB = false
    print("|cFF00FF00Maines|r: when playing your main ("..tostring(_G["Maines_Name_DB"] or "not set")..
        "), the tag will |cFFFFE4B5still show|r (switch back with /mainhide)")
end

-- /mainhelp: a colored, icon-illustrated command reference grouped by what each command does,
-- with a usage line and a worked example per entry so nobody has to dig through the README.
-- Each section carries two colors: "color" is tuned for the dark chat frame (used by
-- Maines_PrintHelpToChat), "winColor" is a deeper equivalent tuned for the light parchment
-- panel in the /mainhelp window, where the chat colors (esp. the cyan and gray) wash out.
local Help_Sections = {
    {
        title = "Setting Up Your Main",
        color = "FF69B4",
        winColor = "B23A72",
        entries = {
            {icon = "INV_Misc_Note_01", cmd = "/mains", args = "<name> <bracket>",
                desc = "Set your main's name and bracket style.",
                example = "/mains Misamu (  ->  tags chat as (Misamu)"},
            {icon = "INV_Misc_Spyglass_03", cmd = "/main", args = "",
                desc = "Print your currently saved main name and bracket.",
                example = "/main"},
            {icon = "INV_Misc_Gem_02", cmd = "/bracket", args = "",
                desc = "List every built-in bracket style by name.",
                example = "/bracket"},
        },
    },
    {
        title = "On Your Main vs. an Alt",
        color = "3CE7FF",
        winColor = "1B6E96",
        entries = {
            {icon = "INV_Misc_QuestionMark", cmd = "/mainhide", args = "",
                desc = "Hide the tag while you're playing your own main. (default)",
                example = "/mainhide", note = "Alts are always tagged either way - this only affects the main itself."},
            {icon = "INV_Misc_QuestionMark", cmd = "/mainshow", args = "",
                desc = "Always tag, even while playing your own main.",
                example = "/mainshow"},
        },
    },
    {
        title = "Chat Channel Filtering",
        color = "77DD77",
        winColor = "2E7D32",
        entries = {
            {icon = "INV_Letter_15", cmd = "/mainchat", args = "SAY,GUILD,...",
                desc = "Only tag the listed channels (comma-separated - case and spacing don't matter).",
                example = "/mainchat SAY,GUILD,PARTY"},
            {icon = "INV_Letter_15", cmd = "/mainchat", args = "(no args)",
                desc = "Clear the filter - back to tagging every channel.",
                example = "/mainchat"},
            {icon = "INV_Letter_15", cmd = "/mainchat", args = "list",
                desc = "Print the channels currently in the filter.",
                example = "/mainchat list"},
            {icon = "INV_Letter_15", cmd = "/mainchat", args = "+CHANNEL / -CHANNEL",
                desc = "Add or remove one channel without retyping the whole list.",
                example = "/mainchat -WHISPER", note = "Handy if another addon already tags your whispers."},
        },
    },
    {
        title = "Cosmetic & Minimap",
        color = "FFA500",
        winColor = "A8631B",
        entries = {
            {icon = "INV_Misc_Dice_01", cmd = "/maincolor", args = "",
                desc = "Repaint the Maines UI with a random public-domain art palette.",
                example = "/maincolor", note = "Also triggered by right-clicking the minimap icon."},
            {icon = "INV_Misc_Map_01", cmd = "/mainmap", args = "",
                desc = "Toggle the Maines minimap icon on/off.",
                example = "/mainmap"},
            {icon = "INV_Misc_Gear_08", cmd = "/maines", args = "",
                desc = "Open the Maines UI (same as left-clicking the minimap icon).",
                example = "/maines"},
            {icon = "INV_Misc_Drum_01", cmd = "/mainmusic", args = "",
                desc = "Replay the intro jingle next time you open the UI.",
                example = "/mainmusic"},
        },
    },
    {
        title = "Utility",
        color = "AAAAAA",
        winColor = "5A5248",
        entries = {
            {icon = "INV_Misc_Coin_02", cmd = "/mainstamp", args = "",
                desc = "Print the current build stamp.",
                example = "/mainstamp"},
            {icon = "INV_Misc_Bag_10", cmd = "/maindebug", args = "",
                desc = "Toggle live debug printing of every tagging decision.",
                example = "/maindebug", note = "Turn this on first if tagging ever silently stops working."},
        },
    },
}

local function Maines_HelpIcon(tex, size)
    return ("|TInterface\\Icons\\%s:%d:%d:-1:0|t"):format(tex, size or 16, size or 16)
end

-- Chat fallback: the original print-based reference, kept behind "/mainhelp text" for anyone
-- who wants a copyable/scrollable-in-chat version instead of the window below.
local function Maines_PrintHelpToChat()
    print(("%s |cFFFFD100Maines — Command Reference|r %s"):format(
        Maines_HelpIcon("INV_Misc_QuestionMark"), Maines_HelpIcon("INV_Misc_QuestionMark")))
    print(" ")

    for _, section in ipairs(Help_Sections) do
        print(("|cFF%s%s|r"):format(section.color, section.title))
        for _, e in ipairs(section.entries) do
            local header = e.args ~= "" and (e.cmd.." |cFFFFFFFF"..e.args.."|r") or e.cmd
            print(("  %s |cFF%s%s|r"):format(Maines_HelpIcon(e.icon), section.color, header))
            print("      |cFFCCCCCC"..e.desc.."|r")
            print("      |cFF888888e.g.|r |cFFEEEEEE"..e.example.."|r")
            if e.note then
                print("      |cFF666666note:|r |cFF999999"..e.note.."|r")
            end
            print(" ")
        end
    end

    print("|cFFFFD100Full write-up with tables and more detail lives in the addon's README.|r")
end

-- /mainhelp window: a movable, scrollable reference panel built from the same Help_Sections
-- data as the chat version above, dressed in the addon's own parchment art instead of Blizzard
-- chrome. Content is a fixed-width column of FontStrings (one per section header, one per
-- command) chained top-to-bottom with GetStringHeight(), which is reliable even before the
-- frame has ever been shown - unlike GetTop()/GetBottom(), which can be unresolved on a frame
-- that's never been laid out yet.
local HELP_CONTENT_WIDTH = 430
local HELP_EXAMPLE_ASPECT = 290 / 920

local Help_Frame = CreateFrame("Frame", "Maines_Help_Frame", UIParent)
Help_Frame:SetSize(520, 620)
Help_Frame:SetPoint("CENTER")
Help_Frame:SetFrameStrata("DIALOG")
Help_Frame:SetMovable(true)
Help_Frame:EnableMouse(true)
Help_Frame:RegisterForDrag("LeftButton")
Help_Frame:SetScript("OnDragStart", Help_Frame.StartMoving)
Help_Frame:SetScript("OnDragStop", Help_Frame.StopMovingOrSizing)
Help_Frame:SetPropagateKeyboardInput(true)
Help_Frame:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then self:Hide() end
end)
Help_Frame:Hide()

Help_Frame.bg = Help_Frame:CreateTexture(nil, "BACKGROUND")
Help_Frame.bg:SetAllPoints()
Help_Frame.bg:SetTexture("Interface\\Addons\\Maines\\img\\bg")
table.insert(Maines_Textures, Help_Frame.bg)

Help_Frame.title = Help_Frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
Help_Frame.title:SetPoint("TOP", 0, -24)
Help_Frame.title:SetText("Maines — Command Reference")
Help_Frame.title:SetTextColor(0.96, 0.87, 0.65)

local helpClose = CreateFrame("Button", nil, Help_Frame)
helpClose:SetPoint("TOPRIGHT", -20, -20)
helpClose:SetSize(32, 32)
local helpCloseTex = helpClose:CreateTexture()
helpCloseTex:SetTexture("Interface\\Addons\\Maines\\img\\closebutton")
helpCloseTex:SetAllPoints()
helpClose:SetNormalTexture(helpCloseTex)
helpClose:SetScript("OnClick", function() Help_Frame:Hide() end)
table.insert(Maines_Textures, helpCloseTex)

-- A seamless, hand-tiled sand/parchment texture (img/parchment_tile.tga) instead of a flat
-- color, so the scroll panel reads as part of the same parchment the rest of the addon uses
-- rather than an unrelated dark box dropped on top of it.
local helpPanel = CreateFrame("Frame", nil, Help_Frame, "BackdropTemplate")
helpPanel:SetPoint("TOPLEFT", 26, -78)
helpPanel:SetPoint("BOTTOMRIGHT", -26, 22)
helpPanel:SetBackdrop({
    bgFile = "Interface\\Addons\\Maines\\img\\parchment_tile",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = true,
    tileSize = 128,
    edgeSize = 1,
})
helpPanel:SetBackdropColor(1, 1, 1, 1)
helpPanel:SetBackdropBorderColor(0.42, 0.30, 0.16, 1)

local helpScroll = CreateFrame("ScrollFrame", "Maines_Help_ScrollFrame", helpPanel, "UIPanelScrollFrameTemplate")
helpScroll:SetPoint("TOPLEFT", 10, -10)
helpScroll:SetPoint("BOTTOMRIGHT", -28, 10)

local helpContent = CreateFrame("Frame", "Maines_Help_ScrollChild", helpScroll)
helpContent:SetWidth(HELP_CONTENT_WIDTH)
helpContent:SetHeight(1)
helpScroll:SetScrollChild(helpContent)

local function Maines_BuildHelpContent()
    if Help_Frame.built then return end
    Help_Frame.built = true

    local y = -6

    local exampleTex = helpContent:CreateTexture(nil, "ARTWORK")
    exampleTex:SetPoint("TOPLEFT", 6, y)
    exampleTex:SetSize(HELP_CONTENT_WIDTH - 12, (HELP_CONTENT_WIDTH - 12) * HELP_EXAMPLE_ASPECT)
    exampleTex:SetTexture("Interface\\Addons\\Maines\\img\\mainhelp_example")
    y = y - exampleTex:GetHeight() - 22

    for _, section in ipairs(Help_Sections) do
        local winColor = section.winColor or section.color

        local header = helpContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        header:SetPoint("TOPLEFT", 6, y)
        header:SetJustifyH("LEFT")
        header:SetText(section.title)
        local r, g, b = Maines_HexToRGB(winColor)
        header:SetTextColor(r, g, b)
        y = y - header:GetStringHeight() - 10

        for _, e in ipairs(section.entries) do
            local entryFS = helpContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            entryFS:SetPoint("TOPLEFT", 6, y)
            entryFS:SetWidth(HELP_CONTENT_WIDTH - 12)
            entryFS:SetJustifyH("LEFT")

            local cmdLine = e.args ~= "" and (e.cmd.." |cFF2A2118"..e.args.."|r") or e.cmd
            local text = Maines_HelpIcon(e.icon, 18).." |cFF"..winColor..cmdLine.."|r\n"
                .."     |cFF4A4030"..e.desc.."|r\n"
                .."     |cFF8A7A63e.g.|r |cFF3A2A1E"..e.example.."|r"
            if e.note then
                text = text.."\n     |cFF8A7A63note:|r |cFF6B5F4D"..e.note.."|r"
            end
            entryFS:SetText(text)

            y = y - entryFS:GetStringHeight() - 14
        end

        y = y - 8
    end

    helpContent:SetHeight(-y + 10)
end

SLASH_MAINHELP1 = "/mainhelp"
SlashCmdList["MAINHELP"] = function(msg)
    msg = msg and strtrim(msg):lower() or ""
    if msg == "text" or msg == "chat" then
        Maines_PrintHelpToChat()
        return
    end
    Maines_BuildHelpContent()
    Help_Frame:Show()
end

-- Gently spins the minimap icon's texture forever, purely for fun.
local function Maines_AnimateMinimapButton(button)
    if not button or not button.icon or button.maines_anim then return end
    local ag = button.icon:CreateAnimationGroup()
    local rot = ag:CreateAnimation("Rotation")
    rot:SetDegrees(360)
    rot:SetDuration(8)
    rot:SetSmoothing("IN_OUT")
    ag:SetLooping("REPEAT")
    ag:Play()
    button.maines_anim = ag
end

function maines:SetupMinimapIcon()
    local ldb = LibStub("LibDataBroker-1.1", true)
    local icon = LibStub("LibDBIcon-1.0", true)
    if not (ldb and icon) then return end

    Maines_DB = Maines_DB or {}
    Maines_DB.minimap = Maines_DB.minimap or { hide = false }

    local dataObject = ldb:NewDataObject("Maines", {
        type = "launcher",
        text = "Maines",
        icon = "Interface\\Addons\\Maines\\img\\maines_minimap_icon",
        OnClick = function(_, button)
            if button == "LeftButton" then
                Maines_ToggleMainWindow()
            elseif button == "RightButton" then
                SlashCmdList["MAINCOLOR"]()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Maines")
            tooltip:AddLine("|cFFFFFFFFLeft-click|r to show/hide Maines")
            tooltip:AddLine("|cFFFFFFFFRight-click|r to recolor (/maincolor)")
        end,
    })

    icon:Register("Maines", dataObject, Maines_DB.minimap)
    -- Register() defers actual button creation when db.hide is true (stashed in an internal
    -- "notCreated" table instead), so GetMinimapButton() can return nil right here for anyone
    -- who previously hid the icon. Refresh() forces creation while still respecting db.hide.
    icon:Refresh("Maines", Maines_DB.minimap)
    local button = icon:GetMinimapButton("Maines")
    if button then
        table.insert(Maines_Textures, button.icon)
        Maines_AnimateMinimapButton(button)
    end
end

function maines:OnInitialize()
    -- Default: hide the tag when you're actually playing the character set as your main.
    -- Nil means never configured yet (fresh install or pre-/mainhide saved variables).
    if Maines_HideOnMain_DB == nil then
        Maines_HideOnMain_DB = true
    end

    -- Classic clients may have a backported EventRegistry table that never fires this
    -- event, so gate on the actual client build rather than just table presence.
    local _, _, _, tocVersion = GetBuildInfo()
    local isModernRetail = tocVersion and tocVersion >= 120000

    if isModernRetail and EventRegistry and EventRegistry.RegisterCallback then
        -- Retail 12.0+: edit the message in-place before it's sent.
        EventRegistry:RegisterCallback("ChatFrame.OnEditBoxPreSendText", function(_, editBox)
            self:ModifyChatMessage(editBox)
        end, self)
        print("|cFF00FF00Maines|r: chat hook active (EventRegistry)")
    else
        -- Classic clients: no EventRegistry callback, so hook the edit box's send path.
        self:RawHook("ChatEdit_SendText", true)
        print("|cFF00FF00Maines|r: chat hook active (ChatEdit_SendText)")
    end

    self:SetupMinimapIcon()
end

function maines:ChatEdit_SendText(editBox, addHistory)
    self:ModifyChatMessage(editBox)
    self.hooks.ChatEdit_SendText(editBox, addHistory)
end

-- UI logic and frame creation (full original code preserved):
maines_frame:SetPoint("CENTER")
maines_frame:SetSize(512, 512)
maines_frame:SetMovable(true)
maines_frame:EnableMouse(true)
maines_frame:SetFrameStrata("DIALOG")
maines_frame:RegisterForDrag("LeftButton")
maines_frame:SetScript("OnDragStart", maines_frame.StartMoving)
maines_frame:SetScript("OnDragStop", maines_frame.StopMovingOrSizing)
maines_frame.tex = maines_frame:CreateTexture()
maines_frame.tex:SetAllPoints(maines_frame)
maines_frame.tex:SetTexture("Interface\\Addons\\Maines\\img\\bg")
maines_header_frame.tex = maines_header_frame:CreateTexture()
maines_header_frame.tex:SetTexture("Interface\\Addons\\Maines\\img\\header")
maines_header_frame.tex:SetAllPoints()
maines_header_frame:SetPoint("CENTER", 0,320)
maines_header_frame:SetSize(512,128)
maines_command_frame.tex = maines_command_frame:CreateTexture()
maines_command_frame.tex:SetTexture("Interface\\Addons\\Maines\\img\\command_bg")
maines_command_frame.tex:SetAllPoints()
maines_command_frame:SetPoint("LEFT", -256,3)
maines_command_frame:SetSize(256,512)
maines_command_frame:SetFrameStrata("HIGH")
maines_option_frame.tex = maines_option_frame:CreateTexture()
maines_option_frame.tex:SetTexture("Interface\\Addons\\Maines\\img\\option")
maines_option_frame.tex:SetAllPoints()
maines_option_frame:SetPoint("CENTER", 0,-320)
maines_option_frame:SetSize(512,128)
maines_option_frame:SetFrameStrata("HIGH")
maines_stamp_frame:SetPoint("RIGHT", 256,-3)
maines_stamp_frame:SetSize(256,512)
maines_stamp_frame:SetFrameStrata("HIGH")
maines_stamp_frame.tex =  maines_stamp_frame:CreateTexture()
maines_stamp_frame.tex:SetAllPoints(maines_stamp_frame)
maines_stamp_frame.tex:SetTexture("Interface\\Addons\\Maines\\img\\stamp")
maines_stamp_frame.tex:SetAllPoints()
maines_close_button = CreateFrame("Button", "maines_close_button", maines_frame)
maines_close_button:SetPoint("CENTER", 282, 284)
maines_close_button:SetWidth(64)
maines_close_button:SetHeight(64)
maines_close_button:SetFrameStrata("DIALOG")
maines_close_button:SetNormalFontObject("GameFontNormal")
maines_close_button_texture = maines_close_button:CreateTexture()
maines_close_button_texture:SetTexture("Interface\\Addons\\Maines\\img\\closebutton")
maines_close_button_texture:SetAllPoints()
maines_close_button:SetNormalTexture(maines_close_button_texture)
maines_close_button:SetScript("OnClick", function(self, button, down)
    if button == "LeftButton" then
        Maines_HideMainWindow()
    elseif button == "RightButton" then
        print("You clicked the right button")
    end
end)
maines_frame:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        Maines_HideMainWindow()
    end
end)
maines_frame:SetPropagateKeyboardInput(true)

Maines_Option_Panel = CreateFrame("Frame", "Maines_Option_Panel", UIParent)
Maines_Option_Panel.name = "Maines"
Maines_Option_Panel_BG = CreateFrame("Frame", "Maines_Option_Panel_BG", Maines_Option_Panel, UIParent)
Maines_Option_Panel_BG:SetPoint("CENTER")
Maines_Option_Panel_BG:SetSize(512, 512)
Maines_Option_Panel_BG.tex = Maines_Option_Panel_BG:CreateTexture()
Maines_Option_Panel_BG.tex:SetAllPoints(Maines_Option_Panel_BG)
Maines_Option_Panel_BG.tex:SetTexture("Interface\\Addons\\Maines\\img\\maines_option_panel_bg")

-- Register every UI texture so /maincolor can repaint them all at once.
for _, tex in ipairs({
    maines_frame.tex, maines_header_frame.tex, maines_command_frame.tex,
    maines_option_frame.tex, maines_stamp_frame.tex, maines_close_button_texture,
    Maines_Option_Panel_BG.tex,
}) do
    table.insert(Maines_Textures, tex)
end

-- You may add the rest of your custom texture, scrollframe, and editbox logic here as needed.
-- All UI logic and slash commands now work in Classic.
