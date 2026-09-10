Config = {}

-- Sprache für ox_lib Benachrichtigungen
Config.Locale = 'de'

-- Item-Name für die Fernbedienung (ox_inventory)
Config.RemoteItem = 'tor_fernbedienung'

-- Maximale Reichweite der Fernbedienung (in Metern)
Config.RemoteRange = 30.0

-- Soll die Fernbedienung auch aus Fahrzeugen funktionieren?
Config.RemoteFromVehicle = true

-- Job-Beschränkung (nil = jeder darf steuern)
-- Beispiel: { ambulance = 0, police = 0, fire = 0 }
Config.AllowedJobs = nil

-- Sound-Lautstärke (0.0 - 1.0)
Config.SoundVolume = 0.65

-- Warnleuchte: Blink-Intervall in Millisekunden
Config.WarningLightBlinkMs = 450

--[[
    Tor-Konfiguration

    Jedes Tor benötigt:
    - id: Eindeutige Kennung
    - label: Anzeigename in der UI
    - model: GTA Prop-Modell für das Tor
    - closed / open: Position und Rotation (vec4: x, y, z, w=heading)
    - moveAxis: 'z' (hoch/runter), 'x' oder 'y' (schieben)
    - speed: Bewegungsgeschwindigkeit (Meter pro Sekunde)
    - warningLight: optionale Warnleuchte am Tor
    - remoteRange: optionale individuelle Fernbedienungs-Reichweite
]]
Config.Gates = {
    {
        id = 'feuerwache_haupttor',
        label = 'Haupttor Feuerwache',
        model = `prop_ind_mech_01c`,
        closed = vec4(215.45, -1645.12, 29.80, 320.0),
        open = vec4(215.45, -1645.12, 33.50, 320.0),
        moveAxis = 'z',
        speed = 0.85,
        warningLight = {
            model = `prop_warninglight_01`,
            offset = vec3(0.0, 0.0, 2.2),
            rot = vec3(0.0, 0.0, 320.0),
        },
        remoteRange = 35.0,
    },
    -- Weitere Tore hier hinzufügen ...
}
