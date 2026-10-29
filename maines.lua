--[[ 

    ADDON NAME: Maines

    DESCRIPTION: Take your main name to the chat frame then gtfo

    ADDON_AUTHOR: Dominic Hughes / Zuniversa / Tuniveza - EU - Universe of Warcraft - Silvermoon

    NOTES: Was so tired of seeing other addons not be customizable and up to scratch; then made this!

    STAMP: GLYPH

    WHAT IS STAMP and GLYPH?
    getting bored of the version ; alpha, beta, release so changed it to stamps ;)
    you can decide; where it's at in development... by using it.


    
    ------------------
    PRESENT FEATURES;
    ------------------

    [main] slash commands
    /main - to see your mainname and brackets type
    /mains  [/mains mainname leftbracketype]
    /mains  [/mains mainname symbol]            -- one custom symbol used for BOTH brackets, e.g. /mains Tuniveza *  ->  *Tuniveza*
    /mains  [/mains mainname left right]        -- independent left/right symbol sequences, e.g. /mains Tuniveza << >>  ->  <<Tuniveza>>
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
      uses). The font loader falls back to Blizzard's FRIZQT__ if the file is ever
      missing so a corrupted install degrades instead of erroring. (Agave was later replaced
      by thicker faces per role - New Rocker, Vollkorn SC, Fira Sans, Bree Serif - see the
      font objects below.)
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
    "(Tuniveza) hello" while you WERE Tuniveza. Maines now compares the logged-in
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

-- Shared with the feature files loaded after this one (phrases.lua, animate.lua, badges.lua -
-- see maines.xml). WoW hands every file of an addon the same private table as its second
-- vararg, so this is how they reach the GUI helpers and panels built below without globals.
local _, ns = ...
ns.RefreshHooks = {}

-- Every message Maines prints for the player goes through ns.Say: it is printed to chat exactly
-- as before, and the latest one is also shown on the window's status line (built further
-- down, which sets ns.OnStatus). ns.Status shows a line in the window without printing it, for
-- replies that print as several chat lines (/mains). Only Maines' own messages pass through
-- here - other add-ons' prints are never captured.
-- `status` (optional) is what the window shows instead of the chat text: a table
-- {kind = "ok" | "warn" | "error" | nil, parts = {{label = , value = , symbol = }, ...}} that the
-- status line lays out with even separators, or a kind string for the chat text itself.
function ns.Status(text, kind)
    ns.lastStatus, ns.lastStatusKind = text, kind
    if ns.OnStatus then ns.OnStatus(text, kind) end
end
function ns.Say(text, status)
    print(text)
    if type(status) == "table" then ns.Status(status) else ns.Status(text, status) end
end

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
Maines_Name = ""
Maines_Chat_Options = {}
_G["PlayedMusic_DB"] = "noplayed"

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
-- is a {name = ..., colors = {hex, hex, ...}, surface = key} table; the command rolls a random
-- palette, then a random color from within it. `surface` names the palette's own paper and band
-- textures (textures/palettes/<key>.tga and <key>_band.tga, from tools/make_textures.py), which
-- replace the start look's grain and brushed overlays while that palette is active. The Cosmetic tab also lets you pick an exact swatch instead
-- of rolling randomly.
local Color_Palettes = {
    {name = "The Starry Night (Van Gogh, 1889)", colors = {"1B3B6F", "2E5A87", "0B1F3A", "F3D250", "F7E7A0"}, surface = "starry"},
    {name = "The Great Wave off Kanagawa (Hokusai, c.1831)", colors = {"1B3A5C", "3E6E96", "C9D8E0", "EDE4D3", "2A2A2A"}, surface = "wave"},
    {name = "The Kiss (Klimt, 1908)", colors = {"C9A227", "8B1E3F", "1C1C1C", "D4AF37", "5A3E2B"}, surface = "kiss"},
    {name = "Water Lilies (Monet, 1906)", colors = {"7FA6A0", "A8C9C4", "D9A6C2", "5B7C99", "EDEAD9"}, surface = "lilies"},
    {name = "The Scream (Munch, 1893)", colors = {"E8622C", "F2A65A", "2E3A6E", "8C1C13", "F4E3B2"}, surface = "scream"},
    {name = "Composition II (Mondrian, 1930)", colors = {"D40920", "1356A2", "F7D842", "1B1B1B", "F5F5F0"}, surface = "mondrian"},
    {name = "Nighthawks (Hopper, 1942)", colors = {"2B3A42", "6E8894", "C9B896", "8A3B2E", "0E1416"}, surface = "nighthawks"},
    {name = "The Persistence of Memory (Dali, 1931)", colors = {"C98A4B", "6E7A8A", "2E2A24", "8C6A3E", "D9C7A3"}, surface = "memory"},
    {name = "Gnomeregan Copper", colors = {"B5651D", "8A4A1E", "D98F3B", "5A3A1E", "C97D3E"}, surface = "copper"},
    {name = "Undermine Neon", colors = {"E84C4C", "F2C230", "3BB273", "2E86AB", "1B1B2E"}, surface = "neon"},
    {name = "Ironforge Brass & Steel", colors = {"9C7A3C", "6B7280", "3A3A3A", "C9A66B", "8A8F98"}, surface = "ironforge"},
    {name = "Verdigris Goblin", colors = {"4E7A5C", "2E4A38", "8AA88A", "6B5B3E", "1C2B22"}, surface = "verdigris"},
    {name = "Blueprint Ink", colors = {"1B3A5C", "3E6E96", "C9D8E0", "F5F5F0", "0B1F3A"}, surface = "blueprint"},
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

-- Font objects, loaded from the addon's own font files (fonts/) rather than Blizzard's
-- built-ins. A different thick, warm face per role, all from Google Fonts under the SIL Open
-- Font License 1.1 (each folder carries its OFL.txt), static instances subset with pyftsubset
-- to Latin + Latin-1 + common punctuation (the display face to ASCII only), 20-37KB each:
--   New Rocker      - the window/help titles (a heavy, flared fantasy display face)
--   Vollkorn SC     - section headings (sturdy engraved small caps)
--   Fira Sans       - labels, body and help text (SemiBold: the Medium weight read thin in game)
--   Bree Serif      - buttons and tabs (a chunky, friendly slab)
-- Sizes are a comfortable medium: body 14, small 12, labels 15, buttons 14, headings 19. The tab
-- labels keep their own 13 so they still fit under the tab icons.
-- Falls back to Blizzard's own FRIZQT__ if a font file is ever missing for some reason (a
-- corrupt install, a manual file deletion) so the UI degrades instead of erroring.
local Maines_Font_Display, Maines_Font_Heading, Maines_Font_Header, Maines_Font_Body
local Maines_Font_BodySmall, Maines_Font_Button, Maines_Font_Tab, Maines_Font_Status
-- (do ... end: the main chunk is close to Lua's 200-locals limit.)
do
    local FONT_DIR = "Interface\\AddOns\\Maines\\fonts\\"
    local FONT_DISPLAY = FONT_DIR .. "newrocker\\NewRocker-Regular.ttf"
    local FONT_HEADING = FONT_DIR .. "vollkornsc\\VollkornSC-Bold.ttf"
    local FONT_LABEL = FONT_DIR .. "firasans\\FiraSans-SemiBold.ttf"
    local FONT_BUTTON = FONT_DIR .. "breeserif\\BreeSerif-Regular.ttf"

    local function make(name, path, size)
        local font = CreateFont(name)
        if not font:SetFont(path, size, "") then
            font:SetFont("Fonts\\FRIZQT__.TTF", size, "")
        end
        return font
    end

    ns.TitleFont = make("Maines_Font_Title", FONT_DISPLAY, 26)
    Maines_Font_Display = make("Maines_Font_Display", FONT_DISPLAY, 32)
    Maines_Font_Heading = make("Maines_Font_Heading", FONT_HEADING, 19)
    Maines_Font_Header = make("Maines_Font_Header", FONT_LABEL, 15)
    Maines_Font_Body = make("Maines_Font_Body", FONT_LABEL, 14)
    Maines_Font_BodySmall = make("Maines_Font_BodySmall", FONT_LABEL, 12)
    Maines_Font_Button = make("Maines_Font_Button", FONT_BUTTON, 14)
    Maines_Font_Tab = make("Maines_Font_Tab", FONT_BUTTON, 13)
    -- the status line's readout face: the chunky slab, a little larger than body text
    Maines_Font_Status = make("Maines_Font_Status", FONT_BUTTON, 15)
end

-- The spacing scale every page lays out with (UI units): xs 4, s 8, m 12, l 16, xl 24.
-- Outer margins from the panel edges are l; gaps between a label and its control s; between
-- rows of controls m; before a new heading or block xl. Buttons pad their text by l on each side.
local SP = {xs = 4, s = 8, m = 12, l = 16, xl = 24}

-- A single warm brass/walnut value ramp used for every panel in the UI, light to dark, so
-- nothing jumps between near-white and near-black the way the first pass did. Ink colors are
-- fixed (not recolored) so text always stays readable regardless of the active palette.
-- Surfaces get depth from soft gradients and a tiled paper grain (textures/grain.tga) layered
-- over their flat fill - see Maines_DressSurface below.
local INK = {0.14, 0.08, 0.03}
local INK_SOFT = {0.32, 0.22, 0.13}
local PLATE_TEXT = {0.96, 0.91, 0.78}
local PLATE_TEXT_SOFT = {0.78, 0.68, 0.52}
-- The brass the buttons, rules and nav marker start as; /maincolor repaints it.
local ACCENT = {0.70, 0.47, 0.18}

local WINDOW_BG = {0.68, 0.55, 0.34, 1}
local CONTENT_BG = {0.80, 0.68, 0.46, 1}
local PLATE_BG = {0.24, 0.16, 0.09, 1}
local BORDER_DARK = {0.30, 0.19, 0.09, 1}

-- Chat-color escapes for inline text, matched to the colors above.
local HEX_TEXT = "|cFF3A2A1E"
local HEX_SOFT = "|cFF6B5233"
local HEX_ACCENT = "|cFF7A4510"

local TEXTURES = "Interface\\AddOns\\Maines\\textures\\"
local GRAIN_TEXTURE = TEXTURES .. "grain.tga"
local BRUSHED_TEXTURE = TEXTURES .. "brushed.tga"
local GLOW_TEXTURE = TEXTURES .. "glow.tga"
-- Each /maincolor palette's own surfaces (see Color_Palettes' `surface`): "paper" overlays
-- replace GRAIN_TEXTURE, "metal" overlays (the title bands' streaks) replace BRUSHED_TEXTURE.
local SURFACE_DEFAULT = {paper = GRAIN_TEXTURE, metal = BRUSHED_TEXTURE}
local function Maines_SurfacePath(key, role)
    if not key then return SURFACE_DEFAULT[role] end
    return TEXTURES .. "palettes\\" .. key .. (role == "metal" and "_band" or "") .. ".tga"
end
local Palette_ByName = {}
for _, palette in ipairs(Color_Palettes) do Palette_ByName[palette.name] = palette end
-- Maines' own painted cut-out icons (tools/make_icons.py, 128x128, WoW ability-icon style with
-- their own outline and drop shadow). Never tinted a colour and never registered for /maincolor
-- (an unselected tab only desaturates and dims its icon a little).
local ICONS = TEXTURES .. "icons\\"
local LOGO_TEXTURE = TEXTURES .. "logo.tga"

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
-- A tiled surface overlay (paper grain, brushed streaks): /maincolor swaps its texture for the
-- palette's own (role "paper" or "metal") and tints it from its fixed start tint toward a deep
-- shade of the palette color, kept at the start tint's brightness so the overlay darkens the
-- surface exactly as much as before.
local function Maines_RegisterSurface(tex, role, tint)
    table.insert(Maines_Textures, {surface = tex, role = role, tint = tint})
    return tex
end
local FILL_BLEND = 0.55
-- Forward-declared, assigned down by Maines_MakeButton - same pattern as Maines_Window and
-- Maines_LayoutMainPanel elsewhere in this file, for the same reason: this function needs to
-- exist as an upvalue here before its real body (which needs button-local state) is written.
local Maines_SetButtonBaseColor

local function Maines_Luminance(r, g, b)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

-- Mixes `base` toward (r, g, b) by t, then brightens or darkens the result until it has exactly
-- base's luminance. The hue follows the palette, the brightness never moves - which is what keeps
-- fixed-color text on these surfaces at the same contrast as the start look, whatever palette is
-- rolled. Brightening scales the color up first (keeping its hue and saturation) and only lifts
-- toward white once a channel is full. (Luminance is linear in r, g, b, so each step hits its
-- target exactly.)
local function Maines_ToneLike(base, r, g, b, t)
    local cr = base[1] + (r - base[1]) * t
    local cg = base[2] + (g - base[2]) * t
    local cb = base[3] + (b - base[3]) * t
    local want, have = Maines_Luminance(base[1], base[2], base[3]), Maines_Luminance(cr, cg, cb)
    if have < want then
        local top = math.max(cr, cg, cb)
        if have > 0 and top > 0 then
            local k = math.min(want / have, 1 / top)
            cr, cg, cb = cr * k, cg * k, cb * k
            have = have * k
        end
        local k = (want - have) / (1 - have)
        cr, cg, cb = cr + (1 - cr) * k, cg + (1 - cg) * k, cb + (1 - cb) * k
    elseif have > 0 then
        local k = want / have
        cr, cg, cb = cr * k, cg * k, cb * k
    end
    return cr, cg, cb
end

