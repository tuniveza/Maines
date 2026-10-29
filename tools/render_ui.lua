-- Dumps the Maines window, as built by the add-on's real UI code under the offline WoW mock
-- (tests/wowmock.lua), to JSON: every visible region with a fully resolved screen rectangle,
-- colours, gradients, textures, text lines and draw order. tools/render_ui.py draws it.
--
-- Normally run by render_ui.py, which first writes font metrics for the fonts the UI uses:
--   MAINES_METRICS=<metrics.lua> MAINES_RENDER_OUT=<out.json> lua5.1 tools/render_ui.lua
--
-- Coordinates in the JSON are UI units on a 1920x1080 UIParent, origin top-left.

local scriptDir = (arg and arg[0] or ""):match("^(.*)[/\\][^/\\]*$") or "."
local repoRoot = scriptDir .. "/.."
package.path = repoRoot .. "/tests/?.lua;" .. package.path

local mock = require("wowmock")
local METRICS = dofile(assert(os.getenv("MAINES_METRICS"), "set MAINES_METRICS"))
local OUT = os.getenv("MAINES_RENDER_OUT") or "render_ui.json"

-- ---------------------------------------------------------------- fonts + text metrics
local function fontKey(path)
    local p = tostring(path or ""):lower()
    if p:find("newrocker") then return "newrocker" end
    if p:find("vollkornsc") then return "vollkornsc" end
    if p:find("firasans%-semibold") then return "fira_semibold" end
    if p:find("firasans") then return "fira_medium" end
    if p:find("breeserif") then return "breeserif" end
    if p:find("morpheus") then return "morpheus" end
    if p:find("arialn") then return "arialn" end
    return "friz"
end

-- The font a FontString/EditBox actually renders with: its own SetFont, else its font
-- object's (followed through font objects), else WoW's default.
local function resolveFont(o)
    local seen = 0
    while o and seen < 8 do
        if o._font then return o._font[1], o._font[2], o._font[3] or "" end
        local fo = o._fontObject
        if type(fo) == "string" then fo = _G[fo] end
        o = fo
        seen = seen + 1
    end
    return "Fonts\\FRIZQT__.TTF", 12, ""
end

local function utf8iter(s)
    return s:gmatch("[%z\1-\127\194-\244][\128-\191]*")
end

