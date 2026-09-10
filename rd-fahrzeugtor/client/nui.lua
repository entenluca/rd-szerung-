RegisterNUICallback('close', function(_, cb)
    CloseGateUI()
    cb('ok')
end)

RegisterNUICallback('action', function(data, cb)
    if data.gateId and data.action then
        RequestGateAction(data.gateId, data.action)
    end
    cb('ok')
end)

RegisterNUICallback('selectGate', function(data, cb)
    if data.gateId then
        OpenGateUI(data.gateId)
    end
    cb('ok')
end)

RegisterNUICallback('backToSelector', function(_, cb)
    OpenGateSelector()
    cb('ok')
end)

RegisterCommand('rd_tor_close', function()
    CloseGateUI()
end, false)

RegisterKeyMapping('rd_tor_close', 'Fahrzeugtor-UI schließen', 'keyboard', 'ESCAPE')
