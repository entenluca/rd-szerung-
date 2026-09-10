local ActiveSounds = {}

local function getGateCoords(gateId)
    local gateData = GetGateData(gateId)
    if not gateData then
        return nil
    end

    return GetEntityCoords(gateData.entity)
end

function StartGateSound(gateId)
    if ActiveSounds[gateId] then
        return
    end

    local coords = getGateCoords(gateId)
    if not coords then
        return
    end

    ActiveSounds[gateId] = true

    SendNUIMessage({
        action = 'playLoop',
        gateId = gateId,
        volume = Config.SoundVolume,
    })

    CreateThread(function()
        while ActiveSounds[gateId] do
            PlaySoundFromCoord(
                -1,
                'OPENING',
                coords.x, coords.y, coords.z,
                'GARAGE_DOOR_SCRIPT_SOUNDS',
                false,
                0,
                false
            )
            Wait(1200)
        end
    end)
end

function StopGateSound(gateId)
    if not ActiveSounds[gateId] then
        return
    end

    ActiveSounds[gateId] = nil

    SendNUIMessage({
        action = 'stopLoop',
        gateId = gateId,
    })
end