-- Escape-code parser: returns a list of tokens {ch=, color=} / {nl=true} / {tex=, w=, h=}.
local function parseText(text, baseColor)
    local toks = {}
    local color = nil
    local i, n = 1, #text
    while i <= n do
        local c = text:sub(i, i)
        if c == "|" then
            local nx = text:sub(i + 1, i + 1)
            if nx == "|" then
                toks[#toks + 1] = { ch = "|", color = color }; i = i + 2
            elseif nx == "c" and text:sub(i + 2, i + 9):match("^%x%x%x%x%x%x%x%x$") then
                local hex = text:sub(i + 2, i + 9)
                color = { tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255,
                    tonumber(hex:sub(7, 8), 16) / 255 }
                i = i + 10
            elseif nx == "r" then
                color = nil; i = i + 2
            elseif nx == "n" then
                toks[#toks + 1] = { nl = true }; i = i + 2
            elseif nx == "T" then
                local close = text:find("|t", i + 2, true)
                local spec = text:sub(i + 2, (close or n + 1) - 1)
                local parts = {}
                for part in (spec .. ":"):gmatch("(.-):") do parts[#parts + 1] = part end
                local h = tonumber(parts[2]) or 0
                local w = tonumber(parts[3]) or 0
                if w == 0 then w = h end
                toks[#toks + 1] = { tex = parts[1], w = w, h = h, spec = parts }
                i = (close or n) + 2
            else
                toks[#toks + 1] = { ch = "|", color = color }; i = i + 1
            end
        elseif c == "\n" then
            toks[#toks + 1] = { nl = true }; i = i + 1
        else
            local ch = text:match("^[%z\1-\127\194-\244][\128-\191]*", i) or c
            toks[#toks + 1] = { ch = ch, color = color }
            i = i + #ch
        end
    end
    return toks
end

local function codepoint(ch)
    local b1 = ch:byte(1)
    if b1 < 0x80 then return b1 end
    if b1 < 0xE0 then return (b1 % 0x20) * 64 + ch:byte(2) % 64 end
    if b1 < 0xF0 then return (b1 % 0x10) * 4096 + (ch:byte(2) % 64) * 64 + ch:byte(3) % 64 end
    return ((b1 % 0x08) * 262144) + (ch:byte(2) % 64) * 4096 + (ch:byte(3) % 64) * 64 + ch:byte(4) % 64
end

local function tokWidth(tok, key, size)
    if tok.tex then return tok.w end
    if not tok.ch then return 0 end
    local m = METRICS[key]
    local adv = m.adv[codepoint(tok.ch)] or m.adv[63] -- unknown -> width of "?"
    return adv * size / 1000
end

local function lineWidth(line, key, size)
    local w = 0
    for _, t in ipairs(line) do w = w + tokWidth(t, key, size) end
    return w
end

local function trimTrailingSpaces(line)
    while #line > 0 and line[#line].ch == " " do table.remove(line) end
    return line
end

-- Splits tokens into lines: hard newlines always; soft wraps at spaces when width > 0.
local function layoutLines(toks, key, size, width, wordWrap)
    local hard, cur = {}, {}
    for _, t in ipairs(toks) do
        if t.nl then hard[#hard + 1] = cur; cur = {} else cur[#cur + 1] = t end
    end
    hard[#hard + 1] = cur
    if not width or width <= 0 or wordWrap == false then return hard end
    local out = {}
    for _, line in ipairs(hard) do
        -- words = runs of non-space tokens, each followed by its spaces
        local words, w = {}, { toks = {}, spaces = {} }
        for _, t in ipairs(line) do
            if t.ch == " " then
                w.spaces[#w.spaces + 1] = t
            else
                if #w.spaces > 0 then words[#words + 1] = w; w = { toks = {}, spaces = {} } end
                w.toks[#w.toks + 1] = t
            end
        end
        if #w.toks > 0 or #w.spaces > 0 then words[#words + 1] = w end
        local current, curW = {}, 0
        for _, word in ipairs(words) do
            local ww = lineWidth(word.toks, key, size)
            if #current > 0 and curW + ww > width + 0.5 then
                out[#out + 1] = trimTrailingSpaces(current)
                current, curW = {}, 0
            end
            for _, t in ipairs(word.toks) do current[#current + 1] = t end
            curW = curW + ww
            for _, t in ipairs(word.spaces) do current[#current + 1] = t; curW = curW + tokWidth(t, key, size) end
        end
        out[#out + 1] = trimTrailingSpaces(current)
    end
    return out
end

local function fsLayout(fs, width)
    local path, size = resolveFont(fs)
    local key = fontKey(path)
    local wrap = true
    if fs._set.SetWordWrap and fs._set.SetWordWrap[1] == false then wrap = false end
    local lines = layoutLines(parseText(fs._text or ""), key, size, width, wrap)
    local maxLines = fs._set.SetMaxLines and fs._set.SetMaxLines[1]
    if maxLines and maxLines > 0 and #lines > maxLines then
        while #lines > maxLines do table.remove(lines) end
        lines.truncated = true
    end
    return lines, key, size
end

local function spacingOf(fs) return (fs._set.SetSpacing and fs._set.SetSpacing[1]) or 0 end

local function fsUnboundedWidth(fs)
    local lines, key, size = fsLayout(fs, nil)
    local w = 0
    for _, l in ipairs(lines) do w = math.max(w, lineWidth(l, key, size)) end
    return w
end
local function fsStringWidth(fs)
    local lines, key, size = fsLayout(fs, (fs._w or 0) > 0 and fs._w or nil)
    local w = 0
    for _, l in ipairs(lines) do w = math.max(w, lineWidth(l, key, size)) end
    return w
end
local function fsStringHeight(fs, width)
    if (fs._text or "") == "" then return 0 end
    local lines, _, size = fsLayout(fs, width or ((fs._w or 0) > 0 and fs._w or nil))
    return #lines * size + (#lines - 1) * spacingOf(fs)
end

-- Every FontString gets real metric-based measuring (the mock's own is 7px per byte).
local origNew = mock.newObject
mock.newObject = function(typ, name, parent, template)
    local o = origNew(typ, name, parent, template)
    o._order = #mock.objects
    if typ == "FontString" then
        o.GetStringWidth = function(self) return fsStringWidth(self) end
        o.GetUnboundedStringWidth = function(self) return fsUnboundedWidth(self) end
        o.GetStringHeight = function(self) return fsStringHeight(self) end
        o.GetNumLines = function(self) return #(fsLayout(self, (self._w or 0) > 0 and self._w or nil)) end
    end
    return o
end

-- ---------------------------------------------------------------- load the add-on
mock.install()
-- Track the order of SetVertexColor vs SetGradient calls on textures (both are just stored
-- by the mock), so the later one wins as in the client.
do
    local seq = 0
    local sample = UIParent:CreateTexture()
    local mt = getmetatable(sample)
    local idx = mt.__index
    mt.__index = function(self, k)
        if k == "SetVertexColor" or k == "SetGradient" then
            local f = idx(self, k)
            return function(s, ...)
                seq = seq + 1
                if k == "SetVertexColor" then s._vcSeq = seq else s._gradSeq = seq end
                return f(s, ...)
            end
        end
        return idx(self, k)
    end
end

-- Blizzard font objects the UI borrows, with their stock fonts/sizes/colours.
local function stockFont(name, path, size, r, g, b, shadow)
    local f = _G[name]
    if not f then return end
    f:SetFont(path, size, "")
    f:SetTextColor(r, g, b)
    if shadow then f:SetShadowColor(0, 0, 0, 1); f:SetShadowOffset(1, -1) end
end
stockFont("ChatFontNormal", "Fonts\\ARIALN.TTF", 14, 1, 1, 1, true)
stockFont("GameFontHighlightSmall", "Fonts\\FRIZQT__.TTF", 10, 1, 1, 1, true)
stockFont("GameFontNormal", "Fonts\\FRIZQT__.TTF", 12, 1, 0.82, 0, true)
stockFont("GameFontHighlight", "Fonts\\FRIZQT__.TTF", 12, 1, 1, 1, true)

math.randomseed(7)
mock.state.playerName = "Altchar"
mock.loadAddon(repoRoot, "Maines", {})
assert(#mock.loadErrors == 0, "add-on failed to load: " .. tostring(mock.loadErrors[1] and mock.loadErrors[1].err))
local ns = mock.ns
local slash = mock.slash

-- ---------------------------------------------------------------- sample settings
-- Logged in as an alt, main set to Tuniveza with square brackets: the preview shows a tag.
slash("/mains Tuniveza [")
slash("/mainchat guild, raid, party")
slash("/mainchat mode include")
slash("/mainphrase add Heading to the next pull in 2 minutes, grab your flasks!")
slash("/mainphrase add LFM Mythic+ key, need tank + healer")
slash("/mainphrase add Thanks for the group, GG all <3")
slash("/mainphrase add brb - coffee refill")
slash("/mainphrase add o/")
ns.SetActionKey("MAINES_NEXT_PHRASE", "CTRL-1")
ns.SetActionKey("MAINES_PREV_PHRASE", "CTRL-2")
slash("/mainanim wave")
ns.SaveCustomBadge("Cat", " /\\_/\\\n( o.o )\n > ^ <")
Maines_Badges_DB.selected = "Cat"

slash("/maines")
assert(Maines_Frame:IsShown(), "/maines did not open the window")
Maines_RefreshWindow()
-- Pick the custom badge in the Badges list, as a click would: fills its name + drawing boxes.
ns.ShowPanel("badges")
Maines_RefreshWindow()
for _, b in ipairs(mock.findFrames(function(o) return o._type == "Button" and o.GetText and o:GetText() == "* Cat" end)) do
    mock.click(b, "LeftButton", true)
end

-- ---------------------------------------------------------------- frame tree -> rects
local STRATA = { BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5, FULLSCREEN = 6,
    FULLSCREEN_DIALOG = 7, TOOLTIP = 8 }
local LAYER = { BACKGROUND = 1, BORDER = 2, ARTWORK = 3, OVERLAY = 4, HIGHLIGHT = 5 }
local SCREEN_W, SCREEN_H = 1920, 1080

local rectCache, resolving = {}, {}

local function hasTemplate(o, name)
    return type(o._template) == "string" and o._template:find(name, 1, true) ~= nil
end

local rectOf

local function anchorXY(r, point)
    local x, y
    if point:find("LEFT") then x = r.l elseif point:find("RIGHT") then x = r.r else x = (r.l + r.r) / 2 end
    if point:find("TOP") then y = r.t elseif point:find("BOTTOM") then y = r.b else y = (r.t + r.b) / 2 end
    return x, y
end

-- Size a region wants when its anchors don't pin that dimension.
local function desiredW(o)
    if o._type == "FontString" then
        if (o._w or 0) > 0 then return o._w end
        return fsUnboundedWidth(o)
    end
    return o._w or 0
end
local function desiredH(o, width)
    if o._type == "FontString" then
        if (o._h or 0) > 0 then return o._h end
        return fsStringHeight(o, width)
    end
    if o._type == "EditBox" and o._multiLine and (o._h or 0) == 0 then
        local path, size = resolveFont(o)
        local lines = layoutLines(parseText(o._text or ""), fontKey(path), size, width, true)
        return math.max(size, #lines * size)
    end
    return o._h or 0
end

rectOf = function(o)
    if o == UIParent then return { l = 0, r = SCREEN_W, b = 0, t = SCREEN_H } end
    if rectCache[o] ~= nil then return rectCache[o] or nil end
    if resolving[o] then return nil end
    resolving[o] = true
    local result
    local parent = o._parent
    if parent and parent._scrollChild == o then
        -- A scroll child hangs from its scroll frame's top-left, scrolled by the vertical offset.
        local pr = rectOf(parent)
        if pr then
            local w = desiredW(o)
            local h = desiredH(o, w)
            local top = pr.t + (parent._vscroll or 0)
            result = { l = pr.l, r = pr.l + w, t = top, b = top - h }
        end
    else
        local byPoint, order = {}, {}
        for _, p in ipairs(o._points) do
            local point, rel, relPoint, x, y = p[1], p[2], p[3], p[4], p[5]
            if type(relPoint) == "number" then relPoint, x, y = nil, relPoint, x end
            if not byPoint[point] then order[#order + 1] = point end
            byPoint[point] = { point, rel, relPoint, x or 0, y or 0 }
        end
        local L, R, T, B, CX, CY
        local ok = #order > 0
        for _, point in ipairs(order) do
            local p = byPoint[point]
            local rel = p[2]
            if type(rel) == "string" then rel = _G[rel] end
            rel = rel or parent or UIParent
            local rr = rectOf(rel)
            if not rr then ok = false; break end
            local ax, ay = anchorXY(rr, p[3] or point)
            ax, ay = ax + p[4], ay + p[5]
            if point:find("LEFT") then L = ax elseif point:find("RIGHT") then R = ax else CX = ax end
            if point:find("TOP") then T = ay elseif point:find("BOTTOM") then B = ay else CY = ay end
        end
        if ok then
            local w
            if L and R then w = R - L else w = desiredW(o) end
            if not L then
                if R then L = R - w elseif CX then L = CX - w / 2 else L = nil end
            end
            if L and not R then R = L + w end
            local h
            if T and B then h = T - B else h = desiredH(o, R and L and (R - L) or w) end
            if not T then
                if B then T = B + h elseif CY then T = CY + h / 2 end
            end
            if T and not B then B = T - h end
            if L and R and T and B then result = { l = L, r = R, t = T, b = B } end
        end
    end
    resolving[o] = nil
    rectCache[o] = result or false
    return result
end

-- ---------------------------------------------------------------- drawables
local function rgba(t, default)
    if not t then return default end
    return { t[1] or 1, t[2] or 1, t[3] or 1, t[4] or 1 }
end
local function colorObj(c) return { c.r, c.g, c.b, c.a or 1 } end

local function toBox(r)
    return { r.l, SCREEN_H - r.t, r.r - r.l, r.t - r.b }
end

local items
local function emit(item, frameInfo, layer, sublevel, order)
    item.sort = { frameInfo.strata, frameInfo.level, frameInfo.order, LAYER[layer] or 3, sublevel or 0, order or 0 }
    item.alpha = (item.alpha or 1) * frameInfo.alpha
    item.clip = frameInfo.clip
    items[#items + 1] = item
end

local function textItem(fs, r, opts)
    opts = opts or {}
    local width = r.r - r.l
    local path, size, flags = resolveFont(fs)
    local key = fontKey(path)
    local wrap = opts.wrap
    if wrap == nil then wrap = not (fs._set.SetWordWrap and fs._set.SetWordWrap[1] == false) end
    local lines = layoutLines(parseText(fs._text or ""), key, size, wrap and width or nil, wrap)
    local maxLines = fs._set.SetMaxLines and fs._set.SetMaxLines[1]
    local truncate = false
    if maxLines and maxLines > 0 and #lines > maxLines then
        while #lines > maxLines do table.remove(lines) end
        truncate = true
    end
    if not wrap then truncate = true end
    -- font object colour/shadow as the fallback for the string's own
    local function inherited(setName)
        local o, n = fs, 0
        while o and n < 8 do
            if o._set and o._set[setName] then return o._set[setName] end
            local fo = o._fontObject
            if type(fo) == "string" then fo = _G[fo] end
            o = fo; n = n + 1
        end
    end
    local tc = rgba(inherited("SetTextColor"), { 1, 1, 1, 1 })
    local outLines = {}
    for _, line in ipairs(lines) do
        local runs, cur = {}, nil
        for _, t in ipairs(line) do
            if t.tex then
                runs[#runs + 1] = { tex = t.tex, w = t.w, h = t.h, spec = t.spec }
                cur = nil
            elseif t.ch then
                local c = t.color or tc
                if cur and cur.color == c then
                    cur.text = cur.text .. t.ch
                else
                    cur = { text = t.ch, color = { c[1], c[2], c[3], c[4] or 1 } }
                    cur.color_ref = c
                    runs[#runs + 1] = cur
                end
            end
        end
        for _, run in ipairs(runs) do
            -- merge-able check above compares table identity; drop the helper before output
            run.color_ref = nil
        end
        outLines[#outLines + 1] = { runs = runs, width = lineWidth(line, key, size) }
    end
    local shadowC = inherited("SetShadowColor")
    local shadowO = inherited("SetShadowOffset")
    return {
        kind = "text", box = toBox(r), font = key, size = size, flags = flags,
        justifyH = opts.justifyH or (fs._set.SetJustifyH and fs._set.SetJustifyH[1]) or "CENTER",
        justifyV = opts.justifyV or (fs._set.SetJustifyV and fs._set.SetJustifyV[1]) or "MIDDLE",
        lines = outLines, lineHeight = size, spacing = (fs._set.SetSpacing and fs._set.SetSpacing[1]) or 0,
        truncate = truncate,
        shadow = (shadowC and shadowO) and { color = rgba(shadowC), offset = { shadowO[1] or 0, shadowO[2] or 0 } } or nil,
    }
end

local function textureItem(t, r)
    local item = { kind = "texture", box = toBox(r) }
    if t._texture == "color" and t._set.SetColorTexture then
        item.texture = "white"
        item.color = rgba(t._set.SetColorTexture)
    elseif type(t._texture) == "string" and t._texture ~= "" then
        local p = t._texture
        if p:lower():find("white8x8") then item.texture = "white"
        else item.texture = p end
        item.color = { 1, 1, 1, 1 }
    elseif type(t._texture) == "number" then
        item.texture = "fileid:" .. t._texture
        item.color = { 1, 1, 1, 1 }
    else
        return nil -- no texture set: draws nothing
    end
    local g = t._set.SetGradient
    local vc = t._set.SetVertexColor
    -- Whichever of SetVertexColor / SetGradient ran last owns the vertex colours.
    if g and (not vc or (t._gradSeq or 0) > (t._vcSeq or 0)) then
        item.gradient = { orientation = g[1], min = colorObj(g[2]), max = colorObj(g[3]) }
    elseif vc then
        local base = item.color
        item.color = { base[1] * (vc[1] or 1), base[2] * (vc[2] or 1), base[3] * (vc[3] or 1), base[4] * (vc[4] or 1) }
    end
    if t._set.SetTexCoord then
        local c = t._set.SetTexCoord
        item.texcoord = { c[1], c[2], c[3], c[4] }
    end
    if t._set.SetRotation then item.rotation = t._set.SetRotation[1] end
    if t._set.SetBlendMode then item.blend = t._set.SetBlendMode[1] end
    if t._set.SetHorizTile and t._set.SetHorizTile[1] then item.htile = true end
    if t._set.SetVertTile and t._set.SetVertTile[1] then item.vtile = true end
    if t._set.SetDesaturated and t._set.SetDesaturated[1] then item.desaturated = true end
    item.alpha = t._alpha or 1
    return item
end

local function scrollRange(sf)
    local child = sf._scrollChild
    local sr = rectOf(sf)
    if not (child and sr) then return 0 end
    local w = desiredW(child)
    local h = desiredH(child, w)
    return math.max(0, h - (sr.t - sr.b))
end

local function walk(o, info)
    if not o._shown then return end
    local level = o._level or (info.level + 1)
    local strata = o._strata and STRATA[o._strata] or info.strata
    local fi = { level = level, strata = strata, order = o._order or 0, alpha = info.alpha * (o._alpha or 1),
        clip = info.clip }
    local r = rectOf(o)

    if r and o._backdrop and o._set.SetBackdrop then
        local bd = o._set.SetBackdrop[1] or {}
        local bg = rgba(o._set.SetBackdropColor, { 1, 1, 1, 1 })
        local bc = rgba(o._set.SetBackdropBorderColor, { 1, 1, 1, 1 })
        if bd.bgFile then
            emit({ kind = "texture", texture = "white", box = toBox(r), color = bg }, fi, "BACKGROUND", -8, 0)
        end
        local e = bd.edgeFile and (bd.edgeSize or 0) or 0
        if e > 0 then
            local edges = {
                { l = r.l, r = r.r, t = r.t, b = r.t - e },
                { l = r.l, r = r.r, t = r.b + e, b = r.b },
                { l = r.l, r = r.l + e, t = r.t - e, b = r.b + e },
                { l = r.r - e, r = r.r, t = r.t - e, b = r.b + e },
            }
            for _, er in ipairs(edges) do
                emit({ kind = "texture", texture = "white", box = toBox(er), color = bc }, fi, "BORDER", -8, 0)
            end
        end
    end

    -- Blizzard templates the mock only stubs: drawn by render_ui.py as stand-ins.
    if r then
        if hasTemplate(o, "UIPanelCloseButton") then
            emit({ kind = "standin", what = "closebutton", box = toBox(r) }, fi, "ARTWORK", 0, 0)
        elseif hasTemplate(o, "UICheckButtonTemplate") then
            emit({ kind = "standin", what = "checkbox", box = toBox(r), checked = o._checked and true or false },
                fi, "ARTWORK", 0, 0)
        elseif hasTemplate(o, "InputBoxTemplate") then
            emit({ kind = "standin", what = "inputbox", box = toBox(r) }, fi, "BACKGROUND", 0, 0)
        end
        if o._type == "EditBox" then
            -- the box's own text: ChatFontNormal for InputBoxTemplate, else its font object
            if hasTemplate(o, "InputBoxTemplate") and not o._fontObject and not o._font then
                o._fontObject = ChatFontNormal
            end
            if (o._text or "") ~= "" then
                local fakeFS = { _text = o._text, _set = o._set, _font = o._font, _fontObject = o._fontObject }
                local multi = o._multiLine
                -- edit boxes start left-aligned in WoW unless SetJustifyH says otherwise
                local jh = o._set.SetJustifyH and o._set.SetJustifyH[1] or "LEFT"
                local item = textItem(fakeFS, r, { justifyH = jh, justifyV = multi and "TOP" or "MIDDLE",
                    wrap = multi and true or false })
                if not multi then item.truncate = false; item.cliptobox = true end
                emit(item, fi, "OVERLAY", 0, 0)
            end
        end
    end

    local childClip = fi.clip
    if r and o._type == "ScrollFrame" then
        local b = toBox(r)
        childClip = b
        if fi.clip then
            local c = fi.clip
            local x0, y0 = math.max(b[1], c[1]), math.max(b[2], c[2])
            local x1, y1 = math.min(b[1] + b[3], c[1] + c[3]), math.min(b[2] + b[4], c[2] + c[4])
            childClip = { x0, y0, math.max(0, x1 - x0), math.max(0, y1 - y0) }
        end
        if hasTemplate(o, "UIPanelScrollFrameTemplate") and o.ScrollBar and o.ScrollBar._shown then
            -- UIPanelScrollBarTemplate: 16 wide, 6px right of the scroll frame, 16px in from its
            -- top/bottom for the arrow buttons; arrows disabled + no thumb when nothing scrolls.
            local range = scrollRange(o)
            local sb = { l = r.r + 6, r = r.r + 22, t = r.t - 16, b = r.b + 16 }
            emit({ kind = "standin", what = "scrollbar", box = toBox(sb), scrollable = range >= 1,
                value = o._vscroll or 0 },
                { level = level + 1, strata = strata, order = fi.order, alpha = fi.alpha, clip = fi.clip },
                "ARTWORK", 0, 0)
        end
    end

    -- regions of this frame
    for _, c in ipairs(o._children or {}) do
        if not c._isFrame and c._shown then
            local cr = rectOf(c)
            local layer = (c._set.SetDrawLayer and c._set.SetDrawLayer[1]) or "ARTWORK"
            local sub = (c._set.SetDrawLayer and c._set.SetDrawLayer[2]) or 0
            if cr and layer ~= "HIGHLIGHT" then
                if c._type == "FontString" then
                    if (c._text or "") ~= "" then
                        local item = textItem(c, cr)
                        item.alpha = c._alpha or 1
                        emit(item, fi, layer, sub, c._order)
                    end
                elseif c._type == "Texture" then
                    local item = textureItem(c, cr)
                    if item then emit(item, fi, layer, sub, c._order) end
                end
            end
        end
    end
    -- child frames
    for _, c in ipairs(o._children or {}) do
        if c._isFrame and not (o.ScrollBar and c == o.ScrollBar) then
            walk(c, { level = level, strata = strata, alpha = fi.alpha, clip = childClip })
        end
    end
end

local function sortItems(list)
    for i, it in ipairs(list) do it._i = i end
    table.sort(list, function(a, b)
        for k = 1, 6 do
            if a.sort[k] ~= b.sort[k] then return a.sort[k] < b.sort[k] end
        end
        return a._i < b._i
    end)
    for _, it in ipairs(list) do it._i = nil; it.sort = nil end
end

local scenes = {}
local function snapshot(name, root, extra)
    rectCache = {}
    items = {}
    walk(root, { level = 0, strata = 3, alpha = 1, clip = nil })
    sortItems(items)
    local r = rectOf(root)
    local scene = { name = name, items = items, root = toBox(r) }
    for k, v in pairs(extra or {}) do scene[k] = v end
    scenes[#scenes + 1] = scene
end

-- ---------------------------------------------------------------- scenes
local TABS = { "main", "phrases", "animate", "badges", "filter", "behavior", "cosmetic", "help" }
for _, key in ipairs(TABS) do
    ns.ShowPanel(key)
    Maines_RefreshWindow()
    snapshot("tab_" .. key, Maines_Frame, { tab = key })
end

-- The Animate page's live preview steps every 1.2 s (its own OnUpdate); capture a few steps.
ns.ShowPanel("animate")
Maines_RefreshWindow()
for step = 1, 4 do
    snapshot("animate_step_" .. step, Maines_Frame, { tab = "animate", step = step })
    mock.advanceTime(1.2, 0.1)
end

-- The /mainnote popup.
Maines_Frame:Hide()
slash("/mainnote")
snapshot("note", Maines_NoteFrame)
Maines_NoteFrame:Hide()

-- /maincolor rolls on the main page, each repainting the whole UI with the add-on's own code.
slash("/maines")
ns.ShowPanel("main")
Maines_RefreshWindow()
snapshot("palette_0", Maines_Frame, { caption = "starting colours, before any /maincolor roll" })
-- Fixed seed so the README GIF is repeatable; the rolls themselves are the add-on's own code.
math.randomseed(79)
for roll = 1, 6 do
    local before = #mock.printed
    slash("/maincolor")
    local msg = mock.printed[#mock.printed] or ""
    if #mock.printed == before then msg = "" end
    msg = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("^Maines: ", "")
    snapshot("palette_" .. roll, Maines_Frame, { caption = msg })
end

-- A contact sheet: every palette once, painted with its first (dominant) color, so each
-- palette's own surface textures and title band can be compared side by side.
for i, palette in ipairs(ns.Palettes) do
    local hex = palette.colors[1]
    local r, g, b = tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
    ns.ApplyPaletteColor(r, g, b, nil, palette.name)
    snapshot("sheet_" .. i, Maines_Frame, { caption = palette.name .. "  #" .. hex })
end

-- ---------------------------------------------------------------- JSON out
local function encode(v, out)
    local t = type(v)
    if t == "table" then
        if #v > 0 or next(v) == nil then
            out[#out + 1] = "["
            for i, x in ipairs(v) do
                if i > 1 then out[#out + 1] = "," end
                encode(x, out)
            end
            out[#out + 1] = "]"
        else
            out[#out + 1] = "{"
            local first = true
            local keys = {}
            for k in pairs(v) do keys[#keys + 1] = tostring(k) end
            table.sort(keys)
            for _, k in ipairs(keys) do
                if not first then out[#out + 1] = "," end
                first = false
                out[#out + 1] = '"' .. k .. '"'
                out[#out + 1] = ":"
                encode(v[k], out)
            end
            out[#out + 1] = "}"
        end
    elseif t == "string" then
        local s = v:gsub('[%c"\\]', function(c)
            if c == '"' then return '\\"' elseif c == "\\" then return "\\\\"
            elseif c == "\n" then return "\\n" else return string.format("\\u%04x", c:byte()) end
        end)
        out[#out + 1] = '"' .. s .. '"'
    elseif t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then out[#out + 1] = "0"
        elseif v == math.floor(v) then out[#out + 1] = string.format("%d", v)
        else out[#out + 1] = string.format("%.5f", v) end
    elseif t == "boolean" then
        out[#out + 1] = tostring(v)
    else
        out[#out + 1] = "null"
    end
end

local buf = {}
encode({ screen = { SCREEN_W, SCREEN_H }, scenes = scenes, errors = mock.errors }, buf)
local f = assert(io.open(OUT, "w"))
f:write(table.concat(buf))
f:close()
mock.rawprint(("render_ui.lua: %d scenes -> %s (%d errors)"):format(#scenes, OUT, #mock.errors))
