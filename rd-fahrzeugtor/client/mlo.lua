local DoorHashes = {}
local ClaimedPanelEntities = {}

local function requestEntityControl(entity)
    if not entity or not DoesEntityExist(entity) then
        return false
    end

    if NetworkGetEntityIsNetworked(entity) then
        local timeout = GetGameTimer() + 2000
        while not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
            NetworkRequestControlOfEntity(entity)
            Wait(0)
        end
    end

    return DoesEntityExist(entity)
end

local function hideOriginalEntity(entity)
    if not entity or not DoesEntityExist(entity) then
        return
    end

    SetEntityAlpha(entity, 0, false)
    SetEntityCollision(entity, false, false)
    FreezeEntityPosition(entity, true)
    SetEntityVisible(entity, false, false)
end

local function showOriginalEntity(entity)
    if not entity or not DoesEntityExist(entity) then
        return
    end

    SetEntityAlpha(entity, 255, false)
    SetEntityCollision(entity, true, true)
    SetEntityVisible(entity, true, false)
end

local function createPanelClone(originalEntity)
    if not originalEntity or not DoesEntityExist(originalEntity) then
        return nil
    end

    local model = GetEntityModel(originalEntity)
    local coords = GetEntityCoords(originalEntity)
    local heading = GetEntityHeading(originalEntity)

    if not IsModelInCdimage(model) then
        return nil
    end

    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) do
        if GetGameTimer() > timeout then
            return nil
        end
        Wait(0)
    end

    local clone = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    SetModelAsNoLongerNeeded(model)

    if clone == 0 then
        return nil
    end

    SetEntityHeading(clone, heading)
    SetEntityAsMissionEntity(clone, true, true)
    FreezeEntityPosition(clone, true)
    SetEntityCollision(clone, true, true)

    hideOriginalEntity(originalEntity)

    return clone
end

function ClearClaimedPanels()
    ClaimedPanelEntities = {}
end

function PrepareMloPanel(panel)
    if panel.clone and DoesEntityExist(panel.clone) then
        return panel
    end

    if not panel.entity or not DoesEntityExist(panel.entity) then
        return panel
    end

    panel.closedCoords = GetEntityCoords(panel.entity)
    panel.closedHeading = GetEntityHeading(panel.entity)

    if not Config.UsePanelClones then
        SecureMloPanel(panel.entity, true)
        return panel
    end

    panel.originalEntity = panel.entity

    local clone = createPanelClone(panel.entity)
    if clone then
        panel.clone = clone
        panel.entity = clone
        panel.closedCoords = GetEntityCoords(clone)
        panel.closedHeading = GetEntityHeading(clone)
    end

    return panel
end

function RegisterDoorNative(gateId, panelIndex, entity)
    if not entity or not DoesEntityExist(entity) then
        return
    end

    local coords = GetEntityCoords(entity)
    local model = GetEntityModel(entity)
    local doorHash = joaat(('%s_%s'):format(gateId, panelIndex))

    if not IsDoorRegisteredWithSystem(doorHash) then
        AddDoorToSystem(doorHash, model, coords.x, coords.y, coords.z, false, false, false)
    end

    DoorSystemSetAutomaticDistance(doorHash, 0.0, false, false)
    DoorSystemSetAutomaticRate(doorHash, 0.0, false, false)
    DoorSystemSetDoorState(doorHash, 1, false, false)

    DoorHashes[('%s_%s'):format(gateId, panelIndex)] = doorHash
    return doorHash
end

function SetDoorNativeState(gateId, panelIndex, open)
    local key = ('%s_%s'):format(gateId, panelIndex)
    local doorHash = DoorHashes[key]
    if doorHash and IsDoorRegisteredWithSystem(doorHash) then
        DoorSystemSetDoorState(doorHash, open and 0 or 1, false, false)
    end
end

local function findClosestObjectAt(model, coords, radius)
    local entity = GetClosestObjectOfType(coords.x, coords.y, coords.z, radius, model, false, false, false)
    if entity ~= 0 and DoesEntityExist(entity) then
        local entityCoords = GetEntityCoords(entity)
        if #(entityCoords - coords) <= radius then
            return entity
        end
    end
end

local function claimPanelEntity(gateId, entity)
    if not entity or not DoesEntityExist(entity) then
        return false
    end

    local owner = ClaimedPanelEntities[entity]
    if owner and owner ~= gateId then
        return false
    end

    ClaimedPanelEntities[entity] = gateId
    return true
end

function SecureMloPanel(entity, frozen)
    if not entity or not DoesEntityExist(entity) then
        return
    end

    requestEntityControl(entity)
    SetEntityAsMissionEntity(entity, true, true)
    SetEntityInvincible(entity, true)
    FreezeEntityPosition(entity, frozen == true)
end

function SecureMloGatePanels(gateData, frozen)
    for _, panel in ipairs(gateData.panels or {}) do
        SecureMloPanel(panel.entity, frozen)
    end
