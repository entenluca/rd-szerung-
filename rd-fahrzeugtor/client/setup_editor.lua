local EditorActive = false
local EditorDraft = nil
local EditorMarkers = {}

local function canUseSetup()
    if not Config.SetupAce then
        return true
    end
    return lib.callback.await('rd-fahrzeugtor:canSetup', false)
end

local function getCameraRaycastHit()
    local hit, entity, coords = lib.raycast.fromCamera(511, 4, 20.0)
    if hit and coords then
        return coords, entity
    end
end

local function getLookedAtObject()
    local _, entity = getCameraRaycastHit()
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        return entity
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local dest = coords + forward * 10.0
    local ray = StartShapeTestRay(coords.x, coords.y, coords.z + 0.5, dest.x, dest.y, dest.z + 0.5, 16, ped, 0)
    local _, didHit, _, _, rayEntity = GetShapeTestResult(ray)

    if didHit == 1 and rayEntity and rayEntity ~= 0 and DoesEntityExist(rayEntity) then
        return rayEntity
    end
end

local function findStackedPanels(originEntity, radius)
    local originCoords = GetEntityCoords(originEntity)
    local originModel = GetEntityModel(originEntity)
    local panels = {
        {
            entity = originEntity,
            model = originModel,
            coords = originCoords,
            heading = GetEntityHeading(originEntity),
            archetype = GetEntityArchetypeName(originEntity) or '',
        },
    }

    local handle, entity = FindFirstObject()
    local success = true

    while success do
        if DoesEntityExist(entity) and entity ~= originEntity and GetEntityModel(entity) == originModel then
            local coords = GetEntityCoords(entity)
            if #(vector2(coords.x, coords.y) - vector2(originCoords.x, originCoords.y)) <= (radius or 3.0) then
                panels[#panels + 1] = {
                    entity = entity,
                    model = originModel,
                    coords = coords,
                    heading = GetEntityHeading(entity),
                    archetype = GetEntityArchetypeName(entity) or '',
                }
            end
        end
        success, entity = FindNextObject(handle)
    end

    EndFindObject(handle)

    table.sort(panels, function(a, b)
        return a.coords.z < b.coords.z
    end)

    return panels
end

local function panelExists(draft, model, coords)
    for _, panel in ipairs(draft.panels) do
        if panel.model == model and #(panel.searchCoords - coords) < 0.3 then
            return true
        end
    end
    return false
end

local function addPanelsToDraft(draft, stack)
    local added = 0
    for _, panel in ipairs(stack) do
        if not panelExists(draft, panel.model, panel.coords) then
            draft.panels[#draft.panels + 1] = {
                model = panel.model,
                searchCoords = panel.coords,
                searchRadius = 3.0,
            }
            added = added + 1
        end
    end
    return added
end

local function updateDraftReference(draft)
    if #draft.panels == 0 then
        return
    end

    local lowest = draft.panels[1].searchCoords
    local center = vector3(0, 0, 0)

    for _, panel in ipairs(draft.panels) do
        center = center + panel.searchCoords
        if panel.searchCoords.z < lowest.z then
            lowest = panel.searchCoords
        end
    end

    center = center / #draft.panels
    draft.closed = vec4(center.x, center.y, lowest.z, 0.0)
    draft.target = {
        coords = vec3(center.x, center.y, center.z),
        radius = 2.5,
    }
end

local function drawEditorMarkers(draft)
    if not draft then return end

    for _, panel in ipairs(draft.panels) do
        DrawMarker(28, panel.searchCoords.x, panel.searchCoords.y, panel.searchCoords.z + 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, 220, 38, 38, 180, false, false, 2, false, nil, nil, false)
    end

    if draft.controlPanel and draft.controlPanel.searchCoords then
        local cp = draft.controlPanel.searchCoords
        DrawMarker(2, cp.x, cp.y, cp.z + 0.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 34, 197, 94, 200, false, false, 2, false, nil, nil, false)
    end

    if draft.target and draft.target.coords then
        DrawMarker(1, draft.target.coords.x, draft.target.coords.y, draft.target.coords.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.2, 1.2, 0.5, 34, 197, 94, 120, false, false, 2, false, nil, nil, false)
    end

    if draft.closed then
        DrawMarker(27, draft.closed.x, draft.closed.y, draft.closed.z + 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.35, 0.35, 0.35, 59, 130, 246, 180, false, false, 2, false, nil, nil, false)
        local openPos = CalculateGateTransform(draft, 1.0)
        DrawLine(draft.closed.x, draft.closed.y, draft.closed.z, openPos.x, openPos.y, openPos.z, 251, 191, 36, 200)
        DrawMarker(27, openPos.x, openPos.y, openPos.z + 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.35, 0.35, 0.35, 251, 191, 36, 180, false, false, 2, false, nil, nil, false)
    end
end

