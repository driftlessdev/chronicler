---@class Chronicler: AceAddon, AceConsole-3.0, AceEvent-3.0, AceSerializer-3.0, AceTimer-3.0
local Chronicler = LibStub("AceAddon-3.0"):NewAddon("Chronicler", "AceConsole-3.0", "AceEvent-3.0", "AceSerializer-3.0", "AceTimer-3.0")

-- Purpose: Setup addon, setup shared functions

function Chronicler:IsDebugOn()
    return self.db.profile.settings.other.debug
end

---Formats text and logs with DLAPI [https://www.curseforge.com/wow/addons/debuglog]
---@param text string|table Text to default to log. Can be an array and will log every line
---@param status string|nil
---|"'OK'" # show text as green in log
---|"'WARN'" # show text as yellow in log
---|"'ERR'" # show text as red in log
---@param verbosity number|nil Verbosity. Default is 6, accepts 1-9
---@param category string|nil Which category for message in window
local function DebugLog(text,status,verbosity,category)
  if not DLAPI then return end

  -- Swap out %, can confuse tracer
  text = string.gsub(text,"%%","$")
  local prefix = ""
  if status ~= nil then
    prefix = status .. "~"
  end

  if type(verbosity) == "number" and verbosity >= 1 and verbosity <= 9 then
    if prefix == "" then
      prefix = tostring(verbosity)
    else
      prefix = prefix .. tostring(verbosity) .. "~"
    end
  end

  if type(category) == "string" then
    if prefix == "" then
      prefix = category
    else
      prefix = prefix .. category .. "~"
    end
  end

  if type(text) == "table" then
    for _, value in pairs(text) do
      DLAPI.DebugLog("Chronicler", prefix .. string.gsub(tostring(value),"%%","$"))
    end
  else
    DLAPI.DebugLog("Chronicler", prefix .. string.gsub(tostring(text),"%%","$"))
  end

end

function Chronicler:TraceDump(...)
  if not DLAPI then return end

  local args = {...}
  local result = {}
  self:TableToText(args, result, 0)

  DebugLog(result,nil,9,"DUMP")
end

function Chronicler:TableToText(inTable,outTable, level)
  level = level or 0
  local padding = "";
  if level > 0 then
    for _ = 1, level do
      padding = padding .. "-"
    end
  end

  if type(inTable) ~= "table" then return end
  if level > 4 then 
    table.insert(outTable,string.format("%s<MAX>",padding))
    return
  end

  for key, value in pairs(inTable) do
    local valType = type(value)
    if valType == "table" then
      table.insert(outTable,string.format("%s%s",padding, key))
      self:TableToText(value, outTable, level + 1)
    elseif valType == "function" or valType == "thread" or valType == "userdata" then
      table.insert(outTable,string.format("%s%s = <%s>", padding, key, valType))
    else
      table.insert(outTable,string.format("%s%s = %s", padding, key, tostring(value)))
    end
    
  end
end

function Chronicler:TraceFormat(...)
  self:Trace(nil,nil,nil,...)
end

---Trace message if DebugLog installed
---@param status string|nil
---|"'OK'" # show text as green in log
---|"'WARN'" # show text as yellow in log
---|"'ERR'" # show text as red in log
---@param verbosity number|nil Verbosity. Default is 6, accepts 1-9
---@param category string|nil Which category for message in window
---@param ... string Strings to be fed to string.format. First string is the output
function Chronicler:Trace(status,verbosity,category,...)

  local formatSts, res = pcall(format, ...)
  if formatSts then
    DebugLog(res,status,verbosity,category)
    if self:IsDebugOn() then
      self:Print(res)
    end
  elseif DLAPI then
    local args = {...}
    local result = {}
    table.insert(result,"Format Failed")
    self:TableToText(args, result)
    DebugLog(result,status,verbosity,category)
  end
end
---Logs an entru into the Event category in DebugLog with verbosity of 7
---@param ... string Strings to be fed to string.format. First string is the output
function Chronicler:TraceEvent(...)
  self:Trace(nil,7,"Event",...)
end

---@param ... string Strings to be fed to string.format. First string is the output
function Chronicler:TraceErr(...)
  self:Trace("ERR",1,"Error",...)
end
