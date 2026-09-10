if not Config.UseMaavimRettungswachePreset then
    return
end

--[[
    MaaviM – Rettungswache MP
    https://store.maavim-modding.com/product/rettungswache-mp

    Auto-Setup erkennt die Garagentore und Warnleuchten automatisch.
    Scan-Zentrum: Postal 7324 (West Mirror Drive) – passe center an,
    falls dein MLO woanders platziert ist.
]]

Config.MloResource = 'MM_Rettungswache'

Config.AutoSetup = {
    enabled = false,
    center = vec3(1048.39, -790.47, 31.5),
    radius = 45.0,
    expectedGates = 3,
    travel = 4.2,
    moveAxis = 'z',
    speed = 0.9,
    clusterAxis = 'x',
    gateGap = 4.0,
    stackGap = 1.5,
    minPanelsPerModel = 2,
    targetRadius = 2.5,
    remoteRange = 35.0,
    retryMs = 3000,
    maxAttempts = 40,
    panelPatterns = {
        'tor', 'door', 'garag', 'gate', 'sect', 'panel', 'rollo', 'mm_',
    },
    lightPatterns = {
        'warn', 'licht', 'light', 'blink', 'ampel', 'lampe', 'signal',
    },
    excludePatterns = {
        'wand', 'decal', 'logo', 'schild', 'boden', 'floor', 'dec', 'text',
    },
}

-- Fallback-Zonen (ox_target) bis Auto-Setup die echten Tore findet
Config.Gates = {
    {
        id = 'rwmp_tor_1',
        label = 'Tor 1 – Rettungswache',
        mode = 'mlo',
        closed = vec4(1044.0, -790.47, 31.5, 0.0),
        travel = 4.2,
        moveAxis = 'z',
        speed = 0.9,
        panels = {},
        target = { coords = vec3(1044.0, -790.47, 31.5), radius = 2.5 },
        remoteRange = 35.0,
    },
    {
        id = 'rwmp_tor_2',
        label = 'Tor 2 – Rettungswache',
        mode = 'mlo',
        closed = vec4(1048.39, -790.47, 31.5, 0.0),
        travel = 4.2,
        moveAxis = 'z',
        speed = 0.9,
        panels = {},
        target = { coords = vec3(1048.39, -790.47, 31.5), radius = 2.5 },
        remoteRange = 35.0,
    },
    {
        id = 'rwmp_tor_3',
        label = 'Tor 3 – Rettungswache',
        mode = 'mlo',
        closed = vec4(1052.5, -790.47, 31.5, 0.0),
        travel = 4.2,
        moveAxis = 'z',
        speed = 0.9,
        panels = {},
        target = { coords = vec3(1052.5, -790.47, 31.5), radius = 2.5 },
        remoteRange = 35.0,
    },
}
