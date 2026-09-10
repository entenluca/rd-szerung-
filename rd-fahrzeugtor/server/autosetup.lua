local SavedBinds = {}

RegisterNetEvent('rd-fahrzeugtor:registerDiscoveredGates', function(gates)
    if type(gates) ~= 'table' then
        return
    end

    for _, gate in ipairs(gates) do
        if type(gate.id) == 'string' then
            GateStatesServer[gate.id] = GateStatesServer[gate.id] or {
                state = GateStates.CLOSED,
                progress = 0.0,
            }
        end
    end
end)

RegisterNetEvent('rd-fahrzeugtor:syncGateBind', function(gateConfig)
    if type(gateConfig) ~= 'table' or type(gateConfig.id) ~= 'string' then
        return
    end

    SavedBinds[gateConfig.id] = gateConfig
    GateStatesServer[gateConfig.id] = GateStatesServer[gateConfig.id] or {
        state = GateStates.CLOSED,
        progress = 0.0,
    }

    TriggerClientEvent('rd-fahrzeugtor:applyGateBind', -1, gateConfig)
end)

RegisterNetEvent('rd-fahrzeugtor:requestGateBinds', function()
    local source = source
    for _, gateConfig in pairs(SavedBinds) do
        TriggerClientEvent('rd-fahrzeugtor:applyGateBind', source, gateConfig)
    end
end)
