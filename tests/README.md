Offline tests: run Maines under plain Lua 5.1 with a mocked WoW API (`wowmock.lua`).
Run everything: `tests/run.sh` (fresh install, then again with your real SavedVariables if found).
Run once: `lua5.1 tests/run.lua` from any folder. Add `MAINES_SV=<path/to/Maines.lua>` to load saved variables.
Debug: `MAINES_ECHO=1` shows the addon's print output; `MAINES_VERBOSE=1` lists globals read while undefined.
New tests go in `run.lua`; helpers: `slash`, `sendChat`, `fireEvent`, `fireScript`, `click`, `advanceTime`, `findFrames`.
