# Maines

Take your main name to the chat frame, then gtfo.

Maines tags your outgoing chat messages with your "main" character's name wrapped in a bracket
style of your choice, so guildies/friends know who's really talking even when you're on an alt.

Compatible with modern retail WoW (Interface 12.1.0 — *Midnight*). Chat tagging was broken by
Midnight's rearchitecture of outgoing chat and has been fixed — see **Status** below.

## Quick Start

1. `/mains Misamu (` — sets your main name to "Misamu" with `(` `)` brackets.
2. Send any chat message — it goes out as `(Misamu) <your message>`.
3. `/main` any time to double check what's currently configured.

That's the whole workflow. Everything below is for customizing it further.

## Slash Commands

### Setting your name and bracket style — `/mains`

`/mains` takes your main's name plus one or two symbols for the bracket, space-separated:

| Command | Result |
|---|---|
| `/mains Misamu (` | `(Misamu)` — recognized bracket symbol, auto-fills the matching right side |
| `/mains Misamu *` | `*Misamu*` — unrecognized symbol, used on both sides |
| `/mains Misamu << >>` | `<<Misamu>>` — two symbols given, used independently as left/right |

Recognized bracket symbols (see `/bracket` for the full list with names): `[` `(` `<` `{` `.` `:` `-` `~` `@` `#`.
Anything else you type (a custom symbol, or two symbols) is used as-is — you're not limited to the
built-in list.

Once set, the name/bracket persist across sessions (saved per character) until you `/mains` again.

### Checking your current setup — `/main`

Prints your currently saved main name, bracket type, and left/right symbols. Doesn't change anything.

### Playing your main vs. an alt — `/mainonmain`

Maines compares your saved main name against whichever character you're actually logged into
(case-insensitive), and behaves differently depending on the result:

| Command | When you're **on your main** | When you're **on an alt** |
|---|---|---|
| `/mainonmain hide` (default) | Tag is suppressed — no point tagging yourself as yourself | Tagged as normal |
| `/mainonmain tag` | Always tagged, even on your main | Tagged as normal |

Run `/mainonmain` with no arguments to print which mode is currently active. This only affects
the "on your main" case — Maines always tags on alts regardless of this setting, since that's
the whole point of the addon.

### Opening the UI — `/maines`

Opens the Maines frame (also reachable via the minimap icon's left-click, see below). Press
`Escape` or click the close button to dismiss it.

### Controlling which channels get tagged — `/mainchat`

By default, Maines tags every channel it knows about (say, yell, party, raid, instance, guild,
officer, whisper, battle.net whisper, communities, channel, emote, raid warning, and the
leader-broadcast variants). Use `/mainchat` to narrow that down:

| Command | Effect |
|---|---|
| `/mainchat` (no arguments) | Clears the filter — back to tagging everything |
| `/mainchat SAY,GUILD,PARTY` | Only tag these channels (comma-separated, **capital letters required**) |
| `/mainchat list` | Print the channels currently in the filter |
| `/mainchat +WHISPER` | Add a single channel to the existing filter, without retyping the rest |
| `/mainchat -WHISPER` | Remove a single channel from the existing filter |

Valid channel names: `SAY`, `YELL`, `EMOTE`, `PARTY`, `PARTY_LEADER`, `RAID`, `RAID_LEADER`,
`RAID_WARNING`, `INSTANCE_CHAT`, `INSTANCE_CHAT_LEADER`, `GUILD`, `OFFICER`, `WHISPER`,
`BN_WHISPER`, `CHANNEL`, `COMMUNITIES_CHANNEL`, `VOICE_TEXT`, `AFK`, `DND`.

Example: if another addon already tags your whispers and you don't want Maines doubling up there,
run `/mainchat -WHISPER` (or list out everything except `WHISPER` explicitly).

### Listing bracket styles — `/bracket`

Prints every built-in bracket symbol with its name (Square, Circle, Crocodile, ButterFly, Dot,
Double Dot, Line, Wave, Spiral, Hash Bracket) so you know what to pass to `/mains`.

### Recoloring the UI — `/maincolor`

Repaints every Maines UI texture (frames, buttons, minimap icon) with a random color pulled from
a random public-domain art palette — Van Gogh's *Starry Night*, Hokusai's *Great Wave*, Klimt's
*The Kiss*, Monet's *Water Lilies*, Munch's *The Scream*, or Mondrian's *Composition II*. Run it
again for a different color. Requires the UI to have been opened at least once (`/maines`) so the
textures exist to paint. You can also right-click the minimap icon to do the same thing.

### Minimap icon — `/mainmap`

Toggles the Maines minimap icon on/off (it's on by default). While it's shown:
- **Left-click** opens the Maines UI (same as `/maines`)
- **Right-click** rolls a new `/maincolor` palette
- It spins slowly, purely for fun
- Drag it anywhere around the minimap ring

### Intro music — `/mainmusic`

The Maines intro jingle only plays the first time you open the UI each session. Run `/mainmusic`
to reset that, so it plays again next time you `/maines`.

### Version stamp — `/mainstamp`

Prints the current build stamp ("The Radial Stamp [ ∂ ]"). Maines uses stamps instead of
alpha/beta/release version numbers.

### Debugging — `/maindebug`

Toggles verbose debug printing of every tagging decision as you type: detected chat type, your
saved name/brackets, whether a channel filter is active and whether it matched, and whether the
message was already tagged. Turn this on first if chat tagging ever appears to silently stop
working — it'll show exactly which check is failing instead of guessing.

## Notes

- If another addon already prefixes your whispers, use `/mainchat -WHISPER` to stop Maines from
  doubling up on that channel.
- Built on Ace3 (AceAddon-3.0 / AceHook-3.0) plus LibDataBroker-1.1 / LibDBIcon-1.0 for the
  minimap icon.

## Status

- **Chat tagging: fixed and confirmed working on retail 12.1.0.** Patch 12.0.0 rearchitected
  outgoing chat, which silently broke the old `SendChatMessage` hook (no errors, tag just never
  appeared). Maines now hooks the modern `EventRegistry` `"ChatFrame.OnEditBoxPreSendText"`
  callback and edits the chat edit box text directly before Blizzard reads it for sending, with
  a `ChatEdit_SendText` hook kept as a fallback for Classic clients.
- **Communities support:** `COMMUNITIES_CHANNEL`, `BN_WHISPER`, and the `*_LEADER` broadcast
  types are now tagged by default alongside the classic channel list.
- **On-main detection:** Maines now knows whether you're playing the character set as your main
  and, by default, skips tagging in that case — see `/mainonmain` above to change it.
- **Still needed:** an aesthetic/GUI rework — the frames, brackets, and textures are still the
  original placeholder art and haven't been touched (though `/maincolor` at least makes them
  more colorful in the meantime).

## Author

Dominic Hughes / Misamu — EU, Silvermoon (Alliance)
