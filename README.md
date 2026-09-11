# rd-fahrzeugtor

FiveM-Script zum Steuern von **bereits vorhandenen MLO-Toren** – ohne Spawning, ohne Objekt-Ersatz.

Nutzt das **FiveM Door-System** (`AddDoorToSystem`) und **ox_target**.

## Features

- Verwendet ausschließlich die **originalen MLO-Tore**
- Alle Tore starten **geschlossen**
- **ox_target**: „Tor öffnen“ / „Tor schließen“ (dynamisch je nach Zustand)
- Kein Auto-Öffnen beim Annähern
- Jedes Tor ist **unabhängig** konfigurierbar
- Kein Framework nötig

## Abhängigkeiten

- [ox_target](https://github.com/overextended/ox_target)
- Dein MLO (z. B. `MM_Rettungswache`)

## Installation

```cfg
ensure ox_target
ensure MM_Rettungswache
ensure rd-fahrzeugtor
```

## Config (`config.lua`)

```lua
Config.Gates = {
    {
        name = 'Haupttor',
        coords = vector3(1048.39, -790.47, 31.5),
        distance = 2.5,
        model = 1234567890,  -- optional, empfohlen (/rd_tor_find)
    },
}
```

| Feld | Beschreibung |
|------|--------------|
| `name` | Anzeigename |
| `coords` | Position des Tores (vector3) |
| `distance` | Such- und Interaktionsradius |
| `model` | Modell-Hash des Tor-Objekts (empfohlen) |
| `doorHash` | Feste Door-ID falls vom MLO vorgegeben |
| `rate` | Öffnungsgeschwindigkeit |

MaaviM Preset: `Config.UseMaavimRettungswachePreset = true`

## Tore finden & eintragen

1. Steh direkt vor dem Tor
2. `/rd_tor_find` – gibt Modell, Koordinaten und Config-Snippet aus
3. Optional: `/rd_tor_scan 6` – listet alle nahen Objekte
4. `model` + `coords` in `Config.Gates` eintragen

## Befehle

| Befehl | Beschreibung |
|--------|--------------|
| `/rd_tor_find` | Objekt vor dir analysieren → Config-Snippet |
| `/rd_tor_scan [radius]` | Alle nahen Objekte in F8 listen |

## Hinweis zu MLO-Toren

Das Script funktioniert am besten, wenn die Tore vom MLO als **Door-System-fähige Objekte** gebaut sind. Steht in der MaaviM-Doku ein `doorHash`, trage ihn als `doorHash` in der Config ein.

Falls ein Tor sich nicht bewegt, liefert `/rd_tor_find` das richtige `model` – manche MLO-Tore sind feste Meshes ohne Door-System. Dann muss der MLO-Autor die Tore als bewegliche Doors exportieren.
