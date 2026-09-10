local Gates = {}
local ActiveGateId = nil
local AnimationThreadRunning = false

local function canControlGate()
    if not Config.AllowedJobs then
        return true
    end

    if GetResourceState('es_extended') == 'started' then
        local ESX = exports['es_extended']:getSharedObject()
        local playerData = ESX.GetPlayerData()
        local job = playerData and playerData.job
        if job and Config.AllowedJobs[job.name] ~= nil then
            return job.grade >= Config.AllowedJobs[job.name]
        end
        return false
    end

    if GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local playerData = QBCore.Functions.GetPlayerData()
        local job = playerData and playerData.job
        if job and Config.AllowedJobs[job.name] ~= nil then
            return job.grade.level >= Config.AllowedJobs[job.name]
        end
        return false
    end

    return true
end

local function notify(title, description, type)
    lib.notify({
        title = title,
        description = description,
        type = type or 'inform',
    })
end

local function loadModel(model)
    if not IsModelInCdimage(model) then
        return false
    end

    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) do
        if GetGameTimer() > timeout then
            return false
        end
        Wait(0)
    end

    return true
end

local function spawnGateEntity(gate)
    if not loadModel(gate.model) then
        print(('[rd-fahrzeugtor] Modell konnte nicht geladen werden: %s (%s)'):format(gate.id, gate.model))
        return nil
    end

    local pos, heading = CalculateGateTransform(gate, 0.0)
    local entity = CreateObject(gate.model, pos.x, pos.y, pos.z, false, false, false)

    if entity == 0 then
        SetModelAsNoLongerNeeded(gate.model)
        return nil
    end

    SetEntityHeading(entity, heading)
    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, true, true)
    SetEntityAsMissionEntity(entity, true, true)

    SetModelAsNoLongerNeeded(gate.model)
    return entity
end

local function spawnWarningLight(gate, gateEntity)
    local lightConfig = gate.warningLight
    if not lightConfig or lightConfig.mode == 'mlo' then
        return nil
    end

    if not loadModel(lightConfig.model) then
        print(('[rd-fahrzeugtor] Warnleuchte konnte nicht geladen werden: %s'):format(gate.id))
        return nil
    end

    local gateCoords = GetEntityCoords(gateEntity)
    local offset = lightConfig.offset or vec3(0.0, 0.0, 2.0)
    local rot = lightConfig.rot or vec3(0.0, 0.0, GetEntityHeading(gateEntity))

    local entity = CreateObject(
        lightConfig.model,
        gateCoords.x + offset.x,
        gateCoords.y + offset.y,
        gateCoords.z + offset.z,
        false, false, false
    )

    if entity == 0 then
        SetModelAsNoLongerNeeded(lightConfig.model)
        return nil
    end

    SetEntityRotation(entity, rot.x, rot.y, rot.z, 2, true)
    FreezeEntityPosition(entity, true)
    SetEntityAsMissionEntity(entity, true, true)
    SetEntityAlpha(entity, 80, false)

    SetModelAsNoLongerNeeded(lightConfig.model)
    return entity
end

local function updateGateEntityTransform(gateData)
    local gate = gateData.config

    if IsMloGate(gate) then
        if gateData.bound and gateData.panels and #gateData.panels > 0 then
            UpdateMloGateTransform(gateData, gateData.progress, IsGateMoving(gateData.state))
        end
        return
    end

    local pos, heading = CalculateGateTransform(gate, gateData.progress)
    SetEntityCoordsNoOffset(gateData.entity, pos.x, pos.y, pos.z, false, false, false)
    SetEntityHeading(gateData.entity, heading)

    if gateData.warningLight and gate.warningLight and gate.warningLight.mode ~= 'mlo' then
        local offset = gate.warningLight.offset or vec3(0.0, 0.0, 2.0)
        SetEntityCoordsNoOffset(
            gateData.warningLight,
            pos.x + offset.x,
            pos.y + offset.y,
            pos.z + offset.z,
            false, false, false
        )
    end
end

