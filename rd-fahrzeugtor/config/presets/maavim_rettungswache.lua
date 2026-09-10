if not Config.UseMaavimRettungswachePreset then
    return
end

--[[
    MaaviM – Rettungswache MP
    https://store.maavim-modding.com/product/rettungswache-mp

    WICHTIG: Die Modell-Hashes und Koordinaten unten sind Platzhalter!
    Du musst sie einmalig mit dem Ingame-Scanner auslesen:

    1. Stelle sicher, dass das MLO (z. B. MM_Rettungswache) läuft
    2. Gehe vor ein geschlossenes Tor und schaue auf ein Tor-Panel
    3. Führe aus: /rd_tor_scan 4
    4. Kopiere Modell + searchCoords aus der F8-Konsole in die panels-Liste
    5. Stelle dich in die Mitte des Tores und nutze /rd_tor_copy für target.coords + closed
    6. Passe travel (Hubhöhe in Metern) an – bei Sektionaltoren meist 3.5–4.2

    Die roten Warnleuchten neben den Toren ebenfalls mit /rd_tor_scan finden
    und unter warningLight eintragen.
]]

Config.MloResource = 'MM_Rettungswache'

Config.Gates = {
    {
        id = 'rwmp_tor_1',
        label = 'Tor 1 – Rettungswache',
        mode = 'mlo',
        closed = vec4(0.0, 0.0, 0.0, 0.0), -- /rd_tor_copy in Tor-Mitte
        travel = 3.8,
        moveAxis = 'z',
        speed = 0.9,
        panels = {
            -- Beispiel – Modell aus /rd_tor_scan eintragen:
            -- { model = `DEIN_TOR_MODELL`, searchCoords = vec3(x, y, z), searchRadius = 2.5 },
        },
        warningLight = {
            mode = 'mlo',
            -- model = `DEIN_WARNLEUCHTEN_MODELL`,
            -- searchCoords = vec3(x, y, z),
            searchRadius = 1.5,
        },
        target = {
            coords = vec3(0.0, 0.0, 0.0), -- gleiche Position wie closed (ohne heading)
            radius = 2.5,
        },
        remoteRange = 35.0,
    },
    {
        id = 'rwmp_tor_2',
        label = 'Tor 2 – Rettungswache',
        mode = 'mlo',
        closed = vec4(0.0, 0.0, 0.0, 0.0),
        travel = 3.8,
        moveAxis = 'z',
        speed = 0.9,
        panels = {},
        warningLight = {
            mode = 'mlo',
            searchRadius = 1.5,
        },
        target = {
            coords = vec3(0.0, 0.0, 0.0),
            radius = 2.5,
        },
        remoteRange = 35.0,
    },
    {
        id = 'rwmp_tor_3',
        label = 'Tor 3 – Rettungswache',
        mode = 'mlo',
        closed = vec4(0.0, 0.0, 0.0, 0.0),
        travel = 3.8,
        moveAxis = 'z',
        speed = 0.9,
        panels = {},
        warningLight = {
            mode = 'mlo',
            searchRadius = 1.5,
        },
        target = {
            coords = vec3(0.0, 0.0, 0.0),
            radius = 2.5,
        },
        remoteRange = 35.0,
    },
}
