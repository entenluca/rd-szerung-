GateStates = {
    CLOSED = 'closed',
    OPEN = 'open',
    OPENING = 'opening',
    CLOSING = 'closing',
    STOPPED = 'stopped',
}

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
    local open = gate.open

    local x = closed.x + (open.x - closed.x) * progress
    local y = closed.y + (open.y - closed.y) * progress
    local z = closed.z + (open.z - closed.z) * progress
    local heading = closed.w + (open.w - closed.w) * progress

    return vector3(x, y, z), heading
end

---@param gate table
---@param progress number
---@return number
function GetAxisValue(gate, progress)
    progress = math.min(1.0, math.max(0.0, progress))
    local closed = gate.closed
    local open = gate.open

    if gate.moveAxis == 'x' then
        return closed.x + (open.x - closed.x) * progress
    elseif gate.moveAxis == 'y' then
        return closed.y + (open.y - closed.y) * progress
    end

    return closed.z + (open.z - closed.z) * progress
end

---@param gate table
---@param coords vector3
---@return number
function GetProgressFromCoords(gate, coords)
    local closed = gate.closed
    local open = gate.open

    local start, target
    if gate.moveAxis == 'x' then
        start, target = closed.x, open.x
        return (coords.x - start) / (target - start)
    elseif gate.moveAxis == 'y' then
        start, target = closed.y, open.y
        return (coords.y - start) / (target - start)
    end

    start, target = closed.z, open.z
    if target == start then
        return 0.0
    end

    return (coords.z - start) / (target - start)
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
