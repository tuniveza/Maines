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
    <NEW> /mainchat mode include -- (default) the list is a whitelist: tag ONLY those channels
    <NEW> /mainchat mode exclude -- flip it: tag every channel EXCEPT the ones listed
    <NEW> /mainchat sticky      -- keep the current filter across reloads (off by default - see below)
    <NEW> /brackets - to see all bracket types
    <NEW> /maincolor - paints the Maines UI textures a random color from a random public-domain art palette
    <NEW> /mainmap - toggle the Maines minimap icon on/off
    <NEW> /mainhide / /mainshow - choose whether the tag is suppressed when you're playing your own main (default: hidden)
    <NEW> /mainhelp - opens a movable, scrollable command reference window (icons, an example graphic, grouped by category) - "/mainhelp text" prints the old chat version instead
    /mainmusic - to reset the maines introduction music upon first open
    /mainstamp - to see stamp (version) of maines


    NEXT FEATURES TO IMPLEMENT:
    Real gnomish/goblin-engineered artwork for the GUI rewrite below (currently a flat-color
    placeholder skeleton - see GUI REWRITE further down)
    Aesthetic Brackets
    Aesthetic Features
    =========================

    ==========================================
    GUI REWRITE: /maines IS NOW A TABBED CONTROL PANEL
    ==========================================
    Every text command above still works exactly as before - nothing was removed. /maines now
    also opens a tabbed window (Main / Filter / Behavior / Cosmetic / Help) that reaches the
    exact same functionality without needing to remember any command syntax: a name box and
    bracket buttons instead of /mains <name> <bracket>, checkboxes instead of /mainchat's
    comma lists, and so on. Every widget calls straight into the existing slash command
    handler (or flips the same saved variable a command flips), so there is exactly one
    implementation of each piece of behavior and the GUI can never drift out of sync with what
    the text commands do.

    All of the old hand-painted .tga/.png art (bg, header, command panel, option panel, stamp,
    close button, parchment tile, minimap icon, the mainhelp example graphic) has been moved to
    img/old/ and is no longer referenced by any code - it's gitignored there, kept only for the
    next art pass to reference or reuse. The window and the /mainhelp reference panel are both
    built from Blizzard's own dialog-box border/background art, button/checkbox/editbox
    templates, and a set of spinning gear/gizmo icons standing in for real artwork. This is a
    deliberate placeholder skeleton, not a finished skin.

    ==========================================
    GUI POLISH PASS: fonts, contrast, dynamic brackets, more color
    ==========================================
    Follow-up pass on the same placeholder skeleton, still with no custom art files:
    - Bracket buttons on the Main tab now live-preview <left><current name><right> as you type
      in the name box, resizing and reflowing into more rows as needed for long names - no more
      static "M" placeholder. Clicking one still applies immediately (auto-update); a new Apply
      button lets you reapply the last-picked bracket (or a filled-in custom symbol) after
      editing the name, without hunting for the same bracket button again.
    - Custom font pairing instead of Blizzard's default UI fonts (superseded below - see
      FONT/CONTRAST/COLOR REWORK for what's actually in use now).
    - Every label that used to inherit Blizzard's default white/gold text color now has an
      explicit dark ink color tuned for the light parchment panels - the old build had several
      spots (channel checkboxes, several checkbox labels, the "currently saved" preview line)
      that were effectively white-on-near-white. Recoloring via /maincolor is now deliberately
      scoped to chrome only (borders, buttons, gear icons, one nameplate on a fixed dark plate)
      rather than body text, so a palette roll can never make the addon unreadable again.
    - /maincolor's reach widened significantly: every button across all five tabs, the window
      and content-panel borders, and every gear/gizmo icon now repaint together, not just the
      window frame and a couple of textures.
    - Several more palettes, including gnomish/goblin-flavored ones (Gnomeregan Copper,
      Undermine Neon, Ironforge Brass & Steel, Verdigris Goblin, Blueprint Ink) alongside the
      original public-domain art palettes. Buttons default to a brass/copper "engineered" tint
      instead of Blizzard's stock gold button skin.
    - Tabs are now icon+text (image buttons), reusing icons already proven safe elsewhere in
      this file (the /mainhelp icon set). Gnome/goblin race-flavor badges flank the window
      title, and a small riveted credits plate ("Designed by ... / Coded and Guided by ...")
      sits above the stamp footer, visible on every tab.
    - Fixed "The Mosaic Stamp" not rendering in the window footer: it used a "▦" character
      that the font it was drawn with has no glyph for, so it silently rendered as nothing.
      Replaced with a small icon plus plain text in a font with full ASCII coverage.

    ==========================================
    FONT/CONTRAST/COLOR REWORK (round 2, direct user feedback)
    ==========================================
    Reported: fonts looked bad, brightness was inconsistent panel-to-panel, the window wasn't
    octagonal, /maincolor's effect was too subtle, "where are the textures", the Mosaic Stamp
    badge didn't actually look like a mosaic, and text should be centered instead of left-run.
    - Fonts: dropped the MORPHEUS/ARIALN pairing (and the FRIZQT__ fallback tried briefly in
      between) for Agave, a real font FILE now shipped with the addon at fonts/agave/ (SIL Open
      Font License 1.1 - see fonts/agave/LICENSE) via its Nerd Fonts "Propo" release, subset
      with pyftsubset down to the Latin + punctuation ranges this UI needs (~2.6MB per weight
      down to ~45KB - the upstream release ships thousands of icon glyphs this addon never
      uses). Maines_MakeFontObject() falls back to Blizzard's FRIZQT__ if the file is ever
      missing so a corrupted install degrades instead of erroring.
    - Brightness: every panel now pulls from one shared value ramp (WINDOW_BG / CONTENT_BG /
      PLATE_BG / BORDER_DARK, defined once near the top of the GUI helpers) instead of each
      panel hard-coding its own tint. The old build jumped from near-white content panels to
      near-black plates within the same window; everything now sits in one warm brass/walnut
      family, light to dark.
    - Octagon shape: NOT attempted as a real window silhouette - that needs an alpha-masked
      texture asset (real art), which backdrops/solid textures fundamentally cannot fake. This
      round tried a diagonal accent-bar "chamfer" as a placeholder compromise - see the next
      section for how that actually turned out.
    - /maincolor depth: backdrop FILLS were made recolorable too (blended toward the palette
      color), not just borders. Buttons were rebuilt on Blizzard's UIPanelButtonTemplate with
      their normal texture vertex-tinted brass/copper - see the next section for how that
      actually turned out.
    - Mosaic badge: the gear icon standing in for the "▦" glyph never actually looked like a
      mosaic. Replaced with Maines_MakeMosaicBadge() - a literal 4-tile checkerboard built from
      colored squares, half of them recolorable so the checker pattern survives every palette.
      This one held up and is still in place.
    - Text centering: every standalone paragraph/label FontString (panel intros, section
      headers, the chat preview line, status lines) is now center-justified. Labels that sit
      inline next to a control - a checkbox, a swatch row - were deliberately left as-is:
      centering "Whisper" independently of the checkbox it names would misalign the row.

    ==========================================
    ROUND 3: what round 2 actually looked like in-game (screenshot-verified)
    ==========================================
    Round 2 was built and reasoned about without ever seeing it rendered - this addon has no
    in-client test harness, only a syntax/logic-level Lua stub. Once a real screenshot came
    back, two of round 2's choices turned out to be flatly broken rather than merely
    suboptimal, and were reverted rather than tuned:
    - "Interface\DialogFrame\UI-DialogBox-Background"/"-Border", used for every panel's fill
      and border, rendered as fully TRANSPARENT in this client - the window and content panel
      showed the 3D world and other UI straight through them, with no visible fill or border at
      all. Reverted Maines_MakeFlatBackdrop to plain "Interface\Buttons\WHITE8X8" (a solid-color
      pixel texture, the same thing Maines_MakeSlab already used successfully for the title/
      credits plates, which DID render correctly opaque in the screenshot). This also explains
      the "still dark text" report: the dark ink text color was tuned for an opaque light
      parchment panel that, in practice, was never actually there - it was dark text on a
      transparent window showing a dark dungeon/world background through it.
    - UIPanelButtonTemplate + GetNormalTexture():SetVertexColor(): the tint never visibly
      applied - every button rendered as Blizzard's stock default skin (a reddish fill with a
      white/cream border), completely unresponsive to /maincolor. Reverted to a fully custom
      WHITE8X8-backdrop button (Maines_MakeButton), matching the panel fix above - color, text,
      sizing, and /maincolor response are now all things this code directly sets rather than
      assumptions about an opaque Blizzard widget's internals.
    - Buttons now auto-size to fit their own rendered text plus padding (measured via
      GetStringWidth() against the actual font in use) instead of a fixed guessed pixel width,
      fixing text that was rendering at the wrong size for its button.
    - The diagonal corner "chamfer" accents from round 2 read as "horrible brown tape" rather
      than a chamfered-plate illusion - removed outright, not tuned. The window is an honest
      rectangle again; a real octagonal silhouette still needs a real art asset.
    - Button rows (mode toggle, sticky/clear, minimap/music/palette controls, help buttons) and
      the bracket button grid are now centered as a block within their panel, not left-anchored
      - "buttons are not centered" was accurate, and the round-2 decision to only center
      standalone text and leave controls left-flowed was corrected.
    - The credits plate's first line was letting Blizzard auto-wrap a single long sentence,
      which broke at an arbitrary point (leaving one orphaned word on its own line). Replaced
      with three explicit, deliberately-chosen lines instead of one auto-wrapped one.

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

    ==========================================
    /mainchat: STICKY FILTERS + INCLUDE/EXCLUDE MODE
    ==========================================
    Two separate follow-ups after the filtering-bug fix above, both from real
    confusion:

    1) A filter set once during testing and then forgotten about kept silently
    excluding channels forever, since Maines_Chat_Options_DB is a plain
    SavedVariable with no expiry. Filters are now session-only by default -
    OnInitialize wipes the filter on every fresh load unless you've explicitly
    run /mainchat sticky to keep it. Middle-clicking the minimap icon also
    clears it instantly, any time, sticky or not.

    2) The filter list was always a whitelist (tag ONLY the listed channels),
    which is fine for "just SAY and GUILD" but awkward for "everything except
    WHISPER, because another addon already handles that" - the old way meant
    listing every other channel by hand. /mainchat mode exclude flips the same
    list into a blacklist (tag everything EXCEPT what's listed); /mainchat mode
    include (the default) flips it back. Same +CHANNEL/-CHANNEL/list commands
    work under either mode - only the interpretation of the list changes.

    ==========================================
    /mainchat -SAY,-YELL COULD SILENTLY ERASE THE FILTER
    ==========================================
    Reported by a real user (not just internal testing): "/mainchat -SAY,-YELL
    removed all channels, and typing them one by one didn't add [it] back."
    The +CHANNEL/-CHANNEL pattern only ever matched ONE operation at a time -
    "-SAY,-YELL" failed that pattern (comma + a second op in the string) and
    fell through to the "replace the whole filter" branch, which stored the
    literal strings "-SAY" and "-YELL" - hyphens included - as if they were
    channel names. Neither can ever equal a real chatType, so the filter
    became "matches nothing": every message stopped getting tagged, not just
    the ones for SAY/YELL. Retyping "-SAY" alone afterwards then searched for
    an entry equal to "SAY" to remove, found "-SAY" instead (not a match), and
    silently did nothing - matching "typed it one by one, it wasn't added."
    Fixed properly rather than patched around: +CHANNEL/-CHANNEL now accepts
    a comma-separated list of operations in one command (edits the existing
    filter), a plain comma-separated list still replaces the whole filter, and
    - critically - mixing the two styles in one command is now REJECTED with
    an explicit error instead of silently falling through to whichever branch
    happens to mishandle it. Verified against the stub harness with the exact
    reported input.

    STILL TO DO:
    - Real gnomish/goblin-engineered artwork for the tabbed window and /mainhelp panel (both
      are currently a flat-color, template-only placeholder skeleton - see GUI REWRITE above)
    - Aesthetic Brackets / Aesthetic Features (see NEXT FEATURES TO IMPLEMENT above)

 ]]
