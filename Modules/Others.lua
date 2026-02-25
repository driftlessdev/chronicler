local Chronicler = LibStub("AceAddon-3.0"):GetAddon("Chronicler")

function Chronicler:BuildOtherOptions(groupArgs, configOrder)
    groupArgs.other = {
        order = configOrder,
        type = "group",
        name = "Other",
        inline = true;
        args = {
            death = {
                order = 1,
                type = "group",
                name = "Death",
                desc = "When you die, memorialize the moment.",
                inline = true,
                args = {
                    screenshot = {
                        order = 1,
                        type = "toggle",
                        name = "Screenshot",
                        desc = "Say cheese upon death.",
                    },
                    showCount = {
                        order = 2,
                        type = "toggle",
                        name = "Show Level Death Count",
                        desc = "Show the number of times you've died this level.",
                        disabled = function () return not self.db.profile.settings.other.death.screenshot end,
                    },
                }
            },
            achievement = {
                order = 2,
                type = "group",
                name = "Achievements",
                desc = "When you get props, screenshot",
                inline = true,
                args = {
                    screenshot = {
                        order = 1,
                        type = "toggle",
                        name = "Screenshot",
                        desc = "Record the moment",
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

    local settings = self:ProfileSettings()
    if not settings.other.death.screenshot then
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

    self:QueueScreenshot(1)
end

Chronicler:RegisterEvent("PLAYER_DEAD", "HandleDeath")
Chronicler:RegisterEvent("ACHIEVEMENT_EARNED", "HandleAchievement")