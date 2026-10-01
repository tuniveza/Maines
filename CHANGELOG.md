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
