-- Animated tag: instead of the same [Name] on every message, the tag steps through a short
-- sequence of "frames" - a different bracket each time, the name typed out letter by letter, a
-- capital letter rolling through the name, a small twinkling symbol, or your own saved phrases.
--
-- Chat messages can't move once they're sent, so the animation plays across messages: either
-- one step per message you send, or one step every so often (chosen on the Animate page or with
-- /mainanim). maines.lua asks ns.AnimatedTag for the current frame each time it tags a message.
local _, ns = ...

local PREFIX = "|cFF00FF00Maines|r: "

local STYLES = {
    {key = "off", label = "Off", desc = "Your tag stays the same on every message."},
    {key = "brackets", label = "Bracket cycle", desc = "Each step uses the next bracket style: [Name] (Name) <Name> ..."},
    {key = "typewriter", label = "Typewriter", desc = "The name types itself out, one letter per step: [N] [Na] [Nam] [Name]"},
    {key = "wave", label = "Capital wave", desc = "One capital letter rolls through the name: [nAme] [naMe] [namE] [Name]"},
    {key = "twinkle", label = "Twinkle", desc = "A small symbol beside the name changes each step: [Name *] [Name +] [Name x]"},
    {key = "phrases", label = "My phrases", desc = "Each step adds your next saved phrase (Phrases page) after the tag."},
}
local STYLE_BY_KEY = {}
for _, s in ipairs(STYLES) do STYLE_BY_KEY[s.key] = s end

local TWINKLE = {"*", "+", "x", "+"}
local INTERVALS = {{30, "30 sec"}, {60, "1 min"}, {300, "5 min"}, {900, "15 min"}}

local function DB()
    Maines_Anim_DB = Maines_Anim_DB or {}
    local db = Maines_Anim_DB
    if not STYLE_BY_KEY[db.style or ""] then db.style = "off" end
    if db.trigger ~= "time" then db.trigger = "message" end
    db.seconds = tonumber(db.seconds) or 60
    db.step = tonumber(db.step) or 0
    return db
end

