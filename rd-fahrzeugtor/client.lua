local GateRegistry = {}
local DOOR_OPEN = 0
local DOOR_CLOSED = 1

local function getGateId(gate, index)
    return gate.id or gate.name or ('gate_%d'):format(index)
end

local function getDoorHash(gate, index)
    if gate.doorHash then
        return type(gate.doorHash) == 'string' and joaat(gate.doorHash) or gate.doorHash
    end
    return joaat(('rd_fahrzeugtor_%s'):format(getGateId(gate, index)))
end

local function resolveModel(model)
    if type(model) == 'string' then
        return joaat(model)
    end
    return model
end

local function findDoorEntity(gate)
    local coords = gate.coords
    local radius = gate.searchRadius or gate.distance or 3.0

    if gate.model then
        local entity = GetClosestObjectOfType(
            coords.x, coords.y, coords.z,
            radius,
            resolveModel(gate.model),
            false, false, false
        )

        if entity ~= 0 and DoesEntityExist(entity) then
            return entity
        end
    end

    local entity = GetClosestObjectOfType(coords.x, coords.y, coords.z, radius, 0, false, false, false)
    if entity ~= 0 and DoesEntityExist(entity) then
        return entity
    end
end

local function isDoorOpen(doorHash)
    if not IsDoorRegisteredWithSystem(doorHash) then
        return false
    end
    return DoorSystemGetDoorState(doorHash) == DOOR_OPEN
end

local function setDoorOpen(gateId, open, sync)
    local entry = GateRegistry[gateId]
    if not entry or not entry.ready then
        return
    end

    DoorSystemSetDoorState(entry.doorHash, open and DOOR_OPEN or DOOR_CLOSED, false, false)
    entry.open = open

    if sync then
        TriggerServerEvent('rd-fahrzeugtor:syncDoor', gateId, open)
    end
end

local function registerDoorSystem(gate, index)
    local gateId = getGateId(gate, index)
    local doorHash = getDoorHash(gate, index)
    local entity = findDoorEntity(gate)

    if not entity then
        return false
    end

    local entityCoords = GetEntityCoords(entity)
    local model = resolveModel(gate.model) or GetEntityModel(entity)
    local rate = gate.rate or Config.DoorRate or 1.0

    if not IsDoorRegisteredWithSystem(doorHash) then
        AddDoorToSystem(
            doorHash,
            model,
            entityCoords.x,
            entityCoords.y,
            entityCoords.z,
            false,
            false,
            false
        )
    end

    -- Kein Auto-Öffnen beim Annähern
    DoorSystemSetAutomaticDistance(doorHash, 0.0, false, false)
    DoorSystemSetAutomaticRate(doorHash, rate, false, false)
    DoorSystemSetDoorState(doorHash, DOOR_CLOSED, false, false)

    GateRegistry[gateId] = {
        config = gate,
        doorHash = doorHash,
        entity = entity,
        ready = true,
        open = false,
        zoneId = nil,
    }

    print(('[rd-fahrzeugtor] "%s" registriert | Hash: %s | Modell: %s'):format(
        gateId, doorHash, model
    ))

    return true
end

local function createTargetZone(gateId)
    local entry = GateRegistry[gateId]
    if not entry or entry.zoneId then
        return
    end

    local gate = entry.config
    local label = gate.name or gate.label or gateId

    entry.zoneId = exports.ox_target:addSphereZone({
        coords = gate.coords,
        radius = gate.distance or 2.5,
        debug = Config.Debug or false,
        options = {
            {
                name = ('rd_gate_open_%s'):format(gateId),
                icon = 'fa-solid fa-door-open',
                label = ('%s öffnen'):format(label),
                distance = gate.distance or 2.5,
                canInteract = function()
                    return entry.ready and not isDoorOpen(entry.doorHash)
                end,
                onSelect = function()
                    setDoorOpen(gateId, true, true)
                end,
            },
            {
                name = ('rd_gate_close_%s'):format(gateId),
                icon = 'fa-solid fa-door-closed',
                label = ('%s schließen'):format(label),
                distance = gate.distance or 2.5,
                canInteract = function()
                    return entry.ready and isDoorOpen(entry.doorHash)
                end,
                onSelect = function()
                    setDoorOpen(gateId, false, true)
                end,
            },
        },
    })
end