local maines = LibStub("AceAddon-3.0"):NewAddon("Maines","AceHook-3.0")

-- Session-to-session variety for /maincolor. GetTime() (unlike the apparently-absent time())
-- is a core WoW timer API that's about as safe a bet as they come, but this is purely cosmetic,
-- so it's still pcall-wrapped: if that assumption is ever wrong too, the failure is swallowed
-- right here instead of aborting the rest of the file the way the old time() call did.
pcall(function() math.randomseed(GetTime() * 1000) end)

-- Every UI texture/backdrop gets registered here as it's created so /maincolor can repaint
-- all of them at once. Holds {texture=..., kind="texture"|"backdrop"} entries.
local Maines_Textures = {}

-- The main window is built once, down in the GUI section near the bottom of this file, and
-- assigned to this forward-declared local. Everything above that (slash handlers, chat tagging)
-- only ever calls Maines_Window:Show()/:Hide() through the wrapper functions below, so load
-- order between "logic" and "GUI construction" doesn't matter - same pattern Lua closures always
-- use for a local that's assigned after other functions already reference it as an upvalue.
local Maines_Window

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

-- /maincolor: dominant colors pulled from well-known public-domain paintings, plus a few
-- named "workshop" schemes tuned for the gnomish/goblin-engineering theme itself. Each entry
-- is a {name = ..., colors = {hex, hex, ...}} table; the command rolls a random palette, then
-- a random color from within it. The Cosmetic tab also lets you pick an exact swatch instead
-- of rolling randomly.
local Color_Palettes = {
    {name = "The Starry Night (Van Gogh, 1889)", colors = {"1B3B6F", "2E5A87", "0B1F3A", "F3D250", "F7E7A0"}},
    {name = "The Great Wave off Kanagawa (Hokusai, c.1831)", colors = {"1B3A5C", "3E6E96", "C9D8E0", "EDE4D3", "2A2A2A"}},
    {name = "The Kiss (Klimt, 1908)", colors = {"C9A227", "8B1E3F", "1C1C1C", "D4AF37", "5A3E2B"}},
    {name = "Water Lilies (Monet, 1906)", colors = {"7FA6A0", "A8C9C4", "D9A6C2", "5B7C99", "EDEAD9"}},
    {name = "The Scream (Munch, 1893)", colors = {"E8622C", "F2A65A", "2E3A6E", "8C1C13", "F4E3B2"}},
    {name = "Composition II (Mondrian, 1930)", colors = {"D40920", "1356A2", "F7D842", "1B1B1B", "F5F5F0"}},
    {name = "Nighthawks (Hopper, 1942)", colors = {"2B3A42", "6E8894", "C9B896", "8A3B2E", "0E1416"}},
    {name = "The Persistence of Memory (Dali, 1931)", colors = {"C98A4B", "6E7A8A", "2E2A24", "8C6A3E", "D9C7A3"}},
    {name = "Gnomeregan Copper", colors = {"B5651D", "8A4A1E", "D98F3B", "5A3A1E", "C97D3E"}},
    {name = "Undermine Neon", colors = {"E84C4C", "F2C230", "3BB273", "2E86AB", "1B1B2E"}},
    {name = "Ironforge Brass & Steel", colors = {"9C7A3C", "6B7280", "3A3A3A", "C9A66B", "8A8F98"}},
    {name = "Verdigris Goblin", colors = {"4E7A5C", "2E4A38", "8AA88A", "6B5B3E", "1C2B22"}},
    {name = "Blueprint Ink", colors = {"1B3A5C", "3E6E96", "C9D8E0", "F5F5F0", "0B1F3A"}},
}

local function Maines_HexToRGB(hex)
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

-- ==========================================================================
-- Art-free GUI helpers
-- ==========================================================================
-- The GUI rewrite drops every custom .tga/.png in favor of Blizzard's own stock textures,
-- backdrop templates, and icons - a placeholder "engineered paper" skeleton that the next art
-- pass can re-skin without touching any layout logic. These few helpers are shared by every
-- panel built further down (the main window and the /mainhelp window).

-- Font objects, loaded from the addon's own font files (fonts/agave/) rather than Blizzard's
-- built-ins - Agave, a free/open monospace-derived font (SIL Open Font License 1.1, bundled
-- with LICENSE/NOTICE in that folder), via its Nerd Fonts "Propo" (proportional-metrics)
-- release, subset down to the Latin + punctuation ranges this UI actually uses (~2.6MB per
-- weight down to ~45KB - the original ships thousands of icon glyphs this addon has no use
-- for). Falls back to Blizzard's own FRIZQT__ if the font file is ever missing for some
-- reason (a corrupt install, a manual file deletion) so the UI degrades instead of erroring.
local AGAVE_REGULAR = "Interface\\AddOns\\Maines\\fonts\\agave\\Agave-Regular.ttf"
local AGAVE_BOLD = "Interface\\AddOns\\Maines\\fonts\\agave\\Agave-Bold.ttf"

local function Maines_MakeFontObject(name, path, size, flags)
    local font = CreateFont(name)
    if not font:SetFont(path, size, flags) then
        font:SetFont("Fonts\\FRIZQT__.TTF", size, flags)
    end
    return font
end

local Maines_Font_Title = Maines_MakeFontObject("Maines_Font_Title", AGAVE_BOLD, 24, "")
local Maines_Font_Header = Maines_MakeFontObject("Maines_Font_Header", AGAVE_BOLD, 13, "")
local Maines_Font_Body = Maines_MakeFontObject("Maines_Font_Body", AGAVE_REGULAR, 12, "")
local Maines_Font_BodySmall = Maines_MakeFontObject("Maines_Font_BodySmall", AGAVE_REGULAR, 10, "")
local Maines_Font_Button = Maines_MakeFontObject("Maines_Font_Button", AGAVE_BOLD, 12, "")

-- A single warm brass/walnut value ramp used for every panel in the UI, light to dark, so
-- nothing jumps between near-white and near-black the way the first pass did. Ink colors are
-- fixed (not recolored) so text always stays readable regardless of the active palette.
local INK = {0.14, 0.08, 0.03}
local INK_SOFT = {0.32, 0.22, 0.13}
local PLATE_TEXT = {0.96, 0.91, 0.78}

local WINDOW_BG = {0.68, 0.55, 0.34, 1}
local CONTENT_BG = {0.80, 0.68, 0.46, 1}
local PLATE_BG = {0.24, 0.16, 0.09, 1}
local BORDER_DARK = {0.30, 0.19, 0.09, 1}

-- Every colorable thing registers here so /maincolor can repaint the whole UI at once:
-- - texture: a plain Texture region, fully tinted to the palette color (gear icons, button
--   faces) - the strongest, most visible form of recolor.
-- - backdrop: a panel's border/edge, fully tinted.
-- - fill: a panel's background fill, BLENDED toward the palette color rather than replaced
--   outright, so the color clearly comes through without ever swinging bright enough to break
--   the fixed-ink text sitting on top of it.
-- - fontstring: a FontString's color - only ever used for accent text sitting on a fixed dark
--   plate, where a light accent color always stays readable.
local function Maines_RegisterTexture(tex)
    table.insert(Maines_Textures, {texture = tex})
    return tex
