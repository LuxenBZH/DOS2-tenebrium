---- Mechanical part

local function CalculateTEIncrease(character, multiplier)
    -- local tInfusionData = CustomStatSystem:GetStatByID("TenebriumInfusion", TenID)
    -- local tInfusion = tInfusionData:GetValue(character)
    local tInfusion = Ext.GetCharacter(character):GetCustomStat(StatTI.Id)
    if tInfusion == 0 then return end
    -- if tInfusion < 20 then tInfusion = 20 end
    if multiplier > 1 then multiplier = 1 end
    local maxRange = math.max(math.ceil(tInfusion/2.5), 5)
    local scaledDamp = math.log(50-(tInfusion/3))/2
    -- local gain = Ext.Round((tInfusion*scaledDamp)*multiplier)
    local gain = Ext.Round(Ext.Math.Lerp(0, maxRange, multiplier))
    -- tInfusionData:SetValue(character, CustomStatSystem:GetStatByID("TenebriumEnergy", TenID):GetValue(character)+gain)
    SetVarInteger(character, "SRP_TEnergy", gain)
    SetStoryEvent(character, "SRP_UpdateTE")
end

local function ScaleTenebriumDamage(target, instigator, statusHitHandle)
    if instigator == nil then return end
    -- Tenebrium damage scaled by infusion
    local bonus = CustomStatSystem:GetStatByID("TenebriumInfusion", TenID):GetValue(instigator) / 1.5
    local shadowDmg = NRD_HitStatusGetDamage(target.MyGuid, statusHitHandle, "Shadow")
    NRD_HitStatusAddDamage(target, statusHitHandle, "Shadow", math.floor(shadowDmg*(bonus/100)))
end

local function ApplyTenebriumOverchargeMultiplier(target, statusHitHandle)
    local te = CustomStatSystem:GetStatByID("TenebriumEnergy", TenID):GetValue(target)
    local ti = CustomStatSystem:GetStatByID("TenebriumInfusion", TenID):GetValue(target)
    local diff = te - ti
    if diff > 0 then
        for i,dmgType in pairs(damageTypes) do
            local base = NRD_HitStatusGetDamage(target.MyGuid, statusHitHandle, dmgType)
            NRD_HitStatusAddDamage(target, statusHitHandle, dmgType, math.floor(base*(diff/100)))
        end
        -- hit.DamageList:Multiply(1.0+(diff/100))
    end
end