local function serializeDraft(draft)
    local panels = {}
    for _, panel in ipairs(draft.panels) do
        panels[#panels + 1] = {
            model = panel.model,
            searchCoords = { x = panel.searchCoords.x, y = panel.searchCoords.y, z = panel.searchCoords.z },
            searchRadius = panel.searchRadius or 3.0,
        }
    end

    return {
        id = draft.id,
        label = draft.label,
        mode = 'mlo',
        closed = draft.closed and { x = draft.closed.x, y = draft.closed.y, z = draft.closed.z, w = draft.closed.w },
        travel = draft.travel,
        moveAxis = draft.moveAxis or 'z',
        speed = draft.speed or 0.9,
        panels = panels,
        target = draft.target and {
            coords = { x = draft.target.coords.x, y = draft.target.coords.y, z = draft.target.coords.z },
            radius = draft.target.radius or 2.5,
        },
        remoteRange = draft.remoteRange or 35.0,
        controlPanel = draft.controlPanel and {
            model = draft.controlPanel.model,
            searchCoords = { x = draft.controlPanel.searchCoords.x, y = draft.controlPanel.searchCoords.y, z = draft.controlPanel.searchCoords.z },
            searchRadius = draft.controlPanel.searchRadius or 1.5,
        },
    }
end

local function stopEditor()
    EditorActive = false
    EditorDraft = nil
    lib.hideTextUI()
end

