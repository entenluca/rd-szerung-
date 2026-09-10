local function getLookedAtObject(maxDistance)
    local hit, entity = lib.raycast.fromCamera(511, 4, maxDistance or 12.0)
    if hit and entity and entity ~= 0 and DoesEntityExist(entity) then
        return entity
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
            if horizontal <= (radius or 2.5) then
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

local function bindGateAtPlayer(gateIndex)
    local gateId = ('rwmp_tor_%d'):format(gateIndex)
    local gateConfig = GetGateConfig(gateId)

    if not gateConfig then
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
            description = 'Schau auf ein Tor-Panel und versuche es erneut.',
            type = 'error',
        })
        return
    end

    local stack = findStackedPanels(entity, 2.5)
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local center = vector3(0, 0, 0)

    for _, panel in ipairs(stack) do
        center = center + panel.coords
    end
    center = center / #stack

    gateConfig.closed = vec4(center.x, center.y, stack[1].coords.z, GetEntityHeading(entity))
    gateConfig.target = {
        coords = vec3(center.x, center.y, center.z),
        radius = 2.5,
    }
    gateConfig.panels = {}

    for _, panel in ipairs(stack) do
        gateConfig.panels[#gateConfig.panels + 1] = {
            model = panel.model,
            searchCoords = panel.coords,
            searchRadius = 2.5,
        }
    end

    local gateData = GetGateData(gateId)
    if gateData then
        gateData.panels = {}
        for _, panel in ipairs(stack) do
            gateData.panels[#gateData.panels + 1] = {
                entity = panel.entity,
                closedCoords = panel.coords,
                closedHeading = panel.heading,
            }
            SecureMloPanel(panel.entity, true)
        end

        gateData.entity = stack[1].entity
        gateData.bound = true
        gateData.progress = 0.0
        gateData.state = GateStates.CLOSED
        UpdateMloGateTransform(gateData, 0.0, false)
        RegisterGateTarget(gateId, gateData.entity)
    else
        RegisterDiscoveredGate(gateConfig, stack)
        GetGateData(gateId).bound = true
    end

    TriggerServerEvent('rd-fahrzeugtor:registerDiscoveredGates', { gateConfig })

    lib.notify({
        title = 'Tor-Bindung',
        description = ('Tor %d gebunden (%d Panel(s)).'):format(gateIndex, #stack),
        type = 'success',
        duration = 8000,
    })

    print(('[rd-fahrzeugtor] Tor %d gebunden mit %d Panel(s), Modell: %s'):format(gateIndex, #stack, stack[1].model))
end

RegisterCommand('rd_tor_bind', function(_, args)
    bindGateAtPlayer(tonumber(args[1]) or 1)
end, false)

RegisterCommand('rd_tor_status', function()
    print('========== rd-fahrzeugtor Status ==========')
    for gateId, gateData in pairs(GetAllGates()) do
        local panelCount = gateData.panels and #gateData.panels or 0
        print(('%s | gebunden: %s | panels: %d | status: %s'):format(
            gateId,
            gateData.bound and 'ja' or 'nein',
            panelCount,
            gateData.state
        ))
    end
    print('===========================================')
end, false)