-- Accent text only ever sits on a dark walnut plate, so a dark palette color (e.g. Starry
-- Night's navy) is lifted toward white until it's readable rather than painted as-is.
local function Maines_LiftForText(r, g, b)
    for _ = 1, 10 do
        if Maines_Luminance(r, g, b) >= 0.55 then break end
        r, g, b = r + (1 - r) * 0.2, g + (1 - g) * 0.2, b + (1 - b) * 0.2
    end
    return r, g, b
end

-- The palette whose surfaces are showing (nil = the start look's grain and brushed brass).
local Maines_ActivePalette
-- The frame, plate and restore helpers below live in this one table (the main chunk is close
-- to Lua's 200-locals limit).
local Maines_Look = {}

-- Text contrast the way WCAG measures it (sRGB-linear luminance). Maines_ToneLike keeps the
-- simple brightness of a surface, but a saturated red at that brightness still reads a little
-- lighter to the eye; HoldContrast then darkens a dark plate (toward black) or lightens a light
-- band (toward white) just enough that its contrast with the fixed text is never below the
-- start look's.
local function Maines_LinLum(c)
    local function lin(x) return x <= 0.03928 and x / 12.92 or ((x + 0.055) / 1.055) ^ 2.4 end
    return 0.2126 * lin(c[1]) + 0.7152 * lin(c[2]) + 0.0722 * lin(c[3])
end
function Maines_Look.HoldContrast(c, base, dark)
    local want, have = Maines_LinLum(base), Maines_LinLum(c)
    if (dark and have <= want) or (not dark and have >= want) then return c end
    local target = dark and 0 or 1
    local lo, hi = 0, 1
    for _ = 1, 16 do
        local t = (lo + hi) / 2
        local m = {c[1] + (target - c[1]) * t, c[2] + (target - c[2]) * t, c[3] + (target - c[3]) * t}
        local l = Maines_LinLum(m)
        if (dark and l > want) or (not dark and l < want) then lo = t else hi = t end
    end
    return {c[1] + (target - c[1]) * hi, c[2] + (target - c[2]) * hi, c[3] + (target - c[3]) * hi}
end

-- `label` is the palette's name; it also picks the palette's surface textures and window frame
-- (an unknown or missing label puts the start look's grain, brushed brass and brass frame back).
-- The choice is remembered in Maines_DB.palette, so it comes back after /reload (see the
-- ADDON_LOADED watcher at the end of this file); `quiet` skips the chat line (used for that).
local function Maines_ApplyPaletteColor(r, g, b, hex, label, quiet)
    ACCENT[1], ACCENT[2], ACCENT[3] = r, g, b
    local palette = label and Palette_ByName[label]
    Maines_ActivePalette = palette
    local surfaceKey = palette and palette.surface
    Maines_DB = Maines_DB or {}
    Maines_DB.palette = palette and {name = palette.name, hex = hex, r = r, g = g, b = b} or nil
    for _, entry in ipairs(Maines_Textures) do
        if entry.frameBorder then
            entry.frameBorder(surfaceKey, r, g, b)
        elseif entry.surface then
            local tex = entry.surface
            tex:SetTexture(Maines_SurfacePath(surfaceKey, entry.role), "REPEAT", "REPEAT")
            tex:SetHorizTile(true)
            tex:SetVertTile(true)
            tex:SetVertexColor(Maines_ToneLike(entry.tint, r * 0.35, g * 0.35, b * 0.35, FILL_BLEND))
        elseif entry.texture then
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
            entry.fontstring:SetTextColor(Maines_LiftForText(r, g, b))
        elseif entry.repaint then
            entry.repaint(r, g, b)
        end
    end
    if hex and label and not quiet then
        ns.Say(("|cFF00FF00Maines|r: painted #%s from \"%s\""):format(hex, label),
            {kind = "ok", parts = {{label = "Palette", value = label}, {symbol = "#" .. hex}}})
    end
end

-- Puts a palette remembered in Maines_DB.palette back, silently. Anything unusable (a palette
-- removed or renamed since, a damaged entry) falls back to the start look and is forgotten.
function Maines_Look.RestorePalette()
    local saved = Maines_DB and Maines_DB.palette
    if type(saved) ~= "table" then
        if Maines_DB then Maines_DB.palette = nil end
        return false
    end
    local palette = type(saved.name) == "string" and Palette_ByName[saved.name]
    local r, g, b = tonumber(saved.r), tonumber(saved.g), tonumber(saved.b)
    if palette and not (r and g and b) and type(saved.hex) == "string" and saved.hex:match("^%x%x%x%x%x%x$") then
        r, g, b = Maines_HexToRGB(saved.hex)
    end
    if not (palette and r and g and b) then
        Maines_DB.palette = nil
        return false
    end
    r, g, b = math.min(1, math.max(0, r)), math.min(1, math.max(0, g)), math.min(1, math.max(0, b))
    Maines_ApplyPaletteColor(r, g, b, saved.hex, palette.name, true)
    return true
end

-- Every panel in this UI - the window itself, the content area, the small plates - is built
-- from "Interface\Buttons\WHITE8X8" (a plain solid-color pixel texture) rather than any of
-- Blizzard's named dialog/frame art. An earlier pass tried real Blizzard border/background
-- textures for visible paper grain; in practice those paths rendered as fully transparent in
-- this client (the window and its panels showed the 3D world straight through them), which is
-- a strictly worse bug than a flat but fully opaque, correctly colored panel. WHITE8X8 is the
-- one texture guaranteed to render exactly as its color says, so everything uses it now.
--
-- Depth and grain are layered ON TOP of that opaque fill (Maines_DressSurface): a soft light-
-- to-shade gradient, then the addon's own tiled paper grain (textures/grain.tga). Both are
-- semi-transparent overlays, so if the grain file ever fails to load, the panel is simply the
-- flat color underneath - never see-through.
local function Maines_DressSurface(frame, inset, grainAlpha)
    inset = inset or 0
    local shade = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
    shade:SetPoint("TOPLEFT", inset, -inset)
    shade:SetPoint("BOTTOMRIGHT", -inset, inset)
    shade:SetTexture("Interface\\Buttons\\WHITE8X8")
    shade:SetGradient("VERTICAL", CreateColor(0.20, 0.10, 0.02, 0.22), CreateColor(1, 0.96, 0.85, 0.12))

    local grain = frame:CreateTexture(nil, "BACKGROUND", nil, 3)
    grain:SetPoint("TOPLEFT", inset, -inset)
    grain:SetPoint("BOTTOMRIGHT", -inset, inset)
    grain:SetTexture(GRAIN_TEXTURE, "REPEAT", "REPEAT")
    grain:SetHorizTile(true)
    grain:SetVertTile(true)
    grain:SetVertexColor(0.30, 0.18, 0.06)
    grain:SetAlpha(grainAlpha or 0.30)
    Maines_RegisterSurface(grain, "paper", {0.30, 0.18, 0.06})
    return shade, grain
end

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
    Maines_DressSurface(frame, edgeSize or 2)
    return frame
end

-- A window's frame: a moulded metal border drawn just outside the window, one motif per palette
-- (textures/frames/<key>/ from tools/make_textures.py; "brass" is the start look). The textures
-- are greyscale relief, all cut from the same moulding and lit like the title band; the frame
-- takes its color from the same palette tone as the band, so window and frame read as one
-- object. Built the way Blizzard's dialog borders are - four corner pieces and four edge strips
-- - but from the add-on's own textures: FRAME_SIZE units thick, FRAME_OUT of it outside the
-- window, so the rest only covers the window's own thin edge, never its content. The strips
-- repeat every FRAME_TILE units through texture coordinates past 1 (wrap mode REPEAT), rounded
-- to a whole number of repeats so the pattern meets each corner cleanly.
do
    local FRAMES = TEXTURES .. "frames\\"
    local FRAME_SIZE, FRAME_OUT, FRAME_TILE = 16, 13, 64
    local FRAME_TINT, FRAME_BLEND = {0.76, 0.57, 0.31}, 0.7
    local FRAME_PIECES = {"tl", "tr", "bl", "br", "top", "bottom", "left", "right"}
    local function Maines_FramePath(key, piece)
        return FRAMES .. (key or "brass") .. "\\" .. piece .. ".tga"
    end

    function Maines_Look.AddFrameBorder(frame)
        local p = {}
        for _, name in ipairs(FRAME_PIECES) do
            p[name] = frame:CreateTexture(nil, "OVERLAY", nil, 7)
        end
        for _, name in ipairs({"tl", "tr", "bl", "br"}) do p[name]:SetSize(FRAME_SIZE, FRAME_SIZE) end
        p.tl:SetPoint("TOPLEFT", frame, "TOPLEFT", -FRAME_OUT, FRAME_OUT)
        p.tr:SetPoint("TOPRIGHT", frame, "TOPRIGHT", FRAME_OUT, FRAME_OUT)
        p.bl:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -FRAME_OUT, -FRAME_OUT)
        p.br:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", FRAME_OUT, -FRAME_OUT)
        p.top:SetPoint("TOPLEFT", p.tl, "TOPRIGHT"); p.top:SetPoint("BOTTOMRIGHT", p.tr, "BOTTOMLEFT")
        p.bottom:SetPoint("TOPLEFT", p.bl, "TOPRIGHT"); p.bottom:SetPoint("BOTTOMRIGHT", p.br, "BOTTOMLEFT")
        p.left:SetPoint("TOPLEFT", p.tl, "BOTTOMLEFT"); p.left:SetPoint("BOTTOMRIGHT", p.bl, "TOPRIGHT")
        p.right:SetPoint("TOPLEFT", p.tr, "BOTTOMLEFT"); p.right:SetPoint("BOTTOMRIGHT", p.br, "TOPRIGHT")

        -- (each direction on its own: the note's height is only known once its text is laid out)
        local function fit()
            local w, h = frame:GetWidth(), frame:GetHeight()
            if w and w > 0 then
                local across = math.max(1, math.floor((w + 2 * FRAME_OUT - 2 * FRAME_SIZE) / FRAME_TILE + 0.5))
                p.top:SetTexCoord(0, across, 0, 1)
                p.bottom:SetTexCoord(0, across, 0, 1)
            end
            if h and h > 0 then
                local down = math.max(1, math.floor((h + 2 * FRAME_OUT - 2 * FRAME_SIZE) / FRAME_TILE + 0.5))
                p.left:SetTexCoord(0, 1, 0, down)
                p.right:SetTexCoord(0, 1, 0, down)
            end
        end
        p.fit = fit
        -- key nil = the start look's brass frame; (r, g, b) = the palette color, toned exactly like
        -- the title band (FRAME_BLEND = the band's blend), so frame and band are one material
        local function dress(key, r, g, b)
            local tr, tg, tb = FRAME_TINT[1], FRAME_TINT[2], FRAME_TINT[3]
            if r then tr, tg, tb = Maines_ToneLike(FRAME_TINT, r, g, b, FRAME_BLEND) end
            for _, name in ipairs(FRAME_PIECES) do
                p[name]:SetTexture(Maines_FramePath(key, name), "REPEAT", "REPEAT")
                p[name]:SetVertexColor(tr, tg, tb)
            end
            p.key, p.tint = key or "brass", {tr, tg, tb}
            fit()
        end
        dress(nil)
        frame:HookScript("OnSizeChanged", fit)
        frame:HookScript("OnShow", fit)
        -- keep the whole frame, not just the window, on screen
        if frame.SetClampRectInsets then frame:SetClampRectInsets(-FRAME_OUT, FRAME_OUT, FRAME_OUT, -FRAME_OUT) end
        frame.maines_frame = p
        table.insert(Maines_Textures, {frameBorder = dress})
        return p
    end

    -- A dark walnut plate (tab strip, footer, preview stages): /maincolor tones it toward the
    -- palette color, but - like the title bands - every tone keeps the walnut's own brightness
    -- (Maines_ToneLike), so the cream text on it stays exactly as readable. `paint(lo, hi)` gets the
    -- toned colors of the plate's two shades; plate.tone holds them for the tests. HoldContrast
-- then makes sure none of them is any lighter, to the eye, than the walnut it replaces.
    local PLATE_BLEND = 0.6
    function Maines_Look.RegisterPlate(plate, shades, paint)
        local function repaint(r, g, b)
            local out = {}
            for i, base in ipairs(shades) do
                if r then
                    out[i] = Maines_Look.HoldContrast({Maines_ToneLike(base, r, g, b, PLATE_BLEND)}, base, true)
                else
                    out[i] = {base[1], base[2], base[3]}
                end
            end
            plate.tone = out
            paint(unpack(out))
        end
        repaint()
        table.insert(Maines_Textures, {repaint = repaint})
    end

    -- A plate drawn as a gradient texture, between `lo` and `hi` times the walnut.
    function Maines_Look.TonePlateGradient(plate, tex, lo, hi)
        Maines_Look.RegisterPlate(plate, {
            {PLATE_BG[1] * lo, PLATE_BG[2] * lo, PLATE_BG[3] * lo},
            {PLATE_BG[1] * hi, PLATE_BG[2] * hi, PLATE_BG[3] * hi},
        }, function(a, b)
            tex:SetGradient("VERTICAL", CreateColor(a[1], a[2], a[3], 1), CreateColor(b[1], b[2], b[3], 1))
        end)
    end

    -- The window's bars (tab strip, status line, footer): the same material as the title band
    -- and frame, only deeper - a fill toned strongly toward the palette (a deep shade of the band
    -- tone, not near-black), the band's own metal streaks (the palette's band texture, swapped
    -- and tinted like every overlay) laid over it at a visible strength, and a bevel: a fine top
    -- highlight, a dark bottom edge, a soft shadow inside both edges. The streaks and shadows only
    -- ever darken the fill, and the fill is held to BAR_BASE's sRGB luminance (HoldContrast), so
    -- cream text keeps at least BAR_BASE's 4.8:1 on every palette. Everything here is a plain
    -- WHITE8X8 or tiled .tga texture with SetGradient / SetVertexColor - the calls the title band
    -- already uses in game. `tex` is the bar's existing BACKGROUND texture; plate.tone holds the
    -- fill's two stops for the tests.
    local BAR_BASE, BAR_BLEND = {0.33, 0.23, 0.12}, 0.75
    function Maines_Look.DressBar(bar, tex, lo, hi)
        tex:SetTexture("Interface\\Buttons\\WHITE8X8")
        local stops = {
            {BAR_BASE[1] * lo, BAR_BASE[2] * lo, BAR_BASE[3] * lo},
            {BAR_BASE[1] * hi, BAR_BASE[2] * hi, BAR_BASE[3] * hi},
        }
        local function repaint(r, g, b)
            local out = {}
            for i, base in ipairs(stops) do
                if r then
                    out[i] = Maines_Look.HoldContrast({Maines_ToneLike(base, r, g, b, BAR_BLEND)}, base, true)
                else
                    out[i] = {base[1], base[2], base[3]}
                end
            end
            bar.tone = out
            tex:SetGradient("VERTICAL", CreateColor(out[1][1], out[1][2], out[1][3], 1), CreateColor(out[2][1], out[2][2], out[2][3], 1))
        end
        repaint()
        table.insert(Maines_Textures, {repaint = repaint})

        local streaks = bar:CreateTexture(nil, "BACKGROUND", nil, 2)
        streaks:SetAllPoints()
        streaks:SetTexture(BRUSHED_TEXTURE, "REPEAT", "REPEAT")
        streaks:SetHorizTile(true)
        streaks:SetVertTile(true)
        streaks:SetVertexColor(0.12, 0.07, 0.03)
        streaks:SetAlpha(0.55)
        Maines_RegisterSurface(streaks, "metal", {0.12, 0.07, 0.03})

        local function edge(point, height, a, b)
            local t = bar:CreateTexture(nil, "BORDER")
            t:SetTexture("Interface\\Buttons\\WHITE8X8")
            t:SetPoint(point .. "LEFT")
            t:SetPoint(point .. "RIGHT")
            t:SetHeight(height)
            t:SetGradient("VERTICAL", a, b)
            return t
        end
        -- soft inner shadows (VERTICAL runs bottom color -> top color)
        edge("TOP", 6, CreateColor(0, 0, 0, 0), CreateColor(0, 0, 0, 0.28))
        edge("BOTTOM", 5, CreateColor(0, 0, 0, 0.32), CreateColor(0, 0, 0, 0))
        local shine = bar:CreateTexture(nil, "ARTWORK", nil, 7)
        shine:SetTexture("Interface\\Buttons\\WHITE8X8")
        shine:SetVertexColor(1, 0.92, 0.76, 0.16)
        shine:SetHeight(1)
        shine:SetPoint("TOPLEFT", 0, -1)
        shine:SetPoint("TOPRIGHT", 0, -1)
        local dark = bar:CreateTexture(nil, "ARTWORK", nil, 7)
        dark:SetTexture("Interface\\Buttons\\WHITE8X8")
        dark:SetVertexColor(0, 0, 0, 0.55)
        dark:SetHeight(1)
        dark:SetPoint("BOTTOMLEFT")
        dark:SetPoint("BOTTOMRIGHT")
        bar.maines_streaks = streaks
        return bar
    end

    -- A plate drawn as a backdrop (fill PLATE_BG, edge BORDER_DARK), for the feature pages.
    function Maines_Look.TonePlateBackdrop(frame)
        Maines_Look.RegisterPlate(frame, {PLATE_BG, BORDER_DARK}, function(fill, edge)
            frame:SetBackdropColor(fill[1], fill[2], fill[3], 1)
            frame:SetBackdropBorderColor(edge[1], edge[2], edge[3], 1)
        end)
    end
    -- A soft light sheen over a whole window, frame included: a faint white falling from the top
    -- (a touch stronger toward the top left, where the light comes from), a faint darkening
    -- toward the bottom, and a soft shadow the frame casts just inside its inner edge. One
    -- child frame on top of everything else, mouse-transparent. Kept this faint so it never
    -- dims the text noticeably (tests/run.lua checks the contrast it leaves).
    Maines_Look.SHEEN = {top = 0.05, corner = 0.035, bottom = 0.05, shadow = 0.22, shadowWidth = 6}
    function Maines_Look.AddSheen(frame)
        local S = Maines_Look.SHEEN
        local sheen = CreateFrame("Frame", nil, frame)
        sheen:SetPoint("TOPLEFT", -FRAME_OUT, FRAME_OUT)
        sheen:SetPoint("BOTTOMRIGHT", FRAME_OUT, -FRAME_OUT)
        sheen:SetFrameLevel(frame:GetFrameLevel() + 60)
        sheen:EnableMouse(false)
        if sheen.SetMouseClickEnabled then sheen:SetMouseClickEnabled(false) end
        local function layer(a1, rel1, a2, rel2, orient, c1, c2)
            local tex = sheen:CreateTexture(nil, "OVERLAY")
            tex:SetTexture("Interface\\Buttons\\WHITE8X8")
            tex:SetPoint(a1, sheen, rel1)
            tex:SetPoint(a2, sheen, rel2)
            tex:SetGradient(orient, c1, c2)
            return tex
        end
        local white, black = function(a) return CreateColor(1, 0.97, 0.90, a) end, function(a) return CreateColor(0, 0, 0, a) end
        -- VERTICAL gradients run from the bottom color to the top color
        layer("TOPLEFT", "TOPLEFT", "BOTTOMRIGHT", "RIGHT", "VERTICAL", white(0), white(S.top))
        layer("TOPLEFT", "TOPLEFT", "BOTTOMRIGHT", "CENTER", "HORIZONTAL", white(S.corner), white(0))
        layer("TOPLEFT", "LEFT", "BOTTOMRIGHT", "BOTTOMRIGHT", "VERTICAL", black(S.bottom), black(0))
        -- the inner shadow, just inside the frame's inner edge (the window's own edge + 3)
        local inset, w = FRAME_OUT + 3, S.shadowWidth
        local function shadow(side)
            local tex = sheen:CreateTexture(nil, "OVERLAY")
            tex:SetTexture("Interface\\Buttons\\WHITE8X8")
            if side == "top" then
                tex:SetPoint("TOPLEFT", inset, -inset); tex:SetPoint("TOPRIGHT", -inset, -inset); tex:SetHeight(w)
                tex:SetGradient("VERTICAL", black(0), black(S.shadow))
            elseif side == "bottom" then
                tex:SetPoint("BOTTOMLEFT", inset, inset); tex:SetPoint("BOTTOMRIGHT", -inset, inset); tex:SetHeight(w)
                tex:SetGradient("VERTICAL", black(S.shadow), black(0))
            elseif side == "left" then
                tex:SetPoint("TOPLEFT", inset, -inset); tex:SetPoint("BOTTOMLEFT", inset, inset); tex:SetWidth(w)
                tex:SetGradient("HORIZONTAL", black(S.shadow), black(0))
            else
                tex:SetPoint("TOPRIGHT", -inset, -inset); tex:SetPoint("BOTTOMRIGHT", -inset, inset); tex:SetWidth(w)
                tex:SetGradient("HORIZONTAL", black(0), black(S.shadow))
            end
        end
        for _, side in ipairs({"top", "bottom", "left", "right"}) do shadow(side) end
        frame.maines_sheen = sheen
        return sheen
    end

    Maines_Look.FRAME_OUT = FRAME_OUT
end

-- The GLYPH stamp mark: a small engraved diamond - an accent-colored diamond with a dark one
-- set inside it and a bright point at the centre. Drawn from rotated squares, since stamp
-- characters like the old "▦" are missing from several UI fonts. The outer diamond follows
-- /maincolor; the inner ones stay fixed so the mark always reads.
local function Maines_MakeGlyphBadge(parent, size)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(size, size)
    local function diamond(edge, r, g, b, layer)
        local tex = holder:CreateTexture(nil, "OVERLAY", nil, layer)
        tex:SetTexture("Interface\\Buttons\\WHITE8X8")
        tex:SetSize(edge, edge)
        tex:SetPoint("CENTER")
        tex:SetRotation(math.rad(45))
        tex:SetVertexColor(r, g, b)
        return tex
    end
    -- a square's diagonal is edge * 1.414, so these fill `size` corner to corner
    Maines_RegisterTexture(diamond(size * 0.70, ACCENT[1], ACCENT[2], ACCENT[3], 1))
    diamond(size * 0.42, 0.20, 0.13, 0.06, 2)
    diamond(math.max(2, size * 0.14), 1, 0.92, 0.70, 3)
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
-- Each button is the brass/palette colour itself, drawn in layers that all follow that colour:
-- a face gradient (darker at the bottom, lighter at the top), a soft gloss over the upper half,
-- a thin bright rim along the top and sides, a darker bottom edge, and a dark outer edge. States:
--   rest      the plain face
--   hover     lifted: brighter face, stronger gloss and rim
--   pressed   shaded, with an inner shadow along the top and the label nudged 1 down
--   selected  this UI uses Disable() to mark the current tab/bracket/mode: sunk into a dark
--             walnut face with a full-colour edge, an inverted gradient and the inner shadow
--   unavailable  btn:SetUnavailable(true) - greyed (most of the colour gone, soft label, no
--             hover); still clickable, so the click can say why it can't do anything yet
-- The label colour is picked from the face's brightness, so it stays readable for every
-- /maincolor palette, including the very light ones.
local BUTTON_BORDER_SHADE = 0.38
local STATE_REST, STATE_HOVER, STATE_DOWN, STATE_SELECTED = 1.0, 1.14, 0.84, "selected"

local function Maines_PaintButton(btn, state)
    local c = btn.baseColor
    if not c then return end
    local selected = state == STATE_SELECTED
    local greyed = btn.unavailable and not selected
    if greyed then state = STATE_REST end
    local r, g, b
    if selected then
        r = PLATE_BG[1] + (c[1] - PLATE_BG[1]) * 0.30
        g = PLATE_BG[2] + (c[2] - PLATE_BG[2]) * 0.30
        b = PLATE_BG[3] + (c[3] - PLATE_BG[3]) * 0.30
        btn:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    else
        if greyed then
            local l = Maines_Luminance(c[1], c[2], c[3])
            r, g, b = (c[1] * 0.3 + l * 0.7) * 0.82, (c[2] * 0.3 + l * 0.7) * 0.82, (c[3] * 0.3 + l * 0.7) * 0.82
        else
            r, g, b = math.min(1, c[1] * state), math.min(1, c[2] * state), math.min(1, c[3] * state)
        end
        btn:SetBackdropBorderColor(r * BUTTON_BORDER_SHADE, g * BUTTON_BORDER_SHADE, b * BUTTON_BORDER_SHADE, 1)
    end
    btn:SetBackdropColor(r, g, b, 1)
    if btn.face then
        local lo, hi = 0.80, 1.14
        if selected then lo, hi = 1.10, 0.78 end
        btn.face:SetGradient("VERTICAL", CreateColor(r * lo, g * lo, b * lo, 1),
            CreateColor(math.min(1, r * hi + 0.03), math.min(1, g * hi + 0.03), math.min(1, b * hi + 0.03), 1))
        local gloss = selected and 0.04 or greyed and 0.06 or state == STATE_HOVER and 0.22 or state == STATE_DOWN and 0.06 or 0.15
        btn.gloss:SetGradient("VERTICAL", CreateColor(1, 0.97, 0.88, 0), CreateColor(1, 0.97, 0.88, gloss))
        local rim = selected and 0.10 or greyed and 0.18 or state == STATE_HOVER and 0.60 or state == STATE_DOWN and 0.22 or 0.42
        btn.rimTop:SetAlpha(rim)
        btn.rimLeft:SetAlpha(rim * 0.45)
        btn.rimRight:SetAlpha(rim * 0.45)
        btn.rimBottom:SetAlpha((selected or state == STATE_DOWN) and 0.10 or 0.38)
        if selected or state == STATE_DOWN then btn.inner:Show() else btn.inner:Hide() end
    end
    if btn.text then
        local tc
        if greyed then
            tc = Maines_Luminance(r, g, b) > 0.55 and INK_SOFT or PLATE_TEXT_SOFT
        elseif Maines_Luminance(r, g, b) > 0.55 then
            tc = INK
        else
            tc = PLATE_TEXT
        end
        btn.text:SetTextColor(tc[1], tc[2], tc[3])
        for _, mark in ipairs(btn.marks or {}) do mark:SetVertexColor(tc[1], tc[2], tc[3]) end
        btn.text:ClearAllPoints()
        btn.text:SetPoint("CENTER", 0, (selected or state == STATE_DOWN) and -1 or 0)
    end
end

function Maines_SetButtonBaseColor(btn, r, g, b)
    btn.baseColor = {r, g, b}
    Maines_PaintButton(btn, btn:IsEnabled() and STATE_REST or STATE_SELECTED)
end

local function Maines_MakeButton(parent, width, height, text)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })

    local fs = btn:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(Maines_Font_Button)
    fs:SetText(text or "")
    fs:SetPoint("CENTER")
    fs:SetJustifyH("CENTER")
    fs:SetJustifyV("MIDDLE")
    fs:SetTextColor(PLATE_TEXT[1], PLATE_TEXT[2], PLATE_TEXT[3])
    fs:SetShadowColor(0, 0, 0, 0.45)
    fs:SetShadowOffset(0, -1)
    btn.text = fs

    -- the layers, inside the 1px outer edge
    local function layer(sub)
        local t = btn:CreateTexture(nil, "ARTWORK", nil, sub)
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        return t
    end
    local face = layer(0)
    face:SetPoint("TOPLEFT", 1, -1)
    face:SetPoint("BOTTOMRIGHT", -1, 1)
    btn.face = face
    local gloss = layer(1)
    gloss:SetPoint("TOPLEFT", 1, -1)
    gloss:SetPoint("RIGHT", -1, 0)
    gloss:SetPoint("BOTTOM", btn, "CENTER")
    btn.gloss = gloss
    local inner = layer(2)
    inner:SetPoint("TOPLEFT", 1, -1)
    inner:SetPoint("TOPRIGHT", -1, -1)
    inner:SetHeight(7)
    inner:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0), CreateColor(0, 0, 0, 0.38))
    btn.inner = inner
    local function rim(r, g, b)
        local t = layer(3)
        t:SetVertexColor(r, g, b)
        return t
    end
    btn.rimTop = rim(1, 0.95, 0.82)
    btn.rimTop:SetPoint("TOPLEFT", 1, -1)
    btn.rimTop:SetPoint("TOPRIGHT", -1, -1)
    btn.rimTop:SetHeight(1)
    btn.rimLeft = rim(1, 0.95, 0.82)
    btn.rimLeft:SetPoint("TOPLEFT", 1, -2)
    btn.rimLeft:SetPoint("BOTTOMLEFT", 1, 2)
    btn.rimLeft:SetWidth(1)
    btn.rimRight = rim(1, 0.95, 0.82)
    btn.rimRight:SetPoint("TOPRIGHT", -1, -2)
    btn.rimRight:SetPoint("BOTTOMRIGHT", -1, 2)
    btn.rimRight:SetWidth(1)
    btn.rimBottom = rim(0.10, 0.05, 0.01)
    btn.rimBottom:SetPoint("BOTTOMLEFT", 1, 1)
    btn.rimBottom:SetPoint("BOTTOMRIGHT", -1, 1)
    btn.rimBottom:SetHeight(1)

    local neededWidth = fs:GetStringWidth() + 2 * SP.l
    btn:SetSize(math.max(width or 0, neededWidth), height)

    Maines_SetButtonBaseColor(btn, ACCENT[1], ACCENT[2], ACCENT[3])
    Maines_RegisterButton(btn)

    local function live(self) return self:IsEnabled() and not self.unavailable end
    btn:SetScript("OnEnter", function(self)
        if live(self) then Maines_PaintButton(self, STATE_HOVER) end
        if self.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if live(self) then Maines_PaintButton(self, STATE_REST) end
        if self.tooltip then GameTooltip:Hide() end
    end)
    btn:SetScript("OnMouseDown", function(self)
        if live(self) then Maines_PaintButton(self, STATE_DOWN) end
    end)
    btn:SetScript("OnMouseUp", function(self)
        if live(self) then Maines_PaintButton(self, STATE_HOVER) end
    end)

    function btn:SetText(t)
        fs:SetText(t)
        local w = fs:GetStringWidth() + 2 * SP.l
        if w > self:GetWidth() then self:SetWidth(w) end
    end
    function btn:GetText() return fs:GetText() end
    function btn:SetUnavailable(flag)
        flag = flag and true or false
        if self.unavailable == flag then return end
        self.unavailable = flag
        Maines_PaintButton(self, self:IsEnabled() and STATE_REST or STATE_SELECTED)
    end

    -- Disable() doubles as "this is the selected one" throughout this UI, so it paints the
    -- strong selected face rather than a greyed-out one.
    local realDisable, realEnable = btn.Disable, btn.Enable
    function btn:Disable()
        realDisable(self)
        Maines_PaintButton(self, STATE_SELECTED)
    end
    function btn:Enable()
        realEnable(self)
        Maines_PaintButton(self, STATE_REST)
    end

    return btn
