#!/usr/bin/env bash
# Runs the offline Maines test suite: once as a fresh install, then again with the real
# SavedVariables file (read-only) if it exists. Exit code is non-zero if either run fails.
set -u
cd "$(dirname "$0")/.."

REAL_SV="${MAINES_REAL_SV:-$HOME/PortProton/data/prefixes/BATTLE_NET/drive_c/Program Files (x86)/World of Warcraft/_retail_/WTF/Account/452907974#1/SavedVariables/Maines.lua}"

status=0
MAINES_SV= lua5.1 tests/run.lua || status=1
if [ -f "$REAL_SV" ]; then
  echo
  MAINES_SV="$REAL_SV" lua5.1 tests/run.lua || status=1
else
  echo "(real SavedVariables not found - skipped second run: $REAL_SV)"
fi
exit $status
