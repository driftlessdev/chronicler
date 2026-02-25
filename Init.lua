local Chronicler = LibStub("AceAddon-3.0"):NewAddon("Chronicler", "AceConsole-3.0", "AceEvent-3.0", "AceSerializer-3.0", "AceTimer-3.0")

-- Purpose: Setup addon, setup shared functions

function Chronicler:TraceDump( ...)
    if DLAPI then DLAPI.DebugLog("Chronicler", Chronicler:Serialize(...)) end
end

function Chronicler:TraceFormat(...)
  local status, res = pcall(format, ...)
  if status then
    if DLAPI then DLAPI.DebugLog("Chronicler", res) end
  end
end

