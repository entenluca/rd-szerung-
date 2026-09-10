local AutoSetupDone = false

local function matchesPattern(text, patterns)
    if not text then
        return false
    end

    text = string.lower(text)
    for _, pattern in ipairs(patterns) do
        if string.find(text, string.lower(pattern), 1, true) then
            return true
        end
    end

    return false
end

local function isExcluded(text, patterns)
    return matchesPattern(text, patterns)
end

local function scanObjectsAt(center, radius)
    local results = {}
    local handle, entity = FindFirstObject()
    local success = true

    while success do
        if DoesEntityExist(entity) then
            local coords = GetEntityCoords(entity)
            if #(coords - center) <= radius then
                results[#results + 1] = {
                    entity = entity,
                    model = GetEntityModel(entity),
                    archetype = GetEntityArchetypeName(entity) or '',
                    coords = coords,
                    heading = GetEntityHeading(entity),
                }
            end
        end
        success, entity = FindNextObject(handle)
    end

    EndFindObject(handle)
    return results
end

local function clusterByAxis(objects, axis, gap)
    if #objects == 0 then
        return {}
    end

    table.sort(objects, function(a, b)
        return a.coords[axis] < b.coords[axis]
    end)

    local clusters = { { objects[1] } }

    for i = 2, #objects do
        local current = objects[i]
        local lastCluster = clusters[#clusters]
        local lastObject = lastCluster[#lastCluster]
        local delta = math.abs(current.coords[axis] - lastObject.coords[axis])

        if delta <= gap then
            lastCluster[#lastCluster + 1] = current
        else
            clusters[#clusters + 1] = { current }
        end
    end

    return clusters
end

local function getClusterCenter(cluster)
    local sum = vector3(0.0, 0.0, 0.0)
    for _, object in ipairs(cluster) do
        sum = sum + object.coords
    end
    return sum / #cluster
end

local function getClusterHeading(cluster)
    local total = 0.0
    for _, object in ipairs(cluster) do
        total = total + object.heading
    end
    return total / #cluster
end

local function findPanelCandidates(objects, setup)
    local byModel = {}

    for _, object in ipairs(objects) do
        local label = object.archetype ~= '' and object.archetype or tostring(object.model)

        if not isExcluded(label, setup.excludePatterns or {}) then
            byModel[object.model] = byModel[object.model] or {}
            byModel[object.model][#byModel[object.model] + 1] = object
        end
    end

    local candidates = {}

    for model, modelObjects in pairs(byModel) do
        local label = modelObjects[1].archetype ~= '' and modelObjects[1].archetype or tostring(model)
        local forced = matchesPattern(label, setup.panelPatterns or {})

        if forced or #modelObjects >= (setup.minPanelsPerModel or 2) then
            local axis = setup.clusterAxis or 'x'
            local stacks = clusterByAxis(modelObjects, axis, setup.stackGap or 1.5)

            for _, stack in ipairs(stacks) do
                if #stack >= 1 then
                    local minZ, maxZ = stack[1].coords.z, stack[1].coords.z
                    for _, panel in ipairs(stack) do
                        minZ = math.min(minZ, panel.coords.z)
                        maxZ = math.max(maxZ, panel.coords.z)
                    end

                    if forced or #stack >= 2 or (maxZ - minZ) >= 0.8 then
                        candidates[#candidates + 1] = {
                            model = model,
                            archetype = label,
                            panels = stack,
                            center = getClusterCenter(stack),
                            heading = getClusterHeading(stack),
                            minZ = minZ,
                            maxZ = maxZ,
                        }
                    end
                end
            end
        end
    end

    return candidates
end

local function clusterCandidates(candidates, axis, gap)
    table.sort(candidates, function(a, b)
        return a.center[axis] < b.center[axis]
    end)

    local clusters = { { candidates[1] } }

    for i = 2, #candidates do
        local current = candidates[i]
        local lastCluster = clusters[#clusters]
        local lastCandidate = lastCluster[#lastCluster]
        local delta = math.abs(current.center[axis] - lastCandidate.center[axis])

        if delta <= gap then
            lastCluster[#lastCluster + 1] = current
        else
            clusters[#clusters + 1] = { current }
        end
    end

    return clusters
end

local function groupCandidatesIntoGates(candidates, setup)
    if #candidates == 0 then
        return {}
    end

    local axis = setup.clusterAxis or 'x'
    local gateClusters = clusterCandidates(candidates, axis, setup.gateGap or 3.5)
    local maxGates = setup.expectedGates or #gateClusters
    local gates = {}

    for index, cluster in ipairs(gateClusters) do
        if index > maxGates then
            break
        end

        local allPanels = {}
        local minZ, maxZ

        for _, candidate in ipairs(cluster) do
            for _, panel in ipairs(candidate.panels) do
                allPanels[#allPanels + 1] = panel
            end
            minZ = minZ and math.min(minZ, candidate.minZ) or candidate.minZ
            maxZ = maxZ and math.max(maxZ, candidate.maxZ) or candidate.maxZ
        end

        if #allPanels > 0 then
            local center = getClusterCenter(allPanels)
            local travel = setup.travel
            if not travel and minZ and maxZ and (maxZ - minZ) > 0.2 then
                travel = math.max(3.2, (maxZ - minZ) + 2.8)
            end

            gates[#gates + 1] = {
                id = ('rwmp_tor_%d'):format(index),
                label = ('Tor %d – Rettungswache'):format(index),
                mode = 'mlo',
                closed = vec4(center.x, center.y, minZ or center.z, getClusterHeading(allPanels)),
                travel = travel or 3.8,
                moveAxis = setup.moveAxis or 'z',
                speed = setup.speed or 0.9,
                panels = {},
                warningLight = {
                    mode = 'mlo',
                    searchRadius = 2.0,
                },
                target = {
                    coords = vec3(center.x, center.y, center.z),
                    radius = setup.targetRadius or 2.5,
                },
                remoteRange = setup.remoteRange or 35.0,
                _panelEntities = allPanels,
            }

            for _, panel in ipairs(allPanels) do
                gates[#gates].panels[#gates[#gates].panels + 1] = {
                    model = panel.model,
                    searchCoords = panel.coords,
                    searchRadius = 2.5,
                }
            end
        end
    end

    return gates
end

local function findWarningLights(objects, setup)
    local lights = {}

    for _, object in ipairs(objects) do
        local label = object.archetype ~= '' and object.archetype or tostring(object.model)
        if matchesPattern(label, setup.lightPatterns or {}) and not isExcluded(label, setup.excludePatterns or {}) then
            lights[#lights + 1] = object
        end
    end

    return lights
end

local function assignWarningLights(gates, lights)
    for _, gate in ipairs(gates) do
        local nearestLight
        local nearestDistance

        for _, light in ipairs(lights) do
            local distance = #(light.coords - gate.target.coords)
            if not nearestDistance or distance < nearestDistance then
                nearestDistance = distance
                nearestLight = light
            end
        end

        if nearestLight and nearestDistance and nearestDistance <= 6.0 then
            gate.warningLight.model = nearestLight.model
            gate.warningLight.searchCoords = nearestLight.coords
        end
    end
end

function RunMloAutoSetup(setup)
    if AutoSetupDone then
        return true
    end

    local center = setup.center
    if not center then
        return false
    end

    local objects = scanObjectsAt(center, setup.radius or 40.0)
    if #objects == 0 then
        return false
    end

    local candidates = findPanelCandidates(objects, setup)
    if #candidates == 0 then
        return false
    end

    local gates = groupCandidatesIntoGates(candidates, setup)
    if #gates == 0 then
        return false
    end

    assignWarningLights(gates, findWarningLights(objects, setup))

    for _, gate in ipairs(gates) do
        local panelEntities = gate._panelEntities
        gate._panelEntities = nil
        RegisterDiscoveredGate(gate, panelEntities)
    end

    AutoSetupDone = true
    TriggerServerEvent('rd-fahrzeugtor:registerDiscoveredGates', gates)

    print(('[rd-fahrzeugtor] Auto-Setup: %d Garagentore erkannt'):format(#gates))
    lib.notify({
        title = 'Fahrzeugtor',
        description = ('%d Tore der Rettungswache automatisch erkannt'):format(#gates),
        type = 'success',
        duration = 8000,
    })

    return true
end

local function getAutoSetupCenter()
    local setup = Config.AutoSetup
    if setup and setup.center then
        return setup.center
    end

    local ped = PlayerPedId()
    return GetEntityCoords(ped)
end

CreateThread(function()
    local setup = Config.AutoSetup
    if not setup or not setup.enabled then
        return
    end

    local attempts = 0
    while attempts < (setup.maxAttempts or 30) do
        if RunMloAutoSetup(setup) then
            break
        end

        attempts = attempts + 1
        Wait(setup.retryMs or 3000)
    end

    if not AutoSetupDone then
        print('[rd-fahrzeugtor] Auto-Setup fehlgeschlagen – nutze /rd_tor_autosetup an der Rettungswache')
    end
end)

RegisterCommand('rd_tor_autosetup', function()
    local setup = Config.AutoSetup or {}
    setup.center = getAutoSetupCenter()
    setup.enabled = true
    AutoSetupDone = false

    if RunMloAutoSetup(setup) then
        return
    end

    lib.notify({
        title = 'Auto-Setup',
        description = 'Keine Tore gefunden. Steh vor die Garagentore und versuche es erneut.',
        type = 'error',
    })
end, false)
