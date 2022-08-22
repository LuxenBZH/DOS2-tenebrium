----- Hex
local hexed = {}

--- @param character EclCharacter
local function CharacterSetHexFX(character)
    if not hexed[character.NetID] then
        hexed[character.NetID] = character.Scale
        character:SetScale(character.Scale * 0.65)
    end
end

---@param character EclCharacter
local function CharacterRemoveHexFX(character)
    if hexed[character.NetID] then
        character:SetScale(hexed[character.NetID])
        hexed[character.NetID] = nil
    end
end

Ext.RegisterNetListener("TEN_SetHexFX", function(channel, payload, ...)
    local character = Ext.ClientEntity.GetCharacter(tonumber(payload))
    CharacterSetHexFX(character)
end)

Ext.RegisterNetListener("TEN_RemoveHexFX", function(channel, payload, ...)
    local character = Ext.ClientEntity.GetCharacter(tonumber(payload))
    CharacterRemoveHexFX(character)
end)

Ext.RegisterNetListener("TEN_BounceHexList", function(channel, payload, ...)
    local characters = Ext.Json.Parse(payload)
    if characters then
        for guid, netID in pairs(characters) do
            CharacterSetHexFX(Ext.ClientEntity.GetCharacter(tonumber(netID)))
        end
    end
end)

--- @param e EclLuaGameStateChangedEvent
Ext.Events.GameStateChanged:Subscribe(function(e)
    if e.FromState == "PrepareRunning" and e.ToState == "Running" then
        local handle = Ext.UI.DoubleToHandle(Ext.UI.GetByType(40):GetRoot().hotbar_mc.characterHandle)
        if Ext.Utils.IsValidHandle(handle) then
            Ext.Net.PostMessageToServer("TEN_RequestHexList", Ext.Entity.GetCharacter(handle))
        else
            Ext.Net.PostMessageToServer("TEN_RequestHexList", "Host")
        end
    end
end)