local function saveAllGates()
    local gates = {}
    for _, gate in ipairs(Config.Gates) do
        gates[#gates + 1] = serializeDraft(gate)
    end

    if EditorDraft then
        local found = false
        for index, gate in ipairs(gates) do
            if gate.id == EditorDraft.id then
                gates[index] = serializeDraft(EditorDraft)
                found = true
                break
            end
        end
        if not found then
            gates[#gates + 1] = serializeDraft(EditorDraft)
        end
    end

    TriggerServerEvent('rd-fahrzeugtor:saveGates', gates)
    lib.notify({ title = 'Tor-Setup', description = 'Tore gespeichert in data/gates.json', type = 'success' })
    stopEditor()
end

local function startPanelPicker(draft)
    EditorActive = true
    EditorDraft = draft

    lib.showTextUI('[E] Tor-Panel  |  [P] Bedienfeld  |  [H] Hubhöhe  |  [ENTER] Speichern  |  [BACKSPACE] Abbrechen', {
        position = 'top-center',
    })

    CreateThread(function()
        while EditorActive and EditorDraft == draft do
            drawEditorMarkers(draft)

            if IsControlJustPressed(0, 38) then -- E
                local entity = getLookedAtObject()
                if entity then
                    local stack = findStackedPanels(entity, 3.0)
                    local added = addPanelsToDraft(draft, stack)
                    updateDraftReference(draft)
                    lib.notify({
                        title = 'Panel hinzugefügt',
                        description = ('+%d Panel(s) | Modell: %s | Gesamt: %d'):format(added, stack[1].model, #draft.panels),
                        type = added > 0 and 'success' or 'inform',
                    })
                else
                    lib.notify({ title = 'Tor-Setup', description = 'Kein Objekt im Fadenkreuz.', type = 'error' })
                end
            end

            if IsControlJustPressed(0, 199) then -- P
                local entity = getLookedAtObject()
                if entity then
                    local coords = GetEntityCoords(entity)
                    draft.controlPanel = {
                        model = GetEntityModel(entity),
                        searchCoords = coords,
                        searchRadius = 1.5,
                    }
                    draft.target = { coords = coords, radius = 2.5 }
                    lib.notify({
                        title = 'Bedienfeld',
                        description = ('Modell: %s | ox_target hier'):format(GetEntityModel(entity)),
                        type = 'success',
                    })
                else
                    lib.notify({ title = 'Tor-Setup', description = 'Schau auf das Wand-Bedienfeld.', type = 'error' })
                end
            end

            if IsControlJustPressed(0, 74) then -- H
                local input = lib.inputDialog('Hubhöhe (Meter)', {
                    { type = 'number', label = 'Travel', default = draft.travel or 4.2, min = 1.0, max = 8.0 },
                })
                if input then
                    draft.travel = input[1]
                    lib.notify({ title = 'Hubhöhe', description = ('%.1fm'):format(draft.travel), type = 'success' })
                end
            end

            if IsControlJustPressed(0, 191) then -- ENTER
                if #draft.panels == 0 then
                    lib.notify({ title = 'Tor-Setup', description = 'Mindestens 1 Tor-Panel hinzufügen.', type = 'error' })
                elseif not draft.controlPanel then
                    lib.notify({ title = 'Tor-Setup', description = 'Bedienfeld mit [P] markieren.', type = 'error' })
                else
                    updateDraftReference(draft)
                    saveAllGates()
                    break
                end
            end

            if IsControlJustPressed(0, 177) then -- BACKSPACE
                stopEditor()
                lib.notify({ title = 'Tor-Setup', description = 'Abgebrochen.', type = 'inform' })
                break
            end

            Wait(0)
        end
    end)
end

local function openGateEditor(gateIndex)
    local gateId = ('rwmp_tor_%d'):format(gateIndex)
    local existing = GetGateConfig(gateId)

    local draft = {
        id = gateId,
        label = existing and existing.label or ('Tor %d – Rettungswache'):format(gateIndex),
        mode = 'mlo',
        travel = existing and existing.travel or 4.2,
        moveAxis = existing and existing.moveAxis or 'z',
        speed = existing and existing.speed or 0.9,
        remoteRange = existing and existing.remoteRange or 35.0,
        panels = {},
        closed = existing and existing.closed,
        target = existing and existing.target,
        controlPanel = existing and existing.controlPanel,
    }

    if existing and existing.panels then
        for _, panel in ipairs(existing.panels) do
            draft.panels[#draft.panels + 1] = {
                model = panel.model,
                searchCoords = panel.searchCoords,
                searchRadius = panel.searchRadius or 3.0,
            }
        end
    end

    lib.registerContext({
        id = 'rd_tor_editor_' .. gateId,
        title = ('Tor einrichten: %s'):format(draft.label),
        menu = 'rd_tor_setup_main',
        options = {
            {
                title = 'Panel-Auswahl starten',
                description = 'Wie ox_doorlock: auf Panels schauen + E drücken',
                icon = 'crosshairs',
                onSelect = function()
                    startPanelPicker(draft)
                end,
            },
            {
                title = 'Bedienfeld markieren',
                description = 'Schau auf die Wand-Box mit den Tasten + bestätigen',
                icon = 'toggle-on',
                onSelect = function()
                    local entity = getLookedAtObject()
                    if not entity then
                        lib.notify({ title = 'Fehler', description = 'Kein Objekt im Fadenkreuz.', type = 'error' })
                        return
                    end
                    local coords = GetEntityCoords(entity)
                    draft.controlPanel = {
                        model = GetEntityModel(entity),
                        searchCoords = coords,
                        searchRadius = 1.5,
                    }
                    draft.target = { coords = coords, radius = 2.5 }
                    lib.notify({ title = 'Bedienfeld', description = 'Markiert – ox_target erscheint hier.', type = 'success' })
                end,
            },
            {
                title = 'Hubhöhe einstellen',
                icon = 'arrows-up-down',
                onSelect = function()
                    local input = lib.inputDialog('Hubhöhe', {
                        { type = 'number', label = 'Meter', default = draft.travel, min = 1, max = 8 },
                    })
                    if input then draft.travel = input[1] end
                end,
            },
            {
                title = 'Panels löschen',
                description = ('Aktuell: %d Panel(s)'):format(#draft.panels),
                icon = 'trash',
                onSelect = function()
                    draft.panels = {}
                    lib.notify({ title = 'Gelöscht', description = 'Alle Panels entfernt.', type = 'inform' })
                end,
            },
            {
                title = 'Speichern & aktivieren',
                icon = 'floppy-disk',
                onSelect = function()
                    if #draft.panels == 0 then
                        lib.notify({ title = 'Fehler', description = 'Keine Tor-Panels ausgewählt.', type = 'error' })
                        return
                    end
                    if not draft.controlPanel then
                        lib.notify({ title = 'Fehler', description = 'Bedienfeld noch nicht markiert.', type = 'error' })
                        return
                    end
                    updateDraftReference(draft)
                    EditorDraft = draft
                    saveAllGates()
                end,
            },
        },
    })

    lib.showContext('rd_tor_editor_' .. gateId)
end

local function openSetupMenu()
    if not canUseSetup() then
        lib.notify({ title = 'Tor-Setup', description = 'Keine Berechtigung.', type = 'error' })
        return
    end

    local options = {
        {
            title = 'Anleitung',
            description = 'Tor wählen → [E] Panels → [P] Bedienfeld → Speichern',
            icon = 'circle-info',
            disabled = true,
        },
    }

    for i = 1, 3 do
        local gateId = ('rwmp_tor_%d'):format(i)
        local gate = GetGateConfig(gateId)
        local panelCount = gate and gate.panels and #gate.panels or 0
        local hasPanel = gate and gate.controlPanel and true or false
        options[#options + 1] = {
            title = gate and gate.label or ('Tor %d'):format(i),
            description = ('%d Panel(s)%s'):format(panelCount, hasPanel and ' · Bedienfeld OK' or ' · kein Bedienfeld'),
            icon = 'warehouse',
            onSelect = function()
                openGateEditor(i)
            end,
        }
    end

    options[#options + 1] = {
        title = 'Alle Tore neu laden',
        icon = 'rotate',
        onSelect = function()
            TriggerServerEvent('rd-fahrzeugtor:requestSavedGates')
        end,
    }

    lib.registerContext({
        id = 'rd_tor_setup_main',
        title = 'Fahrzeugtor Setup (ox_doorlock)',
        options = options,
    })

    lib.showContext('rd_tor_setup_main')
end

RegisterCommand('rd_tor_setup', function()
    openSetupMenu()
end, false)

RegisterNetEvent('rd-fahrzeugtor:reloadGates', function(gates)
    if type(gates) ~= 'table' then return end
    ReloadAllGates(gates)
end)

RegisterNetEvent('rd-fahrzeugtor:loadSavedGates', function(gates)
    if type(gates) == 'table' and #gates > 0 then
        ReloadAllGates(gates)
    end
end)
