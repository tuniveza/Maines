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
      uses). Maines_MakeFontObject() falls back to Blizzard's FRIZQT__ if the file is ever
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
--   Fira Sans       - labels (SemiBold) and body/help text (Medium): thick, open, readable small
--   Bree Serif      - buttons and tabs (a chunky, friendly slab)
-- Falls back to Blizzard's own FRIZQT__ if a font file is ever missing for some reason (a
-- corrupt install, a manual file deletion) so the UI degrades instead of erroring.
local FONT_DIR = "Interface\\AddOns\\Maines\\fonts\\"
local FONT_DISPLAY = FONT_DIR .. "newrocker\\NewRocker-Regular.ttf"
local FONT_HEADING = FONT_DIR .. "vollkornsc\\VollkornSC-Bold.ttf"
local FONT_LABEL = FONT_DIR .. "firasans\\FiraSans-SemiBold.ttf"
local FONT_BODY = FONT_DIR .. "firasans\\FiraSans-Medium.ttf"
local FONT_BUTTON = FONT_DIR .. "breeserif\\BreeSerif-Regular.ttf"

local function Maines_MakeFontObject(name, path, size, flags)
    local font = CreateFont(name)
    if not font:SetFont(path, size, flags) then
        font:SetFont("Fonts\\FRIZQT__.TTF", size, flags)
    end
    return font
end

local Maines_Font_Title = Maines_MakeFontObject("Maines_Font_Title", FONT_DISPLAY, 24, "")
local Maines_Font_Display = Maines_MakeFontObject("Maines_Font_Display", FONT_DISPLAY, 30, "")
local Maines_Font_Heading = Maines_MakeFontObject("Maines_Font_Heading", FONT_HEADING, 17, "")
local Maines_Font_Header = Maines_MakeFontObject("Maines_Font_Header", FONT_LABEL, 13, "")
local Maines_Font_Body = Maines_MakeFontObject("Maines_Font_Body", FONT_BODY, 12, "")
local Maines_Font_BodySmall = Maines_MakeFontObject("Maines_Font_BodySmall", FONT_BODY, 10, "")
local Maines_Font_Button = Maines_MakeFontObject("Maines_Font_Button", FONT_BUTTON, 12, "")

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
-- Maines' own painted square icons (tools/make_icons.py), WoW ability-icon style with their own
-- bevelled frame. Never tinted a colour and never registered for /maincolor (an unselected tab
-- only darkens its icon to a neutral grey).
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
            entry.frameBorder(surfaceKey)
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
        print(("|cFF00FF00Maines|r: painted #%s from \"%s\""):format(hex, label))
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

-- A window's frame: a carved / forged border drawn just outside the window, one style per
-- palette (textures/frames/<key>/ from tools/make_textures.py; "brass" is the start look's
-- riveted brass). Built the way Blizzard's dialog borders are - four corner pieces and four
-- edge strips - but from the add-on's own textures: FRAME_SIZE units thick, FRAME_OUT of it
-- outside the window, so the rest only covers the window's own thin edge, never its content.
-- The strips repeat every FRAME_TILE units through texture coordinates past 1 (wrap mode
-- REPEAT), rounded to a whole number of repeats so the pattern meets each corner cleanly.
do
    local FRAMES = TEXTURES .. "frames\\"
    local FRAME_SIZE, FRAME_OUT, FRAME_TILE = 16, 13, 64
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
        -- nil = the start look's brass frame
        local function dress(key)
            for _, name in ipairs(FRAME_PIECES) do
                p[name]:SetTexture(Maines_FramePath(key, name), "REPEAT", "REPEAT")
            end
            p.key = key or "brass"
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

    -- A plate drawn as a backdrop (fill PLATE_BG, edge BORDER_DARK), for the feature pages.
    function Maines_Look.TonePlateBackdrop(frame)
        Maines_Look.RegisterPlate(frame, {PLATE_BG, BORDER_DARK}, function(fill, edge)
            frame:SetBackdropColor(fill[1], fill[2], fill[3], 1)
            frame:SetBackdropBorderColor(edge[1], edge[2], edge[3], 1)
        end)
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
-- Each button is the brass/palette color itself, with a soft top-light/bottom-shade bevel
-- gradient over it. States change how bright the face is - resting, hover (lifted), pressed
-- (shaded) - and "selected" (this UI uses Disable() to mark the current tab/bracket/mode) sinks
-- the button into a dark walnut face with a full-color rim and an inverted bevel, so it reads as
-- pushed in. Text color is picked from the face's brightness, so it stays readable for every
-- /maincolor palette, including the very light ones.
local BUTTON_BORDER_SHADE = 0.42
local STATE_REST, STATE_HOVER, STATE_DOWN, STATE_SELECTED = 1.0, 1.18, 0.78, "selected"