end
local function Maines_RegisterBackdropTrim(frame)
    table.insert(Maines_Textures, {backdrop = frame})
    return frame
end
local function Maines_RegisterFill(frame, base)
    table.insert(Maines_Textures, {fill = frame, base = base})
    return frame
end
local function Maines_RegisterFontColor(fs)
    table.insert(Maines_Textures, {fontstring = fs})
    return fs
end
-- A button's fill AND border, replaced outright (not blended) with the palette color - buttons
-- have their own fixed-color text layer on top, so pushing the full color through (rather than
-- the softer blend panels use) is what actually makes /maincolor read as a strong, obvious
-- change instead of a subtle tint.
local function Maines_RegisterButton(btn)
    table.insert(Maines_Textures, {button = btn})
    return btn
end
local FILL_BLEND = 0.55
-- Forward-declared, assigned down by Maines_MakeButton - same pattern as Maines_Window and
-- Maines_LayoutMainPanel elsewhere in this file, for the same reason: this function needs to
-- exist as an upvalue here before its real body (which needs button-local state) is written.
local Maines_SetButtonBaseColor
local function Maines_ApplyPaletteColor(r, g, b, hex, label)
    for _, entry in ipairs(Maines_Textures) do
        if entry.texture then
            entry.texture:SetVertexColor(r, g, b)
        elseif entry.button then
            Maines_SetButtonBaseColor(entry.button, r, g, b)
        elseif entry.fill then
            local base = entry.base
            entry.fill:SetBackdropColor(
                base[1] * (1 - FILL_BLEND) + r * FILL_BLEND,
                base[2] * (1 - FILL_BLEND) + g * FILL_BLEND,
                base[3] * (1 - FILL_BLEND) + b * FILL_BLEND,
                base[4] or 1)
        elseif entry.backdrop then
            entry.backdrop:SetBackdropBorderColor(r, g, b, 1)
        elseif entry.fontstring then
            entry.fontstring:SetTextColor(r, g, b)
        end
    end
    if hex and label then
        print(("|cFF00FF00Maines|r: painted #%s from \"%s\""):format(hex, label))
    end
end

-- Every panel in this UI - the window itself, the content area, the small plates - is built
-- from "Interface\Buttons\WHITE8X8" (a plain solid-color pixel texture) rather than any of
-- Blizzard's named dialog/frame art. An earlier pass tried real Blizzard border/background
-- textures for visible paper grain; in practice those paths rendered as fully transparent in
-- this client (the window and its panels showed the 3D world straight through them), which is
-- a strictly worse bug than a flat but fully opaque, correctly colored panel. WHITE8X8 is the
-- one texture guaranteed to render exactly as its color says, so everything uses it now.
-- Genuine surface grain/weathering needs a real art asset - out of scope for this pass.
local function Maines_MakeFlatBackdrop(frame, bg, border, edgeSize)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = edgeSize or 2,
    })
    frame:SetBackdropColor(bg[1], bg[2], bg[3], 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], 1)
    Maines_RegisterFill(frame, bg)
    Maines_RegisterBackdropTrim(frame)
    return frame
end

-- A plain flat-color panel (no palette recoloring) - used for small chrome like the credits
-- plate and the title nameplate, where a stable dark surface is what makes the light accent
-- text on top of it safe to read regardless of the active palette.
local function Maines_MakeSlab(frame, bg, border, edgeSize)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = edgeSize or 1,
    })
    frame:SetBackdropColor(bg[1], bg[2], bg[3], 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], 1)
    return frame
end

-- Slowly spins a texture forever - used for the gear icons that stand in for real engraved
-- artwork until the next art pass.
local function Maines_Spin(tex, duration)
    if not tex or tex.maines_spin then return end
    local ag = tex:CreateAnimationGroup()
    local rot = ag:CreateAnimation("Rotation")
    rot:SetDegrees(360)
    rot:SetDuration(duration or 9)
    rot:SetSmoothing("IN_OUT")
    ag:SetLooping("REPEAT")
    ag:Play()
    tex.maines_spin = ag
end

-- A small brass-toned icon, optionally spinning - the recurring decorative motif standing in
-- for real gnomish/goblin engineering artwork. iconPath defaults to the engineering gear.
local function Maines_MakeGear(parent, size, spin, duration, iconPath)
    local tex = parent:CreateTexture(nil, "OVERLAY")
    tex:SetSize(size, size)
    tex:SetTexture(iconPath or "Interface\\Icons\\Trade_Engineering")
    tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    tex:SetVertexColor(0.62, 0.47, 0.20)
    if spin then Maines_Spin(tex, duration) end
    return Maines_RegisterTexture(tex)
end

-- A static (non-spinning, non-recolored) badge icon - used for race-flavor emblems, where a
-- fixed appearance reads better than something that shifts with /maincolor.
local function Maines_MakeBadge(parent, size, iconPath)
    local tex = parent:CreateTexture(nil, "OVERLAY")
    tex:SetSize(size, size)
    tex:SetTexture(iconPath)
    tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    return tex
end

-- A literal small mosaic: four tiles in a checkerboard, two fixed dark and two recolorable -
-- standing in for the "▦" (mosaic) glyph, which several UI fonts (including the one this used
-- before) simply have no printable character for, so it rendered as nothing. Keeping half the
-- tiles fixed means the checkerboard pattern itself survives every /maincolor repaint instead
-- of turning into one flat square.
local function Maines_MakeMosaicBadge(parent, size)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(size, size)
    local half = math.floor(size / 2)
    local corners = {"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}
    for i, point in ipairs(corners) do
        local tile = holder:CreateTexture(nil, "OVERLAY")
        tile:SetTexture("Interface\\Buttons\\WHITE8X8")
        tile:SetSize(half - 1, half - 1)
        tile:SetPoint(point, holder, point, 0, 0)
        if i % 2 == 0 then
            tile:SetVertexColor(0.62, 0.47, 0.20)
            Maines_RegisterTexture(tile)
        else
            tile:SetVertexColor(0.20, 0.13, 0.06)
        end
    end
    return holder
end

-- A fixed-color swatch button (used by the /maincolor palette picker). Deliberately NOT
-- registered - it exists to always show its true palette color as a legend, so it must not
-- get repainted along with the rest of the UI.
local function Maines_MakeSwatch(parent, r, g, b)
    local sw = CreateFrame("Button", nil, parent, "BackdropTemplate")
    sw:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    sw:SetBackdropColor(r, g, b, 1)
    sw:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)
    return sw
end

-- A gnomish/goblin-engineered button - a fully custom WHITE8X8 backdrop rectangle, the same
-- proven-reliable pattern as the panels above, NOT Blizzard's UIPanelButtonTemplate. An earlier
-- pass tried the template with a vertex-tinted normal texture for "real bevel art"; in practice
-- the tint never took and every button rendered as Blizzard's stock red/white skin, completely
-- untouched. This version is fully self-drawn, so its color, its text, and how /maincolor
-- affects it are all things this code actually controls rather than guesses about template
-- internals. Auto-sizes to fit its own text (plus padding) so it can never clip or overflow
-- regardless of what the font's actual rendered width turns out to be - `width` is a MINIMUM,
-- not a fixed size.
local BUTTON_BORDER_SHADE = 0.42

function Maines_SetButtonBaseColor(btn, r, g, b)
    btn.baseColor = {r, g, b}
    if btn:IsEnabled() then
        btn:SetBackdropColor(r, g, b, 1)
        btn:SetBackdropBorderColor(r * BUTTON_BORDER_SHADE, g * BUTTON_BORDER_SHADE, b * BUTTON_BORDER_SHADE, 1)
    end
end

local BUTTON_TINT = {0.70, 0.47, 0.18}
local BUTTON_DISABLED = {0.40, 0.37, 0.32}
local BUTTON_TEXT_DISABLED = {0.68, 0.64, 0.56}

local function Maines_MakeButton(parent, width, height, text)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })

    local fs = btn:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(Maines_Font_Button)
    fs:SetText(text or "")
    fs:SetPoint("CENTER")
    fs:SetTextColor(PLATE_TEXT[1], PLATE_TEXT[2], PLATE_TEXT[3])
    btn.text = fs

    local neededWidth = fs:GetStringWidth() + 26
    btn:SetSize(math.max(width or 0, neededWidth), height)

    Maines_SetButtonBaseColor(btn, BUTTON_TINT[1], BUTTON_TINT[2], BUTTON_TINT[3])
    Maines_RegisterButton(btn)

    btn:SetScript("OnEnter", function(self)
        if self:IsEnabled() and self.baseColor then
            local c = self.baseColor
            self:SetBackdropColor(math.min(1, c[1] * 1.3), math.min(1, c[2] * 1.3), math.min(1, c[3] * 1.3), 1)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if self:IsEnabled() and self.baseColor then
            local c = self.baseColor
            self:SetBackdropColor(c[1], c[2], c[3], 1)
        end
    end)
    btn:SetScript("OnMouseDown", function(self)
        if self:IsEnabled() and self.baseColor then
            local c = self.baseColor
            self:SetBackdropColor(c[1] * 0.65, c[2] * 0.65, c[3] * 0.65, 1)
        end
    end)
    btn:SetScript("OnMouseUp", function(self)
        if self:IsEnabled() and self.baseColor then
            local c = self.baseColor
            self:SetBackdropColor(math.min(1, c[1] * 1.3), math.min(1, c[2] * 1.3), math.min(1, c[3] * 1.3), 1)
        end
    end)

    function btn:SetText(t)
        fs:SetText(t)
        local w = fs:GetStringWidth() + 26
        if w > self:GetWidth() then self:SetWidth(w) end
    end
    function btn:GetText() return fs:GetText() end

    local realDisable, realEnable = btn.Disable, btn.Enable
    function btn:Disable()
        realDisable(self)
        self:SetBackdropColor(BUTTON_DISABLED[1], BUTTON_DISABLED[2], BUTTON_DISABLED[3], 1)
        self:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)
        fs:SetTextColor(BUTTON_TEXT_DISABLED[1], BUTTON_TEXT_DISABLED[2], BUTTON_TEXT_DISABLED[3])
    end
    function btn:Enable()
        realEnable(self)
        if self.baseColor then
            Maines_SetButtonBaseColor(self, self.baseColor[1], self.baseColor[2], self.baseColor[3])
        end
        fs:SetTextColor(PLATE_TEXT[1], PLATE_TEXT[2], PLATE_TEXT[3])
    end

    return btn
