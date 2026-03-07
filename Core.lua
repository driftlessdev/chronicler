---@class Chronicler
local Chronicler = LibStub("AceAddon-3.0"):GetAddon("Chronicler")

function Chronicler:DebugHandler(command)
    if command == "player" then
        Chronicler:levelUpHandler("PLAYER_LEVEL_UP",random(100))
    elseif command == "death" then
        Chronicler:HandleDeath()
    elseif command == "dungeon" then
        Chronicler:HandleEncounterEnd(nil, 2007, nil, 1, nil, 1)
    elseif command == "trigger" then
        self:QueueScreenshot({"Manual screenshot trigger"})
    end
end

function Chronicler:OnInitialize()

    -- Throwaway playground for tracking, not saved
    Chronicler.session = {}

    local defaults = self:GetDefaults()
    self.db = LibStub("AceDB-3.0"):New("ChroniclerDB", defaults)

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

--[[
If multiple events happen in a short timeframe (boss + achievements) only
let 1 active timer run with a cooldown period.
]]--
function Chronicler:QueueScreenshot(messageList)
    self:TraceFormat("QueueScreenshot(%s)", Chronicler:Serialize(messageList))
    if self.session.screenshot == nil then
        self.session.screenshot = {}
    end

    local delaySeconds = self:ProfileSettings().other.delaySec

    self:TraceFormat("Screenshot in %s seconds.", delaySeconds)

    delaySeconds = delaySeconds or 2
    local msgQueue = self.session.screenshot.messages
    if msgQueue == nil then
        self.session.screenshot.messages = {}
        self.session.screenshot.messages[0] = 0
        msgQueue = self.session.screenshot.messages
    end

    if messageList ~= nil then
        self:TraceFormat("Adding messages")
        local index = msgQueue[0]
        for _, value in pairs(messageList) do
            index = index + 1
            msgQueue[index] = value
        end
        self.session.screenshot.messages[0]=index
    end

    -- Don't add a new timer
    if self.session.screenshot.queued == 1 then
        self:TraceFormat("Screenshot queued. Skipping")
        return
    end

    self.session.screenshot.queued = 1
    self:ScheduleTimer("Screenshot",delaySeconds)
end

function Chronicler:Screenshot()
    self:TraceFormat("Say cheese!")
    for index, message in pairs(self.session.screenshot.messages) do
        if index ~= 0 then
            self:Print(message)    
        end
    end
    Screenshot()
    self.session.screenshot.messages = {}
    self.session.screenshot.messages[0] = 0
    self.session.screenshot.queued = 0
end