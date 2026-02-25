local Chronicler = LibStub("AceAddon-3.0"):GetAddon("Chronicler")


function Chronicler:SetOption(info, value)
    local opts = Chronicler.db.profile;
    -- Ignore root which is just tab grouping for settings/profile
    for level = 1, #info do
        if level == #info then
            -- Set leaf value
            opts[info[level]] = value;
        else
            -- Keep rolling down the chain, building if needed
            opts[info[level]] = opts[info[level]] or {};
            opts = opts[info[level]];
        end
        
    end
    opts[info[#info]] = value;
end

function Chronicler:GetOption(info)
    local opts = Chronicler.db.profile;
    local value = nil;

    -- Ignore root which is just tab grouping for settings/profile
    for level = 1, #info do
        if level == #info then
            -- Set leaf value
            value = opts[info[level]];
        else
            -- Keep rolling down the chain, building if needed
            opts[info[level]] = opts[info[level]] or {};
            opts = opts[info[level]];
        end
        
    end

    return value
end

function Chronicler:GetDefaults()
    local defaults = {
        profile = {
            settings = {
                leveling = {
                    screenshot = true,
                    showTime = true,
                },
                bosses = {
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
                },
                other = {
                    death = {
                        screenshot = true,
                        showCount = true,
                    },
                    achievement = {
                        screenshot = true,
                    },
                },
            },
        },
    }

    return defaults
end


function Chronicler:BuildOptionTable()

    local options = {
        name = "Chronicler",
        handler = Chronicler,
        type = 'group',
        get = 'GetOption',
        set = 'SetOption',
        childGroups = "tab",
        args = {
            settings = {
                order = 1,
                type = "group",
                name = "Settings",
                childGroups = "tab",
                args = {
                    leveling = self:BuildLevelOptions(1),
                    bosses = self:BuildBossOptions(2),
                    other = self:BuildOtherOptions(3),
                }
            }
        }
    }

    return options;

end

function Chronicler:InitConfig()
    local options = self:BuildOptionTable();

    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Chronicler", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Chronicler", "Chronicler")

end

function Chronicler:BuildLevelOptions(configOrder)
    local options = {
        order = configOrder,
        type = "group",
        name = "Leveling",
        inline = true;
        args = {
            screenshot = {
                order = 1,
                type = "toggle",
                name = "Screenshot",
                desc = "Take a screenshot on leveling",
            },
            showTime = {
                order = 2,
                type = "toggle",
                name = "Show Level Timing",
                desc = "Show how long it took to reach the new level",
                disabled = function () return not self.db.profile.settings.leveling.screenshot end
            }
        }
    }

    return options
end

function Chronicler:BuildBossOptions(configOrder)
    local options = {
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

    return options
end

function Chronicler:BuildOtherOptions(configOrder)
    local options = {
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

    return options
end