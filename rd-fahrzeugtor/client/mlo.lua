local function findObjectAt(model, coords, radius)
    local entity = GetClosestObjectOfType(coords.x, coords.y, coords.z, radius, model, false, false, false)
    if entity ~= 0 and DoesEntityExist(entity) then
        return entity
    end
end

local function findAllObjectsAt(model, coords, radius)
    local found = {}
    local handle, entity = FindFirstObject()
    local success = true

    while success do
        if DoesEntityExist(entity) and GetEntityModel(entity) == model then
            local entityCoords = GetEntityCoords(entity)
            if #(entityCoords - coords) <= radius then
                found[#found + 1] = entity
            end
        end
        success, entity = FindNextObject(handle)
    end

    EndFindObject(handle)
    return found
end

function SecureMloPanel(entity, frozen)
    if not entity or not DoesEntityExist(entity) then
        return
    end

    SetEntityAsMissionEntity(entity, true, true)
    SetEntityInvincible(entity, true)
    FreezeEntityPosition(entity, frozen == true)
end

function SecureMloGatePanels(gateData, frozen)
    for _, panel in ipairs(gateData.panels or {}) do
        SecureMloPanel(panel.entity, frozen)
    end
end

---@param gate table
---@return table[]
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
        local radius = definition.searchRadius or 3.0
        local entities = findAllObjectsAt(definition.model, coords, radius)

        if #entities == 0 then
            local entity = findObjectAt(definition.model, coords, radius)
            if entity then
                entities = { entity }
            end
        end

        for _, entity in ipairs(entities) do
            local closedCoords = GetEntityCoords(entity)
            local closedHeading = GetEntityHeading(entity)

            panels[#panels + 1] = {
                entity = entity,
                closedCoords = closedCoords,
                closedHeading = closedHeading,
            }

            SecureMloPanel(entity, true)
        end
    end

    return panels
end

---@param gate table
---@return number|nil
function ResolveMloWarningLight(gate)
    local lightConfig = gate.warningLight
    if not lightConfig or lightConfig.mode == 'spawn' then
        return nil
    end

    local coords = lightConfig.searchCoords or lightConfig.coords
    if not coords or not lightConfig.model then
        return nil
    end

    return findObjectAt(lightConfig.model, coords, lightConfig.searchRadius or 2.0)
end

---@param gateData table
---@param progress number
---@param moving boolean
function UpdateMloGateTransform(gateData, progress, moving)
    local gate = gateData.config
    local referenceClosed = vector3(gate.closed.x, gate.closed.y, gate.closed.z)
    local currentRef = CalculateGateTransform(gate, progress)
    local delta = currentRef - referenceClosed

    for _, panel in ipairs(gateData.panels or {}) do
        if panel.entity and DoesEntityExist(panel.entity) then
            if moving then
                SecureMloPanel(panel.entity, false)
            end

            local pos = panel.closedCoords + delta
            SetEntityCoordsNoOffset(panel.entity, pos.x, pos.y, pos.z, false, false, false)

            if panel.closedHeading then
                SetEntityHeading(panel.entity, panel.closedHeading)
            end

            if not moving then
                SecureMloPanel(panel.entity, true)
            end
        end
    end
end

---@param gateId string
---@param gate table
---@param gateData table
---@return boolean
function TryResolveMloGate(gateId, gate, gateData)
    local panels = ResolveMloPanels(gate)

    if #panels == 0 then
        return false
    end

    gateData.panels = panels
    gateData.entity = panels[1].entity
    gateData.warningLight = ResolveMloWarningLight(gate)
    gateData.resolved = true

    UpdateMloGateTransform(gateData, gateData.progress or 0.0, false)

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