end

-- Maines' own close button for its windows: a small square plate in the same style as every
-- other button (brass, following /maincolor), with an embossed x drawn from two crossed bars.
-- Same click behaviour as WoW's close button: it hides `target` (the windows' own Escape
-- handling is unchanged).
local function Maines_MakeCloseButton(parent, target, onClick)
    local btn = Maines_MakeButton(parent, 26, 26, "")
    btn:SetSize(26, 26)
    btn.marks = {}
    for _, angle in ipairs({45, -45}) do
        local shade = btn:CreateTexture(nil, "OVERLAY", nil, 1)
        shade:SetTexture("Interface\\Buttons\\WHITE8X8")
        shade:SetVertexColor(0.08, 0.04, 0.01, 0.55)
        shade:SetSize(14, 3)
        shade:SetPoint("CENTER", 0, -1)
        shade:SetRotation(math.rad(angle))
        local bar = btn:CreateTexture(nil, "OVERLAY", nil, 2)
        bar:SetTexture("Interface\\Buttons\\WHITE8X8")
        bar:SetSize(14, 3)
        bar:SetPoint("CENTER", 0, 0)
        bar:SetRotation(math.rad(angle))
        btn.marks[#btn.marks + 1] = bar
    end
    Maines_PaintButton(btn, STATE_REST)
    btn.tooltip = "Close"
    btn:SetScript("OnClick", onClick or function() target:Hide() end)
    return btn
end

-- A tab in the row under the title: icon above its label on the dark walnut tab strip, a soft
-- highlight on hover, and - for the open page - a parchment surface that joins it to the
-- content panel below, like a folder tab, with an accent bar along its top edge.
-- Tab icons: 30px cut-outs. An unselected, un-hovered tab's icon is partly desaturated and
-- dimmed to a neutral grey, never tinted a colour. (One table: the main chunk is near Lua's
-- 200-locals limit.)
local NAV_ICON = {size = 30, dim = 0.85, desat = 0.45}
local function Maines_MakeNavButton(parent, width, height, text, iconPath)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, height)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    -- Same color the content panel's fill ends up after /maincolor (FILL_BLEND), so the open
    -- page's entry keeps visually joining the panel whatever the palette.
    local function paintBg(r, g, b)
        local t = r and FILL_BLEND or 0
        local cr = CONTENT_BG[1] * (1 - t) + (r or 0) * t
        local cg = CONTENT_BG[2] * (1 - t) + (g or 0) * t
        local cb = CONTENT_BG[3] * (1 - t) + (b or 0) * t
        bg:SetGradient("VERTICAL", CreateColor(cr, cg, cb, 1), CreateColor(cr * 0.86, cg * 0.86, cb * 0.86, 1))
    end
    paintBg()
    table.insert(Maines_Textures, {repaint = paintBg})
    bg:Hide()
    btn.bg = bg

    local hover = btn:CreateTexture(nil, "BORDER")
    hover:SetAllPoints()
    hover:SetTexture("Interface\\Buttons\\WHITE8X8")
    hover:SetVertexColor(1, 0.9, 0.7, 0.08)
    hover:Hide()

    local bar = btn:CreateTexture(nil, "ARTWORK")
    bar:SetTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetVertexColor(ACCENT[1], ACCENT[2], ACCENT[3])
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("TOPRIGHT")
    bar:SetHeight(3)
    bar:Hide()
    Maines_RegisterTexture(bar)
    btn.bar = bar

    -- Painted cut-out icon (its outline and drop shadow are in the texture), never tinted: the
    -- open tab shows it in full colour, the others a little greyer and darker, hover restores it.
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(NAV_ICON.size, NAV_ICON.size)
    icon:SetTexture(iconPath)
    icon:SetPoint("TOP", 0, -2)
    btn.icon = icon
    local function iconLook(full)
        local v = full and 1 or NAV_ICON.dim
        icon:SetVertexColor(v, v, v)
        if icon.SetDesaturation then
            icon:SetDesaturation(full and 0 or NAV_ICON.desat)
        else
            icon:SetDesaturated(not full)
        end
    end

    local fs = btn:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(Maines_Font_Tab)
    fs:SetPoint("BOTTOM", 0, 3)
    fs:SetText(text)
    btn.text = fs

    function btn:SetSelected(selected)
        self.selected = selected
        if selected then
            bg:Show(); bar:Show()
            fs:SetTextColor(INK[1], INK[2], INK[3])
            iconLook(true)
        else
            bg:Hide(); bar:Hide()
            fs:SetTextColor(PLATE_TEXT_SOFT[1], PLATE_TEXT_SOFT[2], PLATE_TEXT_SOFT[3])
            iconLook(false)
        end
    end
    btn:SetScript("OnEnter", function(self)
        hover:Show()
        if not self.selected then
            fs:SetTextColor(PLATE_TEXT[1], PLATE_TEXT[2], PLATE_TEXT[3])
            iconLook(true)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        hover:Hide()
        self:SetSelected(self.selected)
    end)
    btn:SetSelected(false)
    return btn
