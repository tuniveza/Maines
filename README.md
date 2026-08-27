# Maines

Take your main name to the chat frame, then gtfo.

Maines lets you tag your chat messages with your "main" character's name wrapped in a bracket
style of your choice, so guildies/friends know who's really talking even when you're on an alt.

Compatible with modern retail WoW (Interface 12.1.0 — *Midnight*). Chat tagging was broken by
Midnight's rearchitecture of outgoing chat and has been fixed — see **Status** below.

## Slash Commands

**Core**
- `/mains <name> <bracket symbol>` — set your main name and bracket style, e.g. `/mains Misamu (`
- `/mains <name> <symbol>` — one custom symbol used for both sides, e.g. `/mains Misamu *` → `*Misamu*`
- `/mains <name> <left> <right>` — independent left/right symbol sequences, e.g. `/mains Misamu << >>` → `<<Misamu>>`
- `/main` — print your currently configured main name and bracket
- `/maines` — open the Maines UI

**Extra**
- `/mainchat SAY,WHISPER,GUILD,DND` — restrict which chat channels get the name tag (comma-separated, capital letters required). Run `/mainchat` with nothing after it to clear the filter and tag all channels again (including Communities).
- `/mainchat list` — print the currently active channel filter
- `/mainchat +CHANNEL` / `/mainchat -CHANNEL` — add or remove a single channel from the existing filter without retyping the whole list
- `/bracket` — list all available bracket styles
- `/maincolor` — repaints all Maines UI textures with a random color pulled from a random public-domain art palette (Van Gogh, Hokusai, Klimt, Monet, Munch, Mondrian)
- `/mainmap` — toggle the Maines minimap icon on/off
- `/mainmusic` — replay the Maines intro music next time the UI is opened
- `/mainstamp` — print the current build stamp
- `/maindebug` — toggle debug printing of every tagging decision (chat type, saved name/brackets, channel filter, dedupe check) — use this first if tagging ever silently stops working again

## Bracket Styles

`[ ]` `( )` `< >` `{ }` `. .` `: :` `- -` `~ ~` `@ @` `# #`, plus any custom symbol or symbol pair you define with `/mains`.

## Minimap Icon

Left-click opens the Maines UI, right-click rolls a new `/maincolor` palette. It spins slowly,
purely for fun. Drag it around the minimap, or hide it entirely with `/mainmap`.

## Notes

- If another addon already prefixes your whispers, use `/mainchat` to limit which channels Maines tags.
- Built on Ace3 (AceAddon-3.0 / AceHook-3.0) plus LibDataBroker-1.1 / LibDBIcon-1.0 for the minimap icon.

## Status

- **Chat tagging: fixed and confirmed working on retail 12.1.0.** Patch 12.0.0 rearchitected
  outgoing chat, which silently broke the old `SendChatMessage` hook (no errors, tag just never
  appeared). Maines now hooks the modern `EventRegistry` `"ChatFrame.OnEditBoxPreSendText"`
  callback and edits the chat edit box text directly before Blizzard reads it for sending, with
  a `ChatEdit_SendText` hook kept as a fallback for Classic clients.
- **Communities support:** `COMMUNITIES_CHANNEL`, `BN_WHISPER`, and the `*_LEADER` broadcast
  types are now tagged by default alongside the classic channel list.
- **Still needed:** an aesthetic/GUI rework — the frames, brackets, and textures are still the
  original placeholder art and haven't been touched (though `/maincolor` at least makes them
  more colorful in the meantime).

## Author

Dominic Hughes / Misamu — EU, Silvermoon (Alliance)
