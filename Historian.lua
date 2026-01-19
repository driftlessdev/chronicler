local Chronicler = LibStub("AceAddon-3.0"):GetAddon("Chronicler")

function Chronicler:levelUpHandler(_eventName, newLevel, ...)
    self:TraceFormat("Player Level %s, Event %s", newLevel, _eventName);
    self.session.dingLevel = newLevel
    self:LoadTimePlayed()
end

function Chronicler:LoadTimePlayed()
    self:TraceFormat("Requesting played time")
    self:RegisterEvent("TIME_PLAYED_MSG", "timePlayedHandler")
    RequestTimePlayed() -- TIME_PLAYED_MSG event when collected
end

function Chronicler:timePlayedHandler(_eventName, ...)
    local totalplayedSecs,levelplayedSecs = ...

    self:UnregisterEvent("TIME_PLAYED_MSG")

    if self.db.char.currentLevel == nil then
        self:InitLevelInfo(totalplayedSecs,levelplayedSecs)
    else
        self:CharacterLeveled(totalplayedSecs,levelplayedSecs)
    end

end

function Chronicler:CharacterLeveled(totalplayedSecs, levelplayedSecs)
    local newLevel = UnitLevel("player")
    local oldLevelInfo = self.db.char.currentLevel

    if oldLevelInfo == nil then
        self:TraceFormat("This should not happen... New level is %s",newLevel)
        self:InitLevelInfo(totalplayedSecs, levelplayedSecs)
        self.session.dingLevel = nil
        return
    end

    local oldLevel = oldLevelInfo.level

    if newLevel <= oldLevel then
        -- How in the world did you go backwards...
        -- Timelords not allowed. Reset level data.
        self.db.char.levelInfo = {}
        self:InitLevelInfo(totalplayedSecs, levelplayedSecs, true)
        self:TraceFormat("Timelord Detected. Saved %s - New %s", oldLevelInfo.level, newLevel)
    elseif (newLevel - 1) > oldLevel or self.session.dingLevel == nil then
        -- Addon was off for a few levels.
        -- Close current as incomplete, start a new level.
        self:EndLevelInfo(nil,true)
        self:InitLevelInfo(totalplayedSecs, levelplayedSecs, true)
        self:TraceFormat("Skip Detected. Saved %s - New %s", oldLevelInfo.level, newLevel)
    else
        -- Boring old ding
        self:EndLevelInfo(totalplayedSecs)
        self:InitLevelInfo(totalplayedSecs, 0)
        self:TraceFormat("More Power. Saved %s - New %s", oldLevelInfo.level, newLevel)
        local days = math.floor(oldLevelInfo.playedSecs / 86400)
        local hours = math.floor((oldLevelInfo.playedSecs % 86400) / 3600)
        local mins = math.floor((oldLevelInfo.playedSecs % 3600) / 60)
        local secs = oldLevelInfo.playedSecs % 60
        self:TraceFormat("Days %d, Hours %d, Mins %d, Secs: %s, Played: %d", days, hours, mins, secs, oldLevelInfo.playedSecs)
        local levelMessage = ""
        if days > 0 then
            levelMessage = string.format("Level %d in %d days, %d hours, and %d minutes!",newLevel,days,hours,mins)
        elseif hours > 0 then
            levelMessage = string.format("Level %d in %d hours, and %d minutes!",newLevel,hours,mins)
        elseif mins > 0 then
            levelMessage = string.format("Level %d in %d minutes!",newLevel,mins)
        elseif secs > 0 then
            levelMessage = string.format("Leveled blazing fast to %d in %d seconds!",newLevel,secs)
        end
        RaidNotice_AddMessage(RaidWarningFrame, levelMessage, ChatTypeInfo["RAID_WARNING"])
        self:Print(levelMessage)
        if oldLevelInfo.partial then
            local message = "- Level Data Incomplete -"
            RaidNotice_AddMessage(RaidWarningFrame, message, ChatTypeInfo["RAID_WARNING"])
            self:Print(message)
        end
        Chronicler:ScheduleTimer("RememberTheMoment",2)
    end

    self.session.dingLevel = nil
end

function Chronicler:RememberTheMoment()
    Chronicler:TraceFormat("Say cheese!")
    Screenshot()
end

function Chronicler:InitLevelInfo(totalplayedSecs, levelplayedSecs, lateStart)
    self.db.char.currentLevel = {}
    local curLevelInfo = self.db.char.currentLevel

    curLevelInfo.level = UnitLevel("player")
    if curLevelInfo.level == 1 then
        curLevelInfo.startplayedSecs = 0
    else
        curLevelInfo.startplayedSecs = totalplayedSecs - levelplayedSecs
    end
    
    self:TraceFormat("Late? %s", tostring(lateStart))
    if lateStart and curLevelInfo.level > 1 then curLevelInfo.partial = true end

    curLevelInfo.startTime = time()
    curLevelInfo.version = "1.0"
    self:TraceDump("Char Init",curLevelInfo);
end

function Chronicler:EndLevelInfo(totalplayedSecs, forceClose)
    local oldLevelInfo = self.db.char.currentLevel

    oldLevelInfo.endTime = time()
    if totalplayedSecs ~= nil and (totalplayedSecs > 0) then
        oldLevelInfo.endplayedSecs = totalplayedSecs
        oldLevelInfo.playedSecs = totalplayedSecs - oldLevelInfo.startplayedSecs
    end

    self:TraceFormat("Force? %s", tostring(forceClose))
    if forceClose then oldLevelInfo.partial = true end

    self.db.char.levelInfo = self.db.char.levelInfo or {}
    self.db.char.levelInfo[oldLevelInfo.level] = oldLevelInfo
    self:TraceFormat("Closed level %s", oldLevelInfo.level)
end

Chronicler:RegisterEvent("PLAYER_LEVEL_UP", "levelUpHandler")