SavedGatesFile = 'data/gates.json'
RuntimeGates = {}
HasSavedGates = false

local function vec3FromTable(t)
    if not t then return nil end
    return vec3(t.x or t[1] or 0.0, t.y or t[2] or 0.0, t.z or t[3] or 0.0)
end

local function vec4FromTable(t)
    if not t then return nil end
    return vec4(t.x or t[1] or 0.0, t.y or t[2] or 0.0, t.z or t[3] or 0.0, t.w or t[4] or 0.0)
end

local function tableFromVec3(v)
    return { x = v.x, y = v.y, z = v.z }
end

local function tableFromVec4(v)
    return { x = v.x, y = v.y, z = v.z, w = v.w }
end

function SerializeGate(gate)
    local panels = {}
    for _, panel in ipairs(gate.panels or {}) do
        panels[#panels + 1] = {
            model = panel.model,
            searchCoords = tableFromVec3(panel.searchCoords),
            searchRadius = panel.searchRadius or 3.0,
        }
    end

    local serialized = {
        id = gate.id,
        label = gate.label,
        mode = gate.mode or 'mlo',
        closed = gate.closed and tableFromVec4(gate.closed),
        travel = gate.travel or 4.2,
        moveAxis = gate.moveAxis or 'z',
        speed = gate.speed or 0.9,
        panels = panels,
        remoteRange = gate.remoteRange or 35.0,
    }

    if gate.target and gate.target.coords then
        serialized.target = {
            coords = tableFromVec3(gate.target.coords),
            radius = gate.target.radius or 2.5,
        }
    end

    if gate.warningLight then
        serialized.warningLight = {
            mode = gate.warningLight.mode or 'mlo',
            model = gate.warningLight.model,
            searchCoords = gate.warningLight.searchCoords and tableFromVec3(gate.warningLight.searchCoords),
            searchRadius = gate.warningLight.searchRadius or 2.0,
        }
    end

    if gate.controlPanel and gate.controlPanel.searchCoords then
        serialized.controlPanel = {
            model = gate.controlPanel.model,
            searchCoords = tableFromVec3(gate.controlPanel.searchCoords),
            searchRadius = gate.controlPanel.searchRadius or 1.5,
        }
    end

    return serialized
end

function DeserializeGate(data)
    local panels = {}
    for _, panel in ipairs(data.panels or {}) do
        panels[#panels + 1] = {
            model = panel.model,
            searchCoords = vec3FromTable(panel.searchCoords),
            searchRadius = panel.searchRadius or 3.0,
        }
    end

    local gate = {
        id = data.id,
        label = data.label,
        mode = data.mode or 'mlo',
        closed = vec4FromTable(data.closed),
        travel = data.travel or 4.2,
        moveAxis = data.moveAxis or 'z',
        speed = data.speed or 0.9,
        panels = panels,
        remoteRange = data.remoteRange or 35.0,
    }

    if data.target and data.target.coords then
        gate.target = {
            coords = vec3FromTable(data.target.coords),
            radius = data.target.radius or 2.5,
        }
    end

    if data.warningLight then
        gate.warningLight = {
            mode = data.warningLight.mode or 'mlo',
            model = data.warningLight.model,
            searchCoords = data.warningLight.searchCoords and vec3FromTable(data.warningLight.searchCoords),
            searchRadius = data.warningLight.searchRadius or 2.0,
        }
    end

    if data.controlPanel and data.controlPanel.searchCoords then
        gate.controlPanel = {
            model = data.controlPanel.model,
            searchCoords = vec3FromTable(data.controlPanel.searchCoords),
            searchRadius = data.controlPanel.searchRadius or 1.5,
        }
    end

    return gate
end

function LoadSavedGates()
    local raw = LoadResourceFile(GetCurrentResourceName(), SavedGatesFile)
    RuntimeGates = {}
    HasSavedGates = false

    if not raw or raw == '' then
        return false
    end

    local decoded = json.decode(raw)
    if not decoded or not decoded.gates or #decoded.gates == 0 then
        return false
    end

    for _, gateData in ipairs(decoded.gates) do
        RuntimeGates[#RuntimeGates + 1] = DeserializeGate(gateData)
    end

    Config.Gates = RuntimeGates
    HasSavedGates = true
    return true
end

function SaveGatesToFile(gates)
    local serialized = {}
    for _, gate in ipairs(gates) do
        serialized[#serialized + 1] = SerializeGate(gate)
    end

    local content = json.encode({ gates = serialized }, { indent = true })
    SaveResourceFile(GetCurrentResourceName(), SavedGatesFile, content, -1)
    RuntimeGates = gates
    Config.Gates = gates
    return true
end

RegisterNetEvent('rd-fahrzeugtor:saveGates', function(gates)
    local source = source
    if type(gates) ~= 'table' then
        return
    end

    if Config.SetupAce and not IsPlayerAceAllowed(source, Config.SetupAce) then
        return
    end

    local deserialized = {}
    for _, gateData in ipairs(gates) do
        deserialized[#deserialized + 1] = DeserializeGate(gateData)
    end

    SaveGatesToFile(deserialized)
    HasSavedGates = #deserialized > 0

    GateStatesServer = {}
    for _, gate in ipairs(Config.Gates) do
        GateStatesServer[gate.id] = {
            state = GateStates.CLOSED,
            progress = 0.0,
        }
    end

    TriggerClientEvent('rd-fahrzeugtor:reloadGates', -1, gates)
end)

RegisterNetEvent('rd-fahrzeugtor:requestSavedGates', function()
    if not HasSavedGates then
        return
    end

    local source = source
    local serialized = {}
    for _, gate in ipairs(Config.Gates) do
        serialized[#serialized + 1] = SerializeGate(gate)
    end
    TriggerClientEvent('rd-fahrzeugtor:loadSavedGates', source, serialized)
end)
