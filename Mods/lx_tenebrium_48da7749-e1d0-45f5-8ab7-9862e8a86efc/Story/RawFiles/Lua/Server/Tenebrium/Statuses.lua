--- @param e EsvLuaGameStateChangedEvent
Ext.Events.GameStateChanged:Subscribe(function(e)
    if e.FromState == "Sync" and e.ToState == "Running" then
        for guid,netid in pairs(PersistentVars.Hex) do
            if Osi.ObjectExists(guid) == 1 then
                PersistentVars.Hex[guid] = Ext.Entity.GetCharacter(guid).NetID
            end
        end
    end
end)

Ext.Osiris.RegisterListener("CharacterStatusApplied", 3, "before", function(character, status, instigator)
    if status == "TEN_HEX" then
        PersistentVars.Hex[Osi.GetUUID(character)] = Ext.Entity.GetCharacter(character).NetID
        Ext.Net.BroadcastMessage("TEN_SetHexFX", PersistentVars.Hex[Osi.GetUUID(character)])
    end
end)

Ext.Osiris.RegisterListener("CharacterStatusRemoved", 3, "before", function(character, status, instigator)
    if status == "TEN_HEX" and Osi.ObjectExists(character) == 1 then
        Ext.Net.BroadcastMessage("TEN_RemoveHexFX", Ext.Entity.GetCharacter(character).NetID)
        PersistentVars.Hex[Osi.GetUUID(character)] = nil
    end
end)

Ext.RegisterNetListener("TEN_RequestHexList", function(channel, payload, ...)
    local client = CharacterGetHostCharacter()
    if payload ~= "Host" then
        client = Ext.Entity.GetCharacter(tonumber(payload)).MyGuid
    end
    local currentMapHex = {}
    for guid,netid in pairs(PersistentVars.Hex) do
        if Osi.ObjectExists(guid) == 1 then
            currentMapHex[#currentMapHex+1] = Ext.Entity.GetCharacter(guid).NetID
        end
    end
    if #currentMapHex > 0 then
        Ext.Net.PostMessageToClient(client, "TEN_BounceHexList", Ext.Json.Stringify(currentMapHex))
    end
end)