local function getLookedAtObject(maxDistance)
    local hit, entity = lib.raycast.fromCamera(511, 4, maxDistance or 15.0)
    if hit and entity and entity ~= 0 and DoesEntityExist(entity) then
        return entity
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local dest = coords + forward * 8.0
    local ray = StartShapeTestRay(coords.x, coords.y, coords.z + 0.5, dest.x, dest.y, dest.z + 0.5, 16, ped, 0)
    local _, didHit, _, _, rayEntity = GetShapeTestResult(ray)

    if didHit == 1 and rayEntity and rayEntity ~= 0 and DoesEntityExist(rayEntity) then
        return rayEntity
    end
end

local function findStackedPanels(originEntity, radius)
    local originCoords = GetEntityCoords(originEntity)
    local originModel = GetEntityModel(originEntity)
    local panels = {
        {
            entity = originEntity,
            coords = originCoords,
            heading = GetEntityHeading(originEntity),
            model = originModel,
        },
    }

    local handle, entity = FindFirstObject()
    local success = true

    while success do
        if DoesEntityExist(entity) and entity ~= originEntity and GetEntityModel(entity) == originModel then
            local coords = GetEntityCoords(entity)
            local horizontal = #(vector2(coords.x, coords.y) - vector2(originCoords.x, originCoords.y))
            if horizontal <= (radius or 3.0) then
                panels[#panels + 1] = {
                    entity = entity,
                    coords = coords,
                    heading = GetEntityHeading(entity),
                    model = originModel,
                }
            end
        end
        success, entity = FindNextObject(handle)
    end

    EndFindObject(handle)

    table.sort(panels, function(a, b)
        return a.coords.z < b.coords.z
    end)

    return panels
end

function BindGatePanels(gateId, stack)
    local gateConfig = GetGateConfig(gateId)
    if not gateConfig or #stack == 0 then
        return false
    end

    local center = vector3(0, 0, 0)
    for _, panel in ipairs(stack) do
        center = center + panel.coords
    end
    center = center / #stack

    gateConfig.closed = vec4(center.x, center.y, stack[1].coords.z, stack[1].heading)
    gateConfig.target = {
        coords = vec3(center.x, center.y, center.z),
        radius = 2.5,
    }
    gateConfig.panels = {}

    for _, panel in ipairs(stack) do
        gateConfig.panels[#gateConfig.panels + 1] = {
            model = panel.model,
            searchCoords = panel.coords,
            searchRadius = 3.0,
        }
    end

    local preparedPanels = {}
    for index, panel in ipairs(stack) do
        local prepared = PrepareMloPanel({
            entity = panel.entity,
            closedCoords = panel.coords,
            closedHeading = panel.heading,
        })
        preparedPanels[#preparedPanels + 1] = prepared
        RegisterDoorNative(gateId, index, prepared.originalEntity or prepared.entity)
    end

    local gateData = GetGateData(gateId)
    if not gateData then
        RegisterDiscoveredGate(gateConfig, stack)
        gateData = GetGateData(gateId)
    end

    if not gateData then
        return false
    end

    CleanupMloGate(gateData)

    gateData.panels = preparedPanels
    gateData.entity = preparedPanels[1].entity
    gateData.bound = true
    gateData.useDoorNative = false
    gateData.progress = 0.0
    gateData.state = GateStates.CLOSED
    gateData.config = gateConfig

    UpdateMloGateTransform(gateData, 0.0, false)
    RegisterGateTarget(gateId, gateData.entity)
    RegisterGateZone(gateId, gateConfig)

    TriggerServerEvent('rd-fahrzeugtor:syncGateBind', gateConfig)
    return true
end

local function bindGateAtPlayer(gateIndex)
    local gateId = ('rwmp_tor_%d'):format(gateIndex)

    if not GetGateConfig(gateId) then
        lib.notify({
            title = 'Tor-Bindung',
            description = ('Tor %d existiert nicht in der Config.'):format(gateIndex),
            type = 'error',
        })
        return
    end

    local entity = getLookedAtObject(15.0)
    if not entity then
        lib.notify({
            title = 'Tor-Bindung',
            description = 'Schau direkt auf ein Tor-Panel und versuche es erneut.',
            type = 'error',
        })
        return
    end

    local stack = findStackedPanels(entity, 3.0)

    if not BindGatePanels(gateId, stack) then
        lib.notify({
            title = 'Tor-Bindung',
            description = 'Bindung fehlgeschlagen.',
            type = 'error',
        })
        return
    end

    local testData = GetGateData(gateId)
    local beforeZ = testData.panels[1].closedCoords.z
    testData.progress = 0.15
    UpdateMloGateTransform(testData, 0.15, true)
    Wait(300)
    local afterZ = GetEntityCoords(testData.panels[1].entity).z
    testData.progress = 0.0
    UpdateMloGateTransform(testData, 0.0, false)

    local moved = math.abs(afterZ - beforeZ) > 0.05

    lib.notify({
        title = 'Tor-Bindung',
        description = moved
            and ('Tor %d gebunden (%d Panel(s)s) – Bewegung OK'):format(gateIndex, #stack)
            or ('Tor %d gebunden, aber Panel bewegt sich nicht – evtl. festes MLO-Mesh'):format(gateIndex),
        type = moved and 'success' or 'warning',
        duration = 10000,
    })

    print(('[rd-fahrzeugtor] Tor %d | Panels: %d | Modell: %s | Bewegung: %s'):format(
        gateIndex, #stack, stack[1].model, moved and 'OK' or 'FEHLER'
    ))
end

RegisterNetEvent('rd-fahrzeugtor:applyGateBind', function(gateConfig)
    if not gateConfig or not gateConfig.id then
        return
    end

    local existing = GetGateConfig(gateConfig.id)
    if existing then
        for key, value in pairs(gateConfig) do
            existing[key] = value
        end
    end

    if gateConfig.panels and #gateConfig.panels > 0 then
        TryResolveMloGate(gateConfig.id, gateConfig, GetGateData(gateConfig.id) or { config = gateConfig })
    end
end)

RegisterCommand('rd_tor_bind', function(_, args)
    bindGateAtPlayer(tonumber(args[1]) or 1)
end, false)

RegisterCommand('rd_tor_status', function()
    print('========== rd-fahrzeugtor Status ==========')
    for gateId, gateData in pairs(GetAllGates()) do
        local panelCount = gateData.panels and #gateData.panels or 0
        print(('%s | gebunden: %s | panels: %d | status: %s | progress: %.2f'):format(
            gateId,
            gateData.bound and 'ja' or 'nein',
            panelCount,
            gateData.state,
            gateData.progress or 0
        ))
    end
    print('===========================================')
end, false)
