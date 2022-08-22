if not PersistentVars then
    PersistentVars = {}
    PersistentVars.Hex = {}
end

Ext.Require("BootstrapShared.lua")
Ext.Require("Server/_InitServer.lua")

------ Main ------
---- General Functions ----
-- function CheckStatsPresence()
	-- local customStats = {
	-- "---- Aptitudes ----",
	-- "Endurance",
	-- "Willpower",
	-- "Mind",
	-- "Perception",
	-- "Agility",
	-- "Body",
	-- "Might",
	-- "---- Social ----",
	-- "Charisma",
	-- "Manipulation",
	-- "Suasion",
	-- "Intimidation",
	-- "Insight",
	-- "Intuition",
	-- "---- Knowledge ----",
	-- "Alchemist",
	-- "Blacksmith",
	-- "Tailoring",
	-- "Enchanter",
	-- "Survivalist",
	-- "Academics",
	-- "Medicine",
	-- "Magic",
	-- "---- Misc ----",
	-- "Soul points",
	-- "Fortune point",
	-- "Body condition",
	-- "Tenebrium infusion"
	-- }
	
	-- for i,stat in pairs(customStats) do
	-- 	local exists = NRD_GetCustomStat(stat)
	-- 	if exists == nil then
	-- 		local statID = NRD_CreateCustomStat(stat, "")
	-- 	end
	-- end
-- end

--- @param character EsvCharacter
--- @param tagPrefix string
function SetCharacterCustomStatTag(character, tagPrefix, value)
    ClearCharacterCustomStatTag(character, tagPrefix)
    SetTag(character.MyGuid, tagPrefix..value)
end

Ext.RegisterNetListener("SetCharacterTenebriumInfusionTag", function(call, text)
	local netID = string.gsub(text, "_.*$", "")
	local character = Ext.GetCharacter(tonumber(netID))
	local value = string.gsub(text, ".*_", "")
	SetCharacterCustomStatTag(character, "SRP_TenebriumInfusion_", value)
	-- CharacterAddAttribute(character.MyGuid, "Dummy", 0)
end)