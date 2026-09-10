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

Die Tore und Warnleuchten sind **Teil des MLO** – du musst einmalig die Modell-Hashes und Koordinaten auslesen:

1. Gehe zur Rettungswache (wie auf deinem Screenshot)
2. Stelle dich vor ein **geschlossenes** Tor-Panel
3. Führe aus: `/rd_tor_scan 4`
4. In der **F8-Konsole** siehst du Modell-Hash und Koordinaten
5. Trage diese in `panels` ein:

```lua
panels = {
    { model = `1234567890`, searchCoords = vec3(x, y, z), searchRadius = 2.5 },
    -- bei Sektionaltoren oft mehrere Panels pro Tor
},
```

6. Stelle dich in die **Mitte des Tores** → `/rd_tor_copy` für `closed` und `target.coords`
7. Passe `travel` an (Hubhöhe, meist **3.5–4.2** Meter bei Sektionaltoren)
8. Warnleuchte: mit `/rd_tor_scan` die rote Leuchte neben dem Tor finden:

```lua
warningLight = {
    mode = 'mlo',
    model = `WARNLEUCHTEN_HASH`,
    searchCoords = vec3(x, y, z),
    searchRadius = 1.5,
},
```

9. Wiederhole für Tor 2 und Tor 3

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