end

-- Same button, with a small icon to its left - used for the tab row so tabs read as "image
-- buttons" instead of plain text.
local function Maines_MakeIconButton(parent, width, height, text, iconPath)
    local btn = Maines_MakeButton(parent, width, height, text)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(height - 6, height - 6)
    icon:SetTexture(iconPath)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:SetPoint("LEFT", 8, 0)
    btn.text:ClearAllPoints()
    btn.text:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    btn:SetWidth(math.max(width or 0, btn.text:GetStringWidth() + icon:GetWidth() + 18))
    return btn
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
    Maines_ApplyPaletteColor(r, g, b, hex, palette.name)
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
    Maines_Window:Show()
    if _G["PlayedMusic_DB"] ~= "played" then
        PlaySoundFile("Interface\\Addons\\Maines\\music\\maines_intro.mp3")
    end
    _G["PlayedMusic_DB"] = "played"
end

-- Shared hide logic for the main window - used by the close button, Escape, and the minimap
-- icon's toggle below, so there's one place that knows how "the window" gets hidden.
local function Maines_HideMainWindow()
    Maines_Window:Hide()
end

-- Minimap left-click: show/hide instead of only ever showing.
local function Maines_ToggleMainWindow()
    if Maines_Window:IsShown() then
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

-- A /mainchat filter only survives a reload if explicitly marked sticky (/mainchat sticky).
-- This is the actual fix for "my filter is silently excluding channels and I forgot I set it" -
-- the exact situation that turned out to be the whole story behind a recent "Maines is broken"
-- report. Called once from OnInitialize, so it only ever resets on a fresh load, never mid-session.
local function Maines_ResetChatFilterIfNotSticky()
    if Maines_ChatFilterSticky_DB then return end
    local filter = Maines_GetChatFilter()
    if #filter > 0 then
        print("|cFF00FF00Maines|r: chat filter ("..table.concat(filter, ", ")..
            ") reset on load - tagging all channels again. Run |cFFFFE4B5/mainchat sticky|r to keep a filter across reloads.")
        wipe(filter)
    end
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
        local mode = Maines_ChatFilterMode_DB or "include"
        if #filter == 0 then
            print("|cFF00FF00Maines|r: no filter set — tagging all channels")
        elseif mode == "exclude" then
            print("|cFF00FF00Maines|r: tagging every channel EXCEPT: "..table.concat(filter, ", ")..
                (Maines_ChatFilterSticky_DB and " |cFF888888(sticky)|r" or ""))
        else
            print("|cFF00FF00Maines|r: tagging ONLY: "..table.concat(filter, ", ")..
                (Maines_ChatFilterSticky_DB and " |cFF888888(sticky)|r" or ""))
        end
        return
    end

    -- /mainchat mode: whether the list above is a whitelist (tag ONLY these - the default,
    -- and the fix for any confusion about which way this goes) or a blacklist (tag everything
    -- EXCEPT these - handy for "just don't tag whispers" without listing every other channel).
    if msg:lower():match("^mode%s*$") then
        print("|cFF00FF00Maines|r: filter mode is |cFFFFE4B5"..(Maines_ChatFilterMode_DB or "include").."|r "..
            "(/mainchat mode include | /mainchat mode exclude)")
        return
    end
    local modeSet = msg:lower():match("^mode%s+(%a+)%s*$")
    if modeSet then
        if modeSet == "include" or modeSet == "exclude" then
            Maines_ChatFilterMode_DB = modeSet
            if modeSet == "include" then
                print("|cFF00FF00Maines|r: filter mode set to |cFFFFE4B5include|r - tagging ONLY the listed channels")
            else
                print("|cFF00FF00Maines|r: filter mode set to |cFFFFE4B5exclude|r - tagging every channel EXCEPT the listed ones")
            end
        else
            print("|cFF00FF00Maines|r: unknown mode \""..modeSet.."\" - use \"include\" or \"exclude\"")
        end
        return
    end

    -- By default a filter only lasts for the current session - see Maines_ResetChatFilterIfNotSticky
    -- below. This is the fix for the exact confusion that prompted it: a filter set once during
    -- testing and forgotten about would otherwise silently keep excluding channels forever.
    if msg:lower() == "sticky" then
        Maines_ChatFilterSticky_DB = not Maines_ChatFilterSticky_DB
        if Maines_ChatFilterSticky_DB then
            print("|cFF00FF00Maines|r: filter is now |cFFFFE4B5sticky|r - it'll survive reloads until you change it")
        else
            print("|cFF00FF00Maines|r: filter is |cFFFFE4B5no longer sticky|r - it'll reset to \"tag everything\" next reload")
        end
        return
    end

    -- Channel names are always uppercase (SAY, GUILD, ...), and this is the actual bug behind
    -- "/mainchat doesn't do anything": entries were never trimmed or case-normalized, so
    -- "SAY, GUILD" (a space after the comma - completely natural to type) silently produced
    -- " GUILD" with a leading space, which then never matched the real chatType "GUILD" again.
    local normalized = msg:upper()

    -- Split into comma-separated tokens up front - both the +/- path and the "replace the
    -- whole list" path need this. This is also the fix for a second, worse bug: "/mainchat
    -- -SAY,-YELL" (multiple ops in one command, which reads as completely natural syntax) used
    -- to fail the single-operation +/- pattern below, fall through to the "replace the whole
    -- list" branch, and get stored LITERALLY - "-SAY" and "-YELL", hyphens included - as if
    -- they were channel names. Those can never match a real chatType, so the filter silently
    -- became "match nothing", which tagged NOTHING, not even the channels the user wanted kept.
    -- Retyping "-SAY" alone afterwards then looked for an entry equal to "SAY" to remove, found
    -- "-SAY" instead (not an exact match), and silently did nothing - "typed it one by one, it
    -- wasn't added." Now: every comma-separated token is required to be either ALL +/- operations
    -- (edits an existing filter) or ALL plain channel names (replaces the filter) - never a
    -- silent, corrupting mix of the two.
    local tokens = {}
    for rawToken in normalized:gmatch("([^,]+)") do
        local token = strtrim(rawToken)
        if token ~= "" then table.insert(tokens, token) end
    end

    if #tokens == 0 then
        print("|cFF00FF00Maines|r: nothing to do - run /mainchat with no arguments to clear the filter")
        return
    end

    local opTokens, plainTokens = 0, 0
    for _, t in ipairs(tokens) do
        if t:match("^[%+%-]") then opTokens = opTokens + 1 else plainTokens = plainTokens + 1 end
    end

    if opTokens > 0 and plainTokens > 0 then
        print("|cFF00FF00Maines|r: can't mix +CHANNEL/-CHANNEL with plain channel names in one command")
        print("|cFF00FF00Maines|r: use \"/mainchat SAY,GUILD\" to set the whole list, or \"/mainchat +SAY,-GUILD\" to edit the existing one")
        return
    end

    if opTokens > 0 then
        local added, removed, bad = {}, {}, {}
        for _, t in ipairs(tokens) do
            local op, sel = t:match("^([%+%-])(%u[%u_]*)$")
            if not op then
                table.insert(bad, t)
            elseif op == "+" then
                local exists = false
                for _, v in ipairs(filter) do if v == sel then exists = true; break end end
                if not exists then table.insert(filter, sel) end
                table.insert(added, sel)
            else
                for i, v in ipairs(filter) do
                    if v == sel then table.remove(filter, i); table.insert(removed, sel); break end
                end
            end
        end
        if #added > 0 then print("|cFF00FF00Maines|r: added "..table.concat(added, ", ").." to filter") end
        if #removed > 0 then print("|cFF00FF00Maines|r: removed "..table.concat(removed, ", ").." from filter") end
        if #bad > 0 then print("|cFF00FF00Maines|r: ignored invalid entries: "..table.concat(bad, ", ")) end
        if #added == 0 and #removed == 0 and #bad == 0 then
            print("|cFF00FF00Maines|r: nothing changed")
        end
        return
    end

    wipe(filter)
    for _, token in ipairs(tokens) do table.insert(filter, token) end
    local mode = Maines_ChatFilterMode_DB or "include"
    if #filter == 0 then
        print("|cFF00FF00Maines|r: no valid channel names found - filter left empty, tagging all channels")
    elseif mode == "exclude" then
        print("|cFF00FF00Maines|r: tagging every channel EXCEPT: "..table.concat(filter, ", "))
    else
        print("|cFF00FF00Maines|r: tagging ONLY: "..table.concat(filter, ", "))
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
    local mode = _G["Maines_ChatFilterMode_DB"] or "include"
    local valid = false
    if filter and type(filter) == "table" and #filter > 0 then
        local inFilter = false
        for _, v in ipairs(filter) do if chatType == v then inFilter = true; break end end
        if mode == "exclude" then
            -- Blacklist: tag every recognized channel type except the ones listed - still
            -- gated on Channel_Types so an unrecognized chatType can't slip through untagged-check.
            local isKnownChannel = false
            for _, ctype in ipairs(Channel_Types) do if chatType == ctype then isKnownChannel = true; break end end
            valid = isKnownChannel and not inFilter
        else
            -- Whitelist (default): tag ONLY the listed channels.
            valid = inFilter
        end
        if Maines_Debug then print("|cFF00FF00Maines debug|r: using filter table, mode="..mode..", size="..#filter.." valid="..tostring(valid)) end
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
                desc = "Add or remove one or more channels without retyping the whole list.",
                example = "/mainchat -SAY,-YELL", note = "Comma-separate several +/- ops in one go. Can't mix these with plain channel names in the same command - that's rejected outright rather than guessed at."},
            {icon = "INV_Letter_15", cmd = "/mainchat", args = "mode include | exclude",
                desc = "Switch whether the list above means \"tag ONLY these\" (default) or \"tag everything EXCEPT these\".",
                example = "/mainchat mode exclude",
                note = "\"mode\" with no argument prints which one is active. include+exclude use the same list from above."},
            {icon = "INV_Letter_15", cmd = "/mainchat", args = "sticky",
                desc = "Toggle whether the current filter survives a reload.",
                example = "/mainchat sticky",
                note = "Off by default: any filter resets to \"tag everything\" on your next reload unless you turn this on. Also resettable instantly by middle-clicking the minimap icon."},
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
                example = "/mainmap", note = "The icon itself: left-click shows/hides Maines, right-click recolors it, middle-click resets the /mainchat filter."},
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
-- data as the chat version above. Chrome is the same art-free flat-backdrop + stock-icon
-- skeleton as the main window (see the GUI helpers above) rather than custom parchment art.
-- Content is a fixed-width column of FontStrings (one per section header, one per command)
-- chained top-to-bottom with GetStringHeight(), which is reliable even before the frame has
-- ever been shown - unlike GetTop()/GetBottom(), which can be unresolved on a frame that's
-- never been laid out yet.
local HELP_CONTENT_WIDTH = 430

