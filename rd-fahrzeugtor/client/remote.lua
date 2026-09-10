RegisterNetEvent('rd-fahrzeugtor:useRemote', function()
    OpenGateSelector()
end)

exports('useRemote', function()
    OpenGateSelector()
end)

exports('openNearestGate', function()
    OpenGateSelector()
end)

RegisterCommand('rd_tor_remote', function()
    if GetResourceState('ox_inventory') == 'started' then
        local count = exports.ox_inventory:Search('count', Config.RemoteItem)
        if not count or count < 1 then
            lib.notify({
                title = 'Tor-Fernbedienung',
                description = 'Du hast keine Fernbedienung dabei.',
                type = 'error',
            })
            return
        end
    end

    OpenGateSelector()
end, false)

RegisterKeyMapping('rd_tor_remote', 'Tor-Fernbedienung benutzen', 'keyboard', 'F6')
