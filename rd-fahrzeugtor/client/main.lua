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
    if not lightConfig then
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
    local pos, heading = CalculateGateTransform(gate, gateData.progress)
    SetEntityCoordsNoOffset(gateData.entity, pos.x, pos.y, pos.z, false, false, false)
    SetEntityHeading(gateData.entity, heading)

    if gateData.warningLight and gate.warningLight then
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

                    local closed = gate.closed
                    local open = gate.open
                    local totalDistance = #(vector3(closed.x, closed.y, closed.z) - vector3(open.x, open.y, open.z))

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

function OpenGateUI(gateId)
    if not canControlGate() then
        notify('Fahrzeugtor', 'Du hast keine Berechtigung, dieses Tor zu steuern.', 'error')
        return
    end

    local gateData = Gates[gateId]
    if not gateData then
        return
    end

    ActiveGateId = gateId
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'open',
        gateId = gateId,
        label = gateData.config.label,
        state = gateData.state,
        progress = gateData.progress,
        progressLabel = GetProgressLabel(gateData.progress),
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
        if gateData.entity and DoesEntityExist(gateData.entity) then
            DeleteEntity(gateData.entity)
        end
        if gateData.warningLight and DoesEntityExist(gateData.warningLight) then
            DeleteEntity(gateData.warningLight)
        end
    end
end)

CreateThread(function()
    for _, gate in ipairs(Config.Gates) do
        local entity = spawnGateEntity(gate)
        if entity then
            local gateData = {
                config = gate,
                entity = entity,
                warningLight = spawnWarningLight(gate, entity),
                state = GateStates.CLOSED,
                progress = 0.0,
            }

            Gates[gate.id] = gateData
            RegisterGateTarget(gate.id, entity)
        end
    end

    TriggerServerEvent('rd-fahrzeugtor:requestInit')
end)
