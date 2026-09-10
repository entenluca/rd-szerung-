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
            local lightEntity = gateData.warningLight
            if lightEntity and DoesEntityExist(lightEntity) then
                visible = not visible
                SetEntityAlpha(lightEntity, visible and 255 or 60, false)

                local coords = GetEntityCoords(lightEntity)
                DrawLightWithRange(coords.x, coords.y, coords.z + 0.1, 255, 30, 0, 5.0, 2.5)
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
        SetEntityAlpha(gateData.warningLight, 255, false)
    end
end
