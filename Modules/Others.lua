local Chronicler = LibStub("AceAddon-3.0"):GetAddon("Chronicler")
local TXT = LibStub("AceLocale-3.0"):GetLocale("Chronicler", true)

function Chronicler:BuildOtherOptions(groupArgs, configOrder)
    groupArgs.other = {
        order = configOrder,
        type = "group",
        name = TXT["Other"],
        inline = true;
        args = {
            death = {
                order = 1,
                type = "group",
                name = TXT["Death"],
                desc = TXT["When you die, memorialize the moment."],
                inline = true,
                args = {
                    screenshot = {
                        order = 1,
                        type = "toggle",
                        name = TXT["Screenshot"],
                        desc = TXT["Say cheese upon death."],
                    },
                    showCount = {
                        order = 2,
                        type = "toggle",
                        name = TXT["Show Level Death Count"],
                        desc = TXT["Show the number of times you've died this level."],
                        disabled = function () return not self.db.profile.settings.other.death.screenshot end,
                    },
                }
            },
            achievement = {
                order = 2,
                type = "group",
                name = TXT["Achievements"],
                desc = TXT["When you get props, screenshot"],
                inline = true,
                args = {
                    screenshot = {
                        order = 1,
                        type = "toggle",
                        name = TXT["Screenshot"],
                        desc = TXT["Record the moment"],
                    },
                }
            }
        }
    }
end

function Chronicler:BuildOtherDefaults(settingNode)
    settingNode.other = {
        death = {
            screenshot = true,
            showCount = true,
        },
        achievement = {
            screenshot = true,
        },
    }
end

function Chronicler:HandleAchievement(_eventName, achievementID, alreadyEarned)

    local settings = self:ProfileSettings()
    if not settings.other.achievement.screenshot then
        return
    end

    self:TraceFormat("Achievement: %s, earned? %s" ,achievementID, alreadyEarned)

    self:QueueScreenshot(1)

end

function Chronicler:HandleDeath()

    local settings = self:ProfileSettings().other.death
    if not settings.screenshot then
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
    local message = string.format(TXT["Death #%s as level %s"],count, curLevel)
    Chronicler:TraceFormat("Death msg: %s",message)
    if settings.showCount then
        RaidNotice_AddMessage(RaidBossEmoteFrame, message, ChatTypeInfo["RAID_WARNING"])    
    end

    self:QueueScreenshot(1)
end

Chronicler:RegisterEvent("PLAYER_DEAD", "HandleDeath")
Chronicler:RegisterEvent("ACHIEVEMENT_EARNED", "HandleAchievement")