end

function ResolveMloPanels(gate)
    local panels = {}
    local definitions = gate.panels or {}

    if #definitions == 0 and gate.model and gate.searchCoords then
        definitions = {
            {
                model = gate.model,
                searchCoords = gate.searchCoords,
                searchRadius = gate.searchRadius or 3.0,
            },
        }
    end

    for _, definition in ipairs(definitions) do
        local coords = definition.searchCoords
        local radius = definition.searchRadius or Config.PanelSearchRadius or 1.2
        local entity = findClosestObjectAt(definition.model, coords, radius)

        if entity and claimPanelEntity(gate.id, entity) then
            panels[#panels + 1] = PrepareMloPanel({
                entity = entity,
                closedCoords = GetEntityCoords(entity),
                closedHeading = GetEntityHeading(entity),
            })
        end
    end

    return panels
end

function ResolveMloWarningLight(gate)
    local lightConfig = gate.warningLight
    if not lightConfig or lightConfig.mode == 'spawn' then
        return nil
    end

    local coords = lightConfig.searchCoords or lightConfig.coords
    if not coords or not lightConfig.model then
        return nil
    end

    return findClosestObjectAt(lightConfig.model, coords, lightConfig.searchRadius or 2.0)
end

function StartEnforceClosed(gateId, gateData)
    if not Config.EnforceClosedState then
        return
    end

    CreateThread(function()
        while gateData.bound and gateData.config and gateData.config.id == gateId do
            if gateData.state == GateStates.CLOSED
                and (gateData.progress or 0) <= 0.01
                and not IsGateMoving(gateData.state) then
                UpdateMloGateTransform(gateData, 0.0, false)
                SecureMloGatePanels(gateData, true)
            end
            Wait(750)
        end
    end)
end

function UpdateMloGateTransform(gateData, progress, moving)
    local gate = gateData.config
    local gateId = gate.id
    local referenceClosed = vector3(gate.closed.x, gate.closed.y, gate.closed.z)
    local currentRef = CalculateGateTransform(gate, progress)
    local delta = currentRef - referenceClosed
    local travel = GetGateTravelDistance(gate)

    for index, panel in ipairs(gateData.panels or {}) do
        if panel.entity and DoesEntityExist(panel.entity) then
            requestEntityControl(panel.entity)

            if moving then
                FreezeEntityPosition(panel.entity, false)
            end

            local pos = panel.closedCoords + delta
            SetEntityCoords(panel.entity, pos.x, pos.y, pos.z, false, false, false, true)

            if panel.closedHeading then
                SetEntityHeading(panel.entity, panel.closedHeading)
            end

            if not moving then
                FreezeEntityPosition(panel.entity, true)
            end

            if gateData.useDoorNative and progress <= 0.01 then
                SetDoorNativeState(gateId, index, false)
            elseif gateData.useDoorNative and progress >= 0.99 then
                SetDoorNativeState(gateId, index, true)
            end
        end
    end
end

function TryResolveMloGate(gateId, gate, gateData)
    local panels = ResolveMloPanels(gate)

    if #panels == 0 then
        return false
    end

    gateData.panels = panels
    gateData.entity = panels[1].entity
    gateData.warningLight = ResolveMloWarningLight(gate)
    gateData.resolved = true
    gateData.bound = true

    if Config.UseDoorNatives then
        for index, panel in ipairs(panels) do
            RegisterDoorNative(gateId, index, panel.originalEntity or panel.entity)
        end
    end

    UpdateMloGateTransform(gateData, gateData.progress or 0.0, false)
    StartEnforceClosed(gateId, gateData)

    print(('[rd-fahrzeugtor] MLO-Tor "%s" geladen (%d Panel(s))'):format(gateId, #panels))
    return true
end

function WaitForMloGates(gates, onResolved)
    CreateThread(function()
        local pending = {}

        for gateId, gateData in pairs(gates) do
            if IsMloGate(gateData.config) and not gateData.resolved then
                pending[gateId] = true
            end
        end

        while next(pending) do
            for gateId in pairs(pending) do
                local gateData = gates[gateId]
                if gateData.resolved or TryResolveMloGate(gateId, gateData.config, gateData) then
                    pending[gateId] = nil
                    onResolved(gateId, gateData)
                end
            end

            Wait(2000)
        end
    end)
end

function CleanupMloGate(gateData)
    for _, panel in ipairs(gateData.panels or {}) do
        if panel.entity then
            ClaimedPanelEntities[panel.entity] = nil
        end
        if panel.originalEntity then
            ClaimedPanelEntities[panel.originalEntity] = nil
        end
        if panel.clone and DoesEntityExist(panel.clone) then
            DeleteEntity(panel.clone)
        end
        if panel.originalEntity then
            showOriginalEntity(panel.originalEntity)
        end
    end
end
