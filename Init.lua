-- Adapted from https://www.wowace.com/projects/ace3/pages/getting-started

local Chronicler = LibStub("AceAddon-3.0"):NewAddon("Chronicler", "AceConsole-3.0", "AceEvent-3.0", "AceSerializer-3.0", "AceTimer-3.0")

function Chronicler:TraceDump( ...)
    if DLAPI then DLAPI.DebugLog("Chronicler", Chronicler:Serialize(...)) end
end

function Chronicler:TraceFormat(...)
  local status, res = pcall(format, ...)
  if status then
    if DLAPI then DLAPI.DebugLog("Chronicler", res) end
  end
end

function Chronicler:SlashCommandHandler(command)
    Chronicler:Print(string.format("You gave me %s and the message is %s", command, Chronicler.db.profile.msg));
end

function Chronicler:DebugHandler(command)
    --if command == "player" then
        Chronicler:levelUpHandler("PLAYER_LEVEL_UP",random(100))
    --end
end

function Chronicler:InitConfig()
    local options = {
        name = "Chronicler",
        handler = Chronicler,
        type = 'group',
        args = {
            msg = {
                type = 'input',
                name = 'The message',
                desc = 'A reasonable message',
                get = 'GetMyMessage',
                set = 'SetMyMessage'
            }
        }
    }

    options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Chronicler", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Chronicler", "Chronicler")

end

function Chronicler:GetMyMessage(info)
    Chronicler:TraceFormat("GetMyMessage: %s",tostring(Chronicler.db.profile.msg))
    return Chronicler.db.profile.msg
end

function Chronicler:SetMyMessage(info, input)
    Chronicler:TraceFormat("SetMyMessage: %s",input)
    Chronicler.db.profile.msg = input;
end

local function GetDefaults()
    local defaults = {
        profile = {
            msg = "Stock and boring",
        },
    }

    return defaults
end


function Chronicler:OnInitialize()

    -- Throwaway playground for tracking, not saved
    Chronicler.session = {}

    local defaults = GetDefaults()
    self.db = LibStub("AceDB-3.0"):New("ChroniclerDB", defaults)

    Chronicler:RegisterChatCommand("chron", "SlashCommandHandler")
    Chronicler:RegisterChatCommand("chrondebug", "DebugHandler")
    Chronicler:InitConfig()

    Chronicler:TraceFormat("Init Complete")

end

function Chronicler:OnEnable()
    -- Delay a wee bit to get the played time and initialize the character
    if self.db.char.currentLevel == nil then
        Chronicler:TraceFormat("Triggering character initialize")
        Chronicler:ScheduleTimer("LoadTimePlayed",2)
    elseif self.db.char.currentLevel.level ~= UnitLevel("player") then
        Chronicler:TraceFormat("Player level not same as saved.")
        Chronicler:ScheduleTimer("LoadTimePlayed",2)
    end
end