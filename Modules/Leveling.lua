---@class Chronicler
local Chronicler = LibStub("AceAddon-3.0"):GetAddon("Chronicler")
local TXT = LibStub("AceLocale-3.0"):GetLocale("Chronicler", true)


function Chronicler:BuildLevelOptions(groupArgs,configOrder)
    groupArgs.leveling = {
        order = configOrder,
        type = "group",
        name = "Leveling",
        args = {
            charHeader = {
                order = 50,
                type = "header",
                name = TXT["Character Levels"],
                width = "full",
            },
            screenshot = {
                order = 100,
                type = "toggle",
                name = TXT["Screenshot"],
                desc = TXT["Take a screenshot on leveling"],
            },
            showTime = {
                order = 110,
                type = "toggle",
                name = TXT["Show Level Timing"],
                desc = TXT["Show how long it took to reach the new level"],
                disabled = function () return not self:ProfileSettings().leveling.screenshot end,
            },
            renownHeader = {
                order = 200,
                type = "header",
                name = TXT["Renown Levels"],
                width = "full",
            },
            renown = {
                order = 210,
                type = "toggle",
                name = TXT["Screenshot"],
                desc = TXT["Take a screenshot on a new renown level"],
                width = "full"
            },
        }
    }
end

function Chronicler:BuildLevelingDefaults(settingNode)
    settingNode.leveling = {
        screenshot = true,
        showTime = true,
        renown = true,
    }
end

function Chronicler:levelUpHandler(_eventName, newLevel, ...)
    self:TraceFunc("Player Level %s, Event %s", newLevel, _eventName);
    local settings = self:ProfileSettings().leveling
    if not settings.screenshot then
        return
    end
    self.session.dingLevel = newLevel
    self:LoadTimePlayed()
end

function Chronicler:LoadTimePlayed()
    self:TraceFormat("Requesting played time")
    self:RegisterEvent("TIME_PLAYED_MSG", "timePlayedHandler")
    RequestTimePlayed()
end

function Chronicler:SetupTimePlayed()
    self:TraceFormat("Setting up played time")
    self:RegisterEvent("TIME_PLAYED_MSG", "HandleSetupTimePlayed")
    RequestTimePlayed()
end

function Chronicler:HandleSetupTimePlayed(_, ...)
    local totalplayedSecs,levelplayedSecs = ...
    self:UnregisterEvent("TIME_PLAYED_MSG")
    self:TraceFunc("HandleSetupTimePlayed(%s, %s)", tostring(totalplayedSecs), tostring(levelplayedSecs))
    local levelInfo = self.db.char.currentLevel

    if levelInfo == nil then
        self:InitLevelInfo(totalplayedSecs,levelplayedSecs)
        return
    end

    local curLevel = UnitLevel("player")

    if levelInfo.level ~= curLevel then
        self:EndLevelInfo(nil,true)
        self:InitLevelInfo(totalplayedSecs, levelplayedSecs)
        self:Trace("WARN",4,"Level","Skew Detected. Saved %s - New %s", levelInfo.level, curLevel)
    end
end

function Chronicler:timePlayedHandler(_eventName, ...)
    local totalplayedSecs,levelplayedSecs = ...
    self:TraceEvent("timePlayedHandler(%s, %s, %s)",_eventName, tostring(totalplayedSecs), tostring(levelplayedSecs))

    self:UnregisterEvent("TIME_PLAYED_MSG")
    self:CharacterLeveled(totalplayedSecs,levelplayedSecs)

end
-- [ ] Update handling for new characters to check total time played
function Chronicler:CharacterLeveled(totalplayedSecs, levelplayedSecs)
    local newLevel = UnitLevel("player")
    local oldLevelInfo = self.db.char.currentLevel
    local settings = self:ProfileSettings().leveling

    if oldLevelInfo == nil then
        self:TraceErr("This should not happen... New level is %s",newLevel)
        self:InitLevelInfo(totalplayedSecs, levelplayedSecs)
        self.session.dingLevel = nil
        return
    end

    -- Don't alter session if testing
    if self.session.testLevel then
        oldLevelInfo.playedSecs = 4200
    else
        self:EndLevelInfo(totalplayedSecs)
        self:InitLevelInfo(totalplayedSecs, 0)
    end

    self:TraceFormat("More Power. Saved %s - New %s", oldLevelInfo.level, newLevel)
    local messages = {}
    if settings.showTime then 
        local days = math.floor(oldLevelInfo.playedSecs / 86400)
        local hours = math.floor((oldLevelInfo.playedSecs % 86400) / 3600)
        local mins = math.floor((oldLevelInfo.playedSecs % 3600) / 60)
        local secs = oldLevelInfo.playedSecs % 60
        self:TraceFormat("Days %d, Hours %d, Mins %d, Secs: %s, Played: %d", days, hours, mins, secs, oldLevelInfo.playedSecs)
        local levelMessage = ""
        local levelText = self:ColorLevelText(newLevel)
        if days > 0 then
            levelMessage = string.format(TXT["Level %s in |cnNEUTRAL_STATUS_COLOR:%d days, %d hours, and %d minutes|r!"],levelText,days,hours,mins)
        elseif hours > 0 then
            levelMessage = string.format(TXT["Level %s in |cnNEUTRAL_STATUS_COLOR:%d hours, and %d minutes|r!"],levelText,hours,mins)
        elseif mins > 0 then
            levelMessage = string.format(TXT["Level %s in |cnNEUTRAL_STATUS_COLOR:%d minutes|r!"],levelText,mins)
        elseif secs > 0 then
            levelMessage = string.format(TXT["Leveled blazing fast to %s in |cnNEUTRAL_STATUS_COLOR:%d seconds|r!"],levelText,secs)
        end
        table.insert(messages,levelMessage)

        self:TraceFormat(levelMessage)
    end

    self:QueueScreenshot(messages)

    if self.session.testLevel then
        oldLevelInfo.playedSecs = nil
    end

    self.session.testLevel = false
    self.session.dingLevel = nil
end

function Chronicler:InitLevelInfo(totalplayedSecs, levelplayedSecs)
    self.db.char.currentLevel = {}
    local curLevelInfo = self.db.char.currentLevel

    curLevelInfo.level = UnitLevel("player")
    if curLevelInfo.level == 1 then
        curLevelInfo.startplayedSecs = 0
    else
        curLevelInfo.startplayedSecs = totalplayedSecs - levelplayedSecs
    end

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

function Chronicler:HandleFactionLevelChange(_, factionId, newLevel, oldLevel)
    self:TraceEvent("HandleFactionLevelChange(%s, %s, %s)", factionId, newLevel, oldLevel)
    local settings = self:ProfileSettings().leveling
    if not settings.renown then
        self:TraceErr("Renown settings off %s", tostring(settings.renown))
        return
    end
    local factionData = C_MajorFactions.GetMajorFactionData(factionId)

    if factionData == nil then
        self:TraceErr("No data returned for %s", factionId)
        return
    end

    local nameFormatted = "" 
    if (factionData.factionFontColor and factionData.factionFontColor.color) then
        nameFormatted = factionData.factionFontColor.color:WrapTextInColorCode(factionData.name)
    else
        nameFormatted = string.format("|cnFACTION_YELLOW_COLOR:%s|r", factionData.name)
    end
    
    local message = string.format("%s renown increased to %s", nameFormatted, self:ColorLevelText(factionData.renownLevel))

    self:QueueScreenshot({message})

end

Chronicler:RegisterEvent("PLAYER_LEVEL_UP", "levelUpHandler")
Chronicler:RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED","HandleFactionLevelChange")