-- Splits a UTF-8 string into characters, so names like "Lùna" animate letter by letter
-- instead of byte by byte.
local function Chars(s)
    local out = {}
    for ch in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do out[#out + 1] = ch end
    return out
end

-- Every frame of `style` for this tag, in order.
local function Frames(style, left, name, right)
    local frames = {}
    if style == "brackets" then
        frames[1] = left .. name .. right
        for _, key in ipairs(ns.Bracket_Order or {}) do
            local def = ns.Bracket_Types[key]
            local f = def[1] .. name .. def[2]
            if f ~= frames[1] then frames[#frames + 1] = f end
        end
    elseif style == "typewriter" then
        local chars = Chars(name)
        for i = 1, #chars do frames[i] = left .. table.concat(chars, "", 1, i) .. right end
    elseif style == "wave" then
        local chars = Chars(name:lower())
        for i = 1, #chars do
            local copy = {unpack(chars)}
            copy[i] = copy[i]:upper()
            frames[i] = left .. table.concat(copy) .. right
        end
        frames[#frames + 1] = left .. name .. right
    elseif style == "twinkle" then
        for i, sym in ipairs(TWINKLE) do frames[i] = left .. name .. " " .. sym .. right end
    elseif style == "phrases" then
        local list = ns.PhrasesDB and ns.PhrasesDB().list or {}
        for i, phrase in ipairs(list) do frames[i] = left .. name .. right .. " " .. phrase end
    end
    return frames
end
ns.AnimationFrames = Frames

-- Every frame of the active style - maines.lua uses this to spot a message that already
-- starts with one (resent from chat history) so it isn't tagged twice.
function ns.AllTagFrames(left, name, right)
    local db = DB()
    if db.style == "off" then return {} end
    return Frames(db.style, left, name, right)
end

local function CurrentIndex(db, n)
    if db.trigger == "time" then
        return math.floor(GetTime() / math.max(1, db.seconds)) % n + 1
    end
    return db.step % n + 1
end

-- Called by maines.lua for every message it's about to tag. nil means "use the plain tag".
function ns.AnimatedTag(left, name, right)
    local db = DB()
    if db.style == "off" then return nil end
    local frames = Frames(db.style, left, name, right)
    if #frames == 0 then return nil end
    return frames[CurrentIndex(db, #frames)]
end

-- Called by maines.lua right after it tags a message - that's one "step" in per-message mode.
function ns.OnTagSent()
    local db = DB()
    if db.style ~= "off" and db.trigger == "message" then db.step = db.step + 1 end
end

local function SetStyle(key)
    local db = DB()
    db.style = key
    db.step = 0
    ns.Say(PREFIX .. "tag animation: |cFFFFE4B5" .. STYLE_BY_KEY[key].label .. "|r",
        {kind = "ok", parts = {{label = "Tag animation", value = STYLE_BY_KEY[key].label}}})
end

local function SetTrigger(trigger, seconds)
    local db = DB()
    db.trigger = trigger
    if seconds then db.seconds = seconds end
    if trigger == "time" then
        ns.Say(PREFIX .. "tag animation steps every " .. db.seconds .. " seconds")
    else
        ns.Say(PREFIX .. "tag animation steps once per message you send")
    end
end

SLASH_MAINANIM1 = "/mainanim"
SlashCmdList["MAINANIM"] = function(msg)
    msg = strtrim(msg or ""):lower()
    local db = DB()
    local word, rest = msg:match("^(%S*)%s*(.-)$")
    if msg == "" then
        local s = STYLE_BY_KEY[db.style]
        ns.Say(PREFIX .. "tag animation is |cFFFFE4B5" .. s.label .. "|r, stepping "
            .. (db.trigger == "time" and ("every " .. db.seconds .. " seconds") or "once per message"))
        local names = {}
        for _, st in ipairs(STYLES) do names[#names + 1] = st.key end
        ns.Say(PREFIX .. "styles: " .. table.concat(names, ", ") .. "  -  /mainanim <style> | message | time <seconds>")
    elseif STYLE_BY_KEY[word] then
        SetStyle(word)
    elseif word == "message" then
        SetTrigger("message")
    elseif word == "time" then
        local secs = tonumber(rest)
        if secs and secs >= 10 then
            SetTrigger("time", math.floor(secs))
        else
            ns.Say(PREFIX .. "give a number of seconds, 10 or more: /mainanim time 60")
        end
    else
        ns.Say(PREFIX .. "unknown style \"" .. word .. "\" - type /mainanim to see the styles")
    end
    if Maines_RefreshWindow and Maines_Frame and Maines_Frame:IsShown() then Maines_RefreshWindow() end
end

-- ---- Animate page ----

local panel = ns.Panels.animate
local W = ns.PANEL_WIDTH
local C = ns.Colors
local SP = ns.SP

local function Label(text, font, color)
    local fs = panel:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(font or ns.Fonts.Body)
    fs:SetJustifyH("CENTER")
    fs:SetText(text or "")
    local c = color or C.INK
    fs:SetTextColor(c[1], c[2], c[3])
    return fs
end

local _, y = ns.MakeHeading(panel, "Animated tag", 0, 0, W)
local intro = Label("Your tag can change a little with each message you send, like a slow animation "
    .. "playing across your chat. Pick a style:", ns.Fonts.Body, C.INK_SOFT)
-- A reading width narrower than the page, so the intro wraps into even lines.
intro:SetPoint("TOP", panel, "TOP", 0, y)
ns.BalanceText(intro, ns.READ_W)
y = y - intro:GetStringHeight() - SP.l

local styleButtons = {}
local COLS, BTN_W, BTN_H = 3, 180, ns.BUTTON_H + 2
local gridX = math.floor((W - (COLS * BTN_W + (COLS - 1) * SP.s)) / 2)
for i, st in ipairs(STYLES) do
    local col, row = (i - 1) % COLS, math.floor((i - 1) / COLS)
    local btn = ns.MakeButton(panel, BTN_W, BTN_H, st.label)
    btn:SetPoint("TOPLEFT", gridX + col * (BTN_W + SP.s), y - row * (BTN_H + SP.s))
    btn.tooltip = st.desc
    btn:SetScript("OnClick", function() SetStyle(st.key); Maines_RefreshWindow() end)
    styleButtons[st.key] = btn
end
y = y - math.ceil(#STYLES / COLS) * (BTN_H + SP.s) - SP.xs

-- Room for two lines (the "My phrases" style adds a warning line).
local styleDesc = Label("", ns.Fonts.Body, C.INK_SOFT)
styleDesc:SetPoint("TOPLEFT", 0, y)
styleDesc:SetWidth(W)
y = y - 2 * 14 - SP.xs - SP.xl

local _, ty = ns.MakeHeading(panel, "When it moves", 0, y, W)
y = ty
local perMessageBtn = ns.MakeButton(panel, 220, BTN_H, "One step per message")
perMessageBtn:SetPoint("TOPLEFT", math.floor((W - (2 * 220 + SP.s)) / 2), y)
perMessageBtn:SetScript("OnClick", function() SetTrigger("message"); Maines_RefreshWindow() end)
local overTimeBtn = ns.MakeButton(panel, 220, BTN_H, "One step every...")
overTimeBtn:SetPoint("LEFT", perMessageBtn, "RIGHT", SP.s, 0)
overTimeBtn:SetScript("OnClick", function() SetTrigger("time"); Maines_RefreshWindow() end)
y = y - BTN_H - SP.s

local intervalButtons = {}
local IV_W, IV_H = 76, ns.BUTTON_H - 2
local prev
for _, iv in ipairs(INTERVALS) do
    local btn = ns.MakeButton(panel, IV_W, IV_H, iv[2])
    if prev then
        btn:SetPoint("LEFT", prev, "RIGHT", SP.s, 0)
    else
        btn:SetPoint("TOPLEFT", math.floor((W - (#INTERVALS * IV_W + (#INTERVALS - 1) * SP.s)) / 2), y)
    end
    btn:SetScript("OnClick", function() SetTrigger("time", iv[1]); Maines_RefreshWindow() end)
    intervalButtons[iv[1]] = btn
    prev = btn
end
y = y - IV_H - SP.xl

local _, py = ns.MakeHeading(panel, "Preview", 0, y, W)
y = py

-- A dark nameplate the preview plays on, with the frame changing gently every 1.2 seconds -
-- slow enough to read each step, and only while this page is open.
local stage = CreateFrame("Frame", nil, panel, "BackdropTemplate")
stage:SetPoint("TOPLEFT", 0, y)
stage:SetSize(W, 60)
stage:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
stage:SetBackdropColor(C.PLATE_BG[1], C.PLATE_BG[2], C.PLATE_BG[3], 1)
stage:SetBackdropBorderColor(C.BORDER_DARK[1], C.BORDER_DARK[2], C.BORDER_DARK[3], 1)
ns.TonePlateBackdrop(stage) -- follows /maincolor, keeping the walnut's brightness
local stageShade = stage:CreateTexture(nil, "BACKGROUND", nil, 2)
stageShade:SetPoint("TOPLEFT", 1, -1)
stageShade:SetPoint("BOTTOMRIGHT", -1, 1)
stageShade:SetTexture("Interface\\Buttons\\WHITE8X8")
stageShade:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0.25), CreateColor(1, 0.9, 0.7, 0.07))

local stageText = stage:CreateFontString(nil, "OVERLAY")
stageText:SetFontObject(ChatFontNormal or ns.Fonts.Body)
stageText:SetPoint("LEFT", SP.l, 0)
stageText:SetPoint("RIGHT", -SP.l, 0)
stageText:SetJustifyH("CENTER")

local stageFade = stageText:CreateAnimationGroup()
local fadeIn = stageFade:CreateAnimation("Alpha")
fadeIn:SetFromAlpha(0.35)
fadeIn:SetToAlpha(1)
fadeIn:SetDuration(0.35)
fadeIn:SetSmoothing("OUT")

y = y - 60 - SP.m
local allFrames = Label("", ns.Fonts.BodySmall, C.INK_SOFT)
allFrames:SetPoint("TOPLEFT", 0, y)
allFrames:SetWidth(W)
allFrames:SetMaxLines(3)

local PREVIEW_STEP = 1.2
local previewIndex, previewElapsed = 0, 0

local function PreviewTagParts()
    local name = _G["Maines_Name_DB"]
    local left = _G["Maines_Bracket_Left_DB"]
    local right = _G["Maines_Bracket_Right_DB"]
    if not (name and name ~= "" and left) then return "[", "Name", "]" end
    return left, name, right or ""
end

local function ShowPreviewFrame()
    local db = DB()
    local left, name, right = PreviewTagParts()
    local frames = db.style ~= "off" and Frames(db.style, left, name, right) or {}
    if #frames == 0 then frames = {left .. name .. right} end
    previewIndex = previewIndex % #frames + 1
    stageText:SetText("|cFFE8B867" .. frames[previewIndex] .. "|r  |cFFE9DFC8Hello there, guildies!|r")
    stageFade:Stop()
    stageFade:Play()
end

panel:SetScript("OnUpdate", function(_, elapsed)
    previewElapsed = previewElapsed + elapsed
    if previewElapsed >= PREVIEW_STEP then
        previewElapsed = 0
        ShowPreviewFrame()
    end
end)
panel:HookScript("OnShow", function() previewIndex, previewElapsed = 0, 0; ShowPreviewFrame() end)

table.insert(ns.RefreshHooks, function()
    local db = DB()
    for key, btn in pairs(styleButtons) do
        if key == db.style then btn:Disable() else btn:Enable() end
    end
    styleDesc:SetText(STYLE_BY_KEY[db.style].desc
        .. ((db.style == "phrases" and #(ns.PhrasesDB().list) == 0) and "\n|cFF8B1E1EYou have no saved phrases yet.|r" or ""))
    if db.trigger == "time" then
        overTimeBtn:Disable(); perMessageBtn:Enable()
    else
        perMessageBtn:Disable(); overTimeBtn:Enable()
    end
    for secs, btn in pairs(intervalButtons) do
        if db.trigger == "time" and db.seconds == secs then btn:Disable() else btn:Enable() end
        if db.trigger == "time" then btn:Show() else btn:Hide() end
    end

    local left, name, right = PreviewTagParts()
    local frames = db.style ~= "off" and Frames(db.style, left, name, right) or {}
    if #frames > 1 then
        local shown = {}
        for i = 1, math.min(#frames, 6) do shown[i] = frames[i] end
        allFrames:SetText("Steps: " .. table.concat(shown, "   ") .. (#frames > 6 and "   ..." or ""))
    else
        allFrames:SetText("")
    end
    previewIndex = 0
    ShowPreviewFrame()
end)
