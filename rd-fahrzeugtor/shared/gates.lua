GateStates = {
    CLOSED = 'closed',
    OPEN = 'open',
    OPENING = 'opening',
    CLOSING = 'closing',
    STOPPED = 'stopped',
}

---@param gate table
---@return vector4
function GetGateOpenPosition(gate)
    if gate.open then
        return gate.open
    end

    local closed = gate.closed
    local travel = gate.travel or 3.5
    local axis = gate.moveAxis or 'z'

    if axis == 'x' then
        return vec4(closed.x + travel, closed.y, closed.z, closed.w)
    elseif axis == 'y' then
        return vec4(closed.x, closed.y + travel, closed.z, closed.w)
    end

    return vec4(closed.x, closed.y, closed.z + travel, closed.w)
end

---@param gateId string
---@return table|nil
function GetGateConfig(gateId)
    for _, gate in ipairs(Config.Gates) do
        if gate.id == gateId then
            return gate
        end
    end
end

---@param gate table
---@param progress number 0.0 = geschlossen, 1.0 = geöffnet
---@return vector3, number
function CalculateGateTransform(gate, progress)
    progress = math.min(1.0, math.max(0.0, progress))

    local closed = gate.closed
    local open = GetGateOpenPosition(gate)

    local x = closed.x + (open.x - closed.x) * progress
    local y = closed.y + (open.y - closed.y) * progress
    local z = closed.z + (open.z - closed.z) * progress
    local heading = closed.w + (open.w - closed.w) * progress

    return vector3(x, y, z), heading
end

---@param gate table
---@param progress number
---@return number
function GetGateTravelDistance(gate)
    local closed = gate.closed
    local open = GetGateOpenPosition(gate)
    return #(vector3(closed.x, closed.y, closed.z) - vector3(open.x, open.y, open.z))
end

---@param gate table
---@param progress number
---@return number
function GetAxisValue(gate, progress)
    progress = math.min(1.0, math.max(0.0, progress))
    local closed = gate.closed
    local open = GetGateOpenPosition(gate)

    if gate.moveAxis == 'x' then
        return closed.x + (open.x - closed.x) * progress
    elseif gate.moveAxis == 'y' then
        return closed.y + (open.y - closed.y) * progress
    end

    return closed.z + (open.z - closed.z) * progress
end

---@param state string
---@return boolean
function IsGateMoving(state)
    return state == GateStates.OPENING or state == GateStates.CLOSING
end

---@param progress number
---@return string
function GetProgressLabel(progress)
    if progress <= 0.01 then
        return 'Geschlossen'
    elseif progress >= 0.99 then
        return 'Geöffnet'
    end

    return ('Teilweise geöffnet (%d%%)'):format(math.floor(progress * 100))
end

---@param gate table
---@return boolean
function IsMloGate(gate)
    return gate.mode == 'mlo'
end
