-- Textual Badges: whole multi-line text pictures (2D or "3D" ASCII art) sent to a chat channel,
-- one chat line per row of the picture. Comes with ready-made presets; players can save their
-- own on the Badges page.
--
-- To keep this friendly to everyone else in the channel, only one badge can be sent every
-- 3 minutes (remembered across reloads), and a badge is at most 8 lines.
local _, ns = ...

local PREFIX = "|cFF00FF00Maines|r: "
local COOLDOWN_SECONDS = 180
local MAX_LINES = 8
local MAX_LINE_LETTERS = 200
local MAX_CUSTOM = 20
-- A leading run of normal spaces can be trimmed off a chat line; no-break spaces look the same
-- and keep the picture's indentation.
local NBSP = "\194\160"

-- Written exactly as they should look. "|" is WoW's escape character, so every preset has its
-- pipes doubled when loaded (below) - the same escaped form the chat box itself produces.
local PRESETS = {
    {name = "Heart", art = [==[
 ,d88b.d88b,
 88888888888
 `Y8888888Y'
   `Y888Y'
     `Y']==]},
    {name = "Shield", art = [==[
 _________
|  \   /  |
|   \ /   |
|    V    |
 \       /
  `-._.-']==]},
    {name = "Sword", art = [==[
     /\
     ||
     ||
     ||
  o==[]==o
     ||
     ()]==]},
    {name = "3D Cube", art = [==[
    +--------+
   /        /|
  /        / |
 +--------+  |
 |        |  +
 |        | /
 |        |/
 +--------+]==]},
    {name = "3D Pyramid", art = [==[
        A
       /:\
      / : \
     /  :  \
    /___:___\]==]},
    {name = "Crown", art = [==[
  .  ^  .  ^  .
  |\/ \/ \/ \/|
  |  @  @  @  |
  |___________|]==]},
    {name = "Glyph Stamp", art = [==[
     /\
    /  \
   < <> >
    \  /
     \/]==]},
    {name = "GG", art = [==[
  ____   ____
 / ___| / ___|
| |  _ | |  _
| |_| || |_| |
 \____| \____|]==]},
    {name = "Murloc", art = [==[
   .-"""-.
  / o   o \
 |  .---.  |
  \ \___/ /   Mrrglglgl!
   '-----']==]},
    {name = "Rose", art = [==[
@}-,-'--]==]},
}

-- Splits a picture into its lines: trailing spaces trimmed, blank lines at the very top and
-- bottom dropped (blank lines in the middle become a single space so the gap survives).
local function ToLines(art)
    local lines = {}
    for line in (art .. "\n"):gmatch("(.-)\r?\n") do
        lines[#lines + 1] = (line:gsub("%s+$", ""))
    end
    while #lines > 0 and lines[1] == "" do table.remove(lines, 1) end
    while #lines > 0 and lines[#lines] == "" do table.remove(lines) end
    for i, line in ipairs(lines) do
        if line == "" then lines[i] = " " end
    end
    return lines
end

local PRESET_BADGES = {}
for _, p in ipairs(PRESETS) do
    PRESET_BADGES[#PRESET_BADGES + 1] = {name = p.name, lines = ToLines((p.art:gsub("|", "||")))}
end

local function DB()
    Maines_Badges_DB = Maines_Badges_DB or {}
    local db = Maines_Badges_DB
    db.custom = db.custom or {}
    db.channel = db.channel or "GUILD"
    db.lastSent = tonumber(db.lastSent) or 0
    return db
end

local function AllBadges()
    local all = {}
    for _, b in ipairs(PRESET_BADGES) do all[#all + 1] = b end
    for _, c in ipairs(DB().custom) do
        all[#all + 1] = {name = c.name, lines = ToLines(c.art or ""), custom = true}
    end
    return all
end

local function FindBadge(nameOrIndex)
    local all = AllBadges()
    local i = tonumber(nameOrIndex)
    if i then return all[i] end
    if not nameOrIndex then return nil end
    for _, b in ipairs(all) do
        if b.name:lower() == tostring(nameOrIndex):lower() then return b end
    end
end

local function Now()
    return (GetServerTime and GetServerTime()) or GetTime()
end

local function CooldownLeft()
    local left = DB().lastSent + COOLDOWN_SECONDS - Now()
    -- A saved time in the future (clock change) shouldn't lock badges for longer than 3 minutes.
    if left > COOLDOWN_SECONDS then left = 0 end
    return math.max(0, left)
end
ns.BadgeCooldownLeft = CooldownLeft

local function Clock(secs)
    secs = math.ceil(secs)
    return ("%d:%02d"):format(math.floor(secs / 60), secs % 60)
end

local CHANNELS = {
    {key = "GUILD", label = "Guild"},
    {key = "OFFICER", label = "Officer"},
    {key = "PARTY", label = "Party"},
    {key = "RAID", label = "Raid"},
    {key = "INSTANCE_CHAT", label = "Instance"},
    {key = "SAY", label = "Say"},
    {key = "YELL", label = "Yell"},
}
local CHANNEL_BY_KEY = {}
for _, c in ipairs(CHANNELS) do CHANNEL_BY_KEY[c.key] = c end

-- Why `chatType` can't take a badge right now, or nil if it can.
local function ChannelProblem(chatType, lineCount)
    if chatType == "GUILD" or chatType == "OFFICER" then
        if not IsInGuild() then return "you're not in a guild" end
    elseif chatType == "PARTY" then
        if not IsInGroup(LE_PARTY_CATEGORY_HOME) then return "you're not in a party" end
    elseif chatType == "RAID" then
        if not IsInRaid() then return "you're not in a raid" end
    elseif chatType == "INSTANCE_CHAT" then
        if not IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "you're not in an instance group" end
    elseif chatType == "SAY" or chatType == "YELL" then
        -- Outside instances WoW lets an addon send Say/Yell only as a direct response to a key
        -- press or click, and doesn't promise more than one line per press - so multi-line
        -- badges stay inside instances for Say/Yell rather than risking a blocked-action error.
        if lineCount > 1 and not IsInInstance() then
            return "WoW limits addons to one Say/Yell line per key press outside instances - use Guild, Party or Raid, or a one-line badge"
        end
    else
        return "unknown channel " .. tostring(chatType)
    end
end

local LINE_GAP_SECONDS = 0.2

-- The exact text that goes out for one row: leading spaces as no-break spaces.
local function ChatLine(line)
    local lead, rest = line:match("^( *)(.*)$")
    return NBSP:rep(#lead) .. rest
end

-- ---- Fitting a picture to the chat font ----
-- Badges are drawn on an even grid, but WoW's chat font is proportional: a space is far
-- narrower than "+" or "@", so a picture sent as typed slides out of line. Before a badge is
-- shown or sent, every symbol is moved back onto its grid column by (a) choosing how many
-- spaces go in each gap and (b) stretching runs like "-----" or "_____" to the right length.
-- The widths are measured from the real chat font in game, so what you see in the preview is
-- what other players with the default chat font see. (Players who changed their chat font
-- with another addon may still see it slightly off.)

-- Runs of these may be stretched or shrunk; every other symbol keeps its exact count.
local FILL = {["-"] = true, ["_"] = true, ["="] = true, ["~"] = true, ["."] = true}
-- Line strokes that may be nudged apart when they touch.
local STROKE = {["/"] = true, ["\\"] = true, ["||"] = true}

-- One entry per visible symbol: an escaped pipe "||" is one symbol, as is a UTF-8 letter.
local function Glyphs(line)
    local out, i = {}, 1
    while i <= #line do
        if line:sub(i, i + 1) == "||" then
            out[#out + 1] = "||"
            i = i + 2
        else
            local ch = line:match("^[%z\1-\127\194-\244][\128-\191]*", i) or line:sub(i, i)
            out[#out + 1] = ch
            i = i + #ch
        end
    end
    return out
end

-- lines: escaped badge rows. width(symbol) -> pixels. Returns the fitted rows, spaces as
-- no-break spaces (they keep their width at the start of a line too).
function ns.FitBadgeLines(lines, width)
    -- A one-row picture has no other row to line up with, so it goes out as drawn. (Putting it
    -- on the grid would only stretch its runs: the Rose's "--" stem came out as ~15 dashes.)
    if #lines < 2 then
        local out = {}
        for i, line in ipairs(lines) do out[i] = ChatLine(line) end
        return out
    end
    local rows, cell = {}, 0
    for i, line in ipairs(lines) do rows[i] = Glyphs(line) end
    for _, g in ipairs(rows) do
        for j, u in ipairs(g) do
            local inRun = FILL[u] and (g[j - 1] == u or g[j + 1] == u)
            if u ~= " " and not inRun then cell = math.max(cell, width(u)) end
        end
    end
    local space = width(NBSP)
    if cell <= 0 or space <= 0 then return lines end

    local out = {}
    for i, g in ipairs(rows) do
        local parts, x, j = {}, 0, 1
        while j <= #g do
            local u = g[j]
            if u == " " then
                local k = j
                while g[k] == " " do k = k + 1 end
                local nextGlyph = g[k]
                if nextGlyph then
                    -- Pad so the next symbol is centred in its column (a run's start sits on the
                    -- column's left edge, since the run itself is what gets stretched).
                    local nextIsRun = FILL[nextGlyph] and g[k + 1] == nextGlyph
                    local target = (k - 1) * cell + (nextIsRun and 0 or (cell - width(nextGlyph)) / 2)
                    local n = math.max(1, math.floor((target - x) / space + 0.5))
                    parts[#parts + 1] = NBSP:rep(n)
                    x = x + n * space
                end
                j = k
            elseif FILL[u] and g[j + 1] == u then
                local k = j
                while g[k] == u do k = k + 1 end
                local nextGlyph = g[k]
                local target = (k - 1) * cell
                if nextGlyph and nextGlyph ~= " " then target = target + (cell - width(nextGlyph)) / 2 end
                local n = math.max(2, math.floor((target - x) / width(u) + 0.5))
                parts[#parts + 1] = u:rep(n)
                x = x + n * width(u)
                j = k
            else
                -- Two drawing strokes touching (like "/|" on a cube's corner) get a small gap
                -- when the second would otherwise land left of its column. Letters and other
                -- symbols that touch ("[]", words) are left as drawn.
                local prev = g[j - 1]
                if prev and STROKE[u] and STROKE[prev] then
                    local target = (j - 1) * cell + (cell - width(u)) / 2
                    local n = math.floor((target - x) / space + 0.5)
                    if n > 0 then
                        parts[#parts + 1] = NBSP:rep(n)
                        x = x + n * space
                    end
                end
                parts[#parts + 1] = u
                x = x + width(u)
                j = j + 1
            end
        end
        -- A blank row in the middle of a picture still has to be a sendable line.
        out[i] = #parts > 0 and table.concat(parts) or NBSP
    end
    return out
end

-- The font the main chat window uses (falls back to the default chat font).
local function ChatFontParts()
    local font, size, flags
    if ChatFrame1 and ChatFrame1.GetFont then font, size, flags = ChatFrame1:GetFont() end
    if not font and ChatFontNormal then font, size, flags = ChatFontNormal:GetFont() end
    return font, size, flags
end

local measurer, widthCache, cacheKey = nil, {}, nil
-- A width(symbol) function for the current chat font, or nil if it can't be measured.
local function ChatGlyphWidth()
    local font, size, flags = ChatFontParts()
    if not font then return nil end
    if not measurer then
        local holder = CreateFrame("Frame", nil, UIParent)
        holder:SetSize(1, 1)
        holder:SetPoint("TOPLEFT")
        holder:SetAlpha(0)
        measurer = holder:CreateFontString(nil, "OVERLAY")
    end
    local key = font .. ":" .. tostring(size)
    if key ~= cacheKey then
        wipe(widthCache)
        cacheKey = key
        measurer:SetFont(font, size or 14, flags or "")
    end
    local measure = measurer.GetUnboundedStringWidth or measurer.GetStringWidth
    return function(u)
        local w = widthCache[u]
        if not w then
            -- Measured between two letters, since a lone space can measure as zero width.
            measurer:SetText("xx")
            local base = measure(measurer)
            measurer:SetText("x" .. u .. "x")
            w = math.max(0, measure(measurer) - base)
            widthCache[u] = w
        end
        return w
    end
end

-- The rows exactly as they'll be sent: fitted to the chat font when it can be measured, with
-- any row that fitting would push past the length limit left as drawn instead.
local function BadgeChatLines(lines)
    local width = ChatGlyphWidth()
    local fitted = width and ns.FitBadgeLines(lines, width) or lines
    local out = {}
    for i, line in ipairs(lines) do
        local f = fitted[i]
        out[i] = (#f <= MAX_LINE_LETTERS) and f or ChatLine(line)
    end
    return out
end
ns.BadgeChatLines = BadgeChatLines

local function SendLine(text, chatType)
    if C_ChatInfo and C_ChatInfo.SendChatMessage then
        C_ChatInfo.SendChatMessage(text, chatType)
    else
        SendChatMessage(text, chatType)
    end
end

-- Sends a badge (by name or list number; the selected one if omitted) to `chatType` (the saved
-- channel if omitted). Returns true when it went out.
function Maines_SendBadge(nameOrIndex, chatType)
    local db = DB()
    local badge = FindBadge(nameOrIndex or db.selected or 1)
    if not badge then
        ns.Say(PREFIX .. "no badge called \"" .. tostring(nameOrIndex) .. "\" - /mainbadge lists them")
        return false
    end
    chatType = chatType or db.channel
    if #badge.lines == 0 then
        ns.Say(PREFIX .. "the badge \"" .. badge.name .. "\" is empty")
        return false
    end
    if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
        ns.Say(PREFIX .. "WoW doesn't let addons send chat right now (encounter or match in progress) - try again after")
        return false
    end
    local wait = CooldownLeft()
    if wait > 0 then
        ns.Say(PREFIX .. "one Textual Badge every 3 minutes - the next one is ready in " .. Clock(wait))
        return false
    end
    local problem = ChannelProblem(chatType, #badge.lines)
    if problem then
        ns.Say(PREFIX .. "can't send to " .. (CHANNEL_BY_KEY[chatType] and CHANNEL_BY_KEY[chatType].label or chatType) .. ": " .. problem)
        return false
    end

    -- First line right away (still inside the key press or click), the rest a fifth of a second
    -- apart so the server's chat flood limit doesn't drop any. Multi-line badges only ever go to
    -- channels without the key-press rule (see ChannelProblem), so the delay is safe there.
    for i, text in ipairs(BadgeChatLines(badge.lines)) do
        if i == 1 then
            SendLine(text, chatType)
        else
            C_Timer.After((i - 1) * LINE_GAP_SECONDS, function()
                if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then return end
                SendLine(text, chatType)
            end)
        end
    end
    db.lastSent = Now()
    return true
end

local function SaveCustom(name, art)
    name = strtrim(name or "")
    local db = DB()
    if name == "" then ns.Say(PREFIX .. "give the badge a name first"); return false end
    for _, p in ipairs(PRESET_BADGES) do
        if p.name:lower() == name:lower() then
            ns.Say(PREFIX .. "\"" .. p.name .. "\" is a built-in badge - pick another name")
            return false
        end
    end
    local lines = ToLines(art or "")
    if #lines == 0 then ns.Say(PREFIX .. "the badge is empty - draw something first"); return false end
    if #lines > MAX_LINES then
        ns.Say(PREFIX .. "a badge can be at most " .. MAX_LINES .. " lines (this one has " .. #lines .. ")")
        return false
    end
    for i, line in ipairs(lines) do
        if #ChatLine(line) > MAX_LINE_LETTERS then
            ns.Say(PREFIX .. "line " .. i .. " is too long - keep each line under " .. MAX_LINE_LETTERS .. " letters")
            return false
        end
    end
    for _, c in ipairs(db.custom) do
        if c.name:lower() == name:lower() then
            c.art = table.concat(lines, "\n")
            db.selected = c.name
            ns.Say(PREFIX .. "updated your badge \"" .. c.name .. "\"")
            return true
        end
    end
    if #db.custom >= MAX_CUSTOM then
        ns.Say(PREFIX .. "you already have " .. MAX_CUSTOM .. " badges of your own - delete one first")
        return false
    end
    table.insert(db.custom, {name = name, art = table.concat(lines, "\n")})
    db.selected = name
    ns.Say(PREFIX .. "saved your badge \"" .. name .. "\"")
    return true
end

local function DeleteCustom(name)
    local db = DB()
    for i, c in ipairs(db.custom) do
        if c.name == name then
            table.remove(db.custom, i)
            if db.selected == name then db.selected = nil end
            ns.Say(PREFIX .. "deleted your badge \"" .. name .. "\"")
            return true
        end
    end
    return false
end

ns.SaveCustomBadge, ns.DeleteCustomBadge = SaveCustom, DeleteCustom

SLASH_MAINBADGE1 = "/mainbadge"
SlashCmdList["MAINBADGE"] = function(msg)
    msg = strtrim(msg or "")
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()
    if cmd == "" or cmd == "list" then
        ns.Say(PREFIX .. "Textual Badges (send one with /mainbadge send <number> [guild|party|raid|...]):")
        for i, b in ipairs(AllBadges()) do
            print(("  %d. %s%s |cFF888888(%d lines)|r"):format(i, b.name, b.custom and " |cFF888888(yours)|r" or "", #b.lines))
        end
        local wait = CooldownLeft()
        if wait > 0 then ns.Say(PREFIX .. "next badge ready in " .. Clock(wait)) end
    elseif cmd == "show" then
        local b = FindBadge(rest ~= "" and rest or DB().selected)
        if not b then ns.Say(PREFIX .. "no such badge - /mainbadge lists them"); return end
        ns.Say(PREFIX .. b.name .. " (only you can see this - it's exactly what would be sent):")
        for _, line in ipairs(BadgeChatLines(b.lines)) do print(line) end
    elseif cmd == "send" then
        local which, chan = rest:match("^(.-)%s+(%a+)$")
        local chatType
        if chan then
            for _, c in ipairs(CHANNELS) do
                if c.label:lower() == chan:lower() or c.key:lower() == chan:lower() then chatType = c.key end
            end
        end
        if not chatType then which = rest end
        Maines_SendBadge(which ~= "" and which or nil, chatType)
    else
        ns.Say(PREFIX .. "usage: /mainbadge [list] | show <number> | send <number> [channel]")
    end
end

-- ---- Badges page ----

local panel = ns.Panels.badges
local W = ns.PANEL_WIDTH
local C = ns.Colors
local SP = ns.SP
local CHAT_FONT = ChatFontNormal or ns.Fonts.Body

local function Label(parent, text, font, color)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(font or ns.Fonts.Body)
    fs:SetJustifyH("CENTER")
    fs:SetText(text or "")
    local c = color or C.INK
    fs:SetTextColor(c[1], c[2], c[3])
    return fs
end

local function DarkPlate(frame)
    frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    frame:SetBackdropColor(C.PLATE_BG[1], C.PLATE_BG[2], C.PLATE_BG[3], 1)
    frame:SetBackdropBorderColor(C.BORDER_DARK[1], C.BORDER_DARK[2], C.BORDER_DARK[3], 1)
    ns.TonePlateBackdrop(frame) -- follows /maincolor, keeping the walnut's brightness
    local shade = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
    shade:SetPoint("TOPLEFT", 1, -1)
    shade:SetPoint("BOTTOMRIGHT", -1, 1)
    shade:SetTexture("Interface\\Buttons\\WHITE8X8")
    shade:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0.25), CreateColor(1, 0.9, 0.7, 0.07))
end

local _, y = ns.MakeHeading(panel, "Textual Badges", 0, 0, W)
local intro = Label(panel, "Send a whole picture to chat, one line per row. One badge every 3 minutes. "
    .. "Other players see it in their own chat font, so spacing can shift a little.", ns.Fonts.Body, C.INK_SOFT)
-- A reading width narrower than the page, so the intro wraps into even lines.
intro:SetPoint("TOP", panel, "TOP", 0, y)
ns.BalanceText(intro, ns.READ_W)
y = y - intro:GetStringHeight() - SP.l

-- Left: the list of badges (presets, then your own). Rows are 26 tall, one every 30: the list
-- shows 8 whole rows (xs padding top and bottom) and scrolls for the rest, instead of cutting a
-- row off at the bottom.
local ROW_H, ROW_STEP = 26, 30
local LIST_W, LIST_H = 180, 8 * 30 - 4 + 2 * SP.xs
local listFrame = CreateFrame("Frame", nil, panel, "BackdropTemplate")
listFrame:SetPoint("TOPLEFT", 0, y)
listFrame:SetSize(LIST_W, LIST_H)
ns.MakeFlatBackdrop(listFrame, {0.86, 0.76, 0.56, 1}, C.BORDER_DARK, 1)
local listScroll = CreateFrame("ScrollFrame", nil, listFrame, "UIPanelScrollFrameTemplate")
listScroll:SetPoint("TOPLEFT", SP.xs, -SP.xs)
listScroll:SetPoint("BOTTOMRIGHT", -24, SP.xs)
local listChild = CreateFrame("Frame", nil, listScroll)
listChild:SetSize(LIST_W - 28, 1)
listScroll:SetScrollChild(listChild)

-- Right: the preview, channel choice and send button, together exactly as tall as the list.
local RIGHT_X = LIST_W + SP.l
local RIGHT_W = W - RIGHT_X
local CH_W, CH_H = 92, ns.BUTTON_H
local SEND_H = ns.BUTTON_H + 2
local PREVIEW_H = LIST_H - SP.m - (2 * CH_H + SP.s) - SP.m - SEND_H
local preview = CreateFrame("Frame", nil, panel, "BackdropTemplate")
preview:SetPoint("TOPLEFT", RIGHT_X, y)
preview:SetSize(RIGHT_W, PREVIEW_H)
DarkPlate(preview)
local previewText = preview:CreateFontString(nil, "OVERLAY")
previewText:SetFontObject(CHAT_FONT)
-- No fixed width: the text block is as wide as its longest row and sits centered on the plate,
-- while the rows stay left-aligned to each other so the picture keeps its shape.
previewText:SetPoint("CENTER")
previewText:SetJustifyH("LEFT")
previewText:SetJustifyV("MIDDLE")
previewText:SetTextColor(0.95, 0.88, 0.72)

local ry = y - PREVIEW_H - SP.m
-- "Send to:" on the left of the two rows of channel buttons, all centred as one block.
local sendToLabel = Label(panel, "Send to:", ns.Fonts.Header, C.INK)
local channelButtons = {}
local gridW = sendToLabel:GetStringWidth() + SP.m + 4 * CH_W + 3 * SP.s
local gridX = RIGHT_X + math.floor((RIGHT_W - gridW) / 2) + sendToLabel:GetStringWidth() + SP.m
sendToLabel:SetPoint("TOPRIGHT", panel, "TOPLEFT", gridX - SP.m, ry - (CH_H - sendToLabel:GetStringHeight()) / 2)
for i, ch in ipairs(CHANNELS) do
    local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
    local btn = ns.MakeButton(panel, CH_W, CH_H, ch.label)
    btn:SetPoint("TOPLEFT", gridX + col * (CH_W + SP.s), ry - row * (CH_H + SP.s))
    btn:SetScript("OnClick", function() DB().channel = ch.key; Maines_RefreshWindow() end)
    channelButtons[ch.key] = btn
end
ry = ry - 2 * CH_H - SP.s - SP.m

local sendBtn = ns.MakeButton(panel, 170, SEND_H, "Send Badge")
-- Send button and the cooldown text (about 140 wide) centred together under the channels.
sendBtn:SetPoint("TOPLEFT", RIGHT_X + math.floor((RIGHT_W - (170 + SP.m + 140)) / 2), ry)
sendBtn:SetScript("OnClick", function()
    if Maines_SendBadge() then Maines_RefreshWindow() end
end)
local cooldownText = Label(panel, "", ns.Fonts.Body, C.INK_SOFT)
cooldownText:SetPoint("LEFT", sendBtn, "RIGHT", SP.m, 0)

y = y - LIST_H - SP.xl

-- Bottom: make your own.
local _, cy = ns.MakeHeading(panel, "Make your own badge", 0, y, W)
y = cy
local nameLabel = Label(panel, "Name:", ns.Fonts.Header, C.INK)
local editHint = Label(panel, "Up to " .. MAX_LINES .. " lines.", ns.Fonts.BodySmall, C.INK_SOFT)
-- Name, box, Save, Delete and the hint centred as one row.
local NAME_W, EDIT_BTN_W = 170, 96
local rowW = nameLabel:GetStringWidth() + SP.s + NAME_W + SP.m + 2 * EDIT_BTN_W + SP.s + SP.m + editHint:GetStringWidth()
local rowX = math.floor((W - rowW) / 2)
nameLabel:SetPoint("TOPLEFT", rowX, y - (ns.BUTTON_H - nameLabel:GetStringHeight()) / 2)
local nameBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
nameBox:SetSize(NAME_W, ns.INPUT_H)
nameBox:SetPoint("TOPLEFT", rowX + nameLabel:GetStringWidth() + SP.s, y - (ns.BUTTON_H - ns.INPUT_H) / 2)
nameBox:SetAutoFocus(false)
nameBox:SetJustifyH("CENTER")
nameBox:SetMaxLetters(24)
nameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

local saveBtn = ns.MakeButton(panel, EDIT_BTN_W, ns.BUTTON_H, "Save")
saveBtn:SetPoint("LEFT", nameBox, "RIGHT", SP.m, 0)
local deleteBtn = ns.MakeButton(panel, EDIT_BTN_W, ns.BUTTON_H, "Delete")
deleteBtn:SetPoint("LEFT", saveBtn, "RIGHT", SP.s, 0)
deleteBtn.tooltip = "Delete the selected badge (only your own badges can be deleted)"
editHint:SetPoint("LEFT", deleteBtn, "RIGHT", SP.m, 0)
y = y - ns.BUTTON_H - SP.m

local editFrame = CreateFrame("Frame", nil, panel, "BackdropTemplate")
editFrame:SetPoint("TOPLEFT", 0, y)
editFrame:SetPoint("BOTTOMRIGHT", 0, 0)
DarkPlate(editFrame)
local editScroll = CreateFrame("ScrollFrame", nil, editFrame, "UIPanelScrollFrameTemplate")
editScroll:SetPoint("TOPLEFT", SP.m, -SP.s)
editScroll:SetPoint("BOTTOMRIGHT", -28, SP.s)
local artBox = CreateFrame("EditBox", nil, editScroll)
artBox:SetMultiLine(true)
artBox:SetAutoFocus(false)
artBox:SetFontObject(CHAT_FONT)
artBox:SetTextColor(0.95, 0.88, 0.72)
artBox:SetWidth(W - 28 - SP.m - SP.s)
artBox:SetMaxLetters(MAX_LINES * MAX_LINE_LETTERS)
artBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
editScroll:SetScrollChild(artBox)
editFrame:EnableMouse(true)
editFrame:SetScript("OnMouseDown", function() artBox:SetFocus() end)

saveBtn:SetScript("OnClick", function()
    if SaveCustom(nameBox:GetText(), artBox:GetText()) then
        nameBox:ClearFocus(); artBox:ClearFocus()
        Maines_RefreshWindow()
    end
end)
deleteBtn:SetScript("OnClick", function()
    local selected = FindBadge(DB().selected)
    if selected and selected.custom then
        DeleteCustom(selected.name)
        nameBox:SetText(""); artBox:SetText("")
        Maines_RefreshWindow()
    else
        ns.Say(PREFIX .. "select one of your own badges first - the built-in ones can't be deleted")
    end
end)

local listButtons = {}
local function SelectBadge(b)
    DB().selected = b.name
    if b.custom then
        nameBox:SetText(b.name)
        artBox:SetText(table.concat(b.lines, "\n"))
    end
    Maines_RefreshWindow()
end

local function UpdateCooldown()
    local wait = CooldownLeft()
    if wait > 0 then
        cooldownText:SetText("Next badge in " .. Clock(wait))
    else
        cooldownText:SetText("|cFF2E6B1EReady to send|r")
    end
    -- greyed while cooling down (a click still says how long is left)
    sendBtn:SetUnavailable(wait > 0)
end

local tick = 0
panel:SetScript("OnUpdate", function(_, elapsed)
    tick = tick + elapsed
    if tick >= 0.5 then tick = 0; UpdateCooldown() end
end)

table.insert(ns.RefreshHooks, function()
    local db = DB()
    local all = AllBadges()
    local selected = FindBadge(db.selected) or all[1]
    for i, b in ipairs(all) do
        local btn = listButtons[i]
        if not btn then
            btn = ns.MakeButton(listChild, LIST_W - 30, ROW_H, "")
            btn:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_STEP)
            listButtons[i] = btn
        end
        btn:SetText(b.custom and ("* " .. b.name) or b.name)
        btn:SetWidth(LIST_W - 30)
        btn:SetScript("OnClick", function() SelectBadge(b) end)
        if b == selected or (selected and b.name == selected.name) then btn:Disable() else btn:Enable() end
        btn:Show()
    end
    for i = #all + 1, #listButtons do listButtons[i]:Hide() end
    listChild:SetHeight(math.max(1, (#all - 1) * ROW_STEP + ROW_H))

    -- Same font as the chat window and the same fitted rows that would be sent.
    local font, size, flags = ChatFontParts()
    if font then previewText:SetFont(font, size or 14, flags or "") end
    previewText:SetText(selected and table.concat(BadgeChatLines(selected.lines), "\n") or "")
    for key, btn in pairs(channelButtons) do
        if key == db.channel then btn:Disable() else btn:Enable() end
    end
    -- only your own badges can be deleted: greyed for a built-in one (a click says so)
    deleteBtn:SetUnavailable(not (selected and selected.custom))
    UpdateCooldown()
end)
