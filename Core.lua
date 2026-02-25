local Chronicler = LibStub("AceAddon-3.0"):GetAddon("Chronicler")

function Chronicler:SlashCommandHandler(command)
    Chronicler:Print(string.format("You gave me %s and the message is %s", command, Chronicler.db.profile.msg));
end

function Chronicler:DebugHandler(command)
    if command == "player" then
        Chronicler:levelUpHandler("PLAYER_LEVEL_UP",random(100))
    elseif command == "death" then
        Chronicler:HandleDeath()
    end
end

function Chronicler:OnInitialize()

    -- Throwaway playground for tracking, not saved
    Chronicler.session = {}

    local defaults = self:GetDefaults()
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

function Chronicler:Screenshot()
    Chronicler:TraceFormat("Say cheese!")
    Screenshot()
end