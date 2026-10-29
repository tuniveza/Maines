<p align="center">
  <img src="docs/media/banner.png" width="100%" alt="Maines — take your main name to the chat frame, then gtfo.">
</p>

<p align="center">
  <a href="https://github.com/tuniveza/Maines/releases/latest"><img src="https://img.shields.io/badge/stamp-GLYPH-8B5E3C" alt="Current stamp: GLYPH"></a>
  <img src="https://img.shields.io/badge/WoW-12.1.5%20(Midnight)-3E6E96" alt="WoW 12.1.5 (Midnight)">
  <a href="https://www.curseforge.com/wow/addons/maines"><img src="https://img.shields.io/badge/CurseForge-Maines-F16436" alt="Maines on CurseForge"></a>
  <img src="https://img.shields.io/badge/built%20on-Ace3-C9A227" alt="Built on Ace3">
</p>

<p align="center"><em>
You logged in on your bank alt to sell three stacks of linen.<br>
Guild chat says <q>who is this?</q> for the fourth time this week.<br>
Never again.
</em></p>

---

**Maines** pins your main's name to the front of everything you say, so your guild, your friends and
your raid always know who is really talking, whichever alt you are wearing today.

```
[Guild] [Linenseller]: [Misamu] anyone up for a key?
```

Set it once. Chat as normal. Get on with your evening.

<p align="center">
  <img src="docs/media/tag-anim.gif" width="760" alt="A WoW-style chat frame: messages go out one by one, each tagged with the main name, and the tag changes a little with every message">
</p>

## The GLYPH stamp

Every Maines release gets a name instead of a version number, stamped like a seal on a letter.
**GLYPH** is the one where Maines learned to talk back:

| | |
|---|---|
| ✦ **Animated tag** | Your tag shifts a little with every message: bracket cycle, typewriter, capital wave, twinkle, or your own phrases. |
| 💬 **Saved phrases** | One key drops your next saved line into the chat box. Press again for the one after. |
| 🛡 **Textual Badges** | Send a whole picture to chat, one line at a time. Ten come in the box; draw your own. |
| 🔩 **A new coat of brass** | Parchment, brushed brass, soft gradients, bevelled buttons and hand-made icons. |

Full notes for every stamp: [CHANGELOG.md](CHANGELOG.md).

## Install

**CurseForge app:** search for **Maines** and press Install.