local function Maines_PaintButton(btn, state)
    local c = btn.baseColor
    if not c then return end
    local r, g, b
    if state == STATE_SELECTED then
        r = PLATE_BG[1] + (c[1] - PLATE_BG[1]) * 0.30
        g = PLATE_BG[2] + (c[2] - PLATE_BG[2]) * 0.30
        b = PLATE_BG[3] + (c[3] - PLATE_BG[3]) * 0.30
        btn:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    else
        r, g, b = math.min(1, c[1] * state), math.min(1, c[2] * state), math.min(1, c[3] * state)
        btn:SetBackdropBorderColor(c[1] * BUTTON_BORDER_SHADE, c[2] * BUTTON_BORDER_SHADE, c[3] * BUTTON_BORDER_SHADE, 1)
    end
    btn:SetBackdropColor(r, g, b, 1)
    if btn.bevel then
        if state == STATE_SELECTED then
            btn.bevel:SetGradient("VERTICAL", CreateColor(1, 1, 1, 0.06), CreateColor(0, 0, 0, 0.30))
        else
            btn.bevel:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0.22), CreateColor(1, 1, 1, 0.24))
        end
    end
    if btn.text then
        if Maines_Luminance(r, g, b) > 0.55 then
            btn.text:SetTextColor(INK[1], INK[2], INK[3])
        else
            btn.text:SetTextColor(PLATE_TEXT[1], PLATE_TEXT[2], PLATE_TEXT[3])
        end
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
    fs:SetTextColor(PLATE_TEXT[1], PLATE_TEXT[2], PLATE_TEXT[3])
    btn.text = fs

    local bevel = btn:CreateTexture(nil, "ARTWORK")
    bevel:SetPoint("TOPLEFT", 1, -1)
    bevel:SetPoint("BOTTOMRIGHT", -1, 1)
    bevel:SetTexture("Interface\\Buttons\\WHITE8X8")
    btn.bevel = bevel

    local neededWidth = fs:GetStringWidth() + 26
    btn:SetSize(math.max(width or 0, neededWidth), height)

    Maines_SetButtonBaseColor(btn, ACCENT[1], ACCENT[2], ACCENT[3])
    Maines_RegisterButton(btn)

    btn:SetScript("OnEnter", function(self)
        if self:IsEnabled() then Maines_PaintButton(self, STATE_HOVER) end
        if self.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if self:IsEnabled() then Maines_PaintButton(self, STATE_REST) end
        if self.tooltip then GameTooltip:Hide() end
    end)
    btn:SetScript("OnMouseDown", function(self)
        if self:IsEnabled() then Maines_PaintButton(self, STATE_DOWN) end
    end)
    btn:SetScript("OnMouseUp", function(self)
        if self:IsEnabled() then Maines_PaintButton(self, STATE_HOVER) end
    end)

    function btn:SetText(t)
        fs:SetText(t)
        local w = fs:GetStringWidth() + 26
        if w > self:GetWidth() then self:SetWidth(w) end
    end
    function btn:GetText() return fs:GetText() end

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

