local function getModelLabel(model)
    if type(model) == 'string' then
        return model
    end

    return ('0x%X (%s)'):format(model, model)
end

local function scanNearbyObjects(radius)
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local results = {}
    local handle, entity = FindFirstObject()
    local success = true

    while success do
        if DoesEntityExist(entity) then
            local coords = GetEntityCoords(entity)
            local distance = #(coords - playerCoords)

            if distance <= radius then
                local model = GetEntityModel(entity)
                local archetype = GetEntityArchetypeName(entity)

                results[#results + 1] = {
                    entity = entity,
                    model = model,
                    archetype = archetype,
                    coords = coords,
                    heading = GetEntityHeading(entity),
                    distance = distance,
                }
            end
        end

        success, entity = FindNextObject(handle)
    end

    EndFindObject(handle)

    table.sort(results, function(a, b)
        return a.distance < b.distance
    end)

    return results
end

RegisterCommand('rd_tor_scan', function(_, args)
    local radius = tonumber(args[1]) or 12.0
    local objects = scanNearbyObjects(radius)

    print(('========== rd-fahrzeugtor Scan (%.1fm) =========='):format(radius))
    print(('Gefundene Objekte: %d'):format(#objects))

    for index, entry in ipairs(objects) do
        print(('')
        print(('[%d] Distanz: %.2fm | Entity: %s'):format(index, entry.distance, entry.entity))
        print(('     Modell: %s'):format(getModelLabel(entry.model)))
        print(('     Archetype: %s'):format(entry.archetype or 'n/a'))
        print(('     Coords: vec3(%.3f, %.3f, %.3f)'):format(entry.coords.x, entry.coords.y, entry.coords.z))
        print(('     Heading: %.2f'):format(entry.heading))
        print(('     Config: model = `%s`, searchCoords = vec3(%.3f, %.3f, %.3f)'):format(
            entry.model,
            entry.coords.x,
            entry.coords.y,
            entry.coords.z
        ))
    end

    print('')
    print('Tipp: Schau direkt auf ein Tor-Panel und nutze einen kleinen Radius (z. B. /rd_tor_scan 4)')
    print('==================================================')

    lib.notify({
        title = 'Tor-Scanner',
        description = ('%d Objekte in %.0fm – Details in F8-Konsole'):format(#objects, radius),
        type = 'inform',
        duration = 8000,
    })
end, false)

RegisterCommand('rd_tor_copy', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local text = ('vec4(%.3f, %.3f, %.3f, %.2f)'):format(coords.x, coords.y, coords.z, heading)

    print(('[rd-fahrzeugtor] %s'):format(text))

    lib.notify({
        title = 'Koordinaten',
        description = text,
        type = 'success',
        duration = 10000,
    })
end, false)
