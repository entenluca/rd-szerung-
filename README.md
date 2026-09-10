# RD-Szene Scripts

FiveM-Skripte für Rettungsdienst-, Feuerwehr- und Polizei-RP.

## rd-fahrzeugtor

Realistisches Fahrzeugtor-System – speziell für **MLO-Garagentore** wie die [MaaviM Rettungswache MP](https://store.maavim-modding.com/product/rettungswache-mp).

### Features

- **MLO-Modus** – bewegt die echten Tore aus dem Mapping (kein Prop-Spawn)
- **ox_target** – Tor anwählen oder Interaktionszone in der Tor-Mitte
- **NUI-Steuerung** – Öffnen, Stopp, Schließen mit Fortschrittsanzeige
- **Stopp-Funktion** – Tor auf jeder Höhe anhalten
- **Fernbedienung** – Item oder `F6`, auch aus Fahrzeugen
- **Sounds** – Torgeräusche während der Bewegung
- **Warnleuchte** – nutzt die roten Leuchten am MLO (blinkt bei Bewegung)

### Abhängigkeiten

- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- MaaviM MLO-Ressource (z. B. `MM_Rettungswache`)
- [ox_inventory](https://github.com/overextended/ox_inventory) (optional)

### Installation

```cfg
ensure ox_lib
ensure ox_target
ensure MM_Rettungswache        # dein MaaviM MLO
ensure rd-fahrzeugtor
```

1. In `config.lua`: `Config.UseMaavimRettungswachePreset = true`
2. Tore in `config/presets/maavim_rettungswache.lua` einrichten (siehe unten)
3. Optional: Fernbedienungs-Item aus `install/ox_inventory_item.lua`

### MaaviM Rettungswache MP einrichten

Die Tore werden **automatisch erkannt** – kein manuelles Hash-Auslesen nötig.

1. `ensure MM_Rettungswache` vor `ensure rd-fahrzeugtor`
2. `Config.UseMaavimRettungswachePreset = true` (Standard)
3. Starte den Server – das Script scannt die Rettungswache (Postal 7324 / West Mirror Drive)
4. Falls nötig: stell dich vor die Tore und nutze `/rd_tor_autosetup`

**MLO woanders platziert?** Passe in `config/presets/maavim_rettungswache.lua` nur `Config.AutoSetup.center` an.

**Manuell einrichten** (falls Auto-Setup nicht greift): `/rd_tor_scan 4` und `/rd_tor_copy`

### Scanner-Befehle

| Befehl | Beschreibung |
|--------|--------------|
| `/rd_tor_scan [radius]` | Listet nahe Objekte mit Modell-Hash in F8 |
| `/rd_tor_copy` | Gibt aktuelle Position als `vec4` aus |

### Steuerung

| Aktion | Beschreibung |
|--------|--------------|
| ox_target am Tor / in der Zone | Steuerungs-UI öffnen |
| **Öffnen / Stopp / Schließen** | Tor steuern |
| `F6` | Fernbedienung |
| `ESC` | UI schließen |

### Eigenes MLO / andere Tore

Setze `Config.UseMaavimRettungswachePreset = false` und definiere `Config.Gates` manuell:

```lua
{
    id = 'mein_tor',
    label = 'Garagentor',
    mode = 'mlo',           -- oder 'spawn' für eigene Props
    closed = vec4(x, y, z, heading),
    travel = 3.8,
    moveAxis = 'z',
    speed = 0.9,
    panels = { ... },
    target = { coords = vec3(x, y, z), radius = 2.5 },
}
```