local function initializeGates()
    for index, gate in ipairs(Config.Gates or {}) do
        local gateId = getGateId(gate, index)

        if registerDoorSystem(gate, index) then
            createTargetZone(gateId)
        else
            print(('[rd-fahrzeugtor] "%s" noch nicht gefunden – warte auf MLO...'):format(gateId))
        end
    end
end

local function waitForMissingGates()
    CreateThread(function()
        local attempts = 0

        while attempts < 60 do
            local pending = false

            for index, gate in ipairs(Config.Gates or {}) do
                local gateId = getGateId(gate, index)
                if not GateRegistry[gateId] or not GateRegistry[gateId].ready then
                    pending = true
                    if registerDoorSystem(gate, index) then
                        createTargetZone(gateId)
                    end
                end
            end

            if not pending then
                print('[rd-fahrzeugtor] Alle Tore registriert und geschlossen.')
                return
            end

            attempts = attempts + 1
            Wait(2000)
        end

        print('[rd-fahrzeugtor] Nicht alle Tore gefunden – prüfe coords/model mit /rd_tor_find')
    end)
end

RegisterNetEvent('rd-fahrzeugtor:applyDoor', function(gateId, open)
    setDoorOpen(gateId, open, false)
end)

RegisterNetEvent('rd-fahrzeugtor:initDoors', function(states)
    for gateId, open in pairs(states or {}) do
        setDoorOpen(gateId, open, false)
    end
end)

CreateThread(function()
    Wait(1000)
    initializeGates()
    waitForMissingGates()
    TriggerServerEvent('rd-fahrzeugtor:requestDoors')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    for gateId, entry in pairs(GateRegistry) do
        if entry.zoneId then
            exports.ox_target:removeZone(entry.zoneId)
        end
        if entry.doorHash and IsDoorRegisteredWithSystem(entry.doorHash) then
            DoorSystemSetDoorState(entry.doorHash, DOOR_CLOSED, false, false)
        end
    end
end)

-- Hilfsbefehle: Door-Entity / Modell herausfinden
RegisterCommand('rd_tor_find', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local entity = GetClosestObjectOfType(coords.x, coords.y, coords.z, 4.0, 0, false, false, false)

    if entity == 0 or not DoesEntityExist(entity) then
        print('[rd-fahrzeugtor] Kein Objekt in der Nähe gefunden.')
        return
    end

    local model = GetEntityModel(entity)
    local entCoords = GetEntityCoords(entity)
    local archetype = GetEntityArchetypeName(entity) or 'n/a'

    print('========== rd-fahrzeugtor /rd_tor_find ==========')
    print(('Entity: %s | Modell: %s (0x%X)'):format(entity, model, model))
    print(('Archetype: %s'):format(archetype))
    print(('Coords: vector3(%.3f, %.3f, %.3f)'):format(entCoords.x, entCoords.y, entCoords.z))
    print('Config-Beispiel:')
    print('{')
    print('    name = "Mein Tor",')
    print(('    coords = vector3(%.3f, %.3f, %.3f),'):format(entCoords.x, entCoords.y, entCoords.z))
    print(('    model = %s,'):format(model))
    print('    distance = 2.5,')
    print('}')
    print('=================================================')
end, false)

RegisterCommand('rd_tor_scan', function(_, args)
    local radius = tonumber(args[1]) or 8.0
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local results = {}
    local handle, entity = FindFirstObject()
    local success = true

    while success do
        if DoesEntityExist(entity) then
            local coords = GetEntityCoords(entity)
            local distance = #(coords - playerCoords)
            if distance <= radius then
                results[#results + 1] = {
                    entity = entity,
                    model = GetEntityModel(entity),
                    archetype = GetEntityArchetypeName(entity) or 'n/a',
                    coords = coords,
                    distance = distance,
                }
            end
        end
        success, entity = FindNextObject(handle)
    end

    EndFindObject(handle)

    table.sort(results, function(a, b)
        return a.distance < b.distance
    end)

    print(('========== Scan (%.1fm) – %d Objekte =========='):format(radius, #results))
    for index, entry in ipairs(results) do
        print(('[%d] %.2fm | model=%s | %s | vec3(%.2f, %.2f, %.2f)'):format(
            index,
            entry.distance,
            entry.model,
            entry.archetype,
            entry.coords.x,
            entry.coords.y,
            entry.coords.z
        ))
    end
    print('================================================')
end, false)
