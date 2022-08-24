RegisterTurnTrueStartListener(function(character)
    SetTag(character, "TEN_Sigil_TurnStart")
    if HasActiveStatus(character, "TEN_SIGIL_AURORA") == 1 then
        AddTEnergy(character, -5)
    elseif  HasActiveStatus(character, "TEN_SIGIL_OBSCURA") == 1 then
        AddTEnergy(character, 10)
    end 
end)

Ext.Osiris.RegisterListener("CharacterStartAttackObject", 3, "after", function(defender, owner, attacker)
    if Osi.HasActiveStatus(attacker, "TEN_SIGIL_HOLLOWNESS") == 1 then
        local instigator = Ext.ServerEntity.GetCharacter(attacker)
        instigator.Stats.CurrentVitality = instigator.Stats.CurrentVitality - Ext.Round(instigator.Stats.MaxVitality*0.02)
    end
end)

Ext.Osiris.RegisterListener("CharacterUsedSkill", 4, "after", function(character, skill, skillType, skillElement)
    if Osi.HasActiveStatus(character, "TEN_SIGIL_HOLLOWNESS") == 1 then
        local skill = Ext.Stats.Get(skill)
        if skill["Damage Multiplier"] > 0 or skill.Name == "Target_TEN_PowerHit" then
            local instigator = Ext.ServerEntity.GetCharacter(character)
            instigator.Stats.CurrentVitality = instigator.Stats.CurrentVitality - Ext.Round(instigator.Stats.MaxVitality*0.02)
        end
    end
end)

Ext.Osiris.RegisterListener("ObjectLeftCombat", 2, "after", function(object, combatID)
    Osi.RemoveStatus(object, "TEN_SIGIL_HOLLOWNESS")
end)
