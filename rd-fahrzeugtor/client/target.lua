local RegisteredZones = {}
local RegisteredEntities = {}

local function onControlPanelSelect(gateId)
    UseControlPanel(gateId)
end

function RegisterControlPanelTarget(gateId, entity)
    if not entity or not DoesEntityExist(entity) then
        return
    end

    RegisteredEntities[gateId] = entity

    exports.ox_target:addLocalEntity(entity, {
        {
            name = ('rd_fahrzeugtor_panel_%s'):format(gateId),
            icon = 'fa-solid fa-toggle-on',
            label = 'Bedienfeld benutzen',
            distance = Config.ControlPanelTargetDistance or 1.8,
            onSelect = function()
                onControlPanelSelect(gateId)
            end,
        },
    })
end

function RegisterGateTarget(gateId, entity)
    if Config.InteractionMode == 'controlPanel' then
        return
    end

    if not entity or not DoesEntityExist(entity) then
        return
    end

    RegisteredEntities[gateId] = entity

    exports.ox_target:addLocalEntity(entity, {
        {
            name = ('rd_fahrzeugtor_%s'):format(gateId),
            icon = 'fa-solid fa-warehouse',
            label = 'Tor steuern',
            distance = 2.5,
            onSelect = function()
                onControlPanelSelect(gateId)
            end,
        },
    })
end

function RegisterGateZone(gateId, gate)
    if Config.InteractionMode == 'controlPanel' then
        return
    end

    local target = gate.target
    if not target or not target.coords then
        return
    end

    if RegisteredZones[gateId] then
        return
    end

    RegisteredZones[gateId] = exports.ox_target:addSphereZone({
        coords = target.coords,
        radius = target.radius or 2.5,
        debug = Config.Debug or false,
        options = {
            {
                name = ('rd_fahrzeugtor_zone_%s'):format(gateId),
                icon = 'fa-solid fa-warehouse',
                label = 'Tor steuern',
                onSelect = function()
                    onControlPanelSelect(gateId)
                end,
            },
        },
    })
end

function RegisterGateInteraction(gateId, gate, entity)
    if gate.controlPanel and Config.InteractionMode == 'controlPanel' then
        local panelEntity = ResolveControlPanel(gate)
        if panelEntity then
            RegisterControlPanelTarget(gateId, panelEntity)
            return
        end
        return
    end

    RegisterGateZone(gateId, gate)

    if entity and DoesEntityExist(entity) then
        RegisterGateTarget(gateId, entity)
    end
end

function ClearAllGateZones()
    for gateId, zoneId in pairs(RegisteredZones) do
        exports.ox_target:removeZone(zoneId)
        RegisteredZones[gateId] = nil
    end

    for gateId, entity in pairs(RegisteredEntities) do
        if entity and DoesEntityExist(entity) then
            exports.ox_target:removeLocalEntity(entity)
        end
        RegisteredEntities[gateId] = nil
    end
end
