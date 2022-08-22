function InitCstats()
    CStats = {
    Endurance = Ext.GetCustomStatByName("Endurance"),
    Body = Ext.GetCustomStatByName("Body"),
    Willpower = Ext.GetCustomStatByName("Willpower"),
    Mind = Ext.GetCustomStatByName("Mind"),
    Agility = Ext.GetCustomStatByName("Agility"),
    Perception = Ext.GetCustomStatByName("Perception"),
    ["Tenebrium Infusion"] = Ext.GetCustomStatByName("Tenebrium Infusion"),
    ["Tenebrium Energy"] = Ext.GetCustomStatByName("Tenebrium Energy")
}

    StatTI = Ext.GetCustomStatByName("Tenebrium Infusion")
    StatTE = Ext.GetCustomStatByName("Tenebrium Energy")
end

Ext.RegisterListener("SessionLoaded", InitCstats)

-- CustomStatSystem = Mods.LeaderLib.CustomStatSystem

Ext.RegisterNetListener("SRP_ClientReady", function(channel, payload, user)
    Ext.PostMessageToUser(user, "SRP_CustomStatsInfos", Ext.JsonStringify(CStats))
end)

-- Ext.RegisterOsirisListener("UserConnected", 3, "before", function(userID, userName, userProfileID)
--     Ext.PostMessageToUser(userID, "SRP_CustomStatsInfos", Ext.JsonStringify(CStats))
-- end)

-------- Turn listeners (delay check)
local TurnListeners = {
    Start = {},
    End = {}
}

Ext.RegisterOsirisListener("CharacterGuarded", 1, "before", function(character)
    ObjectSetFlag(character, "HasDelayed")
end)

Ext.RegisterOsirisListener("ObjectTurnEnded", 1, "before", function(character)
    if ObjectGetFlag(character, "HasDelayed") == 0 then
        for i, listener in pairs(TurnListeners.End) do
            listener.Handle(character)
        end
    end
end)

Ext.RegisterOsirisListener("ObjectTurnStarted", 1, "before", function(character)
    if ObjectGetFlag(character, "HasDelayed") == 1 then
        ObjectClearFlag(character, "HasDelayed")
    else
        for i, listener in pairs(TurnListeners.Start) do
            listener.Handle(character)
        end
    end
end)

function RegisterTurnTrueStartListener(func)
    table.insert(TurnListeners.Start, {
        Name = "",
        Handle = func
    })
end

function RegisterTurnTrueEndListener(func)
    table.insert(TurnListeners.End, {
        Name = "",
        Handle = func
    })
end

Ext.Require("Server/ConsoleCommands.lua")
Ext.Require("Server/Tenebrium/EnergyManagement.lua")
Ext.Require("Server/Tenebrium/EnergyCalc.lua")
Ext.Require("Server/Tenebrium/Sigils.lua")
Ext.Require("Server/Tenebrium/Skills.lua")
Ext.Require("Server/Tenebrium/Overcharge.lua")
Ext.Require("Server/Tenebrium/Infusion.lua")
Ext.Require("Server/Tenebrium/Statuses.lua")