**By hand:**
1. Download `Maines-GLYPH.zip` from the [Releases page](https://github.com/tuniveza/Maines/releases/latest).
2. Unzip it into `World of Warcraft/_retail_/Interface/AddOns/`.
3. You should now have a folder called `AddOns/Maines`.

> Don't use the green **Code → Download ZIP** button.
> That folder is called `Maines-main`, and WoW will ignore it.

## Quick start

1. Log in on any character and type `/mains Misamu [` (your main's name, then a bracket).
2. Hop to an alt and say something.
3. It goes out as `[Misamu] something`.

On your main itself, Maines stays quiet. Nobody needs to be told who you are when you are you.
(Change that with `/mainshow`.)

Prefer buttons? Type **`/maines`** or left-click the brass **M** on your minimap.

## The workshop

<p align="center">
  <img src="docs/media/window-tour.gif" width="760" alt="The Maines window: a parchment-and-brass control panel with a row of tabs, cycling through each page">
</p>

Every page of the window does exactly what the slash commands do. Use whichever you like, or mix both.

<table align="center">
  <tr>
    <td align="center" width="50%"><img src="docs/media/window-main.png" alt="Main page: name box and bracket buttons that preview your tag live"><br><sub><b>Main</b> · name and brackets, previewed live</sub></td>
    <td align="center" width="50%"><img src="docs/media/window-phrases.png" alt="Phrases page: your saved phrases and the keys that cycle them"><br><sub><b>Phrases</b> · your lines, your keys</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/media/window-animate.png" alt="Animate page: pick a tag animation style and how often it steps"><br><sub><b>Animate</b> · how your tag moves</sub></td>
    <td align="center"><img src="docs/media/window-badges.png" alt="Badges page: pick, preview, draw and send Textual Badges"><br><sub><b>Badges</b> · pick, preview, draw, send</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/media/window-filter.png" alt="Channels page: a checkbox per chat channel"><br><sub><b>Channels</b> · where the tag goes</sub></td>
    <td align="center"><img src="docs/media/window-cosmetic.png" alt="Cosmetic page: palettes, minimap button and music"><br><sub><b>Cosmetic</b> · paint the brass</sub></td>
  </tr>
</table>

<sub>Window pictures are rendered offline from the addon's real UI code (its own layout, colours, textures and font), not captured in game.</sub>

## Saved phrases

Keep the things you say every night on a key: `LF1M`, `ty for the group!`, `gz`, or a row of symbols you can never remember how to type.

<p align="center">
  <img src="docs/media/phrases.gif" width="760" alt="The chat box: pressing the phrase key puts a saved phrase in, pressing again swaps it for the next one, Enter sends it tagged">
</p>

1. Add a phrase: `/mainphrase add ty for the group!` (or use the **Phrases** page).
2. Set your key: **Phrases** page, or **Key Bindings → AddOns → Maines**.
3. Press the key in chat. Press it again to swap. Press **Enter** to send.

Maines never sends anything for you. You always press Enter yourself.

## Animated tag

Your name, but restless. One step per message, or one step every 30 seconds to 15 minutes.

| Style | What your guild sees, message by message |
|---|---|
| Bracket cycle | `[Misamu]` → `(Misamu)` → `<Misamu>` → `{Misamu}` |
| Typewriter | `[M]` → `[Mi]` → `[Mis]` → … → `[Misamu]` |
| Capital wave | `[mIsamu]` → `[miSamu]` → `[misAmu]` → … → `[Misamu]` |
| Twinkle | `[Misamu *]` → `[Misamu +]` → `[Misamu x]` → `[Misamu +]` |
| My phrases | your tag, then your next saved phrase |

Pick one on the **Animate** page, or `/mainanim typewriter`. `/mainanim off` keeps it still.

## Textual Badges

Why say *gg* when you can send a five-line **GG** carved in text?

<p align="center">
  <img src="docs/media/badges.png" width="760" alt="The ten built-in Textual Badges: Heart, Shield, Sword, 3D Cube, 3D Pyramid, Crown, Glyph Stamp, GG, Murloc and Rose">
</p>

Ten come in the box: **Heart, Shield, Sword, 3D Cube, 3D Pyramid, Crown, Glyph Stamp, GG, Murloc** and **Rose**.
Draw and save your own on the **Badges** page.

- `/mainbadge` lists them.
- `/mainbadge show 8` previews one, only for you.
- `/mainbadge send 8 guild` sends it.

One badge every 3 minutes. Your guild will thank you. Mostly.

## Paint the brass

`/maincolor` (or right-click the minimap button) repaints the whole window from one of 13 palettes.
Some come from famous paintings: *The Starry Night*, *The Great Wave*, *The Kiss*, *Nighthawks*, *The Scream* and more.
Some come from closer to home: *Gnomeregan Copper*, *Undermine Neon*, *Ironforge Brass & Steel*, *Verdigris Goblin*.
Pick a swatch yourself on the **Cosmetic** page. The reading text stays dark ink, so no roll can make it unreadable.

<p align="center">
  <img src="docs/media/palettes.gif" width="560" alt="The Maines window being repainted by several /maincolor rolls">
</p>

## Commands

| Command | What it does |
|---|---|
| `/mains <name> <bracket>` | Set your main and bracket: `/mains Misamu (`, `/mains Misamu *`, `/mains Misamu << >>` |
| `/main` | Show what's set |
| `/maines` | Open the window |
| `/mainhide` · `/mainshow` | Stay quiet on your main (default) · always tag |
| `/mainchat` | Choose channels: `SAY,GUILD`, `+WHISPER`, `-SAY,-YELL`, `list`, `mode exclude`, `sticky` |
| `/mainphrase` | `add <text>`, `del <n>`, `list`, `clear`, `next`, `prev` |
| `/mainanim` | `<style>`, `message`, `time <seconds>` |
| `/mainbadge` | `list`, `show <n>`, `send <n> [channel]` |
| `/maincolor` | Roll a new painting palette |
| `/mainmap` | Show or hide the minimap button |
| `/bracket` | List the built-in bracket styles |
| `/mainhelp` | Every command, with examples, in a window (`/mainhelp text` prints to chat) |
| `/mainnote` | What's new in this stamp |
| `/mainstamp` | Which stamp you're running |
| `/maindebug` | Explain every tagging decision as you type |

**Minimap button:** left-click opens the window · right-click repaints it · middle-click clears your channel filter · drag to move.

<details>
<summary><b>More about channels</b></summary>

By default every channel is tagged: say, yell, emote, party, raid, raid warning, instance, guild, officer,
whispers, Battle.net whispers, channels and Communities (all of them, not just the first one).

- `/mainchat SAY,GUILD` tags only those.
- `/mainchat mode exclude` flips it: tag everything **except** the listed channels.
- Case and spaces don't matter: `say, guild` works.
- Filters reset to "tag everything" on `/reload` unless you turn on `/mainchat sticky`.
  This stops a forgotten filter from silently hiding your tag for weeks.

Another addon already tags your whispers? `/mainchat -WHISPER`.

Valid names: `SAY`, `YELL`, `EMOTE`, `PARTY`, `PARTY_LEADER`, `RAID`, `RAID_LEADER`, `RAID_WARNING`,
`INSTANCE_CHAT`, `INSTANCE_CHAT_LEADER`, `GUILD`, `OFFICER`, `WHISPER`, `BN_WHISPER`, `CHANNEL`,
`COMMUNITIES_CHANNEL`, `VOICE_TEXT`, `AFK`, `DND`.
</details>

<details>
<summary><b>Tag not showing up?</b></summary>

1. Type `/main` and check your name is set.
2. Are you on your main? Maines stays quiet there unless you `/mainshow`.
3. Type `/mainchat list`. A forgotten filter may be skipping that channel. `/mainchat` alone clears it.
4. Still stuck? Type `/maindebug`, say something, and send the lines it prints with your
   [bug report](https://github.com/tuniveza/Maines/issues).
</details>

<details>
<summary><b>For developers</b></summary>

- **Tests:** `tests/run.sh` runs Maines offline under Lua 5.1 against a mocked WoW API (`tests/wowmock.lua`).
- **Pictures:** `tools/` rebuilds the icons, textures and the README media from the real UI code.
- **Releasing:** push an annotated tag named after the stamp (`git tag -a GLYPH -m GLYPH && git push origin GLYPH`).
  [BigWigsMods/packager](https://github.com/BigWigsMods/packager) (`.github/workflows/release.yml`) builds
  `Maines-<stamp>.zip` using `.pkgmeta`, publishes the GitHub release and uploads to CurseForge.
  Player-facing notes come from `CHANGELOG.md`; the CurseForge page text lives in `docs/curseforge-description.md`.
- **How tagging works on Midnight:** patch 12.0 rebuilt outgoing chat, which silently broke the old
  `SendChatMessage` hook. Maines now edits the chat box text in the `ChatFrame.OnEditBoxPreSendText`
  callback, just before Blizzard reads it, with a `ChatEdit_SendText` hook kept for Classic.
  Community chat is detected by the edit box's `clubId`, because Blizzard doesn't always mark it as
  `COMMUNITIES_CHANNEL`.
- Built on Ace3 (AceAddon, AceHook) with LibDataBroker and LibDBIcon. Text is set in
  [New Rocker](https://fonts.google.com/specimen/New+Rocker) (titles),
  [Vollkorn SC](https://fonts.google.com/specimen/Vollkorn+SC) (headings),
  [Fira Sans](https://fonts.google.com/specimen/Fira+Sans) (text) and
  [Bree Serif](https://fonts.google.com/specimen/Bree+Serif) (buttons), all under the
  SIL Open Font License 1.1 (licence files in `fonts/`).
</details>

## Author

Made by **Misamu** (Dominic Hughes) · EU Silvermoon · Alliance.
Say hi in game. You'll know it's me: the tag gives it away.
