GateStatesServer = {}

local function initGateStates()
    for _, gate in ipairs(Config.Gates) do
        GateStatesServer[gate.id] = {
            state = GateStates.CLOSED,
            progress = 0.0,
        }
    end
end

local function setGateState(gateId, state, progress)
    if not GateStatesServer[gateId] then
        return false
    end

    GateStatesServer[gateId].state = state
    GateStatesServer[gateId].progress = progress

    TriggerClientEvent('rd-fahrzeugtor:applyState', -1, gateId, state, progress)
    return true
end

local function handleAction(gateId, action)
    local gateState = GateStatesServer[gateId]
    local gateConfig = GetGateConfig(gateId)

    if not gateState or not gateConfig then
        return
    end

    if action == 'open' then
        if gateState.state == GateStates.OPEN or gateState.state == GateStates.OPENING then
            return
        end

        setGateState(gateId, GateStates.OPENING, gateState.progress)
    elseif action == 'close' then
        if gateState.state == GateStates.CLOSED or gateState.state == GateStates.CLOSING then
            return
        end

        setGateState(gateId, GateStates.CLOSING, gateState.progress)
    elseif action == 'stop' then
        if not IsGateMoving(gateState.state) then
            return
        end

        setGateState(gateId, GateStates.STOPPED, gateState.progress)
    end
end

RegisterNetEvent('rd-fahrzeugtor:requestAction', function(gateId, action)
    if type(gateId) ~= 'string' or type(action) ~= 'string' then
        return
    end

    if action ~= 'open' and action ~= 'close' and action ~= 'stop' then
        return
    end

    handleAction(gateId, action)
end)

RegisterNetEvent('rd-fahrzeugtor:syncState', function(gateId, state, progress)
    if type(gateId) ~= 'string' or type(state) ~= 'string' or type(progress) ~= 'number' then
        return
    end

    if not GateStatesServer[gateId] then
        return
    end

    GateStatesServer[gateId].state = state
    GateStatesServer[gateId].progress = progress
    TriggerClientEvent('rd-fahrzeugtor:applyState', -1, gateId, state, progress)
end)

RegisterNetEvent('rd-fahrzeugtor:requestInit', function()
    local source = source
    TriggerClientEvent('rd-fahrzeugtor:initGates', source, GateStatesServer)
end)

lib.callback.register('rd-fahrzeugtor:canSetup', function(source)
    if not Config.SetupAce then
        return true
    end
    return IsPlayerAceAllowed(source, Config.SetupAce)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    if LoadSavedGates() then
        print(('[rd-fahrzeugtor] %d gespeicherte Tore aus data/gates.json geladen'):format(#Config.Gates))
    end

    initGateStates()
end)

if LoadSavedGates() then
    print(('[rd-fahrzeugtor] %d gespeicherte Tore aus data/gates.json geladen'):format(#Config.Gates))
end

initGateStates()