-- A tab in the row under the title: icon above its label on the dark walnut tab strip, a soft
-- highlight on hover, and - for the open page - a parchment surface that joins it to the
-- content panel below, like a folder tab, with an accent bar along its top edge.
-- An unselected, un-hovered tab's icon is darkened to this grey (neutral, the way WoW dims an
-- action button), never tinted a colour.
local NAV_ICON_DIM = 0.72
local NAV_ICON_SIZE = 22
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

    -- Square full-colour icon (its own dark bevelled frame is in the texture), never tinted:
    -- the open tab shows it at full strength, the others a little darker, hover lights it up.
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(NAV_ICON_SIZE, NAV_ICON_SIZE)
    icon:SetTexture(iconPath)
    icon:SetVertexColor(1, 1, 1)
    icon:SetPoint("TOP", 0, -4)
    btn.icon = icon

    local fs = btn:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(Maines_Font_Button)
    fs:SetPoint("BOTTOM", 0, 3)
    fs:SetText(text)
    btn.text = fs

    function btn:SetSelected(selected)
        self.selected = selected
        if selected then
            bg:Show(); bar:Show()
            fs:SetTextColor(INK[1], INK[2], INK[3])
            icon:SetVertexColor(1, 1, 1)
        else
            bg:Hide(); bar:Hide()
            fs:SetTextColor(PLATE_TEXT_SOFT[1], PLATE_TEXT_SOFT[2], PLATE_TEXT_SOFT[3])
            icon:SetVertexColor(NAV_ICON_DIM, NAV_ICON_DIM, NAV_ICON_DIM)
        end
    end
    btn:SetScript("OnEnter", function(self)
        hover:Show()
        if not self.selected then
            fs:SetTextColor(PLATE_TEXT[1], PLATE_TEXT[2], PLATE_TEXT[3])
            icon:SetVertexColor(1, 1, 1)
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
    rule:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -4)
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
    return fs, y - fs:GetStringHeight() - 12
end

-- Slash command handlers:
SlashCmdList["MAINMUSIC"] = function() _G["PlayedMusic_DB"] = "noplayed" end
SlashCmdList["MAINSTAMP"] = function() print("|cFF00FF00Maines|r: The |cFFFFE4B5GLYPH|r Stamp") end
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
Maines_MakeFlatBackdrop(Help_Frame, WINDOW_BG, BORDER_DARK, 3)
Maines_Look.AddFrameBorder(Help_Frame)

Help_Frame.title = Help_Frame:CreateFontString(nil, "OVERLAY")
Help_Frame.title:SetFontObject(Maines_Font_Display)
Help_Frame.title:SetPoint("TOP", 0, -22)
Help_Frame.title:SetText("Command Reference")
Help_Frame.title:SetTextColor(0.20, 0.11, 0.03)
Help_Frame.title:SetShadowColor(1, 0.94, 0.78, 0.6)
Help_Frame.title:SetShadowOffset(0, -1)

local helpClose = CreateFrame("Button", nil, Help_Frame, "UIPanelCloseButton")
helpClose:SetPoint("TOPRIGHT", -4, -4)
helpClose:SetScript("OnClick", function() Help_Frame:Hide() end)

local helpPanel = CreateFrame("Frame", nil, Help_Frame, "BackdropTemplate")
helpPanel:SetPoint("TOPLEFT", 26, -78)
helpPanel:SetPoint("BOTTOMRIGHT", -26, 22)
Maines_MakeFlatBackdrop(helpPanel, CONTENT_BG, BORDER_DARK, 2)

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
    exampleFS:SetPoint("TOP", 0, y)
    exampleFS:SetWidth(HELP_CONTENT_WIDTH - 12)
    exampleFS:SetJustifyH("CENTER")
    exampleFS:SetText(HEX_SOFT .. "Example tagged message:|r  " .. HEX_ACCENT .. "(Tuniveza)|r " .. HEX_TEXT .. "Hello there, guildies!|r")
    y = y - exampleFS:GetStringHeight() - 22

    for _, section in ipairs(Help_Sections) do
        local winColor = section.winColor or section.color

        local header = helpContent:CreateFontString(nil, "OVERLAY")
        header:SetFontObject(Maines_Font_Heading)
        header:SetPoint("TOP", 0, y)
        header:SetWidth(HELP_CONTENT_WIDTH - 12)
        header:SetJustifyH("CENTER")
        header:SetText(Maines_HelpIcon(section.icon, 22) .. "  " .. section.title)
        local r, g, b = Maines_HexToRGB(winColor)
        header:SetTextColor(r, g, b)
        y = y - header:GetStringHeight() - 10

        for _, e in ipairs(section.entries) do
            local entryFS = helpContent:CreateFontString(nil, "OVERLAY")
            entryFS:SetFontObject(Maines_Font_Body)
            entryFS:SetPoint("TOP", 0, y)
            entryFS:SetWidth(HELP_CONTENT_WIDTH - 12)
            entryFS:SetJustifyH("CENTER")

            local cmdLine = e.args ~= "" and (e.cmd.." |cFF2A2118"..e.args.."|r") or e.cmd
            local text = "|cFF"..winColor..cmdLine.."|r\n"
                .."|cFF4A4030"..e.desc.."|r\n"
                .."|cFF8A7A63e.g.|r |cFF3A2A1E"..e.example.."|r"
            if e.note then
                text = text.."\n|cFF8A7A63note:|r |cFF6B5F4D"..e.note.."|r"
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

