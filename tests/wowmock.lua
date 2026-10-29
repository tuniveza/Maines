-- wowmock.lua - a small, offline stand-in for the World of Warcraft UI API, good enough to load
-- Maines (and its bundled Ace3 / LibDBIcon libraries) under plain Lua 5.1 and drive it from tests.
--
-- Fidelity rules:
--   * Methods are grouped into widget "families" (region, frame, button, editbox, ...). A method
--     that belongs to some family but NOT to the widget's type returns nil, so calling it fails
--     with "attempt to call method 'X' (a nil value)" - exactly what the game does (e.g.
--     SetBackdrop on a frame created without "BackdropTemplate").
--   * A Capitalized method name the mock has never heard of becomes a harmless no-op returning
--     nil, and its name is logged once in M.stubbed (so we can see what's NOT really exercised).
--   * Script handlers, event handlers, timers and callbacks run through M.dispatch, which, like
--     the game, sends errors to the error handler (M.errors) instead of aborting the caller.
--
-- Usage: local M = require("wowmock"); M.install(); M.loadAddon(repoRoot, "Maines")

local M = {}

local rawprint = print
M.rawprint = rawprint

M.objects = {}        -- every widget/texture/fontstring/animation created, in creation order
M.stubbed = {}        -- "Type:Method" -> true for auto-stubbed unknown methods
M.stubbedOrder = {}
M.recorded = {}       -- "Type:Method" -> true for cosmetic setters that were called (values stored, not rendered)
M.recordedOrder = {}
M.printed = {}        -- every line passed to print() / ChatFrameN:AddMessage()
M.sentMessages = {}   -- {msg=, chatType=, language=, target=} for C_ChatInfo.SendChatMessage
M.sounds = {}         -- PlaySoundFile / PlaySound calls
M.errors = {}         -- every error that reached the error handler
M.loadErrors = {}     -- {file=, err=} for addon files that failed to load
M.loadedFiles = {}    -- Lua files run by loadAddon, in order
M.bindings = {}       -- key -> command (SetBinding)
M.bindingCalls = {}   -- log of SetBinding / SaveBindings / override-binding calls
M.timers = {}
M.missingGlobals = {} -- globals read while nil (only when M.trackGlobals is on)
M.echo = os.getenv("MAINES_ECHO") == "1"

M.state = {
    now = 1000,            -- GetTime() clock, seconds
    playerName = "Altchar",
    realm = "TestRealm",
    inCombat = false,
    chatLockdown = false,
    alt = false, ctrl = false, shift = false,
    inGuild = true, inParty = false, inRaid = false, inInstanceGroup = false, inInstance = false,
    loggedIn = false,
    bindingSet = 1,        -- ACCOUNT_BINDINGS
    cursorX = 0, cursorY = 0,
}

local unpack = unpack or table.unpack

local function pack(...) return { n = select("#", ...), ... } end

-- --------------------------------------------------------------------------
-- Error handling / dispatch
-- --------------------------------------------------------------------------
local function errorHandler(err)
    local msg = tostring(err)
    if not msg:find("stack traceback", 1, true) then msg = debug.traceback(msg, 2) end
    table.insert(M.errors, msg)
    if M.echo then rawprint("[error handler] " .. msg) end
    return msg
end
M.errorHandler = errorHandler

-- Call fn(...) the way the game calls handlers: errors go to the error handler, not the caller.
function M.dispatch(fn, ...)
    if type(fn) ~= "function" then return end
    local args = pack(...)
    local res = pack(xpcall(function() return fn(unpack(args, 1, args.n)) end,
        function(e) return errorHandler(debug.traceback(tostring(e), 2)) end))
    if res[1] then return unpack(res, 2, res.n) end
end

-- --------------------------------------------------------------------------
-- Widget method families
-- --------------------------------------------------------------------------
local F = {}   -- family name -> {methodName = impl}
local function fam(name) F[name] = F[name] or {}; return F[name] end

-- Setters that only store their arguments (cosmetic: the mock can't render) and their getters.
local function storeSetter(family, setName, getName)
    fam(family)[setName] = function(self, ...)
        self._set[setName] = pack(...)
        local id = self._type .. ":" .. setName
        if not M.recorded[id] then M.recorded[id] = true; table.insert(M.recordedOrder, id) end
    end
    if getName then
        fam(family)[getName] = function(self)
            local v = self._set[setName]
            if v then return unpack(v, 1, v.n) end
        end
    end
end

local function children(obj) obj._children = obj._children or {}; return obj._children end

local function setParent(obj, parent)
    if obj._parent then
        local list = children(obj._parent)
        for i = #list, 1, -1 do if list[i] == obj then table.remove(list, i) end end
    end
    obj._parent = parent
    if parent then table.insert(children(parent), obj) end
end

local function fireTree(obj, script)
    if obj._scripts and obj._scripts[script] then M.dispatch(obj._scripts[script], obj) end
    for _, c in ipairs(obj._children or {}) do
        if c._shown and c._isFrame then fireTree(c, script) end
    end
end

-- region: everything on screen
local R = fam("region")
function R:SetPoint(point, rel, relPoint, x, y)
    if type(rel) == "number" then rel, relPoint, x, y = nil, nil, rel, relPoint end
    table.insert(self._points, { point, rel, relPoint, x or 0, y or 0 })
end
function R:ClearAllPoints() self._points = {} end
function R:SetAllPoints(rel) self._points = { { "TOPLEFT", rel }, { "BOTTOMRIGHT", rel } } end
function R:GetPoint(i) local p = self._points[i or 1]; if p then return unpack(p, 1, 5) end end
function R:GetNumPoints() return #self._points end
function R:SetSize(w, h) self._w = tonumber(w) or 0; self._h = tonumber(h or w) or 0 end
function R:GetSize() return self._w, self._h end
function R:SetWidth(w) self._w = tonumber(w) or 0 end
function R:SetHeight(h) self._h = tonumber(h) or 0 end
function R:GetWidth() return self._w end
function R:GetHeight() return self._h end
function R:GetLeft() return 0 end
function R:GetBottom() return 0 end
function R:GetRight() return self._w end
function R:GetTop() return self._h end
function R:GetCenter() return self._w / 2, self._h / 2 end
function R:GetRect() return 0, 0, self._w, self._h end
function R:GetScale() return self._scale end
function R:SetScale(s) self._scale = s end
function R:GetEffectiveScale() return self._scale end
function R:SetAlpha(a) self._alpha = a end
function R:GetAlpha() return self._alpha end
function R:IsShown() return self._shown end
function R:IsVisible()
    local o = self
    while o do if not o._shown then return false end; o = o._parent end
    return true
end
function R:Show()
    if self._shown then return end
    self._shown = true
    if self._isFrame and self:IsVisible() then fireTree(self, "OnShow") end
end
function R:Hide()
    if not self._shown then return end
    local wasVisible = self:IsVisible()
    self._shown = false
    if self._isFrame and wasVisible then fireTree(self, "OnHide") end
end
function R:SetShown(b) if b then self:Show() else self:Hide() end end
function R:GetParent() return self._parent end
function R:SetParent(p) setParent(self, p) end
function R:GetName() return self._name end
function R:GetDebugName() return self._name or ("<" .. self._type .. ">") end
function R:GetObjectType() return self._type end
function R:IsObjectType(t) return self._type == t or (t == "Button" and self._type == "CheckButton")
    or t == "Region" or (self._isFrame and t == "Frame") end
function R:IsForbidden() return false end
function R:IsProtected() return false end
function R:IsMouseOver() return false end
function R:CreateAnimationGroup(name) return M.newObject("AnimationGroup", name, self) end
storeSetter("region", "SetDrawLayer", "GetDrawLayer")
storeSetter("region", "SetIgnoreParentAlpha")
storeSetter("region", "SetIgnoreParentScale")

-- frame
local Fr = fam("frame")
function Fr:SetScript(name, fn) self._scripts[name] = fn end
function Fr:GetScript(name) return self._scripts[name] end
function Fr:HasScript() return true end
function Fr:HookScript(name, fn)
    local prev = self._scripts[name]
    if not prev then self._scripts[name] = fn; return end
    self._scripts[name] = function(...) prev(...); return fn(...) end
end
function Fr:RegisterEvent(e) self._events[e] = true end
function Fr:RegisterUnitEvent(e) self._events[e] = true end
function Fr:UnregisterEvent(e) self._events[e] = nil end
function Fr:UnregisterAllEvents() self._events = {} end
function Fr:RegisterAllEvents() self._allEvents = true end
function Fr:IsEventRegistered(e) return self._events[e] == true end
function Fr:CreateFontString(name, layer, template)
    local fs = M.newObject("FontString", name, self)
    fs._set.SetDrawLayer = pack(layer)
    if type(template) == "string" then
        fs._fontObject = _G[template]
        if not fs._fontObject then M.unknownTemplates["font " .. template] = true end
    end
    return fs
end
function Fr:CreateTexture(name, layer) local t = M.newObject("Texture", name, self); t._set.SetDrawLayer = pack(layer); return t end
function Fr:CreateLine(name, layer) return M.newObject("Line", name, self) end
function Fr:CreateMaskTexture(name) return M.newObject("Texture", name, self) end
function Fr:SetAttribute(k, v) self._attrs[k] = v end
function Fr:GetAttribute(k) return self._attrs[k] end
function Fr:EnableKeyboard(b) self._keyboard = b and true or false end
function Fr:IsKeyboardEnabled() return self._keyboard or false end
function Fr:SetPropagateKeyboardInput(b) self._propagate = b and true or false end
function Fr:GetPropagateKeyboardInput() return self._propagate or false end
function Fr:EnableMouse(b) self._mouse = b and true or false end
function Fr:IsMouseEnabled() return self._mouse or false end
function Fr:EnableMouseWheel(b) self._wheel = b and true or false end
function Fr:SetMovable(b) self._movable = b and true or false end
function Fr:IsMovable() return self._movable or false end
function Fr:SetResizable(b) self._resizable = b and true or false end
function Fr:SetFrameStrata(s) self._strata = s end
function Fr:GetFrameStrata() return self._strata or "MEDIUM" end
function Fr:SetFrameLevel(l) self._level = l end
function Fr:GetFrameLevel() return self._level or 1 end
function Fr:SetID(id) self._id = id end
function Fr:GetID() return self._id or 0 end
function Fr:GetChildren()
    local out = {}
    for _, c in ipairs(self._children or {}) do if c._isFrame then out[#out + 1] = c end end
    return unpack(out)
end
function Fr:GetRegions()
    local out = {}
    for _, c in ipairs(self._children or {}) do if not c._isFrame then out[#out + 1] = c end end
    return unpack(out)
end
function Fr:StartMoving() end
function Fr:StopMovingOrSizing() end
for _, n in ipairs({ "RegisterForDrag", "SetClampedToScreen", "SetToplevel", "SetHitRectInsets",
    "SetFixedFrameStrata", "SetFixedFrameLevel", "SetUserPlaced", "SetDontSavePosition",
    "SetClipsChildren", "SetResizeBounds", "SetClampRectInsets" }) do storeSetter("frame", n) end
function Fr:Raise() end
function Fr:Lower() end

-- backdrop: only frames created with "BackdropTemplate"
storeSetter("backdrop", "SetBackdrop", "GetBackdrop")
storeSetter("backdrop", "SetBackdropColor", "GetBackdropColor")
storeSetter("backdrop", "SetBackdropBorderColor", "GetBackdropBorderColor")
function F.backdrop:ApplyBackdrop() end

-- font instance (FontString, EditBox, Font objects)
local FI = fam("fontinstance")
function FI:SetFont(path, size, flags) self._font = { path, size, flags }; return true end
function FI:GetFont() if self._font then return unpack(self._font, 1, 3) end; return "Fonts\\FRIZQT__.TTF", 12, "" end
function FI:SetFontObject(o) self._fontObject = o end
function FI:GetFontObject() return self._fontObject end
storeSetter("fontinstance", "SetTextColor", "GetTextColor")
storeSetter("fontinstance", "SetJustifyH", "GetJustifyH")
storeSetter("fontinstance", "SetJustifyV", "GetJustifyV")
storeSetter("fontinstance", "SetShadowColor", "GetShadowColor")
storeSetter("fontinstance", "SetShadowOffset", "GetShadowOffset")
storeSetter("fontinstance", "SetSpacing", "GetSpacing")

-- font string
local FS = fam("fontstring")
function FS:SetText(t) if t == nil then self._text = nil else self._text = tostring(t) end end
function FS:GetText() return self._text end
function FS:SetFormattedText(fmt, ...) self._text = string.format(fmt, ...) end
function FS:GetStringWidth() return #(self._text or "") * 7 end
function FS:GetUnboundedStringWidth() return #(self._text or "") * 7 end
function FS:GetStringHeight() return 14 end
function FS:GetNumLines() return 1 end
function FS:IsTruncated() return false end
storeSetter("fontstring", "SetWordWrap", "CanWordWrap")
storeSetter("fontstring", "SetNonSpaceWrap", "CanNonSpaceWrap")
storeSetter("fontstring", "SetMaxLines", "GetMaxLines")
storeSetter("fontstring", "SetVertexColor", "GetVertexColor")
storeSetter("fontstring", "SetTextScale", "GetTextScale")

-- texture
local T = fam("texture")
function T:SetTexture(t) self._texture = t; return true end
function T:GetTexture() return self._texture end
function T:SetColorTexture(r, g, b, a) self._texture = "color"; self._set.SetColorTexture = pack(r, g, b, a) end
function T:SetAtlas(a) self._atlas = a; return true end
function T:GetAtlas() return self._atlas end
storeSetter("texture", "SetVertexColor", "GetVertexColor")
storeSetter("texture", "SetTexCoord", "GetTexCoord")
storeSetter("texture", "SetRotation", "GetRotation")
storeSetter("texture", "SetDesaturated", "IsDesaturated")
storeSetter("texture", "SetDesaturation", "GetDesaturation")
storeSetter("texture", "SetBlendMode", "GetBlendMode")
storeSetter("texture", "SetGradient")
storeSetter("texture", "SetHorizTile")
storeSetter("texture", "SetVertTile")
storeSetter("texture", "SetSnapToPixelGrid")
storeSetter("texture", "SetTexelSnappingBias")
function T:AddMaskTexture() end

-- button
local B = fam("button")
local function buttonFS(self)
    if not self._fontString then
        self._fontString = M.newObject("FontString", nil, self)
    end
    return self._fontString
end
function B:SetText(t) buttonFS(self):SetText(t) end
function B:GetText() return self._fontString and self._fontString:GetText() end
function B:GetFontString() return self._fontString end
function B:SetFontString(fs) self._fontString = fs end
function B:GetTextWidth() return self._fontString and self._fontString:GetStringWidth() or 0 end
function B:Enable() self._enabled = true end
function B:Disable() self._enabled = false end
function B:SetEnabled(b) self._enabled = b and true or false end
function B:IsEnabled() return self._enabled end
function B:Click(button, down)
    if not self._enabled then return end
    if self._type == "CheckButton" then self._checked = not self._checked end
    M.dispatch(self._scripts.OnClick, self, button or "LeftButton", down or false)
end
function B:RegisterForClicks(...) self._set.RegisterForClicks = pack(...) end
for _, n in ipairs({ "Normal", "Pushed", "Highlight", "Disabled" }) do
    B["Set" .. n .. "Texture"] = function(self, tex)
        if type(tex) ~= "table" then
            local t = M.newObject("Texture", nil, self); t._texture = tex; tex = t
        end
        self["_tex" .. n] = tex
    end
    B["Get" .. n .. "Texture"] = function(self)
        if not self["_tex" .. n] then self["_tex" .. n] = M.newObject("Texture", nil, self) end
        return self["_tex" .. n]
    end
    storeSetter("button", "Set" .. n .. "FontObject", "Get" .. n .. "FontObject")
    storeSetter("button", "Set" .. n .. "Atlas")
end
storeSetter("button", "SetButtonState", "GetButtonState")
function B:LockHighlight() end
function B:UnlockHighlight() end

-- check button
local CB = fam("checkbutton")
function CB:SetChecked(b) self._checked = b and true or false end
function CB:GetChecked() return self._checked end
storeSetter("checkbutton", "SetCheckedTexture", "GetCheckedTexture")
storeSetter("checkbutton", "SetDisabledCheckedTexture")

-- edit box
local function utf8chars(s) local n = 0; for _ in s:gmatch("[^\128-\191][\128-\191]*") do n = n + 1 end; return n end
local function utf8sub(s, max)
    local out, n = {}, 0
    for ch in s:gmatch("[^\128-\191][\128-\191]*") do
        n = n + 1; if n > max then break end; out[#out + 1] = ch
    end
    return table.concat(out)
end
local EB = fam("editbox")
function EB:SetText(t)
    t = t == nil and "" or tostring(t)
    if self._maxLetters and self._maxLetters > 0 and utf8chars(t) > self._maxLetters then
        t = utf8sub(t, self._maxLetters)
    end
    self._text = t
    self._cursor = #t
    M.dispatch(self._scripts.OnTextChanged, self, false)
end
function EB:GetText() return self._text or "" end
function EB:Insert(s)
    local t, c = self._text or "", self._cursor or #(self._text or "")
    self._text = t:sub(1, c) .. tostring(s) .. t:sub(c + 1)
    self._cursor = c + #tostring(s)
    M.dispatch(self._scripts.OnTextChanged, self, true)
end
function EB:GetNumLetters() return utf8chars(self._text or "") end
function EB:SetCursorPosition(p) self._cursor = math.max(0, math.min(tonumber(p) or 0, #(self._text or ""))) end
function EB:GetCursorPosition() return self._cursor or 0 end
function EB:SetFocus()
    if M.focus and M.focus ~= self then M.focus:ClearFocus() end
    M.focus = self
    M.dispatch(self._scripts.OnEditFocusGained, self)
end
function EB:ClearFocus()
    if M.focus == self then M.focus = nil; M.dispatch(self._scripts.OnEditFocusLost, self) end
end
function EB:HasFocus() return M.focus == self end
function EB:SetMaxLetters(n) self._maxLetters = tonumber(n) or 0 end
function EB:GetMaxLetters() return self._maxLetters or 0 end
function EB:SetMultiLine(b) self._multiLine = b and true or false end
function EB:IsMultiLine() return self._multiLine or false end
function EB:SetAutoFocus(b) self._autoFocus = b and true or false end
function EB:IsAutoFocus() return self._autoFocus or false end
function EB:SetNumeric(b) self._numeric = b and true or false end
function EB:IsNumeric() return self._numeric or false end
function EB:GetNumber() return tonumber(self._text or "") or 0 end
function EB:HighlightText() end
function EB:Enable() self._enabled = true end
function EB:Disable() self._enabled = false end
function EB:SetEnabled(b) self._enabled = b and true or false end
function EB:IsEnabled() return self._enabled end
function EB:AddHistoryLine(l) self._history = self._history or {}; table.insert(self._history, l) end
storeSetter("editbox", "SetTextInsets", "GetTextInsets")
storeSetter("editbox", "SetHistoryLines", "GetHistoryLines")
storeSetter("editbox", "SetCountInvisibleLetters")
storeSetter("editbox", "SetBlinkSpeed")

-- scroll frame
local SF = fam("scrollframe")
function SF:SetScrollChild(c) self._scrollChild = c; if c then setParent(c, self) end end
function SF:GetScrollChild() return self._scrollChild end
function SF:SetVerticalScroll(v) self._vscroll = v end
function SF:GetVerticalScroll() return self._vscroll or 0 end
function SF:SetHorizontalScroll(v) self._hscroll = v end
function SF:GetHorizontalScroll() return self._hscroll or 0 end
function SF:GetVerticalScrollRange()
    local c = self._scrollChild
    return c and math.max(0, c._h - self._h) or 0
end
function SF:GetHorizontalScrollRange() return 0 end
function SF:UpdateScrollChildRect() end

-- slider / status bar
local SL = fam("slider")
function SL:SetMinMaxValues(a, b) self._min, self._max = a, b end
function SL:GetMinMaxValues() return self._min or 0, self._max or 0 end
function SL:SetValue(v) self._value = v; M.dispatch(self._scripts.OnValueChanged, self, v, false) end
function SL:GetValue() return self._value or 0 end
function SL:Enable() self._enabled = true end
function SL:Disable() self._enabled = false end
function SL:IsEnabled() return self._enabled end
storeSetter("slider", "SetValueStep", "GetValueStep")
storeSetter("slider", "SetObeyStepOnDrag")
storeSetter("slider", "SetOrientation", "GetOrientation")
storeSetter("slider", "SetThumbTexture", "GetThumbTexture")
storeSetter("slider", "SetStatusBarTexture", "GetStatusBarTexture")
storeSetter("slider", "SetStatusBarColor", "GetStatusBarColor")

-- tooltip
local TT = fam("tooltip")
function TT:SetOwner(owner, anchor) self._owner = owner; self._lines = {} end
function TT:GetOwner() return self._owner end
function TT:IsOwned(f) return self._owner == f end
function TT:ClearLines() self._lines = {} end
function TT:AddLine(t) table.insert(self._lines, tostring(t)) end
function TT:AddDoubleLine(a, b) table.insert(self._lines, tostring(a) .. "\t" .. tostring(b)) end
function TT:SetText(t) self._lines = { tostring(t) } end
function TT:NumLines() return #self._lines end
function TT:SetHyperlink(l) self._lines = { tostring(l) } end

-- animation group / animation (time-driven by M.advanceTime)
local AG = fam("animgroup")
function AG:CreateAnimation(typ, name) local a = M.newObject("Animation", name, self); a._animType = typ; table.insert(self._anims, a); return a end
function AG:GetAnimations() return unpack(self._anims) end
function AG:Play() self._playing = true; self._started = M.state.now; M.dispatch(self._scripts.OnPlay, self) end
function AG:Restart() self:Stop(); self:Play() end
function AG:Stop() if self._playing then self._playing = false; M.dispatch(self._scripts.OnStop, self) end end
function AG:Pause() self._playing = false end
function AG:Finish() if self._playing then self._playing = false; M.dispatch(self._scripts.OnFinished, self) end end
function AG:IsPlaying() return self._playing or false end
function AG:SetLooping(l) self._looping = l end
function AG:GetLooping() return self._looping or "NONE" end
function AG:GetDuration()
    local byOrder = {}
    for _, a in ipairs(self._anims) do
        local o = a._order or 1
        byOrder[o] = math.max(byOrder[o] or 0, (a._duration or 0) + (a._delay or 0))
    end
    local total = 0
    for _, d in pairs(byOrder) do total = total + d end
    return total
end
function AG:GetParent() return self._parent end
storeSetter("animgroup", "SetToFinalAlpha")
AG.SetScript, AG.GetScript, AG.HookScript = Fr.SetScript, Fr.GetScript, Fr.HookScript
local AN = fam("animation")
function AN:SetDuration(d) self._duration = d end
function AN:GetDuration() return self._duration or 0 end
function AN:SetStartDelay(d) self._delay = d end
function AN:SetOrder(o) self._order = o end
function AN:GetOrder() return self._order or 1 end
function AN:GetParent() return self._parent end
function AN:Play() self._parent:Play() end
function AN:Stop() end
function AN:IsPlaying() return self._parent:IsPlaying() end
AN.SetScript, AN.GetScript, AN.HookScript = Fr.SetScript, Fr.GetScript, Fr.HookScript
for _, n in ipairs({ "SetDegrees", "SetRadians", "SetSmoothing", "SetFromAlpha", "SetToAlpha", "SetOffset",
    "SetScale", "SetScaleFrom", "SetScaleTo", "SetOrigin", "SetChange", "SetTarget", "SetChildKey",
    "SetTranslation" }) do storeSetter("animation", n) end

-- font objects (CreateFont)
local FO = fam("font")
function FO:GetName() return self._name end
function FO:CopyFontObject(o) if type(o) == "string" then o = _G[o] end; if o and o._font then self._font = { unpack(o._font) } end end
function FO:GetObjectType() return "Font" end

-- --------------------------------------------------------------------------
-- Object creation
-- --------------------------------------------------------------------------
local TYPE_FAMILIES = {
    Frame = { "region", "frame" },
    Button = { "region", "frame", "button" },
    CheckButton = { "region", "frame", "button", "checkbutton" },
    EditBox = { "region", "frame", "fontinstance", "editbox" },
    ScrollFrame = { "region", "frame", "scrollframe" },
    Slider = { "region", "frame", "slider" },
    StatusBar = { "region", "frame", "slider" },
    GameTooltip = { "region", "frame", "tooltip" },
    FontString = { "region", "fontinstance", "fontstring" },
    Texture = { "region", "texture" },
    Line = { "region", "texture" },
    AnimationGroup = { "animgroup" },
    Animation = { "animation" },
    Font = { "fontinstance", "font" },
}

-- Every method name any family knows about: calling one the widget's type lacks returns nil.
local KNOWN = {}
for _, f in pairs(F) do for k in pairs(f) do KNOWN[k] = true end end

local metas = {}
local function metaFor(obj)
    local key = obj._type .. (obj._backdrop and "+backdrop" or "")
    if metas[key] then return metas[key] end
    local methods = {}
    local fams = TYPE_FAMILIES[obj._type] or TYPE_FAMILIES.Frame
    for _, fname in ipairs(fams) do for k, v in pairs(F[fname]) do methods[k] = v end end
    if obj._backdrop then for k, v in pairs(F.backdrop) do methods[k] = v end end
    local typ = obj._type
    local mt = {
        __index = function(_, k)
            local m = methods[k]
            if m then return m end
            if type(k) ~= "string" or KNOWN[k] or not k:match("^%u") then return nil end
            local id = typ .. ":" .. k
            if not M.stubbed[id] then M.stubbed[id] = true; table.insert(M.stubbedOrder, id) end
            return function() end
        end,
        __tostring = function(o) return "mock " .. typ .. " " .. tostring(o._name or "") end,
    }
    metas[key] = mt
    return mt
end

function M.newObject(typ, name, parent, template)
    local obj = {
        _type = typ, _name = name, _set = {}, _scripts = {}, _events = {}, _attrs = {},
        _points = {}, _w = 0, _h = 0, _scale = 1, _alpha = 1, _shown = true, _enabled = true,
        _anims = {}, _template = template,
    }
    local fams = TYPE_FAMILIES[typ] or TYPE_FAMILIES.Frame
    for _, f in ipairs(fams) do if f == "frame" then obj._isFrame = true end end
    if template and template:find("BackdropTemplate", 1, true) then obj._backdrop = true end
    setmetatable(obj, metaFor(obj))
    if parent then setParent(obj, parent) end
    table.insert(M.objects, obj)
    if name and typ ~= "Animation" and typ ~= "AnimationGroup" then
        if parent and name:find("$parent", 1, true) then name = name:gsub("%$parent", parent._name or "") ; obj._name = name end
        _G[name] = obj
    end
    return obj
end

-- Minimal versions of the stock Blizzard templates Maines and its libraries use.
local TEMPLATES = {}
TEMPLATES.UIPanelCloseButton = function(f)
    f:SetSize(24, 24)
    f._scripts.OnClick = function(self) local p = self:GetParent(); if p then p:Hide() end end
end
TEMPLATES.UIPanelButtonTemplate = function(f)
    f.Text = M.newObject("FontString", nil, f); f._fontString = f.Text
    f.Left = M.newObject("Texture", nil, f); f.Middle = M.newObject("Texture", nil, f); f.Right = M.newObject("Texture", nil, f)
end
TEMPLATES.UICheckButtonTemplate = function(f)
    f.Text = M.newObject("FontString", nil, f); f.text = f.Text
    f:SetSize(32, 32)
end
TEMPLATES.InputBoxTemplate = function(f)
    f.Left = M.newObject("Texture", nil, f); f.Middle = M.newObject("Texture", nil, f); f.Right = M.newObject("Texture", nil, f)
end
TEMPLATES.UIPanelScrollFrameTemplate = function(f)
    f.ScrollBar = M.newObject("Slider", (f._name and f._name .. "ScrollBar") or nil, f)
    f.ScrollBar.ScrollUpButton = M.newObject("Button", nil, f.ScrollBar)
    f.ScrollBar.ScrollDownButton = M.newObject("Button", nil, f.ScrollBar)
end
TEMPLATES.ScrollFrameTemplate = TEMPLATES.UIPanelScrollFrameTemplate
TEMPLATES.GameTooltipTemplate = function() end
TEMPLATES.BackdropTemplate = function() end
M.TEMPLATES = TEMPLATES
M.unknownTemplates = {}

function M.CreateFrame(typ, name, parent, template)
    if type(parent) == "string" then parent = _G[parent] end
    local obj = M.newObject(typ or "Frame", name, parent, template)
    if type(template) == "string" then
        for t in template:gmatch("[^,%s]+") do
            if TEMPLATES[t] then TEMPLATES[t](obj)
            elseif not M.unknownTemplates[t] then M.unknownTemplates[t] = true end
        end
    end
    return obj
end

-- --------------------------------------------------------------------------
-- Test helpers
-- --------------------------------------------------------------------------
function M.fireEvent(event, ...)
    local list = {}
    for _, o in ipairs(M.objects) do
        if o._isFrame and (o._events[event] or o._allEvents) then list[#list + 1] = o end
    end
    for _, o in ipairs(list) do M.dispatch(o._scripts.OnEvent, o, event, ...) end
end

function M.fireScript(frame, script, ...)
    return M.dispatch(frame._scripts[script], frame, ...)
end

-- A real click: CheckButtons toggle before OnClick fires. Ignores the enabled state on purpose
-- when force is true (so tests can reach handlers of buttons that start disabled).
function M.click(frame, button, force)
    if not force and frame._enabled == false then return end
    if frame._type == "CheckButton" then frame._checked = not frame._checked end
    return M.dispatch(frame._scripts.OnClick, frame, button or "LeftButton", false)
end

function M.findFrames(pred)
    local out = {}
    for _, o in ipairs(M.objects) do if pred(o) then out[#out + 1] = o end end
    return out
end

function M.isDescendant(obj, ancestor)
    local p = obj._parent
    while p do if p == ancestor then return true end; p = p._parent end
    return false
end

-- Run a slash command line the way the chat box does: "/mains Radine [".
function M.slash(line)
    local cmd, rest = line:match("^(/%S+)%s*(.-)$")
    cmd = cmd and cmd:lower()
    for key, fn in pairs(SlashCmdList) do
        local i = 1
        while _G["SLASH_" .. key .. i] do
            if _G["SLASH_" .. key .. i]:lower() == cmd then return fn(rest or "", ChatFrame1EditBox) end
            i = i + 1
        end
    end
    error("unknown slash command " .. tostring(cmd), 2)
end

local fakeEditBox
-- Simulate pressing Enter in a chat edit box: fires "ChatFrame.OnEditBoxPreSendText" and returns
-- the text that would be sent. extraAttrs: e.g. {clubId = 123}.
function M.sendChat(chatType, text, extraAttrs)
    fakeEditBox = fakeEditBox or M.CreateFrame("EditBox", nil, UIParent)
    fakeEditBox._attrs = { chatType = chatType }
    for k, v in pairs(extraAttrs or {}) do fakeEditBox._attrs[k] = v end
    fakeEditBox:SetText(text)
    EventRegistry:TriggerEvent("ChatFrame.OnEditBoxPreSendText", fakeEditBox)
    return fakeEditBox:GetText()
end

local function addTimer(delay, fn, iterations, handle)
    local t = handle or {}
    t._due = M.state.now + math.max(delay or 0, 0)
    t._interval, t._fn, t._left = delay or 0, fn, iterations
    table.insert(M.timers, t)
    return t
end

-- Advance the GetTime() clock: runs due C_Timer callbacks in order, OnUpdate scripts of visible
-- frames every `step` seconds (default 0.1), and finishes non-looping animation groups.
function M.advanceTime(sec, step)
    step = step or 0.1
    local target = M.state.now + sec
    while M.state.now < target - 1e-9 do
        local nextT = math.min(target, M.state.now + step)
        -- timers due within this step, earliest first
        while true do
            local best, bi
            for i, t in ipairs(M.timers) do
                if not t._cancelled and t._due <= nextT + 1e-9 and (not best or t._due < best._due) then best, bi = t, i end
            end
            if not best then break end
            table.remove(M.timers, bi)
            M.state.now = math.max(M.state.now, best._due)
            M.dispatch(best._fn, best)
            if best._left ~= nil then
                if best._left ~= true then best._left = best._left - 1 end
                if (best._left == true or best._left > 0) and not best._cancelled then
                    addTimer(best._interval > 0 and best._interval or step, best._fn, best._left, best)
                end
            end
        end
        local elapsed = nextT - M.state.now
        M.state.now = nextT
        local snapshot = {}
        for _, o in ipairs(M.objects) do
            if o._isFrame and o._scripts.OnUpdate and o:IsVisible() then snapshot[#snapshot + 1] = o end
        end
        for _, o in ipairs(snapshot) do M.dispatch(o._scripts.OnUpdate, o, step) end
        for _, o in ipairs(M.objects) do
            if o._type == "AnimationGroup" and o._playing then
                local d = o:GetDuration()
                if M.state.now - o._started >= d then
                    if o._looping == "REPEAT" or o._looping == "BOUNCE" then
                        o._started = M.state.now
                        M.dispatch(o._scripts.OnLoop, o, "FORWARD")
                    else
                        o._playing = false
                        M.dispatch(o._scripts.OnFinished, o, false)
                    end
                end
            end
        end
        local _ = elapsed
    end
end

function M.printedSince(i)
    local out = {}
    for j = i + 1, #M.printed do out[#out + 1] = M.printed[j] end
    return out
end

-- --------------------------------------------------------------------------
-- String / table helpers that WoW adds to the Lua environment
-- --------------------------------------------------------------------------
local function strtrim(s, chars)
    chars = chars or " \t\r\n"
    local set = "[" .. chars:gsub("[%]%^%-%%]", "%%%0") .. "]"
    s = s:gsub("^" .. set .. "+", "")
    s = s:gsub(set .. "+$", "")
    return s
end

local function strsplit(delim, str, pieces)
    local out = {}
    local pattern = "[" .. delim:gsub("[%]%^%-%%]", "%%%0") .. "]"
    local start, n = 1, 0
    while true do
        if pieces and n == pieces - 1 then out[#out + 1] = str:sub(start); break end
        local s, e = str:find(pattern, start)
        if not s then out[#out + 1] = str:sub(start); break end
        out[#out + 1] = str:sub(start, s - 1); n = n + 1; start = e + 1
    end
    return unpack(out)
end

local function tostringall(...)
    local t = pack(...)
    for i = 1, t.n do t[i] = tostring(t[i]) end
    return unpack(t, 1, t.n)
end

-- 32-bit bit library (Lua 5.1 has none; WoW ships one)
local bit = {}
local function tobit(x) x = math.floor(x) % 4294967296; return x end
local function bitop(a, b, f)
    a, b = tobit(a), tobit(b)
    local r, p = 0, 1
    for _ = 1, 32 do
        local x, y = a % 2, b % 2
        if f(x, y) then r = r + p end
        a, b, p = (a - x) / 2, (b - y) / 2, p * 2
    end
    return r
end
function bit.band(a, b) return bitop(a, b, function(x, y) return x == 1 and y == 1 end) end
function bit.bor(a, b) return bitop(a, b, function(x, y) return x == 1 or y == 1 end) end
function bit.bxor(a, b) return bitop(a, b, function(x, y) return x ~= y end) end
function bit.bnot(a) return 4294967295 - tobit(a) end
function bit.lshift(a, n) return tobit(tobit(a) * 2 ^ n) end
function bit.rshift(a, n) return math.floor(tobit(a) / 2 ^ n) end

-- --------------------------------------------------------------------------
-- install(): put the fake API into _G
-- --------------------------------------------------------------------------
function M.install()
    local G = _G
    local S = M.state

    -- Lua 5.1's xpcall drops extra arguments; WoW's (5.1 + patches) passes them through.
    local xpcall51 = xpcall
    G.xpcall = function(f, eh, ...)
        local args = pack(...)
        return xpcall51(function() return f(unpack(args, 1, args.n)) end, eh)
    end

    G.print = function(...)
        local line = table.concat({ tostringall(...) }, " ")
        table.insert(M.printed, line)
        if M.echo then rawprint("[print] " .. line) end
    end
    G.strtrim, G.strsplit, G.tostringall = strtrim, strsplit, tostringall
    string.split = function(str, delim, pieces) return strsplit(delim, str, pieces) end
    string.trim = function(s, c) return strtrim(s, c) end
    G.strlower, G.strupper, G.strlen, G.strsub = string.lower, string.upper, string.len, string.sub
    G.strfind, G.strmatch, G.gsub, G.strrep = string.find, string.match, string.gsub, string.rep
    G.strbyte, G.strchar, G.strrev, G.format = string.byte, string.char, string.reverse, string.format
    G.strjoin = function(sep, ...) return table.concat({ ... }, sep) end
    G.strconcat = function(...) return table.concat({ ... }) end
    G.gmatch = string.gmatch
    G.tinsert, G.tremove, G.sort, G.tContains = table.insert, table.remove, table.sort, function(t, v)
        for _, x in pairs(t) do if x == v then return true end end; return false end
    G.wipe = function(t) for k in pairs(t) do t[k] = nil end; return t end
    table.wipe = G.wipe
    G.floor, G.ceil, G.abs, G.min, G.max, G.sqrt = math.floor, math.ceil, math.abs, math.min, math.max, math.sqrt
    G.random, G.mod = math.random, math.fmod
    G.bit = bit
    G.debugstack = function() return debug.traceback("", 2) end
    G.debugprofilestop = function() return S.now * 1000 end

    G.GetTime = function() return S.now end
    G.GetServerTime = function() return math.floor(1792000000 + S.now) end
    G.GetBuildInfo = function() return "12.1.5", "70575", "Oct 13 2026", 120105 end
    G.GetLocale = function() return "enUS" end
    G.IsLoggedIn = function() return S.loggedIn end
    G.UnitName = function(unit) if unit == "player" then return S.playerName, nil end; return nil end
    G.UnitGUID = function(unit) if unit == "player" then return "Player-0000-00000001" end end
    G.UnitClass = function() return "Warrior", "WARRIOR", 1 end
    G.UnitFactionGroup = function() return "Alliance", "Alliance" end
    G.UnitRace = function() return "Gnome", "Gnome", 7 end
    G.UnitSex = function() return 2 end
    G.GetCurrentRegion = function() return 3 end
    G.GetCurrentRegionName = function() return "EU" end
    G.UnitLevel = function() return 80 end
    G.GetRealmName = function() return S.realm end
    G.GetNormalizedRealmName = function() return (S.realm:gsub("%s", "")) end
    G.InCombatLockdown = function() return S.inCombat end
    G.IsAltKeyDown = function() return S.alt end
    G.IsControlKeyDown = function() return S.ctrl end
    G.IsShiftKeyDown = function() return S.shift end
    G.IsModifierKeyDown = function() return S.alt or S.ctrl or S.shift end
    G.IsMetaKeyDown = function() return false end
    G.LE_PARTY_CATEGORY_HOME, G.LE_PARTY_CATEGORY_INSTANCE = 1, 2
    G.IsInGuild = function() return S.inGuild end
    G.IsInRaid = function() return S.inRaid end
    G.IsInGroup = function(category)
        if category == G.LE_PARTY_CATEGORY_INSTANCE then return S.inInstanceGroup end
        return S.inParty or S.inRaid
    end
    G.IsInInstance = function() return S.inInstance, S.inInstance and "party" or "none" end
    G.GetCursorPosition = function() return S.cursorX, S.cursorY end
    G.GetCVar = function() return nil end
    G.GetCVarBool = function() return false end
    G.SetCVar = function() end

    G.PlaySoundFile = function(path, channel) table.insert(M.sounds, path); return true, #M.sounds end
    G.PlaySound = function(id, channel) table.insert(M.sounds, id); return true, #M.sounds end
    G.StopSound = function() end
    G.SOUNDKIT = setmetatable({}, { __index = function(_, k) return 0 end })

    -- errors
    G.geterrorhandler = function() return errorHandler end
    G.seterrorhandler = function() end
    G.securecall = function(f, ...)
        if type(f) == "string" then f = G[f] end
        return M.dispatch(f, ...)
    end
    G.securecallfunction = function(f, ...) return M.dispatch(f, ...) end
    G.secureexecuterange = function(t, f, ...)
        for k, v in pairs(t) do M.dispatch(f, k, v, ...) end
    end
    G.issecurevariable = function() return true, nil end
    G.issecure = function() return true end
    G.hooksecurefunc = function(tbl, name, fn)
        if type(tbl) == "string" then tbl, name, fn = G, tbl, name end
        local orig = tbl[name]
        assert(type(orig) == "function", "hooksecurefunc: " .. tostring(name) .. " is not a function")
        tbl[name] = function(...)
            local r = pack(orig(...))
            M.dispatch(fn, ...)
            return unpack(r, 1, r.n)
        end
    end

    -- mixins
    G.Mixin = function(obj, ...)
        for i = 1, select("#", ...) do for k, v in pairs((select(i, ...))) do obj[k] = v end end
        return obj
    end
    G.CreateFromMixins = function(...) return G.Mixin({}, ...) end
    G.CreateColor = function(r, g, b, a)
        return { r = r, g = g, b = b, a = a or 1, GetRGB = function(c) return c.r, c.g, c.b end,
            GetRGBA = function(c) return c.r, c.g, c.b, c.a end }
    end

    -- frames
    G.CreateFrame = M.CreateFrame
    G.CreateFont = function(name)
        local f = M.newObject("Font", name)
        return f
    end
    G.UIParent = M.CreateFrame("Frame", "UIParent")
    G.UIParent:SetSize(1920, 1080)
    G.WorldFrame = M.CreateFrame("Frame", "WorldFrame")
    G.Minimap = M.CreateFrame("Frame", "Minimap", G.UIParent)
    G.Minimap:SetSize(140, 140)
    G.GetMinimapShape = function() return "ROUND" end
    G.GameTooltip = M.CreateFrame("GameTooltip", "GameTooltip", G.UIParent, "GameTooltipTemplate")
    G.GameTooltip:Hide()
    G.UISpecialFrames = {}
    for _, n in ipairs({ "GameFontNormal", "GameFontHighlight", "GameFontNormalSmall", "GameFontHighlightSmall",
        "GameFontNormalLarge", "GameFontHighlightLarge", "GameFontNormalHuge", "GameFontDisable",
        "GameFontDisableSmall", "GameFontRed", "GameFontGreen", "GameFontWhite", "ChatFontNormal",
        "NumberFontNormal", "SystemFont_Shadow_Med1" }) do
        G.CreateFont(n)
    end
    G.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"

    -- chat frames + edit boxes
    G.NUM_CHAT_WINDOWS = 10
    for i = 1, G.NUM_CHAT_WINDOWS do
        local cf = M.CreateFrame("Frame", "ChatFrame" .. i, G.UIParent)
        cf.AddMessage = function(self, msg)
            table.insert(M.printed, tostring(msg))
            if M.echo then rawprint("[ChatFrame" .. i .. "] " .. tostring(msg)) end
        end
        local eb = M.CreateFrame("EditBox", "ChatFrame" .. i .. "EditBox", cf)
        eb:SetAttribute("chatType", "SAY")
        eb.chatFrame = cf
        cf.editBox = eb
        eb:Hide()
    end
    G.DEFAULT_CHAT_FRAME, G.SELECTED_CHAT_FRAME = G.ChatFrame1, G.ChatFrame1
    local function activeWindow()
        if M.focus and M.focus._name and M.focus._name:match("^ChatFrame%d+EditBox$") then return M.focus end
    end
    local function openChat(text, chatFrame)
        local eb = (chatFrame and chatFrame.editBox) or G.ChatFrame1EditBox
        eb:Show()
        eb:SetText(text or "")
        eb:SetFocus()
        G.LAST_ACTIVE_CHAT_EDIT_BOX = eb
        return eb
    end
    local function insertLink(link)
        local eb = activeWindow()
        if not eb then return false end
        eb:Insert(link)
        return true
    end
    local function sendText(editBox, addHistory)
        local text = editBox:GetText()
        if text ~= "" then G.C_ChatInfo.SendChatMessage(text, editBox:GetAttribute("chatType") or "SAY") end
        editBox:SetText("")
    end
    G.ChatFrameUtil = {
        OpenChat = openChat,
        GetActiveWindow = activeWindow,
        InsertLink = insertLink,
    }
    G.ChatFrame_OpenChat, G.ChatEdit_GetActiveWindow, G.ChatEdit_InsertLink = openChat, activeWindow, insertLink
    G.ChatEdit_SendText = sendText
    G.C_ChatInfo = {
        SendChatMessage = function(msg, chatType, language, target)
            table.insert(M.sentMessages, { msg = msg, chatType = chatType, language = language, target = target })
        end,
        InChatMessagingLockdown = function() return S.chatLockdown end,
        RegisterAddonMessagePrefix = function() return true end,
        IsAddonMessagePrefixRegistered = function() return true end,
        SendAddonMessage = function() return true end,
    }
    G.SendChatMessage = G.C_ChatInfo.SendChatMessage

    -- EventRegistry (Blizzard CallbackRegistryMixin subset)
    local registry = { _cbs = {} }
    function registry:RegisterCallback(event, func, owner, ...)
        owner = owner or func
        self._cbs[event] = self._cbs[event] or {}
        table.insert(self._cbs[event], { func = func, owner = owner, args = pack(...) })
        return owner
    end
    function registry:UnregisterCallback(event, owner)
        local list = self._cbs[event] or {}
        for i = #list, 1, -1 do if list[i].owner == owner then table.remove(list, i) end end
    end
    function registry:TriggerEvent(event, ...)
        local list = {}
        for i, cb in ipairs(self._cbs[event] or {}) do list[i] = cb end
        for _, cb in ipairs(list) do
            local a = cb.args
            if a.n > 0 then
                local extra = { unpack(a, 1, a.n) }
                local n = a.n
                for i = 1, select("#", ...) do extra[n + i] = (select(i, ...)) end
                M.dispatch(cb.func, cb.owner, unpack(extra, 1, n + select("#", ...)))
            else
                M.dispatch(cb.func, cb.owner, ...)
            end
        end
    end
    function registry:RegisterFrameEventAndCallback(event, func, owner, ...)
        return self:RegisterCallback(event, func, owner, ...)
    end
    G.EventRegistry = registry
    M.EventRegistry = registry

    -- timers
    G.C_Timer = {
        After = function(sec, fn) addTimer(sec, fn) end,
        NewTimer = function(sec, fn)
            local t = { Cancel = function(self) self._cancelled = true end, IsCancelled = function(self) return self._cancelled or false end }
            return addTimer(sec, fn, nil, t)
        end,
        NewTicker = function(sec, fn, iterations)
            local t = { Cancel = function(self) self._cancelled = true end, IsCancelled = function(self) return self._cancelled or false end }
            return addTimer(sec, fn, iterations or true, t)
        end,
    }

    -- key bindings
    G.ACCOUNT_BINDINGS, G.CHARACTER_BINDINGS = 1, 2
    G.GetBindingKey = function(command)
        local keys = {}
        for k, c in pairs(M.bindings) do if c == command then keys[#keys + 1] = k end end
        table.sort(keys)
        return unpack(keys)
    end
    G.GetBindingAction = function(key) return M.bindings[key] or "" end
    G.SetBinding = function(key, command)
        table.insert(M.bindingCalls, { "SetBinding", key, command })
        if key then M.bindings[key] = command end
        return true
    end
    G.SetBindingClick = function(key, button, mouse)
        table.insert(M.bindingCalls, { "SetBindingClick", key, button, mouse })
        if key then M.bindings[key] = "CLICK " .. tostring(button) .. ":" .. tostring(mouse or "LeftButton") end
        return true
    end
    G.SaveBindings = function(set) table.insert(M.bindingCalls, { "SaveBindings", set }) end
    G.GetCurrentBindingSet = function() return S.bindingSet end
    G.SetOverrideBinding = function(owner, prio, key, cmd) table.insert(M.bindingCalls, { "SetOverrideBinding", owner, prio, key, cmd }) end
    G.SetOverrideBindingClick = function(owner, prio, key, btn, mb) table.insert(M.bindingCalls, { "SetOverrideBindingClick", owner, prio, key, btn, mb }) end
    G.ClearOverrideBindings = function(owner) table.insert(M.bindingCalls, { "ClearOverrideBindings", owner }) end

    -- add-on metadata
    G.C_AddOns = {
        GetAddOnMetadata = function(addon, field) return M.tocFields and M.tocFields[field] end,
        IsAddOnLoaded = function(name) return name == M.addonName, name == M.addonName end,
        GetAddOnInfo = function(name) return name, name, "", true, "INSECURE", false end,
        LoadAddOn = function() return false, "MISSING" end,
    }
    G.GetAddOnMetadata = G.C_AddOns.GetAddOnMetadata
    G.IsAddOnLoaded = G.C_AddOns.IsAddOnLoaded

    G.SlashCmdList = {}
    G.hash_SlashCmdList = {}
    G.Enum = setmetatable({}, { __index = function(t, k) local v = {}; rawset(t, k, v); return v end })
end

-- Report reads of undefined globals (diagnostic only; never changes what the code sees).
function M.trackMissingGlobals()
    setmetatable(_G, { __index = function(_, k)
        if not M.missingGlobals[k] then M.missingGlobals[k] = true end
        return nil
    end })
end

-- --------------------------------------------------------------------------
-- Add-on loading (.toc -> .xml -> .lua), mirroring the client
-- --------------------------------------------------------------------------
local function fileExists(p) local f = io.open(p, "rb"); if f then f:close(); return true end; return false end

-- Windows is case-insensitive; fall back to a case-insensitive lookup and note it.
local function resolvePath(base, rel)
    rel = rel:gsub("\\", "/")
    local full = base .. "/" .. rel
    if fileExists(full) then return full end
    local cur = base
    for part in rel:gmatch("[^/]+") do
        local found
        local p = io.popen('ls -a "' .. cur .. '" 2>/dev/null')
        if p then
            for name in p:lines() do if name:lower() == part:lower() then found = name; break end end
            p:close()
        end
        if not found then return nil end
        cur = cur .. "/" .. found
    end
    table.insert(M.warnings, "case mismatch: " .. rel .. " resolved to " .. cur)
    return cur
end
M.warnings = {}

local function dirname(p) return p:match("^(.*)/[^/]*$") or "." end

function M.runLuaFile(path, addonName, ns)
    table.insert(M.loadedFiles, path)
    local chunk, err = loadfile(path)
    if not chunk then
        table.insert(M.loadErrors, { file = path, err = err }); return false
    end
    local ok, e = xpcall(function() chunk(addonName, ns) end, function(e) return debug.traceback(tostring(e), 2) end)
    if not ok then table.insert(M.loadErrors, { file = path, err = e }) end
    return ok
end

function M.runXmlFile(path, addonName, ns)
    local f = io.open(path, "rb")
    if not f then table.insert(M.loadErrors, { file = path, err = "cannot open" }); return end
    local xml = f:read("*a"); f:close()
    xml = xml:gsub("<!%-%-.-%-%->", "")
    local base = dirname(path)
    if xml:find("<Frame", 1, true) or xml:find("<Button", 1, true) then
        table.insert(M.warnings, "XML frame definitions are not supported by the mock: " .. path)
    end
    for tag, file in xml:gmatch("<%s*(%a+)%s+file%s*=%s*\"([^\"]+)\"") do
        local full = resolvePath(base, file)
        if not full then
            table.insert(M.loadErrors, { file = base .. "/" .. file, err = "file not found (referenced from " .. path .. ")" })
        elseif tag == "Script" then
            M.runLuaFile(full, addonName, ns)
        elseif tag == "Include" then
            M.runXmlFile(full, addonName, ns)
        end
    end
end

function M.loadSavedVariables(path)
    local chunk, err = loadfile(path)
    if not chunk then error("could not read SavedVariables file: " .. tostring(err)) end
    local ok, e = pcall(chunk)
    if not ok then error("SavedVariables file failed to run: " .. tostring(e)) end
end

-- Load the add-on like the client: run every file in .toc order with (addonName, ns), then
-- SavedVariables, then ADDON_LOADED, then PLAYER_LOGIN (+ PLAYER_ENTERING_WORLD).
function M.loadAddon(root, addonName, opts)
    opts = opts or {}
    M.addonName = addonName
    M.ns = {}
    M.tocFields = {}
    local tocPath = resolvePath(root, addonName .. ".toc")
    assert(tocPath, "no " .. addonName .. ".toc in " .. root)
    local entries = {}
    for line in io.lines(tocPath) do
        line = line:gsub("\r", "")
        local key, val = line:match("^##%s*([^:]+):%s*(.-)%s*$")
        if key then M.tocFields[key] = val
        elseif not line:match("^%s*#") and line:match("%S") then
            entries[#entries + 1] = strtrim((line:gsub("%s*%[.-%]%s*", "")))
        end
    end
    for _, e in ipairs(entries) do
        local full = resolvePath(root, e)
        if not full then
            table.insert(M.loadErrors, { file = e, err = "file in .toc not found" })
        elseif full:lower():match("%.xml$") then
            M.runXmlFile(full, addonName, M.ns)
        else
            M.runLuaFile(full, addonName, M.ns)
        end
    end
    if opts.savedVariables then M.loadSavedVariables(opts.savedVariables) end
    M.fireEvent("ADDON_LOADED", addonName)
    M.state.loggedIn = true
    M.fireEvent("PLAYER_LOGIN")
    M.fireEvent("PLAYER_ENTERING_WORLD", true, false)
end

return M