local Help_Frame = CreateFrame("Frame", "Maines_Help_Frame", UIParent, "BackdropTemplate")
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
Maines_MakeFlatBackdrop(Help_Frame, WINDOW_BG, BORDER_DARK, 18)

Maines_MakeGear(Help_Frame, 26, true, 11, "Interface\\Icons\\Trade_Engineering"):SetPoint("TOPLEFT", 10, -8)
Maines_MakeGear(Help_Frame, 26, true, 13, "Interface\\Icons\\INV_Gizmo_03"):SetPoint("BOTTOMRIGHT", -10, 8)

Help_Frame.title = Help_Frame:CreateFontString(nil, "OVERLAY")
Help_Frame.title:SetFontObject(Maines_Font_Title)
Help_Frame.title:SetPoint("TOP", 0, -24)
Help_Frame.title:SetText("Maines — Command Reference")
Help_Frame.title:SetTextColor(0.30, 0.20, 0.08)

local helpClose = CreateFrame("Button", nil, Help_Frame, "UIPanelCloseButton")
helpClose:SetPoint("TOPRIGHT", -4, -4)
helpClose:SetScript("OnClick", function() Help_Frame:Hide() end)

local helpPanel = CreateFrame("Frame", nil, Help_Frame, "BackdropTemplate")
helpPanel:SetPoint("TOPLEFT", 26, -78)
helpPanel:SetPoint("BOTTOMRIGHT", -26, 22)
Maines_MakeFlatBackdrop(helpPanel, CONTENT_BG, BORDER_DARK, 14)

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

    -- Was a captured mockup graphic (mainhelp_example.tga); replaced with the same worked
    -- example as plain colored text so the panel needs no art at all.
    local exampleFS = helpContent:CreateFontString(nil, "OVERLAY")
    exampleFS:SetFontObject(Maines_Font_Body)
    exampleFS:SetPoint("TOPLEFT", 6, y)
    exampleFS:SetWidth(HELP_CONTENT_WIDTH - 12)
    exampleFS:SetJustifyH("LEFT")
    exampleFS:SetText("|cFF6B5F4DExample tagged message:|r  |cFF3A2A1E(Misamu)|r Hello there, guildies!")
    y = y - exampleFS:GetStringHeight() - 22

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
        -- Placeholder icon until the next art pass - a stock gizmo icon fits the
        -- gnomish/goblin-engineering theme without needing any custom art.
        icon = "Interface\\Icons\\INV_Gizmo_02",
        OnClick = function(_, button)
            if button == "LeftButton" then
                Maines_ToggleMainWindow()
            elseif button == "RightButton" then
                SlashCmdList["MAINCOLOR"]()
            elseif button == "MiddleButton" then
                SlashCmdList["MAINCHAT"]("")
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Maines")
            tooltip:AddLine("|cFFFFFFFFLeft-click|r to show/hide Maines")
            tooltip:AddLine("|cFFFFFFFFRight-click|r to recolor (/maincolor)")
            tooltip:AddLine("|cFFFFFFFFMiddle-click|r to reset the /mainchat filter")
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

    Maines_ResetChatFilterIfNotSticky()

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

-- ==========================================================================
-- Main window - GUI rewrite (placeholder skeleton, art-free "engineered paper")
-- ==========================================================================
-- Every slash command below still works exactly as documented - none of them were removed
-- or changed. This window is a second way to reach the exact same functionality: every widget
-- here just builds the same string a slash command would take and hands it to that command's
-- existing SlashCmdList handler (or, for simple booleans, flips the same saved variable the
-- command flips) so there is exactly one implementation of every piece of behavior, and the
-- GUI can never drift out of sync with what /main, /mainchat, etc. actually do.
--
-- Visually this is a deliberate placeholder: Blizzard's own dialog-box paper/border art,
-- gnomish/goblin-brass buttons, a few spinning gear icons, and a custom font pairing standing
-- in for real hand-painted artwork, which is the next pass. No custom texture FILES are
-- referenced anywhere below - only Blizzard's built-in templates, icons, fonts, and stock
-- textures - so the skeleton doesn't depend on anything sitting in img/old/. Every piece of
-- chrome (window/panel/button borders, gear icons) is registered with /maincolor; the actual
-- reading text stays a fixed ink color on purpose, so recoloring never produces unreadable
-- bright-on-bright text.

Maines_Window = CreateFrame("Frame", "Maines_Frame", UIParent, "BackdropTemplate")
Maines_Window:SetSize(480, 700)
Maines_Window:SetPoint("CENTER")
Maines_Window:SetFrameStrata("DIALOG")
Maines_Window:SetMovable(true)
Maines_Window:EnableMouse(true)
Maines_Window:RegisterForDrag("LeftButton")
Maines_Window:SetScript("OnDragStart", Maines_Window.StartMoving)
Maines_Window:SetScript("OnDragStop", Maines_Window.StopMovingOrSizing)
Maines_Window:SetPropagateKeyboardInput(true)
Maines_Window:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then Maines_HideMainWindow() end
end)
Maines_Window:Hide()
Maines_MakeFlatBackdrop(Maines_Window, WINDOW_BG, BORDER_DARK, 20)

-- Corner "engineering" accents - three different stock icons (not just one repeated) for a
-- bit of image variety, each slowly spinning like idle machinery.
Maines_MakeGear(Maines_Window, 30, true, 10, "Interface\\Icons\\Trade_Engineering"):SetPoint("TOPLEFT", 14, -12)
Maines_MakeGear(Maines_Window, 22, true, 14, "Interface\\Icons\\INV_Gizmo_02"):SetPoint("BOTTOMLEFT", 14, 12)
Maines_MakeGear(Maines_Window, 22, true, 15, "Interface\\Icons\\INV_Gizmo_01"):SetPoint("BOTTOMRIGHT", -14, 12)

local windowTitle = Maines_Window:CreateFontString(nil, "OVERLAY")
windowTitle:SetFontObject(Maines_Font_Title)
windowTitle:SetPoint("TOP", 0, -12)
windowTitle:SetText("MAINES")
windowTitle:SetTextColor(INK[1], INK[2], INK[3])

-- Small gnomish/goblin race-flavor badges flanking the title - purely decorative, and left
-- unregistered so they always show their true race colors regardless of /maincolor.
Maines_MakeBadge(Maines_Window, 20, "Interface\\Icons\\Achievement_Character_Gnome_Male"):SetPoint("RIGHT", windowTitle, "LEFT", -10, 0)
Maines_MakeBadge(Maines_Window, 20, "Interface\\Icons\\Achievement_Character_Goblin_Male"):SetPoint("LEFT", windowTitle, "RIGHT", 10, 0)

-- An engraved-looking dark nameplate under the title - the one bit of decorative text that IS
-- recolored by /maincolor, safe to do because it sits on a fixed dark plate (light accent text
-- on a dark plate stays readable across every palette, unlike text on the pale parchment).
local titlePlate = CreateFrame("Frame", nil, Maines_Window, "BackdropTemplate")
titlePlate:SetSize(360, 20)
titlePlate:SetPoint("TOP", windowTitle, "BOTTOM", 0, -4)
Maines_MakeSlab(titlePlate, PLATE_BG, BORDER_DARK, 1)

local windowSubtitle = titlePlate:CreateFontString(nil, "OVERLAY")
windowSubtitle:SetFontObject(Maines_Font_BodySmall)
windowSubtitle:SetPoint("CENTER")
windowSubtitle:SetText("gnomish/goblin-engineered chat tagger")
windowSubtitle:SetTextColor(0.80, 0.62, 0.30)
Maines_RegisterFontColor(windowSubtitle)

local windowClose = CreateFrame("Button", nil, Maines_Window, "UIPanelCloseButton")
windowClose:SetPoint("TOPRIGHT", -4, -4)
windowClose:SetScript("OnClick", function() Maines_HideMainWindow() end)

