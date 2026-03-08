---@class Chronicler
local Chronicler = LibStub("AceAddon-3.0"):GetAddon("Chronicler")
local TXT = LibStub("AceLocale-3.0"):GetLocale("Chronicler", true)

function Chronicler:BuildBossDefaults(settingNode)
    settingNode.bosses = {
        screenshot = true,
        onlyFirst = true,
        delves = true,
        dungeon = {
            follower = false,
            normal = true,
            heroic = true,
            mythic = true,
        },
        raid = {
            story = false,
            lfr = true,
            normal = true,
            heroic = true,
            mythic = true,
        }
    }
end

function Chronicler:BuildBossOptions(groupArgs, configOrder)

    groupArgs.bosses = {
        order = configOrder,
        type = "group",
        name = TXT["Boss Kills"],
        args = {
            screenshot = {
                order = 1,
                type = "toggle",
                name = TXT["Screenshot"],
                desc = TXT["Take a screenshot on a boss kill."],
            },
            onlyFirst = {
                order = 2,
                type = "toggle",
                name = TXT["First Kills Only"],
                desc = TXT["Only screenshot first time kill is detected."],
                disabled = function () return not self:ProfileSettings().bosses.screenshot end
            },
            delves = {
                order = 2.5,
                type = "toggle",
                name = TXT["Delves"],
                desc = TXT["Boss kills when in a delve"],
                disabled = function () return not self:ProfileSettings().bosses.screenshot end
            },
            dungeon = {
                order = 3,
                type = "group",
                name = TXT["Dungeons"],
                desc = TXT["Which dungeons to take boss kill screenshots."],
                inline = true,
                disabled = function () return not self:ProfileSettings().bosses.screenshot end,
                args = {
                    follower = {
                        order = 1,
                        type = "toggle",
                        name = TXT["Follower"],
                        desc = TXT["Boss kills on follower dungeon difficulty"],
                    },
                    normal = {
                        order = 2,
                        type = "toggle",
                        name = TXT["Normal"],
                        desc = TXT["Boss kills on normal dungeon difficulty"],
                    },
                    heroic = {
                        order = 3,
                        type = "toggle",
                        name = TXT["Heroic"],
                        desc = TXT["Boss kills on heroic dungeon difficulty"],
                    },
                    mythic = {
                        order = 4,
                        type = "toggle",
                        name = TXT["Mythic"],
                        desc = TXT["Boss kills on mythic dungeon difficulty"],
                    },
                }
            },
            raid = {
                order = 4,
                type = "group",
                name = TXT["Raids"],
                desc = TXT["Which raids to take boss kill screenshots."],
                inline = true,
                disabled = function () return not self:ProfileSettings().bosses.screenshot end,
                args = {
                    story = {
                        order = 1,
                        type = "toggle",
                        name = TXT["Story mode"],
                        desc = TXT["Boss kills on story mode difficulty"],
                    },
                    lfr = {
                        order = 2,
                        type = "toggle",
                        name = TXT["LFR"],
                        desc = TXT["Boss kills on LFR difficulty"],
                    },
                    normal = {
                        order = 3,
                        type = "toggle",
                        name = TXT["Normal"],
                        desc = TXT["Boss kills on normal raid difficulty"],
                    },
                    heroic = {
                        order = 4,
                        type = "toggle",
                        name = TXT["Heroic"],
                        desc = TXT["Boss kills on heroic raid difficulty"],
                    },
                    mythic = {
                        order = 5,
                        type = "toggle",
                        name = TXT["Mythic"],
                        desc = TXT["Boss kills on mythic raid difficulty"],
                    },
                }
            }
        }
    }
end

function Chronicler:HandleBOSS_KILL(_, encounterId, encounterName)

    self:TraceEvent("HandleBOSS_KILL(%s, %s)", encounterId, encounterName)

    local settings = self:ProfileSettings().bosses

    if not settings.screenshot then
        self:TraceFormat("Boss screenshots off")
        return
    end

    local bossInfo = self.db.char.bossInfo
    if bossInfo == nil then
        self.db.char.bossInfo = {}
        bossInfo = self.db.char.bossInfo
    end

    local _, instanceType, difficultyId, difficultyName = GetInstanceInfo()
    local _, _, isHeroic, isChallengeMode, displayHeroic, displayMythic, _, isLFR = GetDifficultyInfo(difficultyId)

    if instanceType ~= "raid" and instanceType ~= "party" and difficultyId ~= 208 then -- 208 = Delves
        self:TraceErr("Invalid type %s", instanceType)
        return
    end

    -- Handle some special one offs
    if difficultyId == 205 and not settings.dungeon.follower then
        -- Follower dungeons
        return
    elseif difficultyId == 220 and not settings.raid.story then
        -- Story mode
        return
    elseif difficultyId == 7 and not settings.raid.lfr then
        -- Legacy LFR
        return
    elseif instanceType == "raid" and not self:RaidScreenshot(isHeroic, displayHeroic, displayMythic, isLFR) then
        return
    elseif instanceType == "party" and not self:DungeonScreenshot(isHeroic,isChallengeMode,displayMythic) then
        return
    elseif difficultyId == 208 and not settings.delves then
        return
    end

    if bossInfo[difficultyId] == nil then
        bossInfo[difficultyId] = {}
    end

    if bossInfo[difficultyId][encounterId] == nil then
        bossInfo[difficultyId][encounterId] = 0
    end

    bossInfo[difficultyId][encounterId] = bossInfo[difficultyId][encounterId] + 1

    self:TraceFormat("Setting: %s", tostring(settings.onlyFirst))
    self:TraceFormat("Enc Kill %s", bossInfo[difficultyId][encounterId])

    if bossInfo[difficultyId][encounterId] > 1 and settings.onlyFirst then
        self:TraceFormat("Setting off")
        return
    end


    local message = { string.format(TXT["%s (%s) kill #%s"],encounterName,difficultyName,bossInfo[difficultyId][encounterId]) }

    self:QueueScreenshot(message)
end

function Chronicler:DungeonScreenshot(isHeroic,isChallengeMode,displayMythic)
    local settings = self:ProfileSettings().bosses

    -- Mythic or mythic keystone
    if (isHeroic and isChallengeMode) or (isHeroic and displayMythic) then
        return settings.dungeon.mythic
    end

    -- Heroic
    if isHeroic then
        return settings.dungeon.heroic
    end

    return settings.dungeon.normal
    
end

-- Difficulty list https://warcraft.wiki.gg/wiki/DifficultyID
function Chronicler:RaidScreenshot(isHeroic,displayHeroic,displayMythic,isLFR)
    local settings = self:ProfileSettings().bosses

    if isLFR then 
        return settings.raid.lfr
    end

    -- Mythics
    if displayMythic then
        return settings.raid.mythic
    end

    -- Heroic
    if isHeroic or displayHeroic then
        return settings.raid.heroic
    end

    return settings.raid.normal

end

function Chronicler:HandleEncounterEnd(_, encounterId, _, difficultyId, _, success)
    -- Here for tracing assistance
    self:TraceEvent("HandleEncounterEnd: enc: %s, diff: %s, success: %s", encounterId, difficultyId, success)
end


Chronicler:RegisterEvent("BOSS_KILL", "HandleBOSS_KILL")
Chronicler:RegisterEvent("ENCOUNTER_END", "HandleEncounterEnd")