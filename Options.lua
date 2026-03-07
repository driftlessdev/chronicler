---@class Chronicler
local Chronicler = LibStub("AceAddon-3.0"):GetAddon("Chronicler")

function Chronicler:ProfileSettings()
    return self.db.profile.settings
end

function Chronicler:SetOption(info, value)
    local opts = self:ProfileSettings()

    -- Ignore root which is just Chronicler
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
    local opts = self:ProfileSettings()
    local value = nil

    -- Ignore root which is just Chronicler
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

    local settingsNode = {}
    self:BuildOtherDefaults(settingsNode)
    self:BuildBossDefaults(settingsNode)
    self:BuildLevelingDefaults(settingsNode)

    local defaults = {}
    defaults.profile = {}
    defaults.profile.settings = settingsNode

    return defaults
end


function Chronicler:BuildOptionTable()

    local settingsArgs = {}
    self:BuildLevelOptions(settingsArgs,1)
    self:BuildBossOptions(settingsArgs,2)
    self:BuildOtherOptions(settingsArgs,3)

    local options = {
        name = "Chronicler",
        handler = Chronicler,
        type = 'group',
        get = 'GetOption',
        set = 'SetOption',
        childGroups = "tab",
        args = settingsArgs,
    }

    return options;

end

function Chronicler:InitConfig()
    local options = self:BuildOptionTable();

    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Chronicler", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Chronicler", "Chronicler")

end




