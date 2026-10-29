-- Saved phrases: words, sentences or symbols kept in a list and dropped into the chat box one
-- at a time with a key of the player's choosing (set on the Phrases page, or in WoW's own
-- Key Bindings > AddOns > Maines), or with /mainphrase.
--
-- Pressing the "next phrase" key opens the chat box with the next phrase in it; pressing it
-- again swaps that phrase for the one after, instead of piling them up. Nothing is ever sent
-- by itself - the player still presses Enter, so this can't spam a channel by accident.
local _, ns = ...

BINDING_HEADER_MAINES = "Maines"
BINDING_NAME_MAINES_NEXT_PHRASE = "Next saved phrase"
BINDING_NAME_MAINES_PREV_PHRASE = "Previous saved phrase"
BINDING_NAME_MAINES_SEND_BADGE = "Send the selected Textual Badge"

local PREFIX = "|cFF00FF00Maines|r: "
local MAX_PHRASES = 50
local MAX_PHRASE_LETTERS = 255

local function DB()
    Maines_Phrases_DB = Maines_Phrases_DB or {}
    local db = Maines_Phrases_DB
    db.list = db.list or {}
    db.index = db.index or 0
    return db
end
ns.PhrasesDB = DB

local function OpenChat(text)
    if ChatFrameUtil and ChatFrameUtil.OpenChat then return ChatFrameUtil.OpenChat(text) end
    if ChatFrame_OpenChat then return ChatFrame_OpenChat(text) end
end

local function ActiveChatBox()
    if ChatFrameUtil and ChatFrameUtil.GetActiveWindow then return ChatFrameUtil.GetActiveWindow() end
    if ChatEdit_GetActiveWindow then return ChatEdit_GetActiveWindow() end
end

-- ---- Key handling shared with the Badges page ----

local MODIFIER_KEYS = {
    LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true,
    LALT = true, RALT = true, LMETA = true, RMETA = true, UNKNOWN = true,
}

-- Turns a raw OnKeyDown key plus the held modifiers into WoW's binding spelling
-- ("ALT-CTRL-SHIFT-META-X"), using Blizzard's own helper when it's there. Returns nil for a
-- lone modifier key.
function ns.KeyCombo(key)
    if not key or MODIFIER_KEYS[key] then return nil end
    if CreateKeyChordStringUsingMetaKeyState then
        return CreateKeyChordStringUsingMetaKeyState(key)
    end
    local combo = ""
    if IsAltKeyDown() then combo = combo .. "ALT-" end
    if IsControlKeyDown() then combo = combo .. "CTRL-" end
    if IsShiftKeyDown() then combo = combo .. "SHIFT-" end
    if IsMetaKeyDown and IsMetaKeyDown() then combo = combo .. "META-" end
    return combo .. key
end

local function IsBoundTo(combo, action)
    for _, k in ipairs({GetBindingKey(action)}) do
        if k == combo then return true end
    end
    return false
end

function ns.BindingText(action)
    local keys = {GetBindingKey(action)}
    if #keys == 0 then return "not set" end
    return table.concat(keys, ", ")
end

-- Binds `combo` to `action` (replacing any key the action had before) and saves it to the
-- current binding set, exactly as the Key Bindings menu would.
function ns.SetActionKey(action, combo)
    if InCombatLockdown() then
        ns.Say(PREFIX .. "key bindings can't be changed in combat - try again after the fight")
        return false
    end
    local previous = GetBindingAction(combo)
    for _, old in ipairs({GetBindingKey(action)}) do SetBinding(old) end
    if not SetBinding(combo, action) then
        ns.Say(PREFIX .. "WoW refused the key " .. combo)
        return false
    end
    SaveBindings(GetCurrentBindingSet())
    ns.Say(PREFIX .. _G["BINDING_NAME_" .. action] .. " is now |cFFFFE4B5" .. combo .. "|r")
    if previous and previous ~= "" and previous ~= action then
        ns.Say(PREFIX .. combo .. " used to do: " .. (_G["BINDING_NAME_" .. previous] or previous))
    end
    return true
end

function ns.ClearActionKey(action)
    if InCombatLockdown() then
        ns.Say(PREFIX .. "key bindings can't be changed in combat - try again after the fight")
        return
    end
    for _, old in ipairs({GetBindingKey(action)}) do SetBinding(old) end
    SaveBindings(GetCurrentBindingSet())
    ns.Say(PREFIX .. _G["BINDING_NAME_" .. action] .. " key cleared")
end

-- ---- Cycling ----

-- What the last press put into the chat box, so the next press swaps it out.
local lastInserted

