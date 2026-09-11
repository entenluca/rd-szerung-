Config = {}

-- Debug: ox_target-Zonen sichtbar machen
Config.Debug = false

-- MaaviM Rettungswache MP Preset laden?
Config.UseMaavimRettungswachePreset = true

-- Öffnungs-/Schließgeschwindigkeit (Door-System Rate)
Config.DoorRate = 1.0

--[[
    MLO-Tor Konfiguration
    ─────────────────────
    Die Tore sind bereits im MLO – es wird NICHTS gespawnt.

    Pflicht:
      name    – Anzeigename
      coords  – Position des Tores (vector3) – zum Finden & ox_target

    Optional:
      distance    – Such-/Interaktionsradius (Standard: 2.5)
      model       – Modell-Hash des Tor-Objekts (empfohlen, /rd_tor_find)
      doorHash    – Feste Door-System-ID falls vom MLO vorgegeben
      rate        – Öffnungsgeschwindigkeit für dieses Tor

    Tore finden: /rd_tor_find (neben Tor stehen) oder /rd_tor_scan [radius]
]]
Config.Gates = {}