end

-- A section heading: engraved ink text centered over a thin accent rule that fades out toward
-- both ends, placed at y on `parent` within `width` (x is the block's left edge). Returns the
-- heading and the y just below its rule.
local function Maines_MakeHeading(parent, text, x, y, width)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(Maines_Font_Heading)
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetWidth(width)
    fs:SetJustifyH("CENTER")
    fs:SetText(text)
    fs:SetTextColor(INK[1], INK[2], INK[3])
    fs:SetShadowColor(1, 0.95, 0.82, 0.5)
    fs:SetShadowOffset(0, -1)

    local rule = parent:CreateTexture(nil, "ARTWORK")
    rule:SetTexture("Interface\\Buttons\\WHITE8X8")
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -SP.xs)
    rule:SetWidth(width / 2)
    local ruleR = parent:CreateTexture(nil, "ARTWORK")
    ruleR:SetTexture("Interface\\Buttons\\WHITE8X8")
    ruleR:SetHeight(1)
    ruleR:SetPoint("LEFT", rule, "RIGHT")
    ruleR:SetWidth(width / 2)
    local function paintRule(r, g, b)
        r, g, b = r or ACCENT[1], g or ACCENT[2], b or ACCENT[3]
        rule:SetGradient("HORIZONTAL", CreateColor(r, g, b, 0), CreateColor(r, g, b, 0.75))
        ruleR:SetGradient("HORIZONTAL", CreateColor(r, g, b, 0.75), CreateColor(r, g, b, 0))
    end
    paintRule()
    table.insert(Maines_Textures, {repaint = paintRule})
    return fs, y - fs:GetStringHeight() - SP.xs - SP.l
end

-- Slash command handlers:
SlashCmdList["MAINMUSIC"] = function() _G["PlayedMusic_DB"] = "noplayed" end
SlashCmdList["MAINSTAMP"] = function() ns.Say("|cFF00FF00Maines|r: The |cFFFFE4B5GLYPH|r Stamp") end
SlashCmdList["MAINCOLOR"] = function()
    if #Maines_Textures == 0 then
        ns.Say("|cFF00FF00Maines|r: no textures loaded yet — open /maines once first")
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
        ns.Say("|cFF00FF00Maines|r: minimap icon isn't available")
        return
    end
    Maines_DB = Maines_DB or {}
    Maines_DB.minimap = Maines_DB.minimap or {}
    Maines_DB.minimap.hide = not Maines_DB.minimap.hide
    if Maines_DB.minimap.hide then
        icon:Hide("Maines")
        ns.Say("|cFF00FF00Maines|r: minimap icon hidden")
    else
        icon:Show("Maines")
        ns.Say("|cFF00FF00Maines|r: minimap icon shown")
    end
end
SlashCmdList["BRACKET"] = function()
    local i = 1
    for k,v in pairs(Bracket_Types) do
        print(i.." = "..(v[1].." Maines "..v[2]).." - "..v[4]); i = i+1
    end
    ns.Status("|cFF00FF00Maines|r: the " .. (i - 1) .. " bracket types are listed in chat")
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
-- What /mains and /main print: four chat lines as always, and the same facts on one line in
-- the window's status line.
function ns.PrintMainSettings(name, typ, left, right)
    print("|cFFD2C7B7", "Main Name |r", "|cFFFFE4B5", name, "|r")
    if typ and left and right then
        print("|cFFC1B7A8", "Bracket Type", "|r", typ, "|r")
        print("|cFFB8AEA0", "Left Bracket", "|r", left, "|r")
        print("|cFFA9A193", "Right Bracket", "|r", right, "|r")
    end
    -- e.g.  Main Tuniveza  •  Bracket Crocodile  •  <Tuniveza>
    local parts = {{label = "Main", value = (name ~= "" and name) or "not set"}}
    if typ and typ ~= "" then
        parts[2] = {label = "Bracket", value = (typ:gsub("%s*[Bb]racket%s*$", ""))}
    end
    if name ~= "" and left and left ~= "" then
        parts[#parts + 1] = {tag = {left, name, right or ""}}
    end
    ns.Status({parts = parts})
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
        ns.PrintMainSettings(name, typ, left, right)
        -- typed while the window is open: its name box, buttons and preview follow
        if Maines_RefreshWindow and Maines_Window and Maines_Window:IsShown() then Maines_RefreshWindow() end
    else
        ns.Say("Usage: /mains <mainname> <bracket symbol> [right bracket symbol]")
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
    ns.PrintMainSettings(name, typ, left, right)
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
        ns.Say("|cFF00FF00Maines|r: chat filter ("..table.concat(filter, ", ")..
            ") reset on load - tagging all channels again. Run |cFFFFE4B5/mainchat sticky|r to keep a filter across reloads.")
        wipe(filter)
    end
end

SlashCmdList["MAINCHAT"] = function(msg)
    msg = msg and strtrim(msg) or ""
    local filter = Maines_GetChatFilter()

    if msg == "" then
        wipe(filter)
        ns.Say("|cFF00FF00Maines|r: chat filter cleared — tagging all channels (including Communities)")
        return
    end

    if msg:lower() == "list" then
        local mode = Maines_ChatFilterMode_DB or "include"
        if #filter == 0 then
            ns.Say("|cFF00FF00Maines|r: no filter set — tagging all channels")
        elseif mode == "exclude" then
            ns.Say("|cFF00FF00Maines|r: tagging every channel EXCEPT: "..table.concat(filter, ", ")..
                (Maines_ChatFilterSticky_DB and " |cFF888888(sticky)|r" or ""))
        else
            ns.Say("|cFF00FF00Maines|r: tagging ONLY: "..table.concat(filter, ", ")..
                (Maines_ChatFilterSticky_DB and " |cFF888888(sticky)|r" or ""))
        end
        return
    end

    -- /mainchat mode: whether the list above is a whitelist (tag ONLY these - the default,
    -- and the fix for any confusion about which way this goes) or a blacklist (tag everything
    -- EXCEPT these - handy for "just don't tag whispers" without listing every other channel).
    if msg:lower():match("^mode%s*$") then
        ns.Say("|cFF00FF00Maines|r: filter mode is |cFFFFE4B5"..(Maines_ChatFilterMode_DB or "include").."|r "..
            "(/mainchat mode include | /mainchat mode exclude)")
        return
    end
    local modeSet = msg:lower():match("^mode%s+(%a+)%s*$")
    if modeSet then
        if modeSet == "include" or modeSet == "exclude" then
            Maines_ChatFilterMode_DB = modeSet
            if modeSet == "include" then
                ns.Say("|cFF00FF00Maines|r: filter mode set to |cFFFFE4B5include|r - tagging ONLY the listed channels")
            else
                ns.Say("|cFF00FF00Maines|r: filter mode set to |cFFFFE4B5exclude|r - tagging every channel EXCEPT the listed ones")
            end
        else
            ns.Say("|cFF00FF00Maines|r: unknown mode \""..modeSet.."\" - use \"include\" or \"exclude\"")
        end
        return
    end

    -- By default a filter only lasts for the current session - see Maines_ResetChatFilterIfNotSticky
    -- below. This is the fix for the exact confusion that prompted it: a filter set once during
    -- testing and forgotten about would otherwise silently keep excluding channels forever.
    if msg:lower() == "sticky" then
        Maines_ChatFilterSticky_DB = not Maines_ChatFilterSticky_DB
        if Maines_ChatFilterSticky_DB then
            ns.Say("|cFF00FF00Maines|r: filter is now |cFFFFE4B5sticky|r - it'll survive reloads until you change it")
        else
            ns.Say("|cFF00FF00Maines|r: filter is |cFFFFE4B5no longer sticky|r - it'll reset to \"tag everything\" next reload")
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
        ns.Say("|cFF00FF00Maines|r: nothing to do - run /mainchat with no arguments to clear the filter")
        return
    end

    local opTokens, plainTokens = 0, 0
    for _, t in ipairs(tokens) do
        if t:match("^[%+%-]") then opTokens = opTokens + 1 else plainTokens = plainTokens + 1 end
    end

    if opTokens > 0 and plainTokens > 0 then
        ns.Say("|cFF00FF00Maines|r: can't mix +CHANNEL/-CHANNEL with plain channel names in one command")
        ns.Say("|cFF00FF00Maines|r: use \"/mainchat SAY,GUILD\" to set the whole list, or \"/mainchat +SAY,-GUILD\" to edit the existing one")
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
        if #added > 0 then ns.Say("|cFF00FF00Maines|r: added "..table.concat(added, ", ").." to filter") end
        if #removed > 0 then ns.Say("|cFF00FF00Maines|r: removed "..table.concat(removed, ", ").." from filter") end
        if #bad > 0 then ns.Say("|cFF00FF00Maines|r: ignored invalid entries: "..table.concat(bad, ", ")) end
        if #added == 0 and #removed == 0 and #bad == 0 then
            ns.Say("|cFF00FF00Maines|r: nothing changed")
        end
        return
    end

    wipe(filter)
    for _, token in ipairs(tokens) do table.insert(filter, token) end
    local mode = Maines_ChatFilterMode_DB or "include"
    if #filter == 0 then
        ns.Say("|cFF00FF00Maines|r: no valid channel names found - filter left empty, tagging all channels")
    elseif mode == "exclude" then
        ns.Say("|cFF00FF00Maines|r: tagging every channel EXCEPT: "..table.concat(filter, ", "))
    else
        ns.Say("|cFF00FF00Maines|r: tagging ONLY: "..table.concat(filter, ", "))
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

    -- animate.lua may swap in the current frame of an animated tag; without it (or with the
    -- animation off) this is the plain left..name..right tag it always was.
    local plainTag = left .. name .. right
    local tag = plainTag
    if ns.AnimatedTag then tag = ns.AnimatedTag(left, name, right) or tag end
    -- A chat line holds 255 bytes; if a long animated frame (e.g. a saved phrase) would push the
    -- message past that, fall back to the plain tag rather than risk losing the end.
    if #tag + 1 + #msg > 255 then tag = plainTag end

    -- Already tagged: the plain tag anywhere (the original check), or - for a message resent
    -- from chat history - any animation frame at the very start.
    local alreadyTagged = string.find(msg, plainTag, 1, true) ~= nil
    if not alreadyTagged and ns.AllTagFrames then
        for _, frame in ipairs(ns.AllTagFrames(left, name, right)) do
            if msg:sub(1, #frame + 1) == frame .. " " then alreadyTagged = true; break end
        end
    end
    if Maines_Debug then print("|cFF00FF00Maines debug|r: alreadyTagged="..tostring(alreadyTagged)) end
    if valid and not alreadyTagged then
        if ns.OnTagSent then ns.OnTagSent() end
        return tag .. " " .. msg
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
    ns.Say("|cFF00FF00Maines|r: when playing your main ("..tostring(_G["Maines_Name_DB"] or "not set")..
        "), the tag will |cFFFFE4B5hide|r (switch back with /mainshow)")
end

SLASH_MAINSHOW1 = "/mainshow"
SlashCmdList["MAINSHOW"] = function()
    Maines_HideOnMain_DB = false
    ns.Say("|cFF00FF00Maines|r: when playing your main ("..tostring(_G["Maines_Name_DB"] or "not set")..
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
        icon = "main",
        color = "FF69B4",
        winColor = "B23A72",
        entries = {
            {cmd = "/mains", args = "<name> <bracket>",
                desc = "Set your main's name and bracket style.",
                example = "/mains Tuniveza (  ->  tags chat as (Tuniveza)"},
            {cmd = "/main", args = "",
                desc = "Print your currently saved main name and bracket.",
                example = "/main"},
            {cmd = "/bracket", args = "",
                desc = "List every built-in bracket style by name.",
                example = "/bracket"},
        },
    },
    {
        title = "On Your Main vs. an Alt",
        icon = "behavior",
        color = "3CE7FF",
        winColor = "1B6E96",
        entries = {
            {cmd = "/mainhide", args = "",
                desc = "Hide the tag while you're playing your own main. (default)",
                example = "/mainhide", note = "Alts are always tagged either way - this only affects the main itself."},
            {cmd = "/mainshow", args = "",
                desc = "Always tag, even while playing your own main.",
                example = "/mainshow"},
        },
    },
    {
        title = "Chat Channel Filtering",
        icon = "channels",
        color = "77DD77",
        winColor = "2E7D32",
        entries = {
            {cmd = "/mainchat", args = "SAY,GUILD,...",
                desc = "Only tag the listed channels (comma-separated - case and spacing don't matter).",
                example = "/mainchat SAY,GUILD,PARTY"},
            {cmd = "/mainchat", args = "(no args)",
                desc = "Clear the filter - back to tagging every channel.",
                example = "/mainchat"},
            {cmd = "/mainchat", args = "list",
                desc = "Print the channels currently in the filter.",
                example = "/mainchat list"},
            {cmd = "/mainchat", args = "+CHANNEL / -CHANNEL",
                desc = "Add or remove one or more channels without retyping the whole list.",
                example = "/mainchat -SAY,-YELL", note = "Comma-separate several +/- ops in one go. Can't mix these with plain channel names in the same command - that's rejected outright rather than guessed at."},
            {cmd = "/mainchat", args = "mode include | exclude",
                desc = "Switch whether the list above means \"tag ONLY these\" (default) or \"tag everything EXCEPT these\".",
                example = "/mainchat mode exclude",
                note = "\"mode\" with no argument prints which one is active. include+exclude use the same list from above."},
            {cmd = "/mainchat", args = "sticky",
                desc = "Toggle whether the current filter survives a reload.",
                example = "/mainchat sticky",
                note = "Off by default: any filter resets to \"tag everything\" on your next reload unless you turn this on. Also resettable instantly by middle-clicking the minimap icon."},
        },
    },
    {
        title = "Phrases, Animation & Badges",
        icon = "badges",
        color = "C39BFF",
        winColor = "6A3FA0",
        entries = {
            {cmd = "/mainphrase", args = "add <text> | del <n> | list | clear",
                desc = "Save words, sentences or symbols to drop into chat with your shortcut key.",
                example = "/mainphrase add Looking for group!",
                note = "Set the keys on the Phrases page, or in Key Bindings > AddOns > Maines. Each press swaps in the next phrase; Enter sends."},
            {cmd = "/mainanim", args = "<style> | message | time <seconds>",
                desc = "Make your tag change a little with every message (or every so often).",
                example = "/mainanim typewriter",
                note = "Styles: off, brackets, typewriter, wave, twinkle, phrases."},
            {cmd = "/mainbadge", args = "list | show <n> | send <n> [channel]",
                desc = "Send a multi-line Textual Badge (a text picture) to chat.",
                example = "/mainbadge send 4 guild",
                note = "One badge every 3 minutes. \"show\" previews it only to you."},
        },
    },
    {
        title = "Cosmetic & Minimap",
        icon = "cosmetic",
        color = "FFA500",
        winColor = "A8631B",
        entries = {
            {cmd = "/maincolor", args = "",
                desc = "Repaint the Maines UI with a random public-domain art palette.",
                example = "/maincolor", note = "Also triggered by right-clicking the minimap icon."},
            {cmd = "/mainmap", args = "",
                desc = "Toggle the Maines minimap icon on/off.",
                example = "/mainmap", note = "The icon itself: left-click shows/hides Maines, right-click recolors it, middle-click resets the /mainchat filter."},
            {cmd = "/maines", args = "",
                desc = "Open the Maines UI (same as left-clicking the minimap icon).",
                example = "/maines"},
            {cmd = "/mainmusic", args = "",
                desc = "Replay the intro jingle next time you open the UI.",
                example = "/mainmusic"},
        },
    },
    {
        title = "Utility",
        icon = "help",
        color = "AAAAAA",
        winColor = "5A5248",
        entries = {
            {cmd = "/mainnote", args = "",
                desc = "Read the note from the author, with what's new in this update.",
                example = "/mainnote", note = "It also pops up once by itself the first time a new update runs."},
            {cmd = "/mainstamp", args = "",
                desc = "Print the current build stamp.",
                example = "/mainstamp"},
            {cmd = "/maindebug", args = "",
                desc = "Toggle live debug printing of every tagging decision.",
                example = "/maindebug", note = "Turn this on first if tagging ever silently stops working."},
        },
    },
}

-- One of Maines' own icons inline in text, in its own colours (no tint fields in the escape).
local function Maines_HelpIcon(name, size)
    size = size or 16
    return ("|T%s%s.tga:%d:%d|t"):format(ICONS, name, size, size)
end

-- Chat fallback: the original print-based reference, kept behind "/mainhelp text" for anyone
-- who wants a copyable/scrollable-in-chat version instead of the window below.
local function Maines_PrintHelpToChat()
    print(("%s |cFFFFD100Maines — Command Reference|r %s"):format(
        Maines_HelpIcon("help", 16), Maines_HelpIcon("help", 16)))
    print(" ")

    for _, section in ipairs(Help_Sections) do
        print(("|cFF%s%s|r"):format(section.color, section.title))
        for _, e in ipairs(section.entries) do
            local header = e.args ~= "" and (e.cmd.." |cFFFFFFFF"..e.args.."|r") or e.cmd
            print(("  %s |cFF%s%s|r"):format(Maines_HelpIcon(section.icon, 16), section.color, header))
            print("      |cFFCCCCCC"..e.desc.."|r")
            print("      |cFF888888e.g.|r |cFFEEEEEE"..e.example.."|r")
            if e.note then
                print("      |cFF666666note:|r |cFF999999"..e.note.."|r")
            end
            print(" ")
        end
    end

    print("|cFFFFD100Full write-up with tables and more detail lives in the addon's README.|r")
    ns.Status("|cFF00FF00Maines|r: the command reference is printed in chat")
end

-- /mainhelp window: a movable, scrollable reference panel built from the same Help_Sections
-- data as the chat version above. Chrome is the same art-free flat-backdrop + stock-icon
-- skeleton as the main window (see the GUI helpers above) rather than custom parchment art.
-- Content is a fixed-width column of FontStrings (one per section header, one per command)
-- chained top-to-bottom with GetStringHeight(), which is reliable even before the frame has
-- ever been shown - unlike GetTop()/GetBottom(), which can be unresolved on a frame that's
-- never been laid out yet.
local HELP_CONTENT_WIDTH = 510

local Help_Frame = CreateFrame("Frame", "Maines_Help_Frame", UIParent, "BackdropTemplate")
Help_Frame:SetSize(600, 700)
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
Maines_MakeFlatBackdrop(Help_Frame, WINDOW_BG, BORDER_DARK, 3)
Maines_Look.AddFrameBorder(Help_Frame)
Maines_Look.AddSheen(Help_Frame)

Help_Frame.title = Help_Frame:CreateFontString(nil, "OVERLAY")
Help_Frame.title:SetFontObject(Maines_Font_Display)
Help_Frame.title:SetPoint("TOP", 0, -22)
Help_Frame.title:SetText("Command Reference")
Help_Frame.title:SetTextColor(0.20, 0.11, 0.03)
Help_Frame.title:SetShadowColor(1, 0.94, 0.78, 0.6)
Help_Frame.title:SetShadowOffset(0, -1)

local helpClose = Maines_MakeCloseButton(Help_Frame, Help_Frame)
helpClose:SetPoint("TOPRIGHT", -SP.m, -SP.m)

local helpPanel = CreateFrame("Frame", nil, Help_Frame, "BackdropTemplate")
helpPanel:SetPoint("TOPLEFT", 26, -80)
helpPanel:SetPoint("BOTTOMRIGHT", -26, 22)
Maines_MakeFlatBackdrop(helpPanel, CONTENT_BG, BORDER_DARK, 2)

local helpScroll = CreateFrame("ScrollFrame", "Maines_Help_ScrollFrame", helpPanel, "UIPanelScrollFrameTemplate")
helpScroll:SetPoint("TOPLEFT", SP.m, -SP.m)
helpScroll:SetPoint("BOTTOMRIGHT", -28, SP.m)

local helpContent = CreateFrame("Frame", "Maines_Help_ScrollChild", helpScroll)
helpContent:SetWidth(HELP_CONTENT_WIDTH)
helpContent:SetHeight(1)
helpScroll:SetScrollChild(helpContent)

local function Maines_BuildHelpContent()
    if Help_Frame.built then return end
    Help_Frame.built = true

    local y = -SP.s

    -- Was a captured mockup graphic (mainhelp_example.tga); replaced with the same worked
    -- example as plain colored text so the panel needs no art at all.
    local exampleFS = helpContent:CreateFontString(nil, "OVERLAY")
    exampleFS:SetFontObject(Maines_Font_Body)
    exampleFS:SetPoint("TOP", 0, y)
    exampleFS:SetWidth(HELP_CONTENT_WIDTH - SP.l)
    exampleFS:SetJustifyH("CENTER")
    exampleFS:SetText(HEX_SOFT .. "Example tagged message:|r  " .. HEX_ACCENT .. "(Tuniveza)|r " .. HEX_TEXT .. "Hello there, guildies!|r")
    y = y - exampleFS:GetStringHeight() - SP.xl

    for _, section in ipairs(Help_Sections) do
        local winColor = section.winColor or section.color

        local header = helpContent:CreateFontString(nil, "OVERLAY")
        header:SetFontObject(Maines_Font_Heading)
        header:SetPoint("TOP", 0, y)
        header:SetWidth(HELP_CONTENT_WIDTH - SP.l)
        header:SetJustifyH("CENTER")
        header:SetText(Maines_HelpIcon(section.icon, 28) .. "  " .. section.title)
        local r, g, b = Maines_HexToRGB(winColor)
        header:SetTextColor(r, g, b)
        y = y - header:GetStringHeight() - SP.m

        for _, e in ipairs(section.entries) do
            local entryFS = helpContent:CreateFontString(nil, "OVERLAY")
            entryFS:SetFontObject(Maines_Font_Body)
            entryFS:SetPoint("TOP", 0, y)
            entryFS:SetWidth(HELP_CONTENT_WIDTH - SP.l)
            entryFS:SetSpacing(2)
            entryFS:SetJustifyH("CENTER")

            local cmdLine = e.args ~= "" and (e.cmd.." |cFF2A2118"..e.args.."|r") or e.cmd
            local text = "|cFF"..winColor..cmdLine.."|r\n"
                .."|cFF4A4030"..e.desc.."|r\n"
                .."|cFF8A7A63e.g.|r |cFF3A2A1E"..e.example.."|r"
            if e.note then
                text = text.."\n|cFF8A7A63note:|r |cFF6B5F4D"..e.note.."|r"
            end
            entryFS:SetText(text)

            y = y - entryFS:GetStringHeight() - SP.l
        end

        y = y - SP.s
    end

    helpContent:SetHeight(-y + SP.m)
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

-- The minimap icon turns once, slowly, when the mouse moves onto it - it used to spin
-- forever, which was more distracting than fun.
local function Maines_AnimateMinimapButton(button)
    if not button or not button.icon or button.maines_anim then return end
    local ag = button.icon:CreateAnimationGroup()
    local rot = ag:CreateAnimation("Rotation")
    rot:SetDegrees(-360)
    rot:SetDuration(1.6)
    rot:SetSmoothing("IN_OUT")
    button:HookScript("OnEnter", function() if not ag:IsPlaying() then ag:Play() end end)
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
        icon = LOGO_TEXTURE,
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

-- Window size, and the status line between the pages and the footer (one table: the main
-- chunk is near Lua's 200-locals limit). 724 tall keeps the window and its frame inside WoW's
-- 768-unit-high screen at UI scale 1.
local WIN = {w = 720, h = 724, status = 28}
Maines_Window = CreateFrame("Frame", "Maines_Frame", UIParent, "BackdropTemplate")
Maines_Window:SetSize(WIN.w, WIN.h)
Maines_Window:SetPoint("CENTER")
Maines_Window:SetFrameStrata("DIALOG")
Maines_Window:SetMovable(true)
Maines_Window:SetClampedToScreen(true)
Maines_Window:EnableMouse(true)
Maines_Window:RegisterForDrag("LeftButton")
Maines_Window:SetScript("OnDragStart", Maines_Window.StartMoving)
Maines_Window:SetScript("OnDragStop", Maines_Window.StopMovingOrSizing)
Maines_Window:SetPropagateKeyboardInput(true)
Maines_Window:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then Maines_HideMainWindow() end
end)
Maines_Window:Hide()
Maines_MakeFlatBackdrop(Maines_Window, WINDOW_BG, BORDER_DARK, 3)

-- Opening the window is a short, quiet fade-in - the only motion in the window.
local windowFade = Maines_Window:CreateAnimationGroup()
local windowFadeIn = windowFade:CreateAnimation("Alpha")
windowFadeIn:SetFromAlpha(0)
windowFadeIn:SetToAlpha(1)
windowFadeIn:SetDuration(0.18)
windowFadeIn:SetSmoothing("OUT")
Maines_Window:HookScript("OnShow", function() windowFade:Play() end)

-- A soft outer glow around the window: one round falloff texture (textures/glow.tga) cut into
-- four corners and four stretched edges round the window, `out` units out (tucked a little under
-- the frame border, so its rounded corners sit on glow too). Kept faint on purpose, and it
-- takes on the /maincolor accent.
local function Maines_AddOuterGlow(frame, size, alpha, out)
    local parts = {}
    local o = out or 0
    local function piece(l, r, t, b)
        local tex = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
        tex:SetTexture(GLOW_TEXTURE)
        tex:SetTexCoord(l, r, t, b)
        tex:SetBlendMode("ADD")
        tex:SetAlpha(alpha)
        parts[#parts + 1] = tex
        return tex
    end
    local tl = piece(0, 0.5, 0, 0.5); tl:SetSize(size, size); tl:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", -o, o)
    local tr = piece(0.5, 1, 0, 0.5); tr:SetSize(size, size); tr:SetPoint("BOTTOMLEFT", frame, "TOPRIGHT", o, o)
    local bl = piece(0, 0.5, 0.5, 1); bl:SetSize(size, size); bl:SetPoint("TOPRIGHT", frame, "BOTTOMLEFT", -o, -o)
    local br = piece(0.5, 1, 0.5, 1); br:SetSize(size, size); br:SetPoint("TOPLEFT", frame, "BOTTOMRIGHT", o, -o)
    local top = piece(0.49, 0.51, 0, 0.5); top:SetHeight(size)
    top:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -o, o); top:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", o, o)
    local bottom = piece(0.49, 0.51, 0.5, 1); bottom:SetHeight(size)
    bottom:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -o, -o); bottom:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", o, -o)
    local left = piece(0, 0.5, 0.49, 0.51); left:SetWidth(size)
    left:SetPoint("TOPRIGHT", frame, "TOPLEFT", -o, o); left:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", -o, -o)
    local right = piece(0.5, 1, 0.49, 0.51); right:SetWidth(size)
    right:SetPoint("TOPLEFT", frame, "TOPRIGHT", o, o); right:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", o, -o)
    local function paint(r, g, b)
        r, g, b = r or 1, g or 0.78, b or 0.42
        for _, tex in ipairs(parts) do tex:SetVertexColor(r, g, b) end
    end
    paint()
    table.insert(Maines_Textures, {repaint = paint})
