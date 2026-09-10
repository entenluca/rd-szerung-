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
