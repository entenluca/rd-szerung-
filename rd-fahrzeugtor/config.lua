Config = {}

-- Sprache für ox_lib Benachrichtigungen
Config.Locale = 'de'

-- Debug-Modus für ox_target Zonen
Config.Debug = false

-- Interaktion nur am Bedienfeld (empfohlen) – keine Zonen/Tore direkt anwählbar
Config.InteractionMode = 'controlPanel' -- 'controlPanel' | 'zone' | 'entity'

-- GTA Door-Natives deaktivieren (verhindert Auto-Öffnen beim Annähern)
Config.UseDoorNatives = false

-- Keine Klone: bewegt Original-Props (verhindert Doppel-Tore + MLO-Auto-Open)
Config.UsePanelClones = false

-- Hält geschlossene Tore an Position (gegen MLO-Auto-Animation)
Config.EnforceClosedState = true

-- Ein Bedienfeld = ein Tor (nicht alle 3 gleichzeitig)
Config.SharedControlPanels = false

-- Panel-Suchradius beim Laden (klein = kein Nachbar-Tor)
Config.PanelSearchRadius = 1.2

-- ox_target Reichweite am Bedienfeld
Config.ControlPanelTargetDistance = 1.8

-- Animation beim Benutzen des Bedienfelds
Config.ControlPanelAnim = {
    dict = 'anim@heists@keypad@',
    clip = 'idle_a',
    flag = 49,
    duration = 1800,
}

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

-- Tor-Auswahl über ox_lib Menü statt NUI (stabiler)
Config.UseOxLibSelector = true

-- Hinweis beim Start zur Tor-Bindung
Config.ShowSetupHint = true

-- ACE-Berechtigung für /rd_tor_setup (nil = jeder)
-- Beispiel in server.cfg: add_ace group.admin rd_fahrzeugtor.setup allow
Config.SetupAce = nil

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
    - controlPanel: { model, searchCoords, searchRadius } – Wand-Bedienfeld (ox_target)
    - target: ox_target SphereZone { coords, radius } – Fallback wenn InteractionMode = 'zone'
    - warningLight.mode = 'mlo' → vorhandene Warnleuchte im MLO finden

    Scanner-Befehle (ingame):
    - /rd_tor_scan [radius]  → zeigt Modell-Hashes naher Objekte in F8
    - /rd_tor_copy           → aktuelle Position als vec4
]]
Config.Gates = {
    -- Wird durch config/presets/maavim_rettungswache.lua überschrieben wenn Preset aktiv
}