-- Unlucky events
---@param target string GUID
---@param status string
---@param handle integer status handle
---@param instigator string GUID
local function HitAnalysis(target, instigator, damage, handle)
    local instigatorMultiplier = 0.5
    local instigatorGain = false
    local targetMultiplier = 0.5
    local targetGain = false
    local pass,target = pcall(Ext.GetCharacter, target)
    if not pass then return end
    if ObjectExists(instigator) == 0 then return end
    if Ext.GetGameObject(instigator) == nil then return end
    local pass,instigator = pcall(Ext.GetCharacter, instigator)
    if not pass then return end
    local status = Ext.GetStatus(target.MyGuid, handle)

    -- Flags
    local dodged = NRD_StatusGetInt(target.MyGuid, handle, "Dodged")
    local missed = NRD_StatusGetInt(target.MyGuid, handle, "Missed")
    local critical = NRD_StatusGetInt(target.MyGuid, handle, "CriticalHit")
    local backstab = NRD_StatusGetInt(target.MyGuid, handle, "Backstab")
    local sourceType = NRD_StatusGetInt(target.MyGuid, handle, "DamageSourceType")
    local blocked = NRD_StatusGetInt(target.MyGuid, handle, "Blocked")
    -- local shadowDmg = NRD_HitStatusGetDamage(target.MyGuid, handle, "Shadow")
    -- local bonus = GetCustomStatPoints(instigator, "Tenebrium infusion") / 2
    -- Ext.Print(bonus, shadowDmg*(bonus/100))
    -- NRD_HitStatusAddDamage(target, handle, "Shadow", shadowDmg*(bonus/100))
    if sourceType == 1 or sourceType == 2 or sourceType == 3 then return end
    
    -- Critical hit gain
    if critical == 1 and backstab == 0 then
        targetMultiplier = (100 - instigator.Stats.CriticalChance)/100 * Osi.NRD_CharacterGetComputedStat(instigator.MyGuid, "CriticalMultiplier", 0) / 100
        targetGain = true
    end
    -- Sigil of Hollowness
    if target:GetStatus("TEN_SIGIL_HOLLOWNESS") then
        for i, dmgType in pairs(damageTypes) do
            local dmg = NRD_HitStatusGetDamage(target.MyGuid, handle, dmgType)
            if dmg > 0 then
                targetMultiplier = math.min(dmg/(4*Game.Math.GetAverageLevelDamage(target.Stats.Level)), 1)
                targetGain = true
            end
        end
    end

    -- Miss gain
    if dodged == 1 or missed == 1 or blocked == 1 then
        local weapon = Ext.GetItem(instigator.Stats.MainWeapon)
        if weapon ~= nil then 
            if not weapon.Stats.IsTwoHanded then instigatorMultiplier = instigatorMultiplier * 0.5 end
            if not Game.Math.IsRangedWeapon(weapon) then instigatorMultiplier = instigatorMultiplier * 0.66 end
        end
        instigatorMultiplier = instigatorMultiplier * Game.Math.CalculateHitChance(instigator.Stats, target.Stats)/100
        instigatorGain = true
    else
        -- Resistance gain
        for i, dmgType in pairs(damageTypes) do
            -- Ext.Print(hitContext.Hit)
            -- local dmg = hitContext.Hit.DamageList.GetByType(hitContext.Hit.DamageList, dmgType)
            local dmg = NRD_HitStatusGetDamage(target.MyGuid, handle, dmgType)
            if dmg > 0 then
                local resistance = target.Stats[dmgType.."Resistance"]
                if resistance > 0 then
                    if not instigatorGain then
                        -- local dmgMultiplier = (1-resistance*0.01) * dmg/Game.Math.GetAverageLevelDamage(instigator.Stats.Level)
                        -- Ext.Print("Resistance TE gain:",dmg,Game.Math.GetAverageLevelDamage(instigator.Stats.Level),dmgMultiplier)
                        instigatorMultiplier = (math.min(resistance*0.01, 1) * math.min(dmg/(resistance*0.01)/Game.Math.GetAverageLevelDamage(instigator.Stats.Level), 1))*0.75
                        instigatorGain = true
                    end
                end
            end
        end
    end
    
    if instigatorGain then
        CalculateTEIncrease(instigator.MyGuid, instigatorMultiplier)
    end
    if targetGain then
        _P("PROCESS TO TE INCREASE", targetMultiplier)
        CalculateTEIncrease(target.MyGuid, targetMultiplier)
    end
    -- 2nd step infusion
    -- if GetOverchargeStep(instigator) > 1 and (status.DamageSourceType == "Attack" or status.SkillId ~= "") then
    --     local dmg = GetTotalDamage(target.MyGuid, handle)
    --     local hit = NRD_HitPrepare(target.MyGuid, target.MyGuid)
    --     NRD_HitAddDamage(hit, "Shadow", math.floor(dmg*0.1))
    --     NRD_HitSetInt(hit, "SimulateHit", 1)
    --     NRD_HitSetInt(hit, "HitType", 5)
    --     NRD_HitSetInt(hit, "CriticalRoll", 2)
    --     NRD_HitExecute(hit)
    -- end
end

-- Ext.RegisterListener("StatusHitEnter", HitAnalysis)
Ext.RegisterOsirisListener("NRD_OnHit", 4, "after", HitAnalysis)

