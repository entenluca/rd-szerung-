Config = {}

-- Sprache für ox_lib Benachrichtigungen
Config.Locale = 'de'

-- Debug-Modus für ox_target Zonen
Config.Debug = false

-- MaaviM Rettungswache MP Preset aktivieren?
Config.UseMaavimRettungswachePreset = true

-- Auto-Setup: erkennt MLO-Tore automatisch (siehe Preset)
Config.AutoSetup = Config.AutoSetup or nil

-- Name der MLO-Ressource (nur Hinweis/Check beim Start)
Config.MloResource = 'MM_Rettungswache'

-- Item-Name für die Fernbedienung (ox_inventory)
Config.RemoteItem = 'tor_fernbedienung'

-- Maximale Reichweite der Fernbedienung (in Metern)
Config.RemoteRange = 30.0

-- Fernbedienung zeigt immer das Tor-Auswahl-Panel (auch bei nur 1 Tor)
Config.RemoteAlwaysShowSelector = true

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
    Tor-Modi:
    - mode = 'mlo'   → vorhandene MLO-Tore finden und bewegen (MaaviM Rettungswache etc.)
    - mode = 'spawn' → Prop selbst spawnen (Standard wenn mode fehlt)

    MLO-Tor Felder:
    - panels: Liste mit { model, searchCoords, searchRadius } – je Sektional-Panel
    - closed: vec4 Referenzposition (Mitte des Tores, geschlossen)
    - travel: Hubhöhe in Metern (Alternative zu open)
    - target: ox_target SphereZone { coords, radius } – funktioniert immer
    - warningLight.mode = 'mlo' → vorhandene Warnleuchte im MLO finden

    Scanner-Befehle (ingame):
    - /rd_tor_scan [radius]  → zeigt Modell-Hashes naher Objekte in F8
    - /rd_tor_copy           → aktuelle Position als vec4
]]
Config.Gates = {
    -- Wird durch config/presets/maavim_rettungswache.lua überschrieben wenn Preset aktiv
}