-- step is 1 (next) or -1 (previous). box is the chat edit box that has the keyboard, when the
-- key was pressed while typing; otherwise chat is opened.
function Maines_CyclePhrase(step, box)
    local db = DB()
    local n = #db.list
    if n == 0 then
        ns.Say(PREFIX .. "no saved phrases yet - add some on the Phrases page (/maines) or with /mainphrase add <text>")
        return
    end
    local i = db.index
    if i < 1 or i > n then i = (step > 0) and 0 or 1 end
    i = ((i - 1 + step) % n) + 1
    db.index = i
    local text = db.list[i]

    box = box or ActiveChatBox()
    if box and box:IsShown() and box:HasFocus() then
        local current = box:GetText() or ""
        if lastInserted and #lastInserted > 0 and current:sub(-#lastInserted) == lastInserted then
            box:SetText(current:sub(1, #current - #lastInserted) .. text)
        else
            box:Insert(text)
        end
    else
        OpenChat(text)
    end
    lastInserted = text
end

-- While the chat box has the keyboard, WoW doesn't run key bindings at all - every key goes
-- into the box. So the chat boxes themselves watch for the phrase keys too.
local function OnChatKeyDown(self, key)
    local combo = ns.KeyCombo(key)
    if not combo then return end
    if IsBoundTo(combo, "MAINES_NEXT_PHRASE") then
        Maines_CyclePhrase(1, self)
    elseif IsBoundTo(combo, "MAINES_PREV_PHRASE") then
        Maines_CyclePhrase(-1, self)
    end
end

local function HookChatBox(box)
    if box and box.HookScript and not box.maines_phrase_hook then
        box:HookScript("OnKeyDown", OnChatKeyDown)
        box.maines_phrase_hook = true
    end
end

-- The ten main chat boxes at login, plus any other box (whisper pop-outs, Communities) the
-- first time it's opened.
local hooker = CreateFrame("Frame")
hooker:RegisterEvent("PLAYER_LOGIN")
hooker:SetScript("OnEvent", function()
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        HookChatBox(_G["ChatFrame" .. i .. "EditBox"])
    end
    if ChatFrameUtil and ChatFrameUtil.ActivateChat then
        hooksecurefunc(ChatFrameUtil, "ActivateChat", HookChatBox)
    end
end)

-- ---- /mainphrase ----

local function AddPhrase(text)
    text = strtrim(text or "")
    local db = DB()
    if text == "" then
        ns.Say(PREFIX .. "nothing to add - type the phrase first")
        return false
    end
    if #db.list >= MAX_PHRASES then
        ns.Say(PREFIX .. "you already have " .. MAX_PHRASES .. " phrases - remove one first")
        return false
    end
    if #text > MAX_PHRASE_LETTERS then
        -- Not cut short: a cut could split a letter or a "||" pipe and break the message.
        ns.Say(PREFIX .. "that phrase is too long for one chat line - keep it under " .. MAX_PHRASE_LETTERS .. " bytes")
        return false
    end
    table.insert(db.list, text)
    ns.Say(PREFIX .. "saved phrase " .. #db.list .. ": " .. text)
    return true
end
ns.AddPhrase = AddPhrase

local function RemovePhrase(i)
    local db = DB()
    if not db.list[i] then
        ns.Say(PREFIX .. "there's no phrase number " .. tostring(i))
        return
    end
    local removed = table.remove(db.list, i)
    if db.index >= i then db.index = db.index - 1 end
    ns.Say(PREFIX .. "removed: " .. removed)
end
ns.RemovePhrase = RemovePhrase

SLASH_MAINPHRASE1 = "/mainphrase"
SlashCmdList["MAINPHRASE"] = function(msg)
    msg = strtrim(msg or "")
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()
    local db = DB()
    if cmd == "" or cmd == "list" then
        if #db.list == 0 then
            ns.Say(PREFIX .. "no saved phrases. Add one: /mainphrase add <text>")
        else
            ns.Say(PREFIX .. "saved phrases (next key: " .. ns.BindingText("MAINES_NEXT_PHRASE") .. "):")
            for i, p in ipairs(db.list) do print("  " .. i .. ". " .. p) end
        end
    elseif cmd == "add" then
        AddPhrase(rest)
    elseif cmd == "del" or cmd == "remove" then
        RemovePhrase(tonumber(rest))
    elseif cmd == "clear" then
        wipe(db.list)
        db.index = 0
        ns.Say(PREFIX .. "all saved phrases removed")
    elseif cmd == "next" then
        Maines_CyclePhrase(1)
    elseif cmd == "prev" then
        Maines_CyclePhrase(-1)
    else
        ns.Say(PREFIX .. "usage: /mainphrase [list] | add <text> | del <number> | clear | next | prev")
    end
    if Maines_RefreshWindow and Maines_Frame and Maines_Frame:IsShown() then Maines_RefreshWindow() end
end

-- ---- Phrases page ----

local panel = ns.Panels.phrases
local W = ns.PANEL_WIDTH
local C = ns.Colors
local SP = ns.SP

local function Label(parent, text, font, color)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(font or ns.Fonts.Body)
    fs:SetJustifyH("CENTER")
    fs:SetText(text or "")
    local c = color or C.INK
    fs:SetTextColor(c[1], c[2], c[3])
    return fs
end

local _, y = ns.MakeHeading(panel, "Saved phrases", 0, 0, W)

local intro = Label(panel, "Words, sentences or symbols you use a lot. Your shortcut key puts the next one into "
    .. "the chat box; press it again to swap to the one after. Press Enter to send.", ns.Fonts.Body, C.INK_SOFT)
-- A reading width narrower than the page, so the intro wraps into even lines.
intro:SetPoint("TOP", panel, "TOP", 0, y)
ns.BalanceText(intro, ns.READ_W)
y = y - intro:GetStringHeight() - SP.l

local input = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
-- Box and Add button centred together: 420 + m + 96 wide.
input:SetSize(420, ns.INPUT_H)
input:SetPoint("TOP", -(96 + SP.m) / 2, y - (ns.BUTTON_H - ns.INPUT_H) / 2)
input:SetAutoFocus(false)
input:SetJustifyH("CENTER")
input:SetMaxLetters(MAX_PHRASE_LETTERS)

local addBtn = ns.MakeButton(panel, 96, ns.BUTTON_H, "Add")
addBtn:SetPoint("LEFT", input, "RIGHT", SP.m, 0)
local function AddFromInput()
    if AddPhrase(input:GetText()) then
        input:SetText("")
        input:ClearFocus()
        Maines_RefreshWindow()
    end
end
addBtn:SetScript("OnClick", AddFromInput)
input:SetScript("OnEnterPressed", AddFromInput)
input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
y = y - ns.BUTTON_H - SP.m

-- The list: a scrolling column of rows, each with its number, the phrase, a "Use" button that
-- drops it into chat, and a remove button.
-- Six whole rows show before it scrolls (6 x 32 + s padding top and bottom).
local ROW_HEIGHT = 32
local LIST_HEIGHT = 6 * ROW_HEIGHT + 2 * SP.s
local listFrame = CreateFrame("Frame", nil, panel, "BackdropTemplate")
listFrame:SetPoint("TOPLEFT", 0, y)
listFrame:SetSize(W, LIST_HEIGHT)
ns.MakeFlatBackdrop(listFrame, {0.86, 0.76, 0.56, 1}, C.BORDER_DARK, 1)

local listScroll = CreateFrame("ScrollFrame", nil, listFrame, "UIPanelScrollFrameTemplate")
listScroll:SetPoint("TOPLEFT", SP.s, -SP.s)
listScroll:SetPoint("BOTTOMRIGHT", -28, SP.s)
local listChild = CreateFrame("Frame", nil, listScroll)
listChild:SetSize(W - 36, 1)
listScroll:SetScrollChild(listChild)

local emptyText = Label(listFrame, "No phrases yet - type one above and press Add.", ns.Fonts.Body, C.INK_SOFT)
emptyText:SetPoint("CENTER")

local rows = {}
local function GetRow(i)
    if rows[i] then return rows[i] end
    local row = CreateFrame("Frame", nil, listChild)
    row:SetSize(W - 36, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
    if i % 2 == 0 then
        local stripe = row:CreateTexture(nil, "BACKGROUND")
        stripe:SetAllPoints()
        stripe:SetTexture("Interface\\Buttons\\WHITE8X8")
        stripe:SetVertexColor(0.30, 0.19, 0.09, 0.08)
    end
    row.num = Label(row, "", ns.Fonts.Button, C.INK_SOFT)
    row.num:SetPoint("LEFT", SP.s, 0)
    row.num:SetWidth(28)
    row.num:SetJustifyH("LEFT")
    row.del = ns.MakeButton(row, 32, 24, "x")
    row.del:SetPoint("RIGHT", -SP.xs, 0)
    row.del.tooltip = "Remove this phrase"
    row.use = ns.MakeButton(row, 56, 24, "Use")
    row.use:SetPoint("RIGHT", row.del, "LEFT", -SP.xs, 0)
    row.use.tooltip = "Put this phrase into the chat box"
    row.text = Label(row, "", ns.Fonts.Body, C.INK)
    row.text:SetPoint("LEFT", row.num, "RIGHT", SP.s, 0)
    row.text:SetPoint("RIGHT", row.use, "LEFT", -SP.m, 0)
    row.text:SetWordWrap(false)
    row.del:SetScript("OnClick", function(self)
        RemovePhrase(self:GetParent().index)
        Maines_RefreshWindow()
    end)
    row.use:SetScript("OnClick", function(self)
        DB().index = self:GetParent().index - 1
        Maines_CyclePhrase(1)
    end)
    rows[i] = row
    return row
end

y = y - LIST_HEIGHT - SP.xl

-- Shortcut keys
local _, ky = ns.MakeHeading(panel, "Keyboard shortcuts", 0, y, W)
y = ky

-- One invisible, keyboard-grabbing frame shared by every "Set key" button: while it's shown,
-- the next key press (with any modifiers) becomes the binding. Escape cancels.
local capture = CreateFrame("Frame", nil, UIParent)
capture:SetFrameStrata("FULLSCREEN_DIALOG")
capture:SetAllPoints(UIParent)
capture:EnableKeyboard(true)
capture:SetPropagateKeyboardInput(false)
capture:Hide()
local function StopCapture()
    capture:Hide()
    Maines_RefreshWindow()
end
capture:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then StopCapture(); return end
    if key == "ENTER" then
        ns.Say(PREFIX .. "Enter opens chat, so it can't be a phrase key - press another key (Escape cancels)")
        return
    end
    local combo = ns.KeyCombo(key)
    if not combo then return end
    ns.SetActionKey(self.action, combo)
    StopCapture()
end)
capture:SetScript("OnHide", function(self)
    if self.button then self.button:SetText("Set key") end
    self.button, self.action = nil, nil
end)
-- Closing the window, or combat starting, must not leave an invisible frame swallowing the
-- keyboard.
Maines_Frame:HookScript("OnHide", function() capture:Hide() end)
capture:RegisterEvent("PLAYER_REGEN_DISABLED")
capture:SetScript("OnEvent", function(self) self:Hide() end)
ns.KeyCaptureFrame = capture

function ns.StartKeyCapture(button, action)
    if InCombatLockdown() then
        ns.Say(PREFIX .. "key bindings can't be changed in combat - try again after the fight")
        return
    end
    capture.button, capture.action = button, action
    button:SetText("Press a key...")
    capture:Show()
end

local keyRows = {}
local function KeyRow(action, labelText)
    -- label | key | Set key | Clear in fixed columns (170 | 130 | 140 | 80, gaps m), so both
    -- rows line up; the row is centred as one block.
    local LBL_W, KEY_W, SET_W, CLR_W = 170, 130, 140, 80
    local x0 = math.floor((W - (LBL_W + KEY_W + SET_W + CLR_W + 3 * SP.m)) / 2)
    local lbl = Label(panel, labelText, ns.Fonts.Body, C.INK)
    local textY = y - math.floor((ns.BUTTON_H - 14) / 2)
    lbl:SetPoint("TOPLEFT", x0, textY)
    lbl:SetWidth(LBL_W)
    lbl:SetJustifyH("RIGHT")
    local keyText = Label(panel, "", ns.Fonts.Button, C.INK)
    keyText:SetPoint("TOPLEFT", x0 + LBL_W + SP.m, textY)
    keyText:SetWidth(KEY_W)
    local setBtn = ns.MakeButton(panel, SET_W, ns.BUTTON_H, "Set key")
    setBtn:SetPoint("TOPLEFT", x0 + LBL_W + KEY_W + 2 * SP.m, y)
    setBtn:SetScript("OnClick", function(self) ns.StartKeyCapture(self, action) end)
    local clearBtn = ns.MakeButton(panel, CLR_W, ns.BUTTON_H, "Clear")
    clearBtn:SetPoint("LEFT", setBtn, "RIGHT", SP.m, 0)
    clearBtn:SetScript("OnClick", function() ns.ClearActionKey(action); Maines_RefreshWindow() end)
    table.insert(keyRows, {action = action, text = keyText})
    y = y - ns.BUTTON_H - SP.s
end
KeyRow("MAINES_NEXT_PHRASE", "Next phrase:")
KeyRow("MAINES_PREV_PHRASE", "Previous phrase:")

local tip = Label(panel, "Tip: pick a key with Ctrl or Alt (for example Ctrl-1), so it doesn't also type a "
    .. "letter while the chat box is open.", ns.Fonts.BodySmall, C.INK_SOFT)
tip:SetPoint("TOPLEFT", 0, y - SP.s)
tip:SetWidth(W)

table.insert(ns.RefreshHooks, function()
    local list = DB().list
    for i, phrase in ipairs(list) do
        local row = GetRow(i)
        row.index = i
        row.num:SetText(i .. ".")
        row.text:SetText(phrase)
        row:Show()
    end
    for i = #list + 1, #rows do rows[i]:Hide() end
    listChild:SetHeight(math.max(1, #list * ROW_HEIGHT))
    if #list == 0 then emptyText:Show() else emptyText:Hide() end
    for _, kr in ipairs(keyRows) do kr.text:SetText(ns.BindingText(kr.action)) end
end)
