# RD-Szene Scripts

FiveM-Skripte für Rettungsdienst-, Feuerwehr- und Polizei-RP.

## rd-fahrzeugtor

Realistisches Fahrzeugtor-System mit:

- **ox_target** – Tor mit dem Auge anwählen und Steuerungs-UI öffnen
- **UI-Steuerung** – Öffnen, Stopp, Schließen (Stopp hält das Tor auf jeder Höhe an)
- **Fernbedienung** – Tor aus der Ferne oder direkt aus dem Fahrzeug steuern
- **Sounds** – Torgeräusche während der Bewegung (GTA-native Sounds)
- **Warnleuchte** – Blinkt automatisch, solange sich das Tor bewegt

### Abhängigkeiten

- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [ox_inventory](https://github.com/overextended/ox_inventory) (optional, für Fernbedienungs-Item)

### Installation

1. Ordner `rd-fahrzeugtor` in deinen `resources`-Ordner kopieren
2. In `server.cfg` eintragen:
   ```
   ensure ox_lib
   ensure ox_target
   ensure rd-fahrzeugtor
   ```
3. Tore in `rd-fahrzeugtor/config.lua` konfigurieren (Koordinaten anpassen!)
4. Optional: Fernbedienungs-Item aus `rd-fahrzeugtor/install/ox_inventory_item.lua` in ox_inventory einfügen

### Tore konfigurieren

In `config.lua` jedes Tor mit geschlossener und geöffneter Position definieren:

```lua
{
    id = 'feuerwache_haupttor',
    label = 'Haupttor Feuerwache',
    model = `prop_ind_mech_01c`,
    closed = vec4(x, y, z, heading),
    open = vec4(x, y, z + 3.7, heading),  -- z.B. 3.7m nach oben
    moveAxis = 'z',
    speed = 0.85,
    warningLight = {
        model = `prop_warninglight_01`,
        offset = vec3(0.0, 0.0, 2.2),
        rot = vec3(0.0, 0.0, heading),
    },
    remoteRange = 35.0,
}
```

**Tipp:** Koordinaten ingame mit `/coords` oder einem Admin-Tool auslesen.

### Steuerung

| Aktion | Beschreibung |
|--------|--------------|
| ox_target am Tor | Öffnet die Steuerungs-UI |
| **Öffnen** | Tor fährt nach oben (oder in konfigurierte Richtung) |
| **Stopp** | Tor bleibt exakt an der aktuellen Position stehen |
| **Schließen** | Tor fährt zurück in geschlossene Position |
| `F6` | Fernbedienung (wenn Item vorhanden oder ohne ox_inventory) |
| `ESC` | UI schließen |

### Job-Beschränkung

In `config.lua` optional einschränken:

```lua
Config.AllowedJobs = {
    ambulance = 0,
    police = 0,
    fire = 0,
}
```

### Export für andere Scripts

```lua
exports['rd-fahrzeugtor']:openNearestGate()
exports['rd-fahrzeugtor']:useRemote()
```
