local UsingControlPanel = false

local function findObjectAt(model, coords, radius)
    local entity = GetClosestObjectOfType(coords.x, coords.y, coords.z, radius, model, false, false, false)
    if entity ~= 0 and DoesEntityExist(entity) then
        return entity
    end
end

function ResolveControlPanel(gate)
    local panel = gate.controlPanel
    if not panel or not panel.model or not panel.searchCoords then
        return nil
    end

    return findObjectAt(panel.model, panel.searchCoords, panel.searchRadius or 1.5)
end

function WaitForControlPanel(gateId, gate, gateData, onResolved)
    if not gate.controlPanel then
        return
    end

    CreateThread(function()
        local attempts = 0
        while attempts < 40 do
            local entity = ResolveControlPanel(gate)
            if entity then
                gateData.controlPanelEntity = entity
                RegisterControlPanelTarget(gateId, entity)
                if onResolved then
                    onResolved(gateId, gateData)
                end
                print(('[rd-fahrzeugtor] Bedienfeld für "%s" gefunden'):format(gateId))
                return
            end

            attempts = attempts + 1
            Wait(2000)
        end

        print(('[rd-fahrzeugtor] Bedienfeld für "%s" nicht gefunden – /rd_tor_setup nutzen'):format(gateId))
    end)
end

local function faceEntity(ped, entity)
    TaskTurnPedToFaceEntity(ped, entity, 800)
    Wait(800)
end

function UseControlPanel(gateId)
    if UsingControlPanel then
        return
    end

    if not CanControlGate() then
        lib.notify({ title = 'Fahrzeugtor', description = 'Keine Berechtigung.', type = 'error' })
        return
    end

    local gateData = GetGateData(gateId)
    if not gateData then
        return
    end

    if IsMloGate(gateData.config) and not gateData.bound then
        lib.notify({ title = 'Fahrzeugtor', description = 'Tor noch nicht eingerichtet. Nutze /rd_tor_setup', type = 'error' })
        return
    end

    local panelEntity = gateData.controlPanelEntity
    if not panelEntity or not DoesEntityExist(panelEntity) then
        panelEntity = ResolveControlPanel(gateData.config)
        gateData.controlPanelEntity = panelEntity
    end

    if not panelEntity then
        lib.notify({ title = 'Fahrzeugtor', description = 'Bedienfeld nicht gefunden.', type = 'error' })
        return
    end

    UsingControlPanel = true
    local ped = PlayerPedId()
    faceEntity(ped, panelEntity)

    local anim = Config.ControlPanelAnim or {}
    local success = lib.progressCircle({
        duration = anim.duration or 1800,
        label = 'Bedienfeld wird benutzt...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = anim.dict or 'anim@heists@keypad@',
            clip = anim.clip or 'idle_a',
            flag = anim.flag or 49,
        },
    })

    ClearPedTasks(ped)
    UsingControlPanel = false

    if not success then
        return
    end

    local gatesInRange = GetGatesForControlPanel(panelEntity, gateId)
    if #gatesInRange > 1 then
        OpenGateSelectorForPanel(gatesInRange)
    else
        OpenGateUI(gateId)
    end
end

function GetGatesForControlPanel(panelEntity, preferredGateId)
    local results = {}
    local panelCoords = GetEntityCoords(panelEntity)

    for gateId, gateData in pairs(GetAllGates()) do
        local gate = gateData.config
        local matches = gateId == preferredGateId

        if gate.controlPanel and gate.controlPanel.searchCoords then
            local distance = #(panelCoords - gate.controlPanel.searchCoords)
            matches = distance <= (gate.controlPanel.searchRadius or 2.0) + 0.5
        end

        if matches and gateData.bound then
            results[#results + 1] = {
                id = gateId,
                label = gate.label,
                state = gateData.state,
                progress = gateData.progress,
                progressLabel = GetProgressLabel(gateData.progress),
            }
        end
    end

    if #results == 0 and preferredGateId then
        local gateData = GetGateData(preferredGateId)
        if gateData then
            results[#results + 1] = {
                id = preferredGateId,
                label = gateData.config.label,
                state = gateData.state,
                progress = gateData.progress,
                progressLabel = GetProgressLabel(gateData.progress),
            }
        end
    end

    return results
end

function OpenGateSelectorForPanel(gates)
    if Config.UseOxLibSelector then
        local options = {}
        for _, gate in ipairs(gates) do
            options[#options + 1] = {
                title = gate.label,
                description = gate.progressLabel,
                icon = 'warehouse',
                onSelect = function()
                    OpenGateUI(gate.id)
                end,
            }
        end

        lib.registerContext({
            id = 'rd_tor_panel_selector',
            title = 'Tor wählen',
            options = options,
        })
        lib.showContext('rd_tor_panel_selector')
        return
    end

    if #gates == 1 then
        OpenGateUI(gates[1].id)
    else
        OpenGateSelector()
    end
end
