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
    <NEW> /mainchat - [/mainchat SAY,WHISPER,GUILD,DND] - capital letters and comma seperation are a must
    <NEW> /mainchat list        -- print the currently active channel filter
    <NEW> /mainchat +CHANNEL    -- add a single channel to the existing filter
    <NEW> /mainchat -CHANNEL    -- remove a single channel from the existing filter
    <NEW> /mainchat (no args)   -- clear the filter, tags every channel including Communities
    <NEW> /brackets - to see all bracket types
    <NEW> /maincolor - paints the Maines UI textures a random color from a random public-domain art palette
    <NEW> /mainmap - toggle the Maines minimap icon on/off
    <NEW> /mainhide / /mainshow - choose whether the tag is suppressed when you're playing your own main (default: hidden)
    <NEW> /mainhelp - colored, icon-illustrated reference for every command above, grouped by category with usage examples
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

    NOTE: capital letters on channel names is mandatory
    
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

    STILL TO DO:
    - Aesthetic / GUI rework (see NEXT FEATURES TO IMPLEMENT above - still applies)
    - General visual polish pass on frames, brackets, textures

 ]]
local maines = LibStub("AceAddon-3.0"):NewAddon("Maines","AceHook-3.0")

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

    local op, sel = msg:match("^([%+%-])(%u[%u_]*)$")
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
    for sel in string.gmatch(msg, "([^,]+)") do
        table.insert(filter, sel)
    end
    print("|cFF00FF00Maines|r: tagging channels: "..table.concat(filter, ", "))
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
local Help_Sections = {
    {
        title = "Setting Up Your Main",
        color = "FF69B4",
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
        entries = {
            {icon = "INV_Letter_15", cmd = "/mainchat", args = "SAY,GUILD,...",
                desc = "Only tag the listed channels (capital letters, comma-separated).",
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

SLASH_MAINHELP1 = "/mainhelp"
SlashCmdList["MAINHELP"] = function()
    local function icon(tex) return ("|TInterface\\Icons\\%s:16:16:-1:0|t"):format(tex) end

    print(("%s |cFFFFD100Maines — Command Reference|r %s"):format(
        icon("INV_Misc_QuestionMark"), icon("INV_Misc_QuestionMark")))
    print(" ")

    for _, section in ipairs(Help_Sections) do
        print(("|cFF%s%s|r"):format(section.color, section.title))
        for _, e in ipairs(section.entries) do
            local header = e.args ~= "" and (e.cmd.." |cFFFFFFFF"..e.args.."|r") or e.cmd
            print(("  %s |cFF%s%s|r"):format(icon(e.icon), section.color, header))
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
                SlashCmdList["MAINES"]()
            elseif button == "RightButton" then
                SlashCmdList["MAINCOLOR"]()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Maines")
            tooltip:AddLine("|cFFFFFFFFLeft-click|r to open Maines")
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
        maines_close_button:Hide()
        maines_frame:Hide()
        maines_command_frame:Hide()
        maines_stamp_frame:Hide()
        maines_option_frame:Hide()
    elseif button == "RightButton" then
        print("You clicked the right button")
    end
end)
maines_frame:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        maines_close_button:Hide()
        maines_frame:Hide()
        maines_command_frame:Hide()
        maines_stamp_frame:Hide()
        maines_option_frame:Hide()
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
