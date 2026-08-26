# Maines

Take your main name to the chat frame, then gtfo.

Maines lets you tag your chat messages with your "main" character's name wrapped in a bracket
style of your choice, so guildies/friends know who's really talking even when you're on an alt.

Compatible with modern retail WoW (Interface 12.1.0 — *Midnight*).

## Slash Commands

**Core**
- `/mains <name> <bracket symbol>` — set your main name and bracket style, e.g. `/mains Misamu (`
- `/main` — print your currently configured main name and bracket
- `/maines` — open the Maines UI

**Extra**
- `/mainchat SAY,WHISPER,GUILD,DND` — restrict which chat channels get the name tag (comma-separated, capital letters required)
- `/bracket` — list all available bracket styles
- `/mainmusic` — replay the Maines intro music next time the UI is opened
- `/mainstamp` — print the current build stamp

## Bracket Styles

`[ ]` `( )` `< >` `{ }` `. .` `: :` `- -` `~ ~` `@ @` `# #`

## Notes

- If another addon already prefixes your whispers, use `/mainchat` to limit which channels Maines tags.
- Built on Ace3 (AceAddon-3.0 / AceHook-3.0) — hooks `SendChatMessage` to prepend your bracketed main name.

## Author

Dominic Hughes / Misamu — EU, Silvermoon (Alliance)