-- Tabs: one per functional area, each with its own icon so they read as image buttons rather
-- than plain text. Every icon here is one already proven safe elsewhere in this file (the
-- /mainhelp reference uses the same set). Each tab shows/hides its own panel; the active tab
-- is shown disabled (dimmed) purely as a zero-art "you are here" indicator.
local TAB_DEFS = {
    {key = "main", label = "Main", icon = "Interface\\Icons\\INV_Misc_Note_01"},
    {key = "filter", label = "Filter", icon = "Interface\\Icons\\INV_Letter_15"},
    {key = "behavior", label = "Behavior", icon = "Interface\\Icons\\INV_Misc_QuestionMark"},
    {key = "cosmetic", label = "Cosmetic", icon = "Interface\\Icons\\INV_Misc_Dice_01"},
    {key = "help", label = "Help", icon = "Interface\\Icons\\INV_Misc_Gear_08"},
}

local tabRow = CreateFrame("Frame", nil, Maines_Window)
tabRow:SetPoint("TOPLEFT", 16, -78)
tabRow:SetSize(448, 26)

local contentFrame = CreateFrame("Frame", nil, Maines_Window, "BackdropTemplate")
contentFrame:SetPoint("TOPLEFT", 16, -110)
contentFrame:SetPoint("BOTTOMRIGHT", -16, 100)
Maines_MakeFlatBackdrop(contentFrame, CONTENT_BG, BORDER_DARK, 16)

local Maines_Panels, Maines_Tabs = {}, {}

local function Maines_ShowPanel(key)
    for k, panel in pairs(Maines_Panels) do
        if k == key then panel:Show() else panel:Hide() end
    end
    for k, btn in pairs(Maines_Tabs) do
        if k == key then btn:Disable() else btn:Enable() end
    end
end

-- Every tab is sized to fit its OWN label first, then all five are widened to match the
-- widest one and centered as a block - keeps the row an even grid without guessing a fixed
-- pixel width that might clip a longer label under a different font.
local TAB_GAP = 4
local tabButtons = {}
for i, def in ipairs(TAB_DEFS) do
    local btn = Maines_MakeIconButton(tabRow, 0, 26, def.label, def.icon)
    btn:SetScript("OnClick", function() Maines_ShowPanel(def.key) end)
    Maines_Tabs[def.key] = btn
    tabButtons[i] = btn

    local panel = CreateFrame("Frame", nil, contentFrame)
    panel:SetPoint("TOPLEFT", 14, -14)
    panel:SetPoint("BOTTOMRIGHT", -14, 14)
    panel:Hide()
    Maines_Panels[def.key] = panel
end

local tabWidth = 0
for _, btn in ipairs(tabButtons) do
    tabWidth = math.max(tabWidth, btn:GetWidth())
end
local tabsTotalWidth = tabWidth * #tabButtons + TAB_GAP * (#tabButtons - 1)
local tabStartX = (tabRow:GetWidth() - tabsTotalWidth) / 2
for i, btn in ipairs(tabButtons) do
    btn:SetWidth(tabWidth)
    btn:ClearAllPoints()
    btn:SetPoint("LEFT", tabStartX + (i - 1) * (tabWidth + TAB_GAP), 0)
end

-- The small riveted "manufacturer's plate" - always visible regardless of active tab.
-- Three deliberate, explicitly-chosen lines rather than one long sentence left to Blizzard's
-- auto-wrap - the auto-wrapped version broke at an arbitrary point and left one word stranded
-- on its own line.
local creditsPlate = CreateFrame("Frame", nil, Maines_Window, "BackdropTemplate")
creditsPlate:SetSize(420, 64)
creditsPlate:SetPoint("BOTTOM", 0, 28)
Maines_MakeSlab(creditsPlate, PLATE_BG, BORDER_DARK, 2)

Maines_MakeBadge(creditsPlate, 16, "Interface\\Icons\\INV_Misc_Gear_08"):SetPoint("LEFT", 8, 0)
Maines_MakeBadge(creditsPlate, 16, "Interface\\Icons\\INV_Misc_Gear_08"):SetPoint("RIGHT", -8, 0)

local creditsLine1 = creditsPlate:CreateFontString(nil, "OVERLAY")
creditsLine1:SetFontObject(Maines_Font_BodySmall)
creditsLine1:SetPoint("TOP", 0, -8)
creditsLine1:SetJustifyH("CENTER")
creditsLine1:SetText("Designed by Dominic Hughes / Tuniveza")
creditsLine1:SetTextColor(0.90, 0.86, 0.76)

local creditsLine2 = creditsPlate:CreateFontString(nil, "OVERLAY")
creditsLine2:SetFontObject(Maines_Font_BodySmall)
creditsLine2:SetPoint("TOP", creditsLine1, "BOTTOM", 0, -3)
creditsLine2:SetJustifyH("CENTER")
creditsLine2:SetText("Silvermoon EU - Universe of Warcraft")
creditsLine2:SetTextColor(0.90, 0.86, 0.76)

local creditsLine3 = creditsPlate:CreateFontString(nil, "OVERLAY")
creditsLine3:SetFontObject(Maines_Font_BodySmall)
creditsLine3:SetPoint("TOP", creditsLine2, "BOTTOM", 0, -8)
creditsLine3:SetJustifyH("CENTER")
creditsLine3:SetText("Coded and Guided by Generative Assistance")
creditsLine3:SetTextColor(0.72, 0.68, 0.60)

-- The Mosaic Stamp footer: previously used a "▦" character that several UI fonts simply have
-- no glyph for, so it rendered as nothing, then a placeholder gear icon that didn't actually
-- look like a mosaic at all. Fixed properly this time: a real 4-tile checkerboard badge (see
-- Maines_MakeMosaicBadge above) instead of either.
local footerBadge = Maines_MakeMosaicBadge(Maines_Window, 14)
footerBadge:SetPoint("CENTER", Maines_Window, "BOTTOM", 0, 20)
local footer = Maines_Window:CreateFontString(nil, "OVERLAY")
footer:SetFontObject(Maines_Font_BodySmall)
footer:SetPoint("TOP", footerBadge, "BOTTOM", 0, -2)
footer:SetJustifyH("CENTER")
footer:SetText("The Mosaic Stamp")
footer:SetTextColor(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3])

-- ---- Main panel: name + bracket (mirrors /mains and /main) ----
local mainPanel = Maines_Panels.main
local my = -6

local nameLabel = mainPanel:CreateFontString(nil, "OVERLAY")
nameLabel:SetFontObject(Maines_Font_Header)
nameLabel:SetPoint("TOP", 0, my)
nameLabel:SetWidth(420)
nameLabel:SetJustifyH("CENTER")
nameLabel:SetText("Main character name:")
nameLabel:SetTextColor(INK[1], INK[2], INK[3])
my = my - nameLabel:GetStringHeight() - 6

local nameBox = CreateFrame("EditBox", nil, mainPanel, "InputBoxTemplate")
nameBox:SetSize(220, 20)
nameBox:SetAutoFocus(false)
nameBox:SetMaxLetters(24)
nameBox:SetPoint("TOP", 0, my)
my = my - 30

local bracketLabel = mainPanel:CreateFontString(nil, "OVERLAY")
bracketLabel:SetFontObject(Maines_Font_Header)
bracketLabel:SetPoint("TOP", 0, my)
bracketLabel:SetWidth(420)
bracketLabel:SetJustifyH("CENTER")
bracketLabel:SetText("Bracket style - click one to apply it instantly, or select one and use Apply below:")
bracketLabel:SetTextColor(INK[1], INK[2], INK[3])
my = my - bracketLabel:GetStringHeight() - 8

local Bracket_Order = {"[", "(", "<", "{", ".", ":", "-", "~", "@", "#"}
local BRACKET_AREA_WIDTH = 400
local Maines_BracketButtons = {}
local Maines_SelectedBracketKey
local bracketRowTop = my

-- Forward-declared (assigned once every widget below exists) so the OnClick/OnTextChanged
-- closures created below can already reference it as an upvalue - the same pattern
-- Maines_Window itself uses earlier in this file.
local Maines_LayoutMainPanel
local customLeft, customRight

for _, key in ipairs(Bracket_Order) do
    local def = Bracket_Types[key]
    local btn = Maines_MakeButton(mainPanel, 70, 24, def[1] .. "M" .. def[2])
    btn:SetScript("OnClick", function()
        local nm = strtrim(nameBox:GetText() or "")
        if nm == "" then
            print("|cFF00FF00Maines|r: type a name first")
            return
        end
        Maines_SelectedBracketKey = key
        SlashCmdList["MAINS"](nm .. " " .. key)
        Maines_RefreshWindow()
    end)
    Maines_BracketButtons[key] = btn
end

local applyBtn = Maines_MakeButton(mainPanel, 100, 24, "Apply")
applyBtn:SetScript("OnClick", function()
    local nm = strtrim(nameBox:GetText() or "")
    if nm == "" then
        print("|cFF00FF00Maines|r: type a name first")
        return
    end
    local l = strtrim(customLeft:GetText() or "")
    local r = strtrim(customRight:GetText() or "")
    if l ~= "" then
        if r ~= "" then
            SlashCmdList["MAINS"](nm .. " " .. l .. " " .. r)
        else
            SlashCmdList["MAINS"](nm .. " " .. l)
        end
    elseif Maines_SelectedBracketKey then
        SlashCmdList["MAINS"](nm .. " " .. Maines_SelectedBracketKey)
    else
        print("|cFF00FF00Maines|r: pick a bracket above, or enter a custom symbol below, first")
        return
    end
    Maines_RefreshWindow()
end)

