if not Config.UseMaavimRettungswachePreset then
    return
end

--[[
    MaaviM – Rettungswache MP
    Resource: MM_Rettungswache
    Tor-Modell: mm_rdw_gate (Hash: -41480326)

    Koordinaten aus /rd_tor_scan – Tor 3 ggf. mit /rd_tor_find vor Ort prüfen.
]]

Config.MloResource = 'MM_Rettungswache'

local GATE_MODEL = -41480326 -- mm_rdw_gate

Config.Gates = {
    {
        name = 'Tor 1 – Rettungswache',
        coords = vector3(1075.32, -779.10, 60.97),
        model = GATE_MODEL,
        distance = 3.0,
    },
    {
        name = 'Tor 2 – Rettungswache',
        coords = vector3(1080.33, -779.10, 60.97),
        model = GATE_MODEL,
        distance = 3.0,
    },
    {
        name = 'Tor 3 – Rettungswache',
        coords = vector3(1085.34, -779.10, 60.97),
        model = GATE_MODEL,
        distance = 3.0,
    },
}
