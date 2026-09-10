local ActiveLights = {}

function StartWarningLight(gateId)
    if ActiveLights[gateId] then
        return
    end

    local gateData = GetGateData(gateId)
    if not gateData or not gateData.warningLight then
        return
    end

    ActiveLights[gateId] = true

    CreateThread(function()
        local visible = true
        while ActiveLights[gateId] do
            if DoesEntityExist(gateData.warningLight) then
                visible = not visible
                SetEntityAlpha(gateData.warningLight, visible and 255 or 40, false)

                local coords = GetEntityCoords(gateData.warningLight)
                DrawLightWithRange(coords.x, coords.y, coords.z + 0.15, 255, 40, 0, 4.5, 2.0)
            end
            Wait(Config.WarningLightBlinkMs)
        end
    end)
end

function StopWarningLight(gateId)
    if not ActiveLights[gateId] then
        return
    end

    ActiveLights[gateId] = nil

    local gateData = GetGateData(gateId)
    if gateData and gateData.warningLight and DoesEntityExist(gateData.warningLight) then
        SetEntityAlpha(gateData.warningLight, 80, false)
    end
end
