local function getPlayerCoords()
    local ped = PlayerPedId()
    if Config.RemoteFromVehicle and IsPedInAnyVehicle(ped, false) then
        return GetEntityCoords(GetVehiclePedIsIn(ped, false))
    end
    return GetEntityCoords(ped)
end

local function findNearestGate(maxRange)
    local playerCoords = getPlayerCoords()
    local nearestId, nearestDist

    for gateId, gateData in pairs(GetAllGates()) do
        local gate = gateData.config
        local gateCoords

        if gateData.entity and DoesEntityExist(gateData.entity) then
            gateCoords = GetEntityCoords(gateData.entity)
        elseif gate.target and gate.target.coords then
            gateCoords = gate.target.coords
        else
            gateCoords = vector3(gate.closed.x, gate.closed.y, gate.closed.z)
        end

        local range = gate.remoteRange or maxRange or Config.RemoteRange
        local dist = #(playerCoords - gateCoords)

        if dist <= range and (not nearestDist or dist < nearestDist) then
            nearestId = gateId
            nearestDist = dist
        end
    end

    return nearestId, nearestDist
end

local function useRemote()
    local gateId, distance = findNearestGate(Config.RemoteRange)

    if not gateId then
        lib.notify({
            title = 'Tor-Fernbedienung',
            description = 'Kein Tor in Reichweite.',
            type = 'error',
        })
        return
    end

    OpenGateUI(gateId)

    lib.notify({
        title = 'Tor-Fernbedienung',
        description = ('Verbunden mit: %s (%.0fm)'):format(GetGateData(gateId).config.label, distance),
        type = 'success',
    })
end

RegisterNetEvent('rd-fahrzeugtor:useRemote', useRemote)

exports('useRemote', useRemote)

-- ox_inventory Item-Export
exports('openNearestGate', function()
    useRemote()
end)

-- Schnellaktionen per Keybind (optional, nur mit Item in Inventar wenn ox_inventory aktiv)
RegisterCommand('rd_tor_remote', function()
    if GetResourceState('ox_inventory') == 'started' then
        local count = exports.ox_inventory:Search('count', Config.RemoteItem)
        if not count or count < 1 then
            lib.notify({
                title = 'Tor-Fernbedienung',
                description = 'Du hast keine Fernbedienung dabei.',
                type = 'error',
            })
            return
        end
    end

    useRemote()
end, false)

RegisterKeyMapping('rd_tor_remote', 'Tor-Fernbedienung benutzen', 'keyboard', 'F6')