Maines_Window = CreateFrame("Frame", "Maines_Frame", UIParent, "BackdropTemplate")
Maines_Window:SetSize(660, 680)
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
local HEADER_HEIGHT = 60
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
    windowTitle:SetPoint("TOP", header, "TOP", 0, -7)
    windowTitle:SetText("M A I N E S")
    windowTitle:SetTextColor(0.20, 0.11, 0.03)
    windowTitle:SetShadowColor(1, 0.94, 0.78, 0.6)
    windowTitle:SetShadowOffset(0, -1)

    local windowSubtitle = header:CreateFontString(nil, "OVERLAY")
    windowSubtitle:SetFontObject(Maines_Font_BodySmall)
    windowSubtitle:SetPoint("TOP", windowTitle, "BOTTOM", 0, -4)
    windowSubtitle:SetJustifyH("CENTER")
    windowSubtitle:SetText("gnomish / goblin-engineered chat tagger")
    windowSubtitle:SetTextColor(0.30, 0.18, 0.07)
    windowSubtitle:SetShadowColor(1, 0.94, 0.78, 0.4)
    windowSubtitle:SetShadowOffset(0, -1)

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

    local windowClose = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    windowClose:SetPoint("TOPRIGHT", -6, -6)
    windowClose:SetScript("OnClick", function() Maines_HideMainWindow() end)
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

local TAB_BAR_HEIGHT = 46
local TAB_HEIGHT = 42
local TAB_GAP = 2
local FOOTER_HEIGHT = 40
local tabBar = CreateFrame("Frame", nil, Maines_Window)
tabBar:SetPoint("TOPLEFT", 3, -HEADER_HEIGHT - 3)
tabBar:SetPoint("TOPRIGHT", -3, -HEADER_HEIGHT - 3)
tabBar:SetHeight(TAB_BAR_HEIGHT)
local tabBarBg = tabBar:CreateTexture(nil, "BACKGROUND")
tabBarBg:SetAllPoints()
tabBarBg:SetTexture("Interface\\Buttons\\WHITE8X8")
Maines_Look.TonePlateGradient(tabBar, tabBarBg, 0.8, 1.2)