local customLabel = mainPanel:CreateFontString(nil, "OVERLAY")
customLabel:SetFontObject(Maines_Font_Header)
customLabel:SetWidth(420)
customLabel:SetJustifyH("CENTER")
customLabel:SetText("Custom bracket (left symbol, optional right symbol):")
customLabel:SetTextColor(INK[1], INK[2], INK[3])

customLeft = CreateFrame("EditBox", nil, mainPanel, "InputBoxTemplate")
customLeft:SetSize(50, 20)
customLeft:SetAutoFocus(false)
-- Centered as a unit with customRight (combined width 50 + 20 gap + 50 = 120), not left-hung.
local CUSTOM_PAIR_WIDTH = 120

customRight = CreateFrame("EditBox", nil, mainPanel, "InputBoxTemplate")
customRight:SetSize(50, 20)
customRight:SetAutoFocus(false)
customRight:SetPoint("LEFT", customLeft, "RIGHT", 20, 0)

local previewLabel = mainPanel:CreateFontString(nil, "OVERLAY")
previewLabel:SetFontObject(Maines_Font_Header)
previewLabel:SetWidth(420)
previewLabel:SetJustifyH("CENTER")
previewLabel:SetText("Currently saved - this is what your chat will look like:")
previewLabel:SetTextColor(INK[1], INK[2], INK[3])

local previewFS = mainPanel:CreateFontString(nil, "OVERLAY")
previewFS:SetFontObject(Maines_Font_Body)
previewFS:SetWidth(420)
previewFS:SetJustifyH("CENTER")

-- Lays out everything from the bracket grid downward: bracket buttons live-update to show
-- <left><current name><right> and reflow into as many rows as needed once names get long, and
-- everything below the grid slides to follow it. Every row (the bracket grid, one row per
-- wrap; the Apply button; the custom bracket pair) is centered as a block on the panel's
-- horizontal middle via SetPoint("TOP", xOffset, ...) rather than hung off the left edge.
Maines_LayoutMainPanel = function()
    local name = strtrim(nameBox:GetText() or "")
    local previewName = name ~= "" and name or "Name"

    -- Pass 1: which row each button lands in, and how wide it needs to be.
    local rows = {{}}
    local x, row = 0, 1
    for _, key in ipairs(Bracket_Order) do
        local def = Bracket_Types[key]
        local btn = Maines_BracketButtons[key]
        btn:SetText(def[1] .. previewName .. def[2])
        local w = math.max(44, math.min(190, btn.text:GetStringWidth() + 20))
        if x > 0 and x + w > BRACKET_AREA_WIDTH then
            x, row = 0, row + 1
            rows[row] = {}
        end
        table.insert(rows[row], {btn = btn, w = w})
        x = x + w + 6
    end

    -- Pass 2: center each row independently, since a short last row (e.g. one leftover
    -- button) shouldn't be stranded at the left edge under a wider row above it.
    for rowIndex, items in ipairs(rows) do
        local rowWidth = -6
        for _, item in ipairs(items) do rowWidth = rowWidth + item.w + 6 end
        local cx = -rowWidth / 2
        for _, item in ipairs(items) do
            item.btn:SetSize(item.w, 24)
            item.btn:ClearAllPoints()
            item.btn:SetPoint("TOP", cx + item.w / 2, bracketRowTop - (rowIndex - 1) * 28)
            cx = cx + item.w + 6
        end
    end
    local afterBrackets = bracketRowTop - #rows * 28 - 8

    applyBtn:ClearAllPoints()
    applyBtn:SetPoint("TOP", 0, afterBrackets)
    afterBrackets = afterBrackets - 34

    customLabel:ClearAllPoints()
    customLabel:SetPoint("TOP", 0, afterBrackets)
    afterBrackets = afterBrackets - customLabel:GetStringHeight() - 6

    customLeft:ClearAllPoints()
    customLeft:SetPoint("TOP", -(CUSTOM_PAIR_WIDTH / 2) + 25, afterBrackets)
    afterBrackets = afterBrackets - 32

    previewLabel:ClearAllPoints()
    previewLabel:SetPoint("TOP", 0, afterBrackets)
    afterBrackets = afterBrackets - previewLabel:GetStringHeight() - 6

    previewFS:ClearAllPoints()
    previewFS:SetPoint("TOP", 0, afterBrackets)
end

nameBox:SetScript("OnTextChanged", function() Maines_LayoutMainPanel() end)
Maines_LayoutMainPanel()

-- ---- Filter panel: channels + mode + sticky (mirrors /mainchat) ----
local filterPanel = Maines_Panels.filter
local fy = -6

local filterIntro = filterPanel:CreateFontString(nil, "OVERLAY")
filterIntro:SetFontObject(Maines_Font_Body)
filterIntro:SetPoint("TOP", 0, fy)
filterIntro:SetWidth(420)
filterIntro:SetJustifyH("CENTER")
filterIntro:SetText("|cFF4A4030Check the channels you care about, then pick a mode below. Leave everything unchecked to tag every channel.|r")
fy = fy - filterIntro:GetStringHeight() - 10

local Channel_Labels = {
    SAY = "Say", YELL = "Yell", EMOTE = "Emote", PARTY = "Party", PARTY_LEADER = "Party (Leader)",
    RAID = "Raid", RAID_LEADER = "Raid (Leader)", RAID_WARNING = "Raid Warning",
    INSTANCE_CHAT = "Instance", INSTANCE_CHAT_LEADER = "Instance (Leader)",
    GUILD = "Guild", OFFICER = "Officer", WHISPER = "Whisper", BN_WHISPER = "Battle.net Whisper",
    CHANNEL = "Custom Channel", COMMUNITIES_CHANNEL = "Community", VOICE_TEXT = "Voice Text",
    AFK = "AFK", DND = "DND",
}

local Maines_ChannelChecks = {}
local CHAN_COLS = 2
local CHAN_COL_WIDTH = 210
local chanRowTop = fy
for i, chan in ipairs(Channel_Types) do
    local col = (i - 1) % CHAN_COLS
    local row = math.floor((i - 1) / CHAN_COLS)
    local cb = CreateFrame("CheckButton", nil, filterPanel, "UICheckButtonTemplate")
    cb:SetSize(22, 22)
    cb:SetPoint("TOPLEFT", 6 + col * CHAN_COL_WIDTH, chanRowTop - row * 24)
    local lbl = filterPanel:CreateFontString(nil, "OVERLAY")
    lbl:SetFontObject(Maines_Font_Body)
    lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    lbl:SetText(Channel_Labels[chan] or chan)
    lbl:SetTextColor(INK[1], INK[2], INK[3])
    cb:SetScript("OnClick", function(self)
        SlashCmdList["MAINCHAT"]((self:GetChecked() and "+" or "-") .. chan)
        Maines_RefreshWindow()
    end)
    Maines_ChannelChecks[chan] = cb