---- Different scaling from skills and Tenebrium mechanics
--- @param status EsvStatusHit
--- @param context HitContext
Ext.RegisterListener("StatusHitEnter", function(status, context)
    local hit = status.Hit
    --- @type EsvCharacter
    local pass,target = pcall(Ext.GetGameObject, status.TargetHandle)
    if not pass then return end
    if Ext.GetGameObject(status.StatusSourceHandle) == nil then
        if status.DamageSourceType == "SurfaceTick" or status.DamageSourceType == "SurfaceMove" or status.DamageSourceType == "SurfaceCreate" then
            HitMultiplyDamage(hit, target, nil, 3.0)
            status.Hit = hit
            return
        end
    else
        local pass,instigator = pcall(Ext.GetCharacter, status.StatusSourceHandle)
        if not pass then return end
        -- Tenebrium damage scaled by infusion
        -- local bonus = CustomStatSystem:GetStatByID("TenebriumInfusion", "ff4dba5a-16e3-420a-aa51-e5c8531b0095"):GetValue(instigator) * Ext.ExtraData.TEN_ShadowDamagePerTi
        local bonus = instigator:GetCustomStat(StatTI.Id) * Ext.ExtraData.TEN_ShadowDamagePerTi
        local shadowDmg = status.Hit.DamageList:GetByType("Shadow")
        hit.DamageList:Add("Shadow", math.floor(shadowDmg*(bonus/100)))
        -- Tainted feet surface multiplier
        if target:GetStatus("TEN_TAINTEDFEET") ~= nil and (status.DamageSourceType == "SurfaceTick" or status.DamageSourceType == "SurfaceMove" or status.DamageSourceType == "SurfaceCreate") then
            HitMultiplyDamage(hit, target, instigator, 3.0)
        end
        status.Hit = hit
    end
end)

-- Ext.RegisterOsirisListener("ObjectLeftCombat", 2, "after", function(object, combatID)
--     if ObjectIsCharacter(object) == 0 then return end
--     local tInfusion = GetCustomStatPoints(object, "Tenebrium infusion")
--     local tEnergy = GetTenebriumEnergy(object)
--     if tInfusion == 0 then return end
--     if tEnergy > tInfusion then
--         local roll = math.random(1, 100)
--         if roll > tInfusion then
--             local subtract = (tEnergy - tInfusion) < 10 and 1 or tEnergy - tInfusion
--             local increase = tonumber(string.sub(tostring(subtract), 1, 1))
--             if increase < 3 then increase = 3 end
--             Ext.Print("TI increased by", increase, "(rolled",roll,")")
--             CustomStatSystem:GetStatByID("TenebriumEnergy", "ff4dba5a-16e3-420a-aa51-e5c8531b0095"):SetValue(object, tInfusion+increase)
--             PlayEffect(object, "RS3_FX_Overhead_Dice_Purple", "Dummy_OverheadFX")
--             CharacterStatusText(object, "Tenebrium Infusion +"..tostring(increase).." !")
--             -- SetCharacterCustomStatTag(Ext.GetCharacter(object).MyGuid, "SRP_TenebriumInfusion_", tInfusion+increase)
--         end
--     end
-- end)

local incapacitatedTypes = {
    FEAR = true,
    CHARMED = true,
    INCAPACITATED = true,
    KNOCKED_DOWN = true
}

Ext.RegisterOsirisListener("CharacterStatusApplied", 3, "before", function(character, status, causee)
    local sts = ""
    if status ~= "CHARMED" and NRD_StatExists(status) then
        sts = Ext.GetStat(status)
    end
    if status == "CHARMED" or (sts.LoseControl == "Yes" or incapacitatedTypes[sts.StatusType])then
        local turns = GetStatusTurns(character, status)
        if turns > 0 then
            CalculateTEIncrease(character, turns*0.5)
        end
    end
end)

-- Game.Math.DamageBoostTable = {
--     --- @param character StatCharacter
--     Physical = function (character)
--         return character.WarriorLore * Ext.ExtraData.SkillAbilityPhysicalDamageBoostPerPoint
--     end,
--     --- @param character StatCharacter
--     Fire = function (character)
--         return character.FireSpecialist * Ext.ExtraData.SkillAbilityFireDamageBoostPerPoint
--     end,
--     --- @param character StatCharacter
--     Air = function (character)
--         return character.AirSpecialist * Ext.ExtraData.SkillAbilityAirDamageBoostPerPoint
--     end,
--     --- @param character StatCharacter
--     Water = function (character)
--         return character.WaterSpecialist * Ext.ExtraData.SkillAbilityWaterDamageBoostPerPoint
--     end,
--     --- @param character StatCharacter
--     Earth = function (character)
--         return character.EarthSpecialist * Ext.ExtraData.SkillAbilityPoisonAndEarthDamageBoostPerPoint
--     end,
--     --- @param character StatCharacter
--     Poison = function (character)
--         return character.EarthSpecialist * Ext.ExtraData.SkillAbilityPoisonAndEarthDamageBoostPerPoint
--     end,
--     Shadow = function(character) 
--         return math.floor(GetCustomStatPoints(character.Character, "Tenebrium infusion") / 1.5) 
--     end
-- }

