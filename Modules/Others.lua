local Chronicler = LibStub("AceAddon-3.0"):GetAddon("Chronicler")

function Chronicler:HandleAchievement(_eventName, achievementID, alreadyEarned)

    if not self.db.profile.settings.other.achievement.screenshot then
        return
    end

    Chronicler:TraceFormat("Achievement: %s, earned? %s" ,achievementID, alreadyEarned)

    Chronicler:ScheduleTimer("Screenshot",1)

end

function Chronicler:HandleDeath()

    Chronicler:TraceFormat("DEATH!")

    if not self.db.profile.settings.other.death.screenshot then
        return
    end

    local curLevel = UnitLevel("player")
    if self.db.char.deathData == nil or self.db.char.deathData.level ~= curLevel then
        self.db.char.deathData = {
            level = curLevel,
            count = 0,
        }
    end

    local count = self.db.char.deathData.count + 1
    self.db.char.deathData.count = count
    local message = string.format("You've died %s times as level %s",count, curLevel)
    Chronicler:TraceFormat("Death msg: %s",message)
    RaidNotice_AddMessage(RaidBossEmoteFrame, message, ChatTypeInfo["RAID_WARNING"])

    Chronicler:ScheduleTimer("Screenshot",1)
end

-- PLAYER_DEAD
Chronicler:RegisterEvent("PLAYER_DEAD", "HandleDeath")
Chronicler:RegisterEvent("ACHIEVEMENT_EARNED", "HandleAchievement")