local contentFrame = CreateFrame("Frame", nil, Maines_Window, "BackdropTemplate")
contentFrame:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, 0)
contentFrame:SetPoint("BOTTOMRIGHT", -3, FOOTER_HEIGHT)
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
local TAB_WIDTH = math.floor((660 - 6 - 16 - TAB_GAP * (#TAB_DEFS - 1)) / #TAB_DEFS)
for i, def in ipairs(TAB_DEFS) do
    local btn = Maines_MakeNavButton(tabBar, TAB_WIDTH, TAB_HEIGHT, def.label, def.icon)
    btn:SetPoint("BOTTOMLEFT", 8 + (i - 1) * (TAB_WIDTH + TAB_GAP), 0)
    btn:SetScript("OnClick", function() Maines_ShowPanel(def.key) end)
    Maines_Tabs[def.key] = btn

    local panel = CreateFrame("Frame", nil, contentFrame)
    panel:SetPoint("TOPLEFT", 16, -16)
    panel:SetPoint("BOTTOMRIGHT", -16, 16)
    panel:Hide()
    Maines_Panels[def.key] = panel
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
    Maines_Look.TonePlateGradient(footerBar, footerBg, 0.75, 1.15)
    Maines_Look.RegisterPlate(footerRule, {BORDER_DARK}, function(c) footerRule:SetVertexColor(c[1], c[2], c[3]) end)
    footerRule:SetHeight(1)
    footerRule:SetPoint("TOPLEFT")
    footerRule:SetPoint("TOPRIGHT")

    local creditsLine1 = footerBar:CreateFontString(nil, "OVERLAY")
    creditsLine1:SetFontObject(Maines_Font_BodySmall)
    creditsLine1:SetPoint("TOP", 0, -7)
    creditsLine1:SetJustifyH("CENTER")
    creditsLine1:SetText("Designed by Dominic Hughes / Zuniversa / Tuniveza  -  Silvermoon EU, Universe of Warcraft")
    creditsLine1:SetTextColor(PLATE_TEXT[1], PLATE_TEXT[2], PLATE_TEXT[3])

    -- Shifted right by half the stamp's width (+ gap) so stamp and text together stay centered.
    local creditsLine2 = footerBar:CreateFontString(nil, "OVERLAY")
    creditsLine2:SetFontObject(Maines_Font_BodySmall)
    creditsLine2:SetPoint("TOP", creditsLine1, "BOTTOM", 10, -3)
    creditsLine2:SetJustifyH("CENTER")
    creditsLine2:SetText("The GLYPH Stamp  -  Coded and Guided by Generative Assistance")
    creditsLine2:SetTextColor(PLATE_TEXT_SOFT[1], PLATE_TEXT_SOFT[2], PLATE_TEXT_SOFT[3])

    -- The stamp's mark (see Maines_MakeGlyphBadge above).
    local footerBadge = Maines_MakeGlyphBadge(footerBar, 12)
    footerBadge:SetPoint("RIGHT", creditsLine2, "LEFT", -8, 0)
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
ns.TabBar, ns.FooterBar = tabBar, footerBar
ns.Fonts = {
    Title = Maines_Font_Title, Header = Maines_Font_Header, Body = Maines_Font_Body,
    BodySmall = Maines_Font_BodySmall, Button = Maines_Font_Button,
}
ns.Colors = {
    INK = INK, INK_SOFT = INK_SOFT, ACCENT = ACCENT, CONTENT_BG = CONTENT_BG, PLATE_BG = PLATE_BG,
    BORDER_DARK = BORDER_DARK, HEX_TEXT = HEX_TEXT, HEX_SOFT = HEX_SOFT, HEX_ACCENT = HEX_ACCENT,
}
ns.Bracket_Types = Bracket_Types
ns.PANEL_WIDTH = 660 - 6 - 32

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
nameBox:SetJustifyH("CENTER")
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
ns.Bracket_Order = Bracket_Order
local BRACKET_AREA_WIDTH = 440
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
customLeft:SetJustifyH("CENTER")
-- Centered as a unit with customRight (combined width 50 + 20 gap + 50 = 120), not left-hung.
local CUSTOM_PAIR_WIDTH = 120

customRight = CreateFrame("EditBox", nil, mainPanel, "InputBoxTemplate")
customRight:SetSize(50, 20)
customRight:SetAutoFocus(false)
customRight:SetJustifyH("CENTER")
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
    -- the two columns centered as a block on the page
    local gridX = math.floor((ns.PANEL_WIDTH - CHAN_COLS * CHAN_COL_WIDTH) / 2) + 30
    cb:SetPoint("TOPLEFT", gridX + col * CHAN_COL_WIDTH, chanRowTop - row * 24)
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
helpIntro:SetText("|cFF4A4030Every command has a page in this window. For the full written reference - icons, examples, and notes - open the dedicated help window, or print the same thing to chat.|r")
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
        previewFS:SetText(HEX_ACCENT .. left .. name .. right .. "|r " .. HEX_TEXT .. "Hello there, guildies!|r")
    else
        previewFS:SetText(HEX_SOFT .. "(not set yet - pick a name and bracket above)|r")
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

local NOTE_WIDTH = 480
local NOTE_TEXT_WIDTH = NOTE_WIDTH - 60

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
noteBand:SetHeight(48)
Maines_DressBrassBand(noteBand)

local noteTitle = noteBand:CreateFontString(nil, "OVERLAY")
noteTitle:SetFontObject(Maines_Font_Heading)
noteTitle:SetPoint("CENTER", 0, 0)
noteTitle:SetText(NOTE_TITLE)
noteTitle:SetTextColor(0.20, 0.11, 0.03)
noteTitle:SetShadowColor(1, 0.94, 0.78, 0.6)
noteTitle:SetShadowOffset(0, -1)

local noteClose = CreateFrame("Button", nil, noteBand, "UIPanelCloseButton")
noteClose:SetPoint("TOPRIGHT", -4, -4)

-- The body: one centered column of text blocks, stacked top to bottom.
local noteY = -48 - 20
local function NoteText(text, font, color, gapAfter)
    local fs = Note_Frame:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(font)
    fs:SetWidth(NOTE_TEXT_WIDTH)
    fs:SetJustifyH("CENTER")
    fs:SetPoint("TOP", 0, noteY)
    fs:SetText(text)
    fs:SetTextColor(color[1], color[2], color[3])
    noteY = noteY - fs:GetStringHeight() - (gapAfter or 6)
    return fs
end

-- A short fading rule with a diamond in the middle, between sections.
local function NoteDivider()
    noteY = noteY - 4
    local diamond = Note_Frame:CreateTexture(nil, "ARTWORK")
    diamond:SetTexture("Interface\\Buttons\\WHITE8X8")
    diamond:SetVertexColor(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3])
    diamond:SetSize(5, 5)
    diamond:SetRotation(math.rad(45))
    diamond:SetPoint("TOP", 0, noteY)
    for _, side in ipairs({-1, 1}) do
        local line = Note_Frame:CreateTexture(nil, "ARTWORK")
        line:SetTexture("Interface\\Buttons\\WHITE8X8")
        line:SetSize(110, 1)
        local ink, clear = CreateColor(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3], 0.8), CreateColor(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3], 0)
        if side < 0 then
            line:SetPoint("RIGHT", diamond, "LEFT", -6, 0)
            line:SetGradient("HORIZONTAL", clear, ink)
        else
            line:SetPoint("LEFT", diamond, "RIGHT", 6, 0)
            line:SetGradient("HORIZONTAL", ink, clear)
        end
    end
    noteY = noteY - 18