end
Maines_Look.AddFrameBorder(Maines_Window)
Maines_Look.AddSheen(Maines_Window)
Maines_AddOuterGlow(Maines_Window, 22, 0.35, Maines_Look.FRAME_OUT - 5)

-- Dresses a band (the window header, the note's title strip) as brushed brass: a warm gradient,
-- tiled brushed-metal streaks and paper grain, darker toward both ends, a fine highlight along
-- the top edge and an accent rule along the bottom.
-- /maincolor tones the whole band toward the palette color (BAND_BLEND) and swaps its streaks
-- and grain for the palette's own surfaces, but every layer keeps its start brightness
-- (Maines_ToneLike), so the dark engraved title on top reads exactly as well as on plain brass.
local BAND_BLEND = 0.7
local BAND_LOW, BAND_HIGH = {0.60, 0.45, 0.24}, {0.82, 0.67, 0.42}
local BAND_SHADE = {0.18, 0.09, 0.02}
local function Maines_DressBrassBand(band)
    local headerBg = band:CreateTexture(nil, "BACKGROUND", nil, 0)
    headerBg:SetAllPoints()
    headerBg:SetTexture("Interface\\Buttons\\WHITE8X8")

    local headerBrush = band:CreateTexture(nil, "BACKGROUND", nil, 1)
    headerBrush:SetAllPoints()
    headerBrush:SetTexture(BRUSHED_TEXTURE, "REPEAT", "REPEAT")
    headerBrush:SetHorizTile(true)
    headerBrush:SetVertTile(true)
    headerBrush:SetVertexColor(0.36, 0.22, 0.07)
    headerBrush:SetAlpha(0.38)
    Maines_RegisterSurface(headerBrush, "metal", {0.36, 0.22, 0.07})

    local headerGrain = band:CreateTexture(nil, "BACKGROUND", nil, 2)
    headerGrain:SetAllPoints()
    headerGrain:SetTexture(GRAIN_TEXTURE, "REPEAT", "REPEAT")
    headerGrain:SetHorizTile(true)
    headerGrain:SetVertTile(true)
    headerGrain:SetVertexColor(0.30, 0.18, 0.06)
    headerGrain:SetAlpha(0.22)
    Maines_RegisterSurface(headerGrain, "paper", {0.30, 0.18, 0.06})

    local shades = {}
    for _, side in ipairs({"LEFT", "RIGHT"}) do
        local shade = band:CreateTexture(nil, "BACKGROUND", nil, 3)
        shade:SetTexture("Interface\\Buttons\\WHITE8X8")
        shade:SetPoint("TOP" .. side)
        shade:SetPoint("BOTTOM" .. side)
        shade:SetWidth(160)
        shade.side = side
        shades[#shades + 1] = shade
    end

    -- nil = the start brass; otherwise the palette color it is toned toward
    local function paint(r, g, b)
        local lr, lg, lb, hr, hg, hb, sr, sg, sb
        if r then
            lr, lg, lb = unpack(Maines_Look.HoldContrast({Maines_ToneLike(BAND_LOW, r, g, b, BAND_BLEND)}, BAND_LOW, false))
            hr, hg, hb = unpack(Maines_Look.HoldContrast({Maines_ToneLike(BAND_HIGH, r, g, b, BAND_BLEND)}, BAND_HIGH, false))
            sr, sg, sb = Maines_ToneLike(BAND_SHADE, r * 0.3, g * 0.3, b * 0.3, BAND_BLEND)
        else
            lr, lg, lb = BAND_LOW[1], BAND_LOW[2], BAND_LOW[3]
            hr, hg, hb = BAND_HIGH[1], BAND_HIGH[2], BAND_HIGH[3]
            sr, sg, sb = BAND_SHADE[1], BAND_SHADE[2], BAND_SHADE[3]
        end
        headerBg:SetGradient("VERTICAL", CreateColor(lr, lg, lb, 1), CreateColor(hr, hg, hb, 1))
        band.toneLow, band.toneHigh = {lr, lg, lb}, {hr, hg, hb}
        for _, shade in ipairs(shades) do
            local dark, clear = CreateColor(sr, sg, sb, 0.30), CreateColor(sr, sg, sb, 0)
            if shade.side == "LEFT" then
                shade:SetGradient("HORIZONTAL", dark, clear)
            else
                shade:SetGradient("HORIZONTAL", clear, dark)
            end
        end
    end
    paint()
    table.insert(Maines_Textures, {repaint = paint})

    local headerShine = band:CreateTexture(nil, "ARTWORK")
    headerShine:SetTexture("Interface\\Buttons\\WHITE8X8")
    headerShine:SetVertexColor(1, 0.96, 0.85)
    headerShine:SetAlpha(0.35)
    headerShine:SetHeight(1)
    headerShine:SetPoint("TOPLEFT")
    headerShine:SetPoint("TOPRIGHT")

    local headerRule = band:CreateTexture(nil, "ARTWORK")
    headerRule:SetTexture("Interface\\Buttons\\WHITE8X8")
    headerRule:SetVertexColor(ACCENT[1], ACCENT[2], ACCENT[3])
    headerRule:SetAlpha(0.8)
    headerRule:SetHeight(1)
    headerRule:SetPoint("BOTTOMLEFT")
    headerRule:SetPoint("BOTTOMRIGHT")
    Maines_RegisterTexture(headerRule)
end

-- Header: a band of brushed brass across the top (Maines_DressBrassBand above), with the title
-- engraved in the middle.
local HEADER_HEIGHT = 56
local header = CreateFrame("Frame", nil, Maines_Window)
header:SetPoint("TOPLEFT", 3, -3)
header:SetPoint("TOPRIGHT", -3, -3)
header:SetHeight(HEADER_HEIGHT)

Maines_DressBrassBand(header)

-- (Wrapped in do ... end: the main chunk is close to Lua's 200-locals limit, and these
-- header pieces are only needed right here.)
do
    -- The title: letter-spaced capitals in the engraved display face, dark ink with a pale edge
    -- below each stroke so it reads as pressed into the brass.
    local windowTitle = header:CreateFontString(nil, "OVERLAY")
    windowTitle:SetFontObject(Maines_Font_Display)
    windowTitle:SetPoint("CENTER", header, "CENTER", 0, 0)
    windowTitle:SetText("M A I N E S")
    windowTitle:SetTextColor(0.20, 0.11, 0.03)
    windowTitle:SetShadowColor(1, 0.94, 0.78, 0.6)
    windowTitle:SetShadowOffset(0, -1)

    -- Fine engraved flourishes either side of the title: a hairline fading outward, ending in a
    -- small diamond next to the lettering. Drawn, not pictures.
    for _, side in ipairs({-1, 1}) do
        local diamond = header:CreateTexture(nil, "ARTWORK")
        diamond:SetTexture("Interface\\Buttons\\WHITE8X8")
        diamond:SetVertexColor(0.24, 0.13, 0.04)
        diamond:SetSize(5, 5)
        diamond:SetRotation(math.rad(45))
        if side < 0 then
            diamond:SetPoint("RIGHT", windowTitle, "LEFT", -14, -1)
        else
            diamond:SetPoint("LEFT", windowTitle, "RIGHT", 14, -1)
        end
        local line = header:CreateTexture(nil, "ARTWORK")
        line:SetTexture("Interface\\Buttons\\WHITE8X8")
        line:SetHeight(1)
        line:SetWidth(90)
        local ink, clear = CreateColor(0.24, 0.13, 0.04, 0.8), CreateColor(0.24, 0.13, 0.04, 0)
        if side < 0 then
            line:SetPoint("RIGHT", diamond, "LEFT", -4, 0)
            line:SetGradient("HORIZONTAL", clear, ink)
        else
            line:SetPoint("LEFT", diamond, "RIGHT", 4, 0)
            line:SetGradient("HORIZONTAL", ink, clear)
        end
    end

    local windowClose = Maines_MakeCloseButton(header, Maines_Window, function() Maines_HideMainWindow() end)
    windowClose:SetPoint("RIGHT", -SP.l, 0)
end

-- Pages: one per functional area, as a row of tabs under the title, each with Maines' own icon.
-- Each page shows/hides its own panel; the open page's tab is highlighted.
local TAB_DEFS = {
    {key = "main", label = "Main", icon = ICONS .. "main.tga"},
    {key = "phrases", label = "Phrases", icon = ICONS .. "phrases.tga"},
    {key = "animate", label = "Animate", icon = ICONS .. "animate.tga"},
    {key = "badges", label = "Badges", icon = ICONS .. "badges.tga"},
    {key = "filter", label = "Channels", icon = ICONS .. "channels.tga"},
    {key = "behavior", label = "Behavior", icon = ICONS .. "behavior.tga"},
    {key = "cosmetic", label = "Cosmetic", icon = ICONS .. "cosmetic.tga"},
    {key = "help", label = "Help", icon = ICONS .. "help.tga"},
}

local TAB_BAR_HEIGHT = 52
local TAB_HEIGHT = 48
local TAB_GAP = 2
local FOOTER_HEIGHT = 40
local tabBar = CreateFrame("Frame", nil, Maines_Window)
tabBar:SetPoint("TOPLEFT", 3, -HEADER_HEIGHT - 3)
tabBar:SetPoint("TOPRIGHT", -3, -HEADER_HEIGHT - 3)
tabBar:SetHeight(TAB_BAR_HEIGHT)
local tabBarBg = tabBar:CreateTexture(nil, "BACKGROUND")
tabBarBg:SetAllPoints()
tabBarBg:SetTexture("Interface\\Buttons\\WHITE8X8")
Maines_Look.DressBar(tabBar, tabBarBg, 0.78, 1.0)

local contentFrame = CreateFrame("Frame", nil, Maines_Window, "BackdropTemplate")
contentFrame:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, 0)
contentFrame:SetPoint("BOTTOMRIGHT", -3, FOOTER_HEIGHT + WIN.status)
Maines_MakeFlatBackdrop(contentFrame, CONTENT_BG, BORDER_DARK, 1)

local Maines_Panels, Maines_Tabs = {}, {}

local function Maines_ShowPanel(key)
    for k, panel in pairs(Maines_Panels) do
        if k == key then panel:Show() else panel:Hide() end
    end
    for k, btn in pairs(Maines_Tabs) do
        btn:SetSelected(k == key)
    end
end

-- Equal-width tabs filling the row, 8px in from each side, sitting on the strip's bottom edge
-- so the open one runs straight into the page.
local TAB_WIDTH = math.floor((WIN.w - 6 - 16 - TAB_GAP * (#TAB_DEFS - 1)) / #TAB_DEFS)
for i, def in ipairs(TAB_DEFS) do
    local btn = Maines_MakeNavButton(tabBar, TAB_WIDTH, TAB_HEIGHT, def.label, def.icon)
    btn:SetPoint("BOTTOMLEFT", 8 + (i - 1) * (TAB_WIDTH + TAB_GAP), 0)
    btn:SetScript("OnClick", function() Maines_ShowPanel(def.key) end)
    Maines_Tabs[def.key] = btn

    local panel = CreateFrame("Frame", nil, contentFrame)
    panel:SetPoint("TOPLEFT", SP.l, -SP.l)
    panel:SetPoint("BOTTOMRIGHT", -SP.l, SP.l)
    panel:Hide()
    Maines_Panels[def.key] = panel
end
-- A faint engraved divider in the gap between neighbouring tabs: a dark cut with a lit edge.
for i = 1, #TAB_DEFS - 1 do
    local x = 8 + i * (TAB_WIDTH + TAB_GAP) - TAB_GAP
    for k, c in ipairs({{0, 0, 0, 0.38}, {1, 0.92, 0.76, 0.10}}) do
        local line = tabBar:CreateTexture(nil, "ARTWORK")
        line:SetTexture("Interface\\Buttons\\WHITE8X8")
        line:SetVertexColor(c[1], c[2], c[3], c[4])
        line:SetWidth(1)
        line:SetPoint("TOPLEFT", x + k - 1, -10)
        line:SetPoint("BOTTOMLEFT", x + k - 1, 8)
    end
end

-- Footer: the maker's credits, with the GLYPH stamp beside the second line - centered,
-- always visible.
local footerBar = CreateFrame("Frame", nil, Maines_Window)
footerBar:SetPoint("BOTTOMLEFT", 3, 3)
footerBar:SetPoint("BOTTOMRIGHT", -3, 3)
footerBar:SetHeight(FOOTER_HEIGHT - 3)
local footerBg = footerBar:CreateTexture(nil, "BACKGROUND")
footerBg:SetAllPoints()
footerBg:SetTexture("Interface\\Buttons\\WHITE8X8")
-- (do ... end for the same 200-locals reason as the header.)
do
    local footerRule = footerBar:CreateTexture(nil, "ARTWORK")
    footerRule:SetTexture("Interface\\Buttons\\WHITE8X8")
    Maines_Look.DressBar(footerBar, footerBg, 0.75, 1.0)
    Maines_Look.RegisterPlate(footerRule, {BORDER_DARK}, function(c) footerRule:SetVertexColor(c[1], c[2], c[3]) end)
    footerRule:SetHeight(1)
    footerRule:SetPoint("TOPLEFT")
    footerRule:SetPoint("TOPRIGHT")

    local creditsLine1 = footerBar:CreateFontString(nil, "OVERLAY")
    creditsLine1:SetFontObject(Maines_Font_BodySmall)
    creditsLine1:SetPoint("BOTTOM", footerBar, "CENTER", 0, 1)
    creditsLine1:SetJustifyH("CENTER")
    creditsLine1:SetText("Designed by Dominic Hughes / Tuniveza  -  Silvermoon EU, Universe of Warcraft")
    creditsLine1:SetTextColor(PLATE_TEXT[1], PLATE_TEXT[2], PLATE_TEXT[3])

    -- Shifted right by half the stamp's width (+ gap) so stamp and text together stay centered.
    local creditsLine2 = footerBar:CreateFontString(nil, "OVERLAY")
    creditsLine2:SetFontObject(Maines_Font_BodySmall)
    creditsLine2:SetPoint("TOP", footerBar, "CENTER", 10, -2)
    creditsLine2:SetJustifyH("CENTER")
    creditsLine2:SetText("The GLYPH Stamp  -  Coded and Guided by Generative Assistance")
    creditsLine2:SetTextColor(PLATE_TEXT_SOFT[1], PLATE_TEXT_SOFT[2], PLATE_TEXT_SOFT[3])

    -- The stamp's mark (see Maines_MakeGlyphBadge above).
    local footerBadge = Maines_MakeGlyphBadge(footerBar, 12)
    footerBadge:SetPoint("RIGHT", creditsLine2, "LEFT", -8, 0)
end

-- Status line: a slim walnut strip just above the footer that shows the latest message Maines
-- printed to chat (everything sent through ns.Say / ns.Status), so a click on a bracket,
-- channel, style, badge or palette answers right where the click was. Chat still gets every
-- message too. It reads like an engraved readout plate: the slab face with a dark shadow, labels
-- muted, values gold, symbols verdigris, even separators; plain messages are tidied (prefix
-- dropped, spaces collapsed) and tinted by kind. A new message fades in and stays until the
-- next; hovering a line too long to fit shows all of it.
do
    local bar = CreateFrame("Frame", nil, Maines_Window)
    bar:SetPoint("BOTTOMLEFT", footerBar, "TOPLEFT", 0, 0)
    bar:SetPoint("BOTTOMRIGHT", footerBar, "TOPRIGHT", 0, 0)
    bar:SetHeight(WIN.status)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    Maines_Look.DressBar(bar, bg, 0.85, 1.0)

    -- The readout: the chunky slab face with a dark engraved shadow under every stroke.
    local text = bar:CreateFontString(nil, "OVERLAY")
    text:SetFontObject(Maines_Font_Status)
    text:SetPoint("LEFT", SP.xl, 0)
    text:SetPoint("RIGHT", -SP.xl, 0)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetWordWrap(false)
    text:SetMaxLines(1)
    text:SetShadowColor(0, 0, 0, 0.85)
    text:SetShadowOffset(1, -1)

    local fade = text:CreateAnimationGroup()
    local fadeIn = fade:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.3)
    fadeIn:SetSmoothing("OUT")

    -- Colours, all light enough to keep 4.5:1 or better on the strip in every palette (tests/run.lua
    -- checks them on the strip's tones and on deeper and mid shades of every palette's band):
    -- labels a soft muted cream, values warm gold, symbols (bracket characters, a palette's hex)
    -- pale verdigris; plain messages cream, or tinted green / amber / coral when they're a
    -- success / a warning / an error. The separator is a muted brass bullet.
    local COLOR = {
        label = "D9CBAE", value = "FFD27A", symbol = "96E6D6", sep = "C2AC84",
        plain = "EFE6D2", ok = "AEEBA0", warn = "FFB866", error = "FFB4A6",
    }
    ns.StatusColors = COLOR
    local function c(key) return "|cFF" .. COLOR[key] end
    local SEP = "  " .. c("sep") .. "\226\128\162|r  "    -- "  •  ": the same padding everywhere
    local function esc(v) return (tostring(v):gsub("|", "||")) end

    -- Structured messages: label value [symbol] pieces, single spaces inside, SEP between.
    local function build(status)
        local pieces = {}
        for _, part in ipairs(status.parts or {}) do
            local bits = {}
            if part.label then bits[#bits + 1] = c("label") .. esc(part.label) .. "|r" end
            if part.value then bits[#bits + 1] = c("value") .. esc(part.value) .. "|r" end
            if part.symbol then bits[#bits + 1] = c("symbol") .. esc(part.symbol) .. "|r" end
            if part.tag then
                local l, n, r = part.tag[1], part.tag[2], part.tag[3]
                bits[#bits + 1] = c("symbol") .. esc(l) .. "|r" .. c("value") .. esc(n) .. "|r" .. c("symbol") .. esc(r) .. "|r"
            end
            if #bits > 0 then pieces[#pieces + 1] = table.concat(bits, " ") end
        end
        return table.concat(pieces, SEP), status.kind and COLOR[status.kind] and status.kind or "plain"
    end

    -- What kind a plain message is, when its caller didn't say: by its wording.
    local KINDS = {
        {"error", {"can't", "cannot", "refused", "unknown", "invalid", "no such", "isn't available",
            "doesn't let", "too long", "at most", "no badge called", "there's no"}},
        {"warn", {"first", "usage", "nothing", "already have", "is empty", "give ", "pick ", "ignored",
            "reset on load", "ready in", "every 3 minutes", "no saved", "no filter", "no valid", "not set"}},
        {"ok", {"saved", "added", "removed", "updated", "deleted", "is now", "set to", "cleared", "painted",
            "shown", "hidden", "sticky", "playing", "tagging", "tag animation", "steps ", "printed", "listed"}},
    }
    local function classify(plain)
        local low = plain:lower()
        for _, entry in ipairs(KINDS) do
            for _, word in ipairs(entry[2]) do
                if low:find(word, 1, true) then return entry[1] end
            end
        end
        return "plain"
    end

    -- Chat text: the green "Maines:" prefix dropped, whitespace trimmed and collapsed (chat lines use
    -- runs of spaces as separators), first letter capitalised; its own highlights become gold
    -- (cream on an amber/coral line), everything else takes the message's kind colour.
    local function tidy(msg, kind)
        msg = tostring(msg or ""):gsub("^|c%x%x%x%x%x%x%x%xMaines|r:%s*", "")
        msg = msg:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
        msg = msg:gsub("^(%l)", string.upper)
        local plain = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        kind = (kind and COLOR[kind]) and kind or classify(plain)
        local hi = (kind == "warn" or kind == "error") and c("plain") or c("value")
        return (msg:gsub("|c%x%x%x%x%x%x%x%x", hi)), kind
    end

    local function show(str, colorKey)
        local r, g, b = Maines_HexToRGB(COLOR[colorKey])
        text:SetText(str)
        text:SetTextColor(r, g, b)
        text.kind = colorKey
    end
    ns.OnStatus = function(msg, kind)
        if type(msg) == "table" then show(build(msg)) else show(tidy(msg, kind)) end
        fade:Stop()
        fade:Play()
    end
    if ns.lastStatus then
        ns.OnStatus(ns.lastStatus, ns.lastStatusKind)
    else
        show("Messages from Maines show up here, and in chat.", "label")
    end

    bar:EnableMouse(true)
    bar:SetScript("OnEnter", function(self)
        if text.IsTruncated and text:IsTruncated() then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(text:GetText(), 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    bar:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- Dragging the strip still moves the window, like the rest of it.
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function() Maines_Window:StartMoving() end)
    bar:SetScript("OnDragStop", function() Maines_Window:StopMovingOrSizing() end)
    ns.StatusBar, ns.StatusText = bar, text
end

-- Everything the feature files (phrases.lua, animate.lua, badges.lua) need to build their own
-- pages in the same style.
ns.Panels = Maines_Panels
ns.ShowPanel = Maines_ShowPanel
ns.MakeButton = Maines_MakeButton
ns.MakeHeading = Maines_MakeHeading
ns.MakeFlatBackdrop = Maines_MakeFlatBackdrop
ns.RegisterTexture = Maines_RegisterTexture
ns.Palettes = Color_Palettes
ns.ApplyPaletteColor = Maines_ApplyPaletteColor
ns.ActivePalette = function() return Maines_ActivePalette end
ns.TonePlateBackdrop = Maines_Look.TonePlateBackdrop
ns.Sheen = Maines_Look.SHEEN
ns.TabBar, ns.FooterBar = tabBar, footerBar
ns.Fonts = {
    Title = ns.TitleFont, Header = Maines_Font_Header, Body = Maines_Font_Body,
    BodySmall = Maines_Font_BodySmall, Button = Maines_Font_Button,
}
ns.Colors = {
    INK = INK, INK_SOFT = INK_SOFT, ACCENT = ACCENT, CONTENT_BG = CONTENT_BG, PLATE_BG = PLATE_BG,
    BORDER_DARK = BORDER_DARK, HEX_TEXT = HEX_TEXT, HEX_SOFT = HEX_SOFT, HEX_ACCENT = HEX_ACCENT,
}
ns.Bracket_Types = Bracket_Types
ns.PANEL_WIDTH = WIN.w - 6 - 2 * SP.l
ns.SP = SP
ns.READ_W = 600 -- intro paragraphs: narrower than the page so they wrap into even lines
-- Narrows a wrapped paragraph (at most maxW wide) so its lines come out about the same length,
-- instead of a full line and a lone word or two under it.
function ns.BalanceText(fs, maxW)
    fs:SetWidth(maxW)
    local full = fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth() or 0
    if not full or full <= maxW then return end
    local lines = math.ceil(full / maxW)
    fs:SetWidth(math.min(maxW, math.ceil(full / lines) + SP.xl))
end

-- Small builders shared by the pages below.
-- A text block in one of the UI fonts, ink-coloured unless told otherwise, `width` wide (or as
-- wide as its text when width is nil).
local function Maines_Text(parent, font, text, color, width)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(font)
    if width then fs:SetWidth(width) end
    fs:SetJustifyH("CENTER")
    fs:SetText(text or "")
    color = color or INK
    fs:SetTextColor(color[1], color[2], color[3])
    return fs
end

-- A checkbox with its label to the right (s apart). Returns the checkbox and the row's width;
-- the caller places the checkbox ("TOPLEFT" on the page), the label follows it.
local CHECK_SIZE = 24
local function Maines_MakeCheckRow(parent, text)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(CHECK_SIZE, CHECK_SIZE)
    local lbl = Maines_Text(parent, Maines_Font_Body, text)
    lbl:SetPoint("LEFT", cb, "RIGHT", SP.s, 0)
    cb.label = lbl
    return cb, CHECK_SIZE + SP.s + lbl:GetStringWidth()
end

-- Several check rows stacked as one block, checkboxes aligned on one left edge, the block
-- centred on the page. Returns the checkboxes (in order) and the y below the block.
local function Maines_CheckColumn(parent, y, texts)
    local checks, widest = {}, 0
    for i, t in ipairs(texts) do
        local cb, w = Maines_MakeCheckRow(parent, t)
        checks[i] = cb
        widest = math.max(widest, w)
    end
    local x0 = math.floor((ns.PANEL_WIDTH - widest) / 2)
    for i, cb in ipairs(checks) do
        cb:SetPoint("TOPLEFT", x0, y - (i - 1) * (CHECK_SIZE + SP.m))
    end
    return checks, y - #checks * (CHECK_SIZE + SP.m) + SP.m
end

local INPUT_H, BUTTON_H = 24, 30
ns.INPUT_H, ns.BUTTON_H = INPUT_H, BUTTON_H

-- ---- Main panel: name + bracket (mirrors /mains and /main) ----
do
    local mainPanel = Maines_Panels.main
    local W = ns.PANEL_WIDTH
    local my = 0

    local nameLabel = Maines_Text(mainPanel, Maines_Font_Header, "Main character name:", INK, W)
    nameLabel:SetPoint("TOP", 0, my)
    my = my - nameLabel:GetStringHeight() - SP.s

    local nameBox = CreateFrame("EditBox", nil, mainPanel, "InputBoxTemplate")
    nameBox:SetSize(260, INPUT_H)
    nameBox:SetAutoFocus(false)
    nameBox:SetJustifyH("CENTER")
    nameBox:SetMaxLetters(24)
    nameBox:SetPoint("TOP", 0, my)
    my = my - INPUT_H - SP.xl

    local bracketLabel = Maines_Text(mainPanel, Maines_Font_Header,
        "Bracket style - click one to apply it instantly, or select one and use Apply below:", INK, W)
    bracketLabel:SetPoint("TOP", 0, my)
    my = my - bracketLabel:GetStringHeight() - SP.m

    local Bracket_Order = {"[", "(", "<", "{", ".", ":", "-", "~", "@", "#"}
    ns.Bracket_Order = Bracket_Order
    local BRACKET_AREA_WIDTH = W - 2 * SP.xl
    local bracketButtons = {}
    local selectedKey
    local bracketRowTop = my
    local layout
    local customLeft, customRight

    for _, key in ipairs(Bracket_Order) do
        local def = Bracket_Types[key]
        local btn = Maines_MakeButton(mainPanel, 70, BUTTON_H, def[1] .. "M" .. def[2])
        btn:SetScript("OnClick", function()
            local nm = strtrim(nameBox:GetText() or "")
            if nm == "" then
                ns.Say("|cFF00FF00Maines|r: type a name first")
                return
            end
            selectedKey = key
            SlashCmdList["MAINS"](nm .. " " .. key)
            Maines_RefreshWindow()
        end)
        bracketButtons[key] = btn
    end

    local applyBtn = Maines_MakeButton(mainPanel, 120, BUTTON_H, "Apply")
    applyBtn:SetScript("OnClick", function()
        local nm = strtrim(nameBox:GetText() or "")
        if nm == "" then
            ns.Say("|cFF00FF00Maines|r: type a name first")
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
        elseif selectedKey then
            SlashCmdList["MAINS"](nm .. " " .. selectedKey)
        else
            ns.Say("|cFF00FF00Maines|r: pick a bracket above, or enter a custom symbol below, first")
            return
        end
        Maines_RefreshWindow()
    end)

    local customLabel = Maines_Text(mainPanel, Maines_Font_Header,
        "Custom bracket (left symbol, optional right symbol):", INK, W)

    -- The two symbol boxes are centred as one unit (56 + l gap + 56), not left-hung.
    local CUSTOM_W = 56
    customLeft = CreateFrame("EditBox", nil, mainPanel, "InputBoxTemplate")
    customLeft:SetSize(CUSTOM_W, INPUT_H)
    customLeft:SetAutoFocus(false)
    customLeft:SetJustifyH("CENTER")
    customRight = CreateFrame("EditBox", nil, mainPanel, "InputBoxTemplate")
    customRight:SetSize(CUSTOM_W, INPUT_H)
    customRight:SetAutoFocus(false)
    customRight:SetJustifyH("CENTER")
    customRight:SetPoint("LEFT", customLeft, "RIGHT", SP.l, 0)

    local previewLabel = Maines_Text(mainPanel, Maines_Font_Header,
        "Currently saved - this is what your chat will look like:", INK, W)
    local previewFS = Maines_Text(mainPanel, Maines_Font_Body, "", INK, W)

    -- Lays out everything from the bracket grid downward: bracket buttons live-update to show
    -- <left><current name><right> and reflow into as many rows as needed once names get long,
    -- and everything below the grid slides to follow it. Every row is centred on the page.
    layout = function()
        local name = strtrim(nameBox:GetText() or "")
        local previewName = name ~= "" and name or "Name"

        -- Pass 1: which row each button lands in, and how wide it needs to be.
        local rows = {{}}
        local x, row = 0, 1
        for _, key in ipairs(Bracket_Order) do
            local def = Bracket_Types[key]
            local btn = bracketButtons[key]
            btn:SetText(def[1] .. previewName .. def[2])
            local w = math.max(56, math.min(220, btn.text:GetStringWidth() + 2 * SP.l))
            if x > 0 and x + w > BRACKET_AREA_WIDTH then
                x, row = 0, row + 1
                rows[row] = {}
            end
            table.insert(rows[row], {btn = btn, w = w})
            x = x + w + SP.s
        end

        -- Pass 2: centre each row on its own, so a short last row isn't stranded at the left.
        for rowIndex, items in ipairs(rows) do
            local rowWidth = -SP.s
            for _, item in ipairs(items) do rowWidth = rowWidth + item.w + SP.s end
            local cx = -rowWidth / 2
            for _, item in ipairs(items) do
                item.btn:SetSize(item.w, BUTTON_H)
                item.btn:ClearAllPoints()
                item.btn:SetPoint("TOP", cx + item.w / 2, bracketRowTop - (rowIndex - 1) * (BUTTON_H + SP.s))
                cx = cx + item.w + SP.s
            end
        end
        local y = bracketRowTop - #rows * (BUTTON_H + SP.s) - SP.xs

        applyBtn:ClearAllPoints()
        applyBtn:SetPoint("TOP", 0, y)
        y = y - BUTTON_H - SP.xl

        customLabel:ClearAllPoints()
        customLabel:SetPoint("TOP", 0, y)
        y = y - customLabel:GetStringHeight() - SP.s

        customLeft:ClearAllPoints()
        customLeft:SetPoint("TOP", -(CUSTOM_W + SP.l) / 2, y)
        y = y - INPUT_H - SP.xl

        previewLabel:ClearAllPoints()
        previewLabel:SetPoint("TOP", 0, y)
        y = y - previewLabel:GetStringHeight() - SP.s

        previewFS:ClearAllPoints()
        previewFS:SetPoint("TOP", 0, y)
    end

    nameBox:SetScript("OnTextChanged", function() layout() end)
    layout()

    table.insert(ns.RefreshHooks, function()
        local name = _G["Maines_Name_DB"] or ""
        local left = _G["Maines_Bracket_Left_DB"] or ""
        local right = _G["Maines_Bracket_Right_DB"] or ""
        nameBox:SetText(name)
        layout()

        selectedKey = nil
        for key, btn in pairs(bracketButtons) do
            local def = Bracket_Types[key]
            if left ~= "" and def[1] == left and def[2] == right then
                btn:Disable()
                selectedKey = key
            else
                btn:Enable()
            end
        end

        if name ~= "" and left ~= "" then
            previewFS:SetText(HEX_ACCENT .. left .. name .. right .. "|r " .. HEX_TEXT .. "Hello there, guildies!|r")
        else
            previewFS:SetText(HEX_SOFT .. "(not set yet - pick a name and bracket above)|r")
        end
    end)
end

-- ---- Filter panel: channels + mode + sticky (mirrors /mainchat) ----
do
    local filterPanel = Maines_Panels.filter
    local W = ns.PANEL_WIDTH
    local fy = 0

    local filterIntro = Maines_Text(filterPanel, Maines_Font_Body, "Check the channels you care about, then pick "
        .. "a mode below. Leave everything unchecked to tag every channel.", INK_SOFT, ns.READ_W)
    filterIntro:SetPoint("TOP", 0, fy)
    ns.BalanceText(filterIntro, ns.READ_W)
    fy = fy - filterIntro:GetStringHeight() - SP.l

    local Channel_Labels = {
        SAY = "Say", YELL = "Yell", EMOTE = "Emote", PARTY = "Party", PARTY_LEADER = "Party (Leader)",
        RAID = "Raid", RAID_LEADER = "Raid (Leader)", RAID_WARNING = "Raid Warning",
        INSTANCE_CHAT = "Instance", INSTANCE_CHAT_LEADER = "Instance (Leader)",
        GUILD = "Guild", OFFICER = "Officer", WHISPER = "Whisper", BN_WHISPER = "Battle.net Whisper",
        CHANNEL = "Custom Channel", COMMUNITIES_CHANNEL = "Community", VOICE_TEXT = "Voice Text",
        AFK = "AFK", DND = "DND",
    }

    -- Three columns, each as wide as the longest label, checkboxes aligned down each column and
    -- the grid centred as a block.
    local channelChecks = {}
    local COLS, ROW_STEP = 3, CHECK_SIZE + SP.s
    local widest = 0
    for _, chan in ipairs(Channel_Types) do
        local cb, w = Maines_MakeCheckRow(filterPanel, Channel_Labels[chan] or chan)
        widest = math.max(widest, w)
        cb:SetScript("OnClick", function(self)
            SlashCmdList["MAINCHAT"]((self:GetChecked() and "+" or "-") .. chan)
            Maines_RefreshWindow()
        end)
        channelChecks[#channelChecks + 1] = cb
        channelChecks[chan] = cb
    end
    local colW = widest + SP.xl
    local gridX = math.floor((W - (COLS * colW - SP.xl)) / 2)
    for i, cb in ipairs(channelChecks) do
        local col, row = (i - 1) % COLS, math.floor((i - 1) / COLS)
        cb:SetPoint("TOPLEFT", gridX + col * colW, fy - row * ROW_STEP)
    end
    fy = fy - math.ceil(#Channel_Types / COLS) * ROW_STEP - SP.l

    -- Mode: the label and its two buttons centred together as one row.
    local modeLabel = Maines_Text(filterPanel, Maines_Font_Header, "Filter mode:")
    local modeIncludeBtn = Maines_MakeButton(filterPanel, 0, BUTTON_H, "Only checked")
    modeIncludeBtn:SetPoint("LEFT", modeLabel, "RIGHT", SP.m, 0)
    modeIncludeBtn:SetScript("OnClick", function() SlashCmdList["MAINCHAT"]("mode include"); Maines_RefreshWindow() end)
    local modeExcludeBtn = Maines_MakeButton(filterPanel, 0, BUTTON_H, "All except checked")
    modeExcludeBtn:SetPoint("LEFT", modeIncludeBtn, "RIGHT", SP.s, 0)
    modeExcludeBtn:SetScript("OnClick", function() SlashCmdList["MAINCHAT"]("mode exclude"); Maines_RefreshWindow() end)
    local modeRowWidth = modeLabel:GetStringWidth() + SP.m + modeIncludeBtn:GetWidth() + SP.s + modeExcludeBtn:GetWidth()
    modeLabel:SetPoint("TOP", -modeRowWidth / 2 + modeLabel:GetStringWidth() / 2, fy - (BUTTON_H - modeLabel:GetStringHeight()) / 2)
    fy = fy - BUTTON_H - SP.m

    local sticky
    sticky, fy = Maines_CheckColumn(filterPanel, fy, {"Keep this filter across reloads (sticky)"})
    local stickyCheck = sticky[1]
    stickyCheck:SetScript("OnClick", function() SlashCmdList["MAINCHAT"]("sticky"); Maines_RefreshWindow() end)
    fy = fy - SP.m

    local clearFilterBtn = Maines_MakeButton(filterPanel, 0, BUTTON_H, "Clear Filter (Tag All)")
    clearFilterBtn:SetPoint("TOP", 0, fy)
    clearFilterBtn:SetScript("OnClick", function() SlashCmdList["MAINCHAT"](""); Maines_RefreshWindow() end)
    fy = fy - BUTTON_H - SP.m

    local filterStatus = Maines_Text(filterPanel, Maines_Font_Body, "", INK_SOFT, W)
    filterStatus:SetPoint("TOP", 0, fy)

    table.insert(ns.RefreshHooks, function()
        local filter = Maines_GetChatFilter()
        local mode = Maines_ChatFilterMode_DB or "include"
        for _, chan in ipairs(Channel_Types) do
            local checked = false
            for _, v in ipairs(filter) do if v == chan then checked = true; break end end
            channelChecks[chan]:SetChecked(checked)
        end
        if mode == "exclude" then
            modeExcludeBtn:Disable(); modeIncludeBtn:Enable()
        else
            modeIncludeBtn:Disable(); modeExcludeBtn:Enable()
        end
        stickyCheck:SetChecked(Maines_ChatFilterSticky_DB and true or false)
        if #filter == 0 then
            filterStatus:SetText("Currently: tagging every channel (no filter set).")
        elseif mode == "exclude" then
            filterStatus:SetText("Currently: tagging every channel EXCEPT " .. table.concat(filter, ", ") .. ".")
        else
            filterStatus:SetText("Currently: tagging ONLY " .. table.concat(filter, ", ") .. ".")
        end
    end)
end

-- ---- Behavior panel: on-main detection + debug (mirrors /mainhide, /mainshow, /maindebug) ----
do
    local behaviorPanel = Maines_Panels.behavior
    local checks = Maines_CheckColumn(behaviorPanel, 0, {
        "Hide the tag while playing my main (alts are always tagged)",
        "Print debug info for every tagging decision",
    })
    local hideOnMainCheck, debugCheck = checks[1], checks[2]
    hideOnMainCheck:SetScript("OnClick", function(self)
        if self:GetChecked() then SlashCmdList["MAINHIDE"]() else SlashCmdList["MAINSHOW"]() end
        Maines_RefreshWindow()
    end)
    debugCheck:SetScript("OnClick", function() SlashCmdList["MAINDEBUG"](); Maines_RefreshWindow() end)

    table.insert(ns.RefreshHooks, function()
        hideOnMainCheck:SetChecked(Maines_HideOnMain_DB and true or false)
        debugCheck:SetChecked(Maines_Debug and true or false)
    end)
end

-- ---- Cosmetic panel: minimap + music + colors (mirrors /mainmap, /mainmusic, /maincolor) ----
do
    local cosmeticPanel = Maines_Panels.cosmetic
    local W = ns.PANEL_WIDTH
    local cy = 0

    -- The minimap checkbox and the music button share the first row, centred together.
    local minimapCheck, minimapW = Maines_MakeCheckRow(cosmeticPanel, "Show minimap icon")
    minimapCheck:SetScript("OnClick", function() SlashCmdList["MAINMAP"](); Maines_RefreshWindow() end)
    local musicBtn = Maines_MakeButton(cosmeticPanel, 0, BUTTON_H, "Replay Intro Music")
    musicBtn:SetScript("OnClick", function()
        SlashCmdList["MAINMUSIC"]()
        PlaySoundFile("Interface\\Addons\\Maines\\music\\maines_intro.mp3")
        ns.Status("|cFF00FF00Maines|r: playing the intro music")
    end)
    local rowW = minimapW + SP.xl + musicBtn:GetWidth()
    local x0 = math.floor((W - rowW) / 2)
    minimapCheck:SetPoint("TOPLEFT", x0, cy - (BUTTON_H - CHECK_SIZE) / 2)
    musicBtn:SetPoint("TOPLEFT", x0 + minimapW + SP.xl, cy)
    cy = cy - BUTTON_H - SP.xl

    local paletteLabel = Maines_Text(cosmeticPanel, Maines_Font_Header,
        "Recolor the UI - click a swatch, or roll one at random:", INK, W)
    paletteLabel:SetPoint("TOP", 0, cy)
    cy = cy - paletteLabel:GetStringHeight() - SP.m

    -- Each row: the palette's name in a column as wide as the longest name, then its 5 swatches,
    -- so the swatch columns line up row to row; the whole block is centred.
    local SWATCH, SWATCH_GAP = 22, SP.xs
    local labels, nameW = {}, 0
    for i, palette in ipairs(Color_Palettes) do
        labels[i] = Maines_Text(cosmeticPanel, Maines_Font_BodySmall, palette.name, INK_SOFT)
        nameW = math.max(nameW, labels[i]:GetStringWidth())
    end
    nameW = math.ceil(nameW)
    local blockW = nameW + SP.m + 5 * SWATCH + 4 * SWATCH_GAP
    local bx = math.floor((W - blockW) / 2)
    for i, palette in ipairs(Color_Palettes) do
        local rowLbl = labels[i]
        rowLbl:SetWidth(nameW)
        rowLbl:SetJustifyH("LEFT")
        rowLbl:SetPoint("TOPLEFT", bx, cy - (SWATCH - rowLbl:GetStringHeight()) / 2)
        for j, hex in ipairs(palette.colors) do
            local r, g, b = Maines_HexToRGB(hex)
            local sw = Maines_MakeSwatch(cosmeticPanel, r, g, b)
            sw:SetSize(SWATCH, SWATCH)
            sw:SetPoint("TOPLEFT", bx + nameW + SP.m + (j - 1) * (SWATCH + SWATCH_GAP), cy)
            sw:SetScript("OnClick", function() Maines_ApplyPaletteColor(r, g, b, hex, palette.name) end)
            sw:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText("#" .. hex)
                GameTooltip:Show()
            end)
            sw:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        cy = cy - SWATCH - SWATCH_GAP
    end
    cy = cy - SP.l

    local randomBtn = Maines_MakeButton(cosmeticPanel, 0, BUTTON_H, "Random Palette")
    randomBtn:SetPoint("TOP", 0, cy)
    randomBtn:SetScript("OnClick", function() SlashCmdList["MAINCOLOR"]() end)

    table.insert(ns.RefreshHooks, function()
        local mmHidden = Maines_DB and Maines_DB.minimap and Maines_DB.minimap.hide
        minimapCheck:SetChecked(not mmHidden)
    end)
end

-- ---- Help panel: points at the full reference window/chat dump (mirrors /mainhelp) ----
do
    local helpTabPanel = Maines_Panels.help
    local hy = 0

    local helpIntro = Maines_Text(helpTabPanel, Maines_Font_Body, "Every command has a page in this window. For "
        .. "the full written reference - icons, examples, and notes - open the dedicated help window, or print "
        .. "the same thing to chat.", INK_SOFT, ns.READ_W)
    helpIntro:SetPoint("TOP", 0, hy)
    ns.BalanceText(helpIntro, ns.READ_W)
    hy = hy - helpIntro:GetStringHeight() - SP.xl

    local openHelpBtn = Maines_MakeButton(helpTabPanel, 300, BUTTON_H, "Open Full Command Reference")
    openHelpBtn:SetPoint("TOP", 0, hy)
    openHelpBtn:SetScript("OnClick", function()
        Maines_BuildHelpContent()
        Help_Frame:Show()
    end)
    hy = hy - BUTTON_H - SP.m

    local printHelpBtn = Maines_MakeButton(helpTabPanel, 300, BUTTON_H, "Print Reference to Chat")
    printHelpBtn:SetPoint("TOP", 0, hy)
    printHelpBtn:SetScript("OnClick", function() Maines_PrintHelpToChat() end)
end

Maines_ShowPanel("main")

-- Pulls every saved variable the slash commands above already read/write and reflects it into
-- the widgets: each page (here and in phrases.lua, animate.lua, badges.lua) registers its own
-- refresh in ns.RefreshHooks. Deliberately a plain global (not local) - several OnClick handlers
-- above reference it as a forward reference.
function Maines_RefreshWindow()
    for _, refresh in ipairs(ns.RefreshHooks) do refresh() end
end

-- HookScript, not SetScript: SetScript would also wipe the fade-in hooked on above.
Maines_Window:HookScript("OnShow", Maines_RefreshWindow)

-- ==========================================================================
-- A note from the author (/mainnote)
-- ==========================================================================
-- Shown once, a few seconds after logging in, the first time each new release runs (keyed by
-- NOTE_VERSION in Maines_DB), and any time after with /mainnote. Each release can update the
-- message and the "New in ..." list here; bumping NOTE_VERSION shows it to everyone once more.
local NOTE_VERSION = "GLYPH"
local NOTE_TITLE = "A Note From Tuniveza"
local NOTE_MESSAGE = {
    "Hey Players Who Use My Maines Addon;",
    "Thank you So much and am Still Updating This Project As You Can See There Will Be "
        .. "Dramatic Pleasurable Improvements Over-Time For Now Am BackLogged with So Many Other Projects:",
}
local NOTE_PROJECTS = {
    "Nova Hub for My Relative At Novacane Studios",
    "Generative Video-Game Experiments",
    "Code Editor Called Symbolizer",
    "Predetermination of Other Future Projects ; Etc",
}
local NOTE_CLOSING = {"That's Why It Has Taken So Long", "Please Bare With Me"}
local NOTE_SIGNATURE = "- Dominic Hughes / Zuniversa / Tuniveza"
local NOTE_NEW = {
    "Saved phrases on a shortcut key (Phrases page)",
    "An animated tag that changes with each message (Animate page)",
    "Textual Badges: whole text pictures sent to chat (Badges page)",
    "A new hand-made look, with its own icons - not the final look by a long stretch, but a nice "
        .. "make-over to keep it fun and interesting till I can sit down and properly update it full on, "
        .. "like I did in the early versions",
}

local NOTE_WIDTH = 540
local NOTE_TEXT_WIDTH = NOTE_WIDTH - 2 * (SP.xl + 6)

local Note_Frame = CreateFrame("Frame", "Maines_NoteFrame", UIParent, "BackdropTemplate")
Note_Frame:SetWidth(NOTE_WIDTH)
Note_Frame:SetPoint("CENTER", 0, 40)
Note_Frame:SetFrameStrata("FULLSCREEN_DIALOG")
Note_Frame:SetClampedToScreen(true)
Note_Frame:SetMovable(true)
Note_Frame:EnableMouse(true)
Note_Frame:RegisterForDrag("LeftButton")
Note_Frame:SetScript("OnDragStart", Note_Frame.StartMoving)
Note_Frame:SetScript("OnDragStop", Note_Frame.StopMovingOrSizing)
Note_Frame:Hide()
Maines_MakeFlatBackdrop(Note_Frame, CONTENT_BG, BORDER_DARK, 3)
Maines_Look.AddFrameBorder(Note_Frame)
Maines_Look.AddSheen(Note_Frame)
Maines_AddOuterGlow(Note_Frame, 22, 0.35, Maines_Look.FRAME_OUT - 5)
-- Escape closes it, like Blizzard's own dialogs.
if UISpecialFrames then table.insert(UISpecialFrames, "Maines_NoteFrame") end

local noteFade = Note_Frame:CreateAnimationGroup()
local noteFadeIn = noteFade:CreateAnimation("Alpha")
noteFadeIn:SetFromAlpha(0)
noteFadeIn:SetToAlpha(1)
noteFadeIn:SetDuration(0.25)
noteFadeIn:SetSmoothing("OUT")
Note_Frame:HookScript("OnShow", function() noteFade:Play() end) -- hooked: the frame border refits on show too

local noteBand = CreateFrame("Frame", nil, Note_Frame)
noteBand:SetPoint("TOPLEFT", 3, -3)
noteBand:SetPoint("TOPRIGHT", -3, -3)
noteBand:SetHeight(52)
Maines_DressBrassBand(noteBand)

local noteTitle = noteBand:CreateFontString(nil, "OVERLAY")
noteTitle:SetFontObject(Maines_Font_Heading)
noteTitle:SetPoint("CENTER", 0, 0)
noteTitle:SetText(NOTE_TITLE)
noteTitle:SetTextColor(0.20, 0.11, 0.03)
noteTitle:SetShadowColor(1, 0.94, 0.78, 0.6)
noteTitle:SetShadowOffset(0, -1)

local noteClose = Maines_MakeCloseButton(noteBand, Note_Frame)
noteClose:SetPoint("RIGHT", -SP.m, 0)

-- The body: one centered column of text blocks, stacked top to bottom.
local noteY = -52 - SP.l - SP.xs
local function NoteText(text, font, color, gapAfter)
    local fs = Note_Frame:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(font)
    fs:SetWidth(NOTE_TEXT_WIDTH)
    fs:SetJustifyH("CENTER")
    fs:SetPoint("TOP", 0, noteY)
    fs:SetText(text)
    ns.BalanceText(fs, NOTE_TEXT_WIDTH)
    fs:SetTextColor(color[1], color[2], color[3])
    noteY = noteY - fs:GetStringHeight() - (gapAfter or SP.s)
    return fs
end

-- A short fading rule with a diamond in the middle, between sections.
local function NoteDivider()
    noteY = noteY - SP.xs
    local diamond = Note_Frame:CreateTexture(nil, "ARTWORK")
    diamond:SetTexture("Interface\\Buttons\\WHITE8X8")
    diamond:SetVertexColor(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3])
    diamond:SetSize(5, 5)
    diamond:SetRotation(math.rad(45))
    diamond:SetPoint("TOP", 0, noteY)
    for _, side in ipairs({-1, 1}) do
        local line = Note_Frame:CreateTexture(nil, "ARTWORK")
        line:SetTexture("Interface\\Buttons\\WHITE8X8")
        line:SetSize(140, 1)
        local ink, clear = CreateColor(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3], 0.8), CreateColor(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3], 0)
        if side < 0 then
            line:SetPoint("RIGHT", diamond, "LEFT", -6, 0)
            line:SetGradient("HORIZONTAL", clear, ink)
        else
            line:SetPoint("LEFT", diamond, "RIGHT", 6, 0)
            line:SetGradient("HORIZONTAL", ink, clear)
        end
    end
    noteY = noteY - SP.l - SP.xs
end

NoteText(NOTE_MESSAGE[1], Maines_Font_Header, INK, SP.s)
NoteText(NOTE_MESSAGE[2], Maines_Font_Body, INK, SP.m)
for i, project in ipairs(NOTE_PROJECTS) do
    NoteText(HEX_ACCENT .. "-|r  " .. project .. "  " .. HEX_ACCENT .. "-|r", Maines_Font_Body, INK, i == #NOTE_PROJECTS and SP.m or SP.xs)
end
NoteText(NOTE_CLOSING[1], Maines_Font_Body, INK, SP.xs)
NoteText(NOTE_CLOSING[2], Maines_Font_Header, INK, SP.s)
NoteText(NOTE_SIGNATURE, Maines_Font_BodySmall, INK_SOFT, SP.m)
NoteDivider()
NoteText("New in " .. NOTE_VERSION, Maines_Font_Heading, INK, SP.s)
for i, line in ipairs(NOTE_NEW) do
    NoteText(line, Maines_Font_Body, INK_SOFT, i == #NOTE_NEW and SP.m or SP.xs)
end
NoteDivider()
NoteText("Type " .. HEX_ACCENT .. "/mainnote|r any time to read this again - news and changes "
    .. "for each update will be here.", Maines_Font_BodySmall, INK_SOFT, SP.l)

local noteOk = Maines_MakeButton(Note_Frame, 180, 30, "Thank you!")
noteOk:SetPoint("TOP", 0, noteY)
noteOk:SetScript("OnClick", function() Note_Frame:Hide() end)
noteY = noteY - 30 - SP.xl
Note_Frame:SetHeight(-noteY)
Note_Frame.maines_frame.fit()

function Maines_ShowNote()
    Maines_DB = Maines_DB or {}
    Maines_DB.noteSeen = NOTE_VERSION
    Note_Frame:Show()
end

SLASH_MAINNOTE1 = "/mainnote"
SlashCmdList["MAINNOTE"] = function() Maines_ShowNote() end

-- First run of this release: show it once, a few seconds after the loading screen, so it
-- doesn't land on top of everything else that pops up at login.
local noteWatcher = CreateFrame("Frame")
noteWatcher:RegisterEvent("PLAYER_LOGIN")
noteWatcher:SetScript("OnEvent", function()
    if Maines_DB and Maines_DB.noteSeen == NOTE_VERSION then return end
    C_Timer.After(4, function()
        if not (Maines_DB and Maines_DB.noteSeen == NOTE_VERSION) then Maines_ShowNote() end
    end)
end)

-- /maincolor's choice survives /reload: once the saved variables are in (ADDON_LOADED, after
-- every file of the add-on has built its UI), put the remembered palette back before the
-- window is ever shown.
do
    local paletteWatcher = CreateFrame("Frame")
    paletteWatcher:RegisterEvent("ADDON_LOADED")
    paletteWatcher:SetScript("OnEvent", function(self, _, name)
        if name ~= "Maines" then return end
        self:UnregisterEvent("ADDON_LOADED")
        Maines_Look.RestorePalette()
    end)
end
