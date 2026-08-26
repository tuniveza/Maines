# Maines

Take your main name to the chat frame, then gtfo.

Maines lets you tag your chat messages with your "main" character's name wrapped in a bracket
style of your choice, so guildies/friends know who's really talking even when you're on an alt.

Compatible with modern retail WoW (Interface 12.1.0 — *Midnight*). Chat tagging was broken by
Midnight's rearchitecture of outgoing chat and has been fixed — see **Status** below.

## Slash Commands

**Core**
- `/mains <name> <bracket symbol>` — set your main name and bracket style, e.g. `/mains Misamu (`
- `/main` — print your currently configured main name and bracket
- `/maines` — open the Maines UI

**Extra**
- `/mainchat SAY,WHISPER,GUILD,DND` — restrict which chat channels get the name tag (comma-separated, capital letters required). Run `/mainchat` with nothing after it to clear the filter and tag all channels again.
- `/bracket` — list all available bracket styles
- `/mainmusic` — replay the Maines intro music next time the UI is opened
- `/mainstamp` — print the current build stamp
- `/maindebug` — toggle debug printing of every tagging decision (chat type, saved name/brackets, channel filter, dedupe check) — use this first if tagging ever silently stops working again

## Bracket Styles

`[ ]` `( )` `< >` `{ }` `. .` `: :` `- -` `~ ~` `@ @` `# #`

## Notes

- If another addon already prefixes your whispers, use `/mainchat` to limit which channels Maines tags.
- Built on Ace3 (AceAddon-3.0 / AceHook-3.0).

## Status

- **Chat tagging: fixed and confirmed working on retail 12.1.0.** Patch 12.0.0 rearchitected
  outgoing chat, which silently broke the old `SendChatMessage` hook (no errors, tag just never
  appeared). Maines now hooks the modern `EventRegistry` `"ChatFrame.OnEditBoxPreSendText"`
  callback and edits the chat edit box text directly before Blizzard reads it for sending, with
  a `ChatEdit_SendText` hook kept as a fallback for Classic clients.
- **Still needed:** an aesthetic/GUI rework — the frames, brackets, and textures are still the
  original placeholder art and haven't been touched.

## Author

Dominic Hughes / Misamu — EU, Silvermoon (Alliance)
