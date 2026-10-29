# GLYPH.1

A small revision of GLYPH: mostly a fresh coat of paint.

### Changed

- **New icons.** Every tab has a new hand-made icon in a painted, square style. The tab you're on shows in full colour.
- **New fonts.** Thicker, easier-to-read text, with a different font for titles, headings, text and buttons.
- **Palettes go further.** Each `/maincolor` palette now has its own paper texture and its own window border, and it also colours the title bar, the tab bar and the footer.
- **Your palette is remembered.** The palette you pick now stays after a `/reload` or the next login.
- **Centred input boxes.** Text you type in the name, bracket, phrase and badge-name boxes sits in the middle.
- **Credits** now read Zuniversa / Tuniveza.

### Fixed

- The Rose badge's stem was stretched to about 15 dashes when sent. One-line badges now go out exactly as drawn.
- The badge list cut off the bottom of its 11th row. It now shows 11 full rows before it scrolls.

# GLYPH

Updated for WoW 12.1.5.

### New

- **Saved phrases.** Keep a list of words, sentences or symbols on the new **Phrases** page (or `/mainphrase add <text>`). Press your shortcut key to put the next one in the chat box; press it again to swap to the one after. You still press Enter to send. Set the keys on the Phrases page or in Key Bindings > AddOns > Maines.
- **Animated tag.** Your tag can change a little with every message: bracket cycle, typewriter, capital wave, twinkle, or your own saved phrases. One step per message, or one step every 30 seconds to 15 minutes. See the **Animate** page or `/mainanim`.
- **Textual Badges.** Send a whole text picture to chat, one line per row. Comes with 10 ready-made badges (Heart, Shield, Sword, 3D Cube, 3D Pyramid, Crown, Glyph Stamp, GG, Murloc, Rose), and you can draw and save your own. One badge every 3 minutes. See the **Badges** page or `/mainbadge`.

- **`/mainnote`.** A short note from me, with what's new in each update. It pops up once by itself after an update.

### Changed

- **New look.** The window keeps its brass-and-parchment colors, now with soft gradients, paper and brushed-brass textures, bevelled buttons, a row of tabs, a soft glow and its own hand-made icons. It's not the final look by a long stretch: just a nice make-over to keep it fun and interesting until I can sit down and properly update it, like in the early versions.
- **Calmer motion.** The gears and minimap icon no longer spin all the time. The minimap icon turns once when you point at it, and the window fades in when it opens.

# MOSAIC

First release on CurseForge. Updated for WoW Midnight (12.x).

### New

- **Control panel.** `/maines` (or left-click the minimap button) opens a tabbed window: Main, Filter, Behavior, Cosmetic and Help. Everything the slash commands do can now be done with buttons and checkboxes, and the bracket buttons preview your tag live as you type.
- **More bracket styles.** Use any single symbol on both sides (`/mains tuniveza *` gives `*tuniveza*`) or separate left and right symbols (`/mains tuniveza << >>` gives `<<tuniveza>>`).
- **Main vs. alt.** Maines no longer tags you as yourself when you're playing your main. Use `/mainshow` to always tag, or `/mainhide` to go back to the default.
- **Better channel filtering.** `/mainchat` now accepts:
  - `+WHISPER` / `-WHISPER` to add or remove channels without retyping the list (several at once also works: `-SAY,-YELL`)
  - `list` to see the current filter
  - `mode exclude` to tag every channel *except* the ones listed
  - `sticky` to keep your filter after a reload
- **More channels tagged by default:** Communities, Battle.net whispers, and the party, raid and instance leader channels.
- **Minimap button.** Left-click opens the window, right-click recolors it, and middle-click clears your channel filter. `/mainmap` shows or hides it.
- **`/maincolor`** recolors the UI with a palette taken from a classic painting: Starry Night, The Great Wave, The Kiss, Water Lilies, The Scream or Composition II.
- **`/mainhelp`** opens an in-game command reference with an example for every command.

### Fixed

- Chat tagging works again on Midnight. Patch 12.0.0 changed how chat messages are sent, which had stopped Maines tagging anything.
- Plain `/say` messages weren't always tagged.
- Messages in your second or later Community weren't tagged.
- `/mainchat SAY, GUILD` (with a space after the comma) never matched any channel.
- `/mainchat -SAY,-YELL` and mistyped commands like `+whisper` could wipe your whole filter and silently stop all tagging.
- A bug that could stop the addon loading entirely, leaving every command "unknown".

### Changed

- Channel filters now reset to "tag everything" on reload unless you turn on `/mainchat sticky`. This stops a forgotten filter from quietly blocking channels for good. Middle-clicking the minimap button clears the filter at any time.
- The old painted artwork has been retired. The window currently has a plain, flat look while new artwork is made.
