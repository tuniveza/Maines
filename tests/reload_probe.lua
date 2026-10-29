-- Helper for tests/run.lua's /reload test: loads Maines fresh in the offline mock with the given
-- SavedVariables file (as the client does after /reload), then prints the look it came back with,
-- one "key=value" per line, WITHOUT opening any window first.
--   lua5.1 tests/reload_probe.lua <SavedVariables file>
local scriptDir = (arg and arg[0] or ""):match("^(.*)[/\\][^/\\]*$") or "."
package.path = scriptDir .. "/?.lua;" .. package.path
local mock = require("wowmock")
mock.install()
mock.loadAddon(scriptDir .. "/..", "Maines", { savedVariables = arg[1] })

local out = mock.rawprint
local ns = mock.ns
local active = ns.ActivePalette()
local accent = ns.Colors.ACCENT
local band
for _, o in ipairs(mock.objects) do
    if type(o.toneHigh) == "table" and not band then band = o.toneHigh end
end
local frameTex = Maines_Frame.maines_frame
out("shown=" .. tostring(Maines_Frame:IsShown()))
out("palette=" .. tostring(active and active.name))
out(("accent=%.4f,%.4f,%.4f"):format(accent[1], accent[2], accent[3]))
out(("band=%.4f,%.4f,%.4f"):format(band[1], band[2], band[3]))
out(("tabbar=%.4f,%.4f,%.4f"):format(ns.TabBar.tone[2][1], ns.TabBar.tone[2][2], ns.TabBar.tone[2][3]))
out("frame=" .. tostring(frameTex.tl._texture))
out("notefr=" .. tostring(Maines_NoteFrame.maines_frame.top._texture))
local grain
for _, o in ipairs(mock.objects) do
    local t = o._texture
    if type(t) == "string" and (t:find("grain%.tga$") or t:find("palettes\\[%a]+%.tga$")) then grain = t; break end
end
out("grain=" .. tostring(grain))
out("saved=" .. tostring(Maines_DB and Maines_DB.palette and Maines_DB.palette.name))
out("errors=" .. #mock.errors)
for _, line in ipairs(mock.printed) do
    if line:find("painted #", 1, true) then out("chatline=" .. line) end
end