end

NoteText(NOTE_MESSAGE[1], Maines_Font_Header, INK, 8)
NoteText(NOTE_MESSAGE[2], Maines_Font_Body, INK, 12)
for i, project in ipairs(NOTE_PROJECTS) do
    NoteText(HEX_ACCENT .. "-|r  " .. project .. "  " .. HEX_ACCENT .. "-|r", Maines_Font_Body, INK, i == #NOTE_PROJECTS and 12 or 4)
end
NoteText(NOTE_CLOSING[1], Maines_Font_Body, INK, 4)
NoteText(NOTE_CLOSING[2], Maines_Font_Header, INK, 8)
NoteText(NOTE_SIGNATURE, Maines_Font_BodySmall, INK_SOFT, 10)
NoteDivider()
NoteText("New in " .. NOTE_VERSION, Maines_Font_Heading, INK, 8)
for i, line in ipairs(NOTE_NEW) do
    NoteText(line, Maines_Font_Body, INK_SOFT, i == #NOTE_NEW and 12 or 3)
end
NoteDivider()
NoteText("Type " .. HEX_ACCENT .. "/mainnote|r any time to read this again - news and changes "
    .. "for each update will be here.", Maines_Font_BodySmall, INK_SOFT, 14)

local noteOk = Maines_MakeButton(Note_Frame, 160, 26, "Thank you!")
noteOk:SetPoint("TOP", 0, noteY)
noteOk:SetScript("OnClick", function() Note_Frame:Hide() end)
noteY = noteY - 26 - 20
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
