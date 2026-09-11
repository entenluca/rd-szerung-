local DoorStates = {}

local function getGateId(gate, index)
    return gate.id or gate.name or ('gate_%d'):format(index)
end

local function initDoorStates()
    DoorStates = {}
    for index, gate in ipairs(Config.Gates or {}) do
        local gateId = getGateId(gate, index)
        DoorStates[gateId] = false
    end
end

RegisterNetEvent('rd-fahrzeugtor:syncDoor', function(gateId, open)
    if type(gateId) ~= 'string' or type(open) ~= 'boolean' then
        return
    end

    if DoorStates[gateId] == nil then
        return
    end

    DoorStates[gateId] = open
    TriggerClientEvent('rd-fahrzeugtor:applyDoor', -1, gateId, open)
end)

RegisterNetEvent('rd-fahrzeugtor:requestDoors', function()
    TriggerClientEvent('rd-fahrzeugtor:initDoors', source, DoorStates)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    initDoorStates()
end)

initDoorStates()
