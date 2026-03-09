---@class Chronicler
local Chronicler = LibStub("AceAddon-3.0"):GetAddon("Chronicler")

--@do-not-package@
function Chronicler:DebugHandler(command)
    if command == "level" then
        self.session.testLevel = true
        Chronicler:levelUpHandler("PLAYER_LEVEL_UP",UnitLevel("player"))
    elseif command == "death" then
        Chronicler:HandleDeath()
    elseif command == "dungeon" then
        Chronicler:HandleEncounterEnd(nil, 2007, nil, 1, nil, 1)
    elseif command == "trigger" then
        self:QueueScreenshot({"Manual screenshot trigger"})
    elseif command == "renown" then
        -- Silvermoon Court
        Chronicler:HandleFactionLevelChange("TEST",2710, 10, 9)
    end
end
--@end-do-not-package@

function Chronicler:CommandHandler(...)
    LibStub("AceConfigDialog-3.0"):Open("Chronicler")
end

function Chronicler:OnInitialize()

    -- Throwaway playground for tracking, not saved
    Chronicler.session = {}

    local defaults = self:GetDefaults()
    self.db = LibStub("AceDB-3.0"):New("ChroniclerDB", defaults)

    --@do-not-package@
    Chronicler:RegisterChatCommand("chrondebug", "DebugHandler")
    --@end-do-not-package@
    Chronicler:RegisterChatCommand("chron", "CommandHandler")
    Chronicler:InitConfig()

    Chronicler:Trace(nil,5,"Events","Init Complete")

end

function Chronicler:OnEnable()
    -- Delay a wee bit to get the played time and initialize the character
    Chronicler:ScheduleTimer("SetupTimePlayed",2)
end

--[[
If multiple events happen in a short timeframe (boss + achievements) only
let 1 active timer run with a cooldown period.
]]--
function Chronicler:QueueScreenshot(messageList)
    self:TraceFunc("QueueScreenshot(%s)", tostring(#messageList))
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
            self:TraceFormat("-%s", value)
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