local function ensureAnimationThread()
    if AnimationThreadRunning then
        return
    end

    AnimationThreadRunning = true

    CreateThread(function()
        while true do
            local anyMoving = false

            for gateId, gateData in pairs(Gates) do
                if IsGateMoving(gateData.state) then
                    anyMoving = true
                    local gate = gateData.config
                    local distance = gate.speed * GetFrameTime()
                    local direction = gateData.state == GateStates.OPENING and 1.0 or -1.0
                    local totalDistance = GetGateTravelDistance(gate)

                    if totalDistance > 0.0 then
                        local delta = (distance / totalDistance) * direction
                        gateData.progress = math.min(1.0, math.max(0.0, gateData.progress + delta))
                    end

                    updateGateEntityTransform(gateData)

                    if gateData.progress <= 0.0 and gateData.state == GateStates.CLOSING then
                        gateData.state = GateStates.CLOSED
                        gateData.progress = 0.0
                        TriggerServerEvent('rd-fahrzeugtor:syncState', gateId, GateStates.CLOSED, 0.0)
                        StopGateSound(gateId)
                        StopWarningLight(gateId)
                    elseif gateData.progress >= 1.0 and gateData.state == GateStates.OPENING then
                        gateData.state = GateStates.OPEN
                        gateData.progress = 1.0
                        TriggerServerEvent('rd-fahrzeugtor:syncState', gateId, GateStates.OPEN, 1.0)
                        StopGateSound(gateId)
                        StopWarningLight(gateId)
                    end
                end
            end

            if not anyMoving then
                AnimationThreadRunning = false
                break
            end

            Wait(0)
        end
    end)
end

local function applyGateState(gateId, state, progress)
    local gateData = Gates[gateId]
    if not gateData then
        return
    end

    gateData.state = state
    gateData.progress = progress
    updateGateEntityTransform(gateData)

    if IsGateMoving(state) then
        StartGateSound(gateId)
        StartWarningLight(gateId)
        ensureAnimationThread()
    else
        StopGateSound(gateId)
        StopWarningLight(gateId)
    end

    if ActiveGateId == gateId then
        SendNUIMessage({
            action = 'updateState',
            state = state,
            progress = progress,
            progressLabel = GetProgressLabel(progress),
        })
    end
end

function RefreshGateSelector()
    local gates = GetGatesInRange(Config.RemoteRange)
    SendNUIMessage({
        action = 'updateSelector',
        gates = gates,
    })
end

local function getGateCoords(gateData)
    local gate = gateData.config

    if gateData.entity and DoesEntityExist(gateData.entity) then
        return GetEntityCoords(gateData.entity)
    end

    if gate.target and gate.target.coords then
        return gate.target.coords
    end

    return vector3(gate.closed.x, gate.closed.y, gate.closed.z)
end

function GetGatesInRange(maxRange)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local results = {}

    for gateId, gateData in pairs(Gates) do
        local gate = gateData.config
        local gateCoords = getGateCoords(gateData)
        local range = gate.remoteRange or maxRange or Config.RemoteRange
        local distance = #(playerCoords - gateCoords)

        if distance <= range then
            results[#results + 1] = {
                id = gateId,
                label = gate.label,
                state = gateData.state,
                progress = gateData.progress,
                progressLabel = GetProgressLabel(gateData.progress),
                distance = distance,
            }
        end
    end

    table.sort(results, function(a, b)
        return a.distance < b.distance
    end)

    return results
end

function OpenGateSelector()
    if not canControlGate() then
        notify('Fahrzeugtor', 'Du hast keine Berechtigung, dieses Tor zu steuern.', 'error')
        return
    end

    local gates = GetGatesInRange(Config.RemoteRange)

    if #gates == 0 then
        notify('Tor-Fernbedienung', 'Kein Tor in Reichweite.', 'error')
        return
    end

    if #gates == 1 and not Config.RemoteAlwaysShowSelector then
        OpenGateUI(gates[1].id)
        return
    end

    if Config.UseOxLibSelector then
        OpenGateSelectorMenu()
        return
    end

    ActiveGateId = nil
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'openSelector',
        gates = gates,
    })
end

function OpenGateUI(gateId)
    if not canControlGate() then
        notify('Fahrzeugtor', 'Du hast keine Berechtigung, dieses Tor zu steuern.', 'error')
        return
    end

    local gateData = Gates[gateId]
    if not gateData then
        return
    end

    if IsMloGate(gateData.config) and not gateData.bound then
        notify('Fahrzeugtor', 'Tor noch nicht gebunden. Schau auf das Panel und nutze /rd_tor_bind', 'error')
        return
    end

    ActiveGateId = gateId
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'openControl',
        gateId = gateId,
        label = gateData.config.label,
        state = gateData.state,
        progress = gateData.progress,
        progressLabel = GetProgressLabel(gateData.progress),
        showBack = Config.RemoteAlwaysShowSelector or #GetGatesInRange(Config.RemoteRange) > 1,
    })
