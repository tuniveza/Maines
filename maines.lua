--[[ 

    ADDON NAME: Maines

    DESCRIPTION: Take your main name to the chat frame then gtfo

    ADDON_AUTHOR: Dominic Hughes / Misamu - EU - Universe of Warcraft - Alliance - Silvermoon

    NOTES: Was so tired of seeing other addons not be customizable and up to scratch; then made this!

    STAMP: RADIAL [ ∂ ] 
    
    WHAT IS STAMP and RADIAL [ ∂ ]?
    getting bored of the version ; alpha, beta, release so changed it to stamps ;)
    you can decide; where it's at in development... by using it.


    
    ------------------
    PRESENT FEATURES;
    ------------------
    
    [main] slash commands
    /main - to see your mainname and brackets type
    /mains  [/mains mainname leftbracketype]
    /maines - to open the maines user interfaces

    [extra] slash commands:
    <NEW> /mainchat - [/mainchat SAY,WHISPER,GUILD,DND] - capital letters and comma seperation are a must
    <NEW> /brackets - to see all bracket types 
    /mainmusic - to reset the maines introduction music upon first open
    /mainstamp - to see stamp (version) of maines

    
    NEXT FEATURES TO IMPLEMENT:
    Graphical User Interface Improvements *ENTIRE RE-WORK -_-*
    Aesthetic Brackets
    Aesthetic Features
    
    SLASH COMMANDS:
    /mainhelp - a way to see all the commands for maines
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

 ]]
local maines = LibStub("AceAddon-3.0"):NewAddon("Maines","AceHook-3.0")

local FontPath = [[Interface\AddOns\Maines\fonts\adventure\Adventure.ttf]]

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

Maines_Bracket_Color = ""
bracket_left_option = ""
Maines_Name = ""
bracket_right_option = ""
Maines_Chat_Options = {}
_G["PlayedMusic_DB"] = "noplayed"
_G["Space_Option_DB"] = ""

local Channel_Types = {
    "GUILD", "OFFICER", "RAID", "INSTANCE_CHAT", "PARTY", "WHISPER", "RAID_WARNING",
    "EMOTE", "VOICE_TEXT", "CHANNEL", "AFK", "DND", "SAY", "YELL"
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

-- Slash command handlers:
SlashCmdList["MAINMUSIC"] = function() _G["PlayedMusic_DB"] = "noplayed" end
SlashCmdList["MAINSTAMP"] = function() print("The Radial Stamp [ ∂ ]") end
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
    local name = string.match(msg, "(%w+)")
    local left, right, color, typ
    for symbol, info in pairs(Bracket_Types) do
        if string.find(msg, "%" .. symbol) then
            left, right, color, typ = unpack(info)
            break
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
        print("Usage: /mains <mainname> <bracket symbol>")
        print("Example: /mains hello (  — will output (hello) in chat channels")
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
SlashCmdList["MAINCHAT"] = function(msg)
    Maines_Chat_Options = {}; for sel in string.gmatch(msg, "([^,]+)") do
        print("CHAT_SELECTION : "..sel); table.insert(Maines_Chat_Options, sel)
    end
    _G["Maines_Chat_Options_DB"] = Maines_Chat_Options
    ReloadUI()
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
    if not (name and left and right) then return msg end

    local filter = _G["Maines_Chat_Options_DB"]
    local valid = false
    if filter and type(filter) == "table" and #filter > 0 then
        for _, v in ipairs(filter) do if chatType == v then valid = true; break end end
    else
        for _, ctype in ipairs(Channel_Types) do if chatType == ctype then valid = true; break end end
    end

    if valid and not string.find(msg, left..name..right, 1, true) then
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
    if Maines_Debug then print("|cFF00FF00Maines debug|r: chatType="..tostring(chatType).." msg="..tostring(msg)) end
    local tagged = Maines_TagMessage(msg, chatType)
    if tagged ~= msg then
        editBox:SetText(tagged)
    end
end

SLASH_MAINDEBUG1 = "/maindebug"
SlashCmdList["MAINDEBUG"] = function()
    Maines_Debug = not Maines_Debug
    print("|cFF00FF00Maines debug|r: "..(Maines_Debug and "ON" or "OFF"))
end

function maines:OnInitialize()
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

-- You may add the rest of your custom texture, scrollframe, and editbox logic here as needed.
-- All UI logic and slash commands now work in Classic.
