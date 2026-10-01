**Take your main name to the chat frame, then gtfo.**

Playing an alt? Maines tags your outgoing chat messages with your main character's name, so your guildies and friends always know who's actually talking.

`(tuniveza) anyone up for a key?`

## Quick start

1. `/mains tuniveza (`: sets your main name to *tuniveza* with `( )` brackets
2. Type in chat as normal. Your messages go out as `(tuniveza) your message`
3. `/main` shows what's currently set

That's it. Everything else is optional.

## Features

- **Any bracket style you like.** Use a built-in style (`[ ]` `( )` `< >` `{ }` `~` `@` `#` and more), a single symbol on both sides (`*tuniveza*`), or separate left/right symbols (`<<tuniveza>>`).
- **Main vs. alt aware.** By default you're only tagged when you're on an alt. Use `/mainshow` to always tag, or `/mainhide` to go back to the default.
- **Per-channel filtering.** Choose which channels get tagged: say, yell, party, raid, instance, guild, officer, whispers, Battle.net whispers, communities and more. Filters can be a whitelist or a blacklist. By default they reset on reload, so a forgotten test filter can't silently stick around.
- **Full control panel.** `/maines` opens a tabbed window (Main, Filter, Behavior, Cosmetic, Help) with live bracket previews, so you never have to type command syntax unless you want to.
- **Minimap button.** Left-click opens the window, right-click recolors it, and middle-click clears your channel filter.
- **Palette recoloring.** `/maincolor` repaints the UI with a palette taken from a classic public-domain painting: Starry Night, The Great Wave, The Kiss, Water Lilies, The Scream or Composition II.

## Commands

| Command | What it does |
|---|---|
| `/mains <name> <bracket>` | Set your main name and bracket style |
| `/main` | Show your current setup |
| `/maines` | Open the control panel |
| `/mainhide` / `/mainshow` | Hide or show the tag while you're on your main |
| `/mainchat` | Channel filter (`/mainchat SAY,GUILD`, `+WHISPER`, `-WHISPER`, `mode exclude`, `sticky`, `list`) |
| `/bracket` | List the built-in bracket styles |
| `/maincolor` | Recolor the UI with a random art palette |
| `/mainmap` | Toggle the minimap button |
| `/mainmusic` | Replay the intro jingle the next time you open the window |
| `/mainhelp` | In-game command reference |

## Notes

- The current window uses a plain, flat look while the final hand-made artwork is in progress.
- Text uses the [Agave](https://github.com/blobject/agave) font (SIL Open Font License 1.1).
- Built on Ace3, LibDataBroker and LibDBIcon.
- Source code, issues and full documentation: [github.com/tuniveza/Maines](https://github.com/tuniveza/Maines)