end

function CloseGateUI()
    ActiveGateId = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

function GetGateData(gateId)
    return Gates[gateId]
end

function GetAllGates()
    return Gates
end

function RequestGateAction(gateId, action)
    if not canControlGate() then
        notify('Fahrzeugtor', 'Du hast keine Berechtigung, dieses Tor zu steuern.', 'error')
        return
    end

    TriggerServerEvent('rd-fahrzeugtor:requestAction', gateId, action)
end

local function createGateData(gate, entity, warningLight)
    return {
        config = gate,
        entity = entity,
        panels = {},
        warningLight = warningLight,
        state = GateStates.CLOSED,
        progress = 0.0,
    }
end

local function registerGate(gateId, gate, gateData)
    Gates[gateId] = gateData
    RegisterGateInteraction(gateId, gate, gateData.entity)
end

function RegisterDiscoveredGate(gate, panelEntities)
    if Gates[gate.id] then
        return
    end

    local panels = {}
    for _, object in ipairs(panelEntities or {}) do
        if DoesEntityExist(object.entity) then
            panels[#panels + 1] = {
                entity = object.entity,
                closedCoords = object.coords,
                closedHeading = object.heading,
            }
        end
    end

    if #panels == 0 then
        return
    end

    local gateData = {
        config = gate,
        entity = panels[1].entity,
        panels = panels,
        warningLight = ResolveMloWarningLight(gate),
        state = GateStates.CLOSED,
        progress = 0.0,
    }

    for _, panel in ipairs(panels) do
        SecureMloPanel(panel.entity, true)
    end

    gateData.bound = true
    registerGate(gate.id, gate, gateData)
end

RegisterNetEvent('rd-fahrzeugtor:applyState', function(gateId, state, progress)
    applyGateState(gateId, state, progress)
end)

RegisterNetEvent('rd-fahrzeugtor:initGates', function(serverStates)
    for gateId, gateData in pairs(Gates) do
        local serverState = serverStates[gateId]
        if serverState then
            applyGateState(gateId, serverState.state, serverState.progress)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    CloseGateUI()

    for _, gateData in pairs(Gates) do
        if not IsMloGate(gateData.config) then
            if gateData.entity and DoesEntityExist(gateData.entity) then
                DeleteEntity(gateData.entity)
            end
            if gateData.warningLight and DoesEntityExist(gateData.warningLight) then
                DeleteEntity(gateData.warningLight)
            end
        end
    end
end)

local function initializeConfiguredGates()
    for _, gate in ipairs(Config.Gates) do
        if Config.AutoSetup and Config.AutoSetup.enabled then
            local hasPanels = gate.panels and #gate.panels > 0
            if IsMloGate(gate) and not hasPanels then
                goto continue
            end
        end

        if IsMloGate(gate) then
            local gateData = createGateData(gate, nil, nil)
            registerGate(gate.id, gate, gateData)
        else
            local entity = spawnGateEntity(gate)
            if entity then
                local gateData = createGateData(gate, entity, spawnWarningLight(gate, entity))
                registerGate(gate.id, gate, gateData)
            end
        end

        ::continue::
    end

    for gateId, gateData in pairs(Gates) do
        local gate = gateData.config
        if gate.panels and #gate.panels > 0 then
            WaitForMloGates({ [gateId] = gateData }, function(resolvedId, resolvedData)
                resolvedData.bound = true
                if resolvedData.warningLight then
                    resolvedData.warningLight = ResolveMloWarningLight(gate) or resolvedData.warningLight
                else
                    resolvedData.warningLight = ResolveMloWarningLight(gate)
                end
                RegisterGateTarget(resolvedId, resolvedData.entity)
            end)
        end
    end
end

CreateThread(function()
    if Config.MloResource and GetResourceState(Config.MloResource) == 'missing' then
        print(('[rd-fahrzeugtor] Hinweis: MLO-Ressource "%s" nicht gefunden – stelle sicher, dass sie gestartet ist.'):format(Config.MloResource))
    end

    initializeConfiguredGates()
    TriggerServerEvent('rd-fahrzeugtor:requestInit')

    lib.notify({
        title = 'Fahrzeugtor',
        description = 'Tore binden: Schau auf Panel → /rd_tor_bind 1 (2, 3)',
        type = 'inform',
        duration = 12000,
    })
end)
