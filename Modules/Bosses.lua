local Chronicler = LibStub("AceAddon-3.0"):GetAddon("Chronicler")

function Chronicler:BuildBossDefaults(settingNode)
    settingNode.bosses = {
        screenshot = true,
        onlyFirst = true,
        dungeon = {
            follower = false,
            normal = true,
            heroic = true,
            mythic = true,
        },
        raid = {
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
        name = "Boss Kills",
        inline = true;
        args = {
            screenshot = {
                order = 1,
                type = "toggle",
                name = "Screenshot",
                desc = "Take a screenshot on a boss kill.",
            },
            onlyFirst = {
                order = 2,
                type = "toggle",
                name = "First Kills Only",
                desc = "Only screenshot first time kill is detected.",
                disabled = function () return not self.db.profile.settings.bosses.screenshot end
            },
            dungeon = {
                order = 3,
                type = "group",
                name = "Dungeons",
                desc = "Which dungeons to take boss kill screenshots.",
                inline = true,
                disabled = function () return not self.db.profile.settings.bosses.screenshot end,
                args = {
                    follower = {
                        order = 1,
                        type = "toggle",
                        name = "Follower",
                        desc = "Boss kills on follower dungeon difficulty",
                    },
                    normal = {
                        order = 2,
                        type = "toggle",
                        name = "Normal",
                        desc = "Boss kills on normal dungeon difficulty",
                    },
                    heroic = {
                        order = 3,
                        type = "toggle",
                        name = "Heroic",
                        desc = "Boss kills on heroic dungeon difficulty",
                    },
                    mythic = {
                        order = 4,
                        type = "toggle",
                        name = "Mythic",
                        desc = "Boss kills on mythic dungeon difficulty",
                    },
                }
            },
            raid = {
                order = 4,
                type = "group",
                name = "Raids",
                desc = "Which raids to take boss kill screenshots.",
                inline = true,
                disabled = function () return not self.db.profile.settings.bosses.screenshot end,
                args = {
                    lfr = {
                        order = 1,
                        type = "toggle",
                        name = "LFR",
                        desc = "Boss kills on LFR difficulty",
                    },
                    normal = {
                        order = 2,
                        type = "toggle",
                        name = "Normal",
                        desc = "Boss kills on normal raid difficulty",
                    },
                    heroic = {
                        order = 3,
                        type = "toggle",
                        name = "Heroic",
                        desc = "Boss kills on heroic raid difficulty",
                    },
                    mythic = {
                        order = 4,
                        type = "toggle",
                        name = "Mythic",
                        desc = "Boss kills on mythic raid difficulty",
                    },
                }
            }
        }
    }
end