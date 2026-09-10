local function openSelectorMenu(gates)
    local options = {}

    for _, gate in ipairs(gates) do
        options[#options + 1] = {
            title = gate.label,
            description = ('%s · %.0fm'):format(gate.progressLabel, gate.distance),
            icon = 'warehouse',
            onSelect = function()
                OpenGateUI(gate.id)
            end,
        }
    end

    lib.registerContext({
        id = 'rd_fahrzeugtor_selector',
        title = 'Tor-Fernbedienung',
        options = options,
    })

    lib.showContext('rd_fahrzeugtor_selector')
end

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

-- ox_lib Menü als Fallback, falls NUI Probleme macht
function OpenGateSelectorMenu()
    local gates = GetGatesInRange(Config.RemoteRange)
    if #gates == 0 then
        lib.notify({ title = 'Tor-Fernbedienung', description = 'Kein Tor in Reichweite.', type = 'error' })
        return
    end
    openSelectorMenu(gates)
end