end
fy = chanRowTop - math.ceil(#Channel_Types / CHAN_COLS) * 24 - 10

-- Rows below are centered as a block (label/checkbox + control together), computed AFTER the
-- buttons exist so it accounts for their real auto-sized widths, not a guess.
local modeLabel = filterPanel:CreateFontString(nil, "OVERLAY")
modeLabel:SetFontObject(Maines_Font_Header)
modeLabel:SetText("Filter mode:")
modeLabel:SetTextColor(INK[1], INK[2], INK[3])

local modeIncludeBtn = Maines_MakeButton(filterPanel, 0, 24, "Only checked")
modeIncludeBtn:SetPoint("LEFT", modeLabel, "RIGHT", 10, 0)
modeIncludeBtn:SetScript("OnClick", function() SlashCmdList["MAINCHAT"]("mode include"); Maines_RefreshWindow() end)

local modeExcludeBtn = Maines_MakeButton(filterPanel, 0, 24, "All except checked")
modeExcludeBtn:SetPoint("LEFT", modeIncludeBtn, "RIGHT", 6, 0)
modeExcludeBtn:SetScript("OnClick", function() SlashCmdList["MAINCHAT"]("mode exclude"); Maines_RefreshWindow() end)

local modeRowWidth = modeLabel:GetStringWidth() + 10 + modeIncludeBtn:GetWidth() + 6 + modeExcludeBtn:GetWidth()
modeLabel:SetPoint("TOP", -modeRowWidth / 2 + modeLabel:GetStringWidth() / 2, fy)
fy = fy - 32

local stickyCheck = CreateFrame("CheckButton", nil, filterPanel, "UICheckButtonTemplate")
stickyCheck:SetSize(22, 22)
local stickyLbl = filterPanel:CreateFontString(nil, "OVERLAY")
stickyLbl:SetFontObject(Maines_Font_Body)
stickyLbl:SetPoint("LEFT", stickyCheck, "RIGHT", 2, 0)
stickyLbl:SetText("Keep this filter across reloads (sticky)")
stickyLbl:SetTextColor(INK[1], INK[2], INK[3])
local stickyRowWidth = 22 + 2 + stickyLbl:GetStringWidth()
stickyCheck:SetPoint("TOP", -stickyRowWidth / 2 + 11, fy)
stickyCheck:SetScript("OnClick", function() SlashCmdList["MAINCHAT"]("sticky"); Maines_RefreshWindow() end)
fy = fy - 30

local clearFilterBtn = Maines_MakeButton(filterPanel, 0, 24, "Clear Filter (Tag All)")
clearFilterBtn:SetPoint("TOP", 0, fy)
clearFilterBtn:SetScript("OnClick", function() SlashCmdList["MAINCHAT"](""); Maines_RefreshWindow() end)
fy = fy - 32

local filterStatus = filterPanel:CreateFontString(nil, "OVERLAY")
filterStatus:SetFontObject(Maines_Font_Body)
filterStatus:SetPoint("TOP", 0, fy)
filterStatus:SetWidth(420)
filterStatus:SetJustifyH("CENTER")

-- ---- Behavior panel: on-main detection + debug (mirrors /mainhide, /mainshow, /maindebug) ----
local behaviorPanel = Maines_Panels.behavior
local by = -10

local hideOnMainCheck = CreateFrame("CheckButton", nil, behaviorPanel, "UICheckButtonTemplate")
hideOnMainCheck:SetSize(22, 22)
local hideOnMainLbl = behaviorPanel:CreateFontString(nil, "OVERLAY")
hideOnMainLbl:SetFontObject(Maines_Font_Body)
hideOnMainLbl:SetPoint("LEFT", hideOnMainCheck, "RIGHT", 2, 0)
hideOnMainLbl:SetText("Hide the tag while playing my main (alts are always tagged)")
hideOnMainLbl:SetTextColor(INK[1], INK[2], INK[3])
local hideOnMainRowWidth = 22 + 2 + hideOnMainLbl:GetStringWidth()
hideOnMainCheck:SetPoint("TOP", -hideOnMainRowWidth / 2 + 11, by)
hideOnMainCheck:SetScript("OnClick", function(self)
    if self:GetChecked() then SlashCmdList["MAINHIDE"]() else SlashCmdList["MAINSHOW"]() end
    Maines_RefreshWindow()
end)
by = by - 34

local debugCheck = CreateFrame("CheckButton", nil, behaviorPanel, "UICheckButtonTemplate")
debugCheck:SetSize(22, 22)
local debugLbl = behaviorPanel:CreateFontString(nil, "OVERLAY")
debugLbl:SetFontObject(Maines_Font_Body)
debugLbl:SetPoint("LEFT", debugCheck, "RIGHT", 2, 0)
debugLbl:SetText("Print debug info for every tagging decision")
debugLbl:SetTextColor(INK[1], INK[2], INK[3])
local debugRowWidth = 22 + 2 + debugLbl:GetStringWidth()
debugCheck:SetPoint("TOP", -debugRowWidth / 2 + 11, by)
debugCheck:SetScript("OnClick", function() SlashCmdList["MAINDEBUG"](); Maines_RefreshWindow() end)

-- ---- Cosmetic panel: minimap + music + colors (mirrors /mainmap, /mainmusic, /maincolor) ----
local cosmeticPanel = Maines_Panels.cosmetic
local cy = -6

local minimapCheck = CreateFrame("CheckButton", nil, cosmeticPanel, "UICheckButtonTemplate")
minimapCheck:SetSize(22, 22)
local minimapLbl = cosmeticPanel:CreateFontString(nil, "OVERLAY")
minimapLbl:SetFontObject(Maines_Font_Body)
minimapLbl:SetPoint("LEFT", minimapCheck, "RIGHT", 2, 0)
minimapLbl:SetText("Show minimap icon")
minimapLbl:SetTextColor(INK[1], INK[2], INK[3])
local minimapRowWidth = 22 + 2 + minimapLbl:GetStringWidth()
minimapCheck:SetPoint("TOP", -minimapRowWidth / 2 + 11, cy)
minimapCheck:SetScript("OnClick", function() SlashCmdList["MAINMAP"](); Maines_RefreshWindow() end)
cy = cy - 32

local musicBtn = Maines_MakeButton(cosmeticPanel, 0, 24, "Replay Intro Music")
musicBtn:SetPoint("TOP", 0, cy)
musicBtn:SetScript("OnClick", function()
    SlashCmdList["MAINMUSIC"]()
    PlaySoundFile("Interface\\Addons\\Maines\\music\\maines_intro.mp3")
end)
cy = cy - 36

local paletteLabel = cosmeticPanel:CreateFontString(nil, "OVERLAY")
paletteLabel:SetFontObject(Maines_Font_Header)
paletteLabel:SetPoint("TOP", 0, cy)
paletteLabel:SetWidth(420)
paletteLabel:SetJustifyH("CENTER")
paletteLabel:SetText("Recolor the UI - click a swatch, or roll one at random:")
paletteLabel:SetTextColor(INK[1], INK[2], INK[3])
cy = cy - paletteLabel:GetStringHeight() - 8

-- Each row is label (fixed 150px box, so the swatch columns stay aligned row to row) + 5
-- swatches (20px + 4px gap each = 116px) = 270px total, centered as one constant-width block.
local PALETTE_ROW_OFFSET = -60
for _, palette in ipairs(Color_Palettes) do
    local rowLbl = cosmeticPanel:CreateFontString(nil, "OVERLAY")
    rowLbl:SetFontObject(Maines_Font_BodySmall)
    rowLbl:SetPoint("TOP", PALETTE_ROW_OFFSET, cy)
    rowLbl:SetWidth(150)
    rowLbl:SetJustifyH("LEFT")
    rowLbl:SetText(palette.name)
    rowLbl:SetTextColor(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3])
    for j, hex in ipairs(palette.colors) do
        local r, g, b = Maines_HexToRGB(hex)
        local sw = Maines_MakeSwatch(cosmeticPanel, r, g, b)
        sw:SetSize(20, 20)
        sw:SetPoint("LEFT", rowLbl, "RIGHT", 4 + (j - 1) * 24, 0)
        sw:SetScript("OnClick", function() Maines_ApplyPaletteColor(r, g, b, hex, palette.name) end)
        sw:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("#" .. hex)
            GameTooltip:Show()
        end)
        sw:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    cy = cy - 26
end
cy = cy - 6

local randomBtn = Maines_MakeButton(cosmeticPanel, 0, 24, "Random Palette")
randomBtn:SetPoint("TOP", 0, cy)
randomBtn:SetScript("OnClick", function() SlashCmdList["MAINCOLOR"]() end)

-- ---- Help panel: points at the full reference window/chat dump (mirrors /mainhelp) ----
local helpTabPanel = Maines_Panels.help
local hy = -6

local helpIntro = helpTabPanel:CreateFontString(nil, "OVERLAY")
helpIntro:SetFontObject(Maines_Font_Body)
helpIntro:SetPoint("TOP", 0, hy)
helpIntro:SetWidth(420)
helpIntro:SetJustifyH("CENTER")
helpIntro:SetText("|cFF4A4030Every command above now has a tab here. For the full written reference - icons, examples, and notes - open the dedicated help window, or print the same thing to chat.|r")
hy = hy - helpIntro:GetStringHeight() - 14

local openHelpBtn = Maines_MakeButton(helpTabPanel, 0, 24, "Open Full Command Reference")
openHelpBtn:SetPoint("TOP", 0, hy)
openHelpBtn:SetScript("OnClick", function()
    Maines_BuildHelpContent()
    Help_Frame:Show()
end)
hy = hy - 32

local printHelpBtn = Maines_MakeButton(helpTabPanel, 0, 24, "Print Reference to Chat")
printHelpBtn:SetPoint("TOP", 0, hy)
printHelpBtn:SetScript("OnClick", function() Maines_PrintHelpToChat() end)

Maines_ShowPanel("main")

-- Pulls every saved variable the slash commands above already read/write and reflects it
-- into the widgets built above. Deliberately a plain global (not local) - several OnClick
-- handlers above reference it as a forward reference, the same pattern the rest of this file
-- already relies on (see maines_close_button historically, Maines_Window now).
function Maines_RefreshWindow()
    local name = _G["Maines_Name_DB"] or ""
    local left = _G["Maines_Bracket_Left_DB"] or ""
    local right = _G["Maines_Bracket_Right_DB"] or ""
    nameBox:SetText(name)
    Maines_LayoutMainPanel()

    Maines_SelectedBracketKey = nil
    for key, btn in pairs(Maines_BracketButtons) do
        local def = Bracket_Types[key]
        if left ~= "" and def[1] == left and def[2] == right then
            btn:Disable()
            Maines_SelectedBracketKey = key
        else
            btn:Enable()
        end
    end

    if name ~= "" and left ~= "" then
        previewFS:SetText("|cFF3A2A1E" .. left .. name .. right .. "|r |cFF6B5233Hello there, guildies!|r")
    else
        previewFS:SetText("|cFF6B5233(not set yet - pick a name and bracket above)|r")
    end

    local filter = Maines_GetChatFilter()
    local mode = Maines_ChatFilterMode_DB or "include"
    for _, chan in ipairs(Channel_Types) do
        local checked = false
        for _, v in ipairs(filter) do if v == chan then checked = true; break end end
        Maines_ChannelChecks[chan]:SetChecked(checked)
    end
    if mode == "exclude" then
        modeExcludeBtn:Disable(); modeIncludeBtn:Enable()
    else
        modeIncludeBtn:Disable(); modeExcludeBtn:Enable()
    end
    stickyCheck:SetChecked(Maines_ChatFilterSticky_DB and true or false)
    if #filter == 0 then
        filterStatus:SetText("|cFF4A4030Currently: tagging every channel (no filter set).|r")
    elseif mode == "exclude" then
        filterStatus:SetText("|cFF4A4030Currently: tagging every channel EXCEPT " .. table.concat(filter, ", ") .. ".|r")
    else
        filterStatus:SetText("|cFF4A4030Currently: tagging ONLY " .. table.concat(filter, ", ") .. ".|r")
    end

    hideOnMainCheck:SetChecked(Maines_HideOnMain_DB and true or false)
    debugCheck:SetChecked(Maines_Debug and true or false)

    local mmHidden = Maines_DB and Maines_DB.minimap and Maines_DB.minimap.hide
    minimapCheck:SetChecked(not mmHidden)
end

Maines_Window:SetScript("OnShow", Maines_RefreshWindow)
