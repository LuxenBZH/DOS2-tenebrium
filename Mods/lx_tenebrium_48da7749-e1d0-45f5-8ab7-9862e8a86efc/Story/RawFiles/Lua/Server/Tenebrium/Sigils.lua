RegisterTurnTrueStartListener(function(character)
    SetTag(character, "TEN_Sigil_TurnStart")
    if HasActiveStatus(character, "TEN_SIGIL_AURORA") == 1 then
        AddTEnergy(character, -5)
    elseif  HasActiveStatus(character, "TEN_SIGIL_OBSCURA") == 1 then
        AddTEnergy(character, 10)
    end 
end)