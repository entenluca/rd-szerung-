local RegisteredZones = {}
local RegisteredEntities = {}

function RegisterGateTarget(gateId, entity)
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
                local gatesInRange = GetGatesInRange(8.0)
                if #gatesInRange > 1 then
                    OpenGateSelector()
                else
                    OpenGateUI(gateId)
                end
            end,
        },
    })
end

function RegisterGateZone(gateId, gate)
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
                    local gatesInRange = GetGatesInRange(8.0)
                    if #gatesInRange > 1 then
                        OpenGateSelector()
                    else
                        OpenGateUI(gateId)
                    end
                end,
            },
        },
    })
end

function RegisterGateInteraction(gateId, gate, entity)
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
