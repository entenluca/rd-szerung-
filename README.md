# RD-Szene Scripts

FiveM-Skripte für Rettungsdienst-, Feuerwehr- und Polizei-RP.

## rd-fahrzeugtor

Realistisches Fahrzeugtor-System – speziell für **MLO-Garagentore** wie die [MaaviM Rettungswache MP](https://store.maavim-modding.com/product/rettungswache-mp).

### Features

- **MLO-Modus** – bewegt die echten Tore aus dem Mapping (kein Prop-Spawn)
- **ox_doorlock-Setup** – `/rd_tor_setup` zum Markieren von Panels und Koordinaten ingame
- **ox_target am Bedienfeld** – Wand-Box mit Animation, dann Steuerungs-UI (kein Auto-Öffnen)
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

### MaaviM Rettungswache MP einrichten (wie ox_doorlock)

1. `ensure MM_Rettungswache` **vor** `ensure rd-fahrzeugtor`
2. `Config.UseMaavimRettungswachePreset = true` (Standard)
3. Gehe ingame zur Rettungswache und nutze **`/rd_tor_setup`**
4. Wähle **Tor 1 / 2 / 3** → **Panel-Auswahl starten**
5. Schau auf ein **Tor-Panel** und drücke **E** (markiert alle gestapelten Panels)
6. Schau auf das **Wand-Bedienfeld** (Box mit Tasten) und drücke **P**
7. Drücke **H** für die Hubhöhe (Standard: 4,2 m)
8. **ENTER** zum Speichern → Konfiguration landet in `data/gates.json`

Danach: Zum Bedienfeld laufen → **ox_target** „Bedienfeld benutzen“ → Animation → UI zum Öffnen/Schließen.

Die gespeicherten Koordinaten werden beim Serverstart und für alle Spieler automatisch geladen.

**Schnell-Bindung** (Alternative): `/rd_tor_bind 1` – schau auf ein Panel, bindet und speichert direkt.

**Bewegung testen**: `/rd_tor_test` – prüft ob das angeschaute Objekt bewegt werden kann.

**MLO woanders platziert?** Einmal `/rd_tor_setup` nutzen – keine Config-Datei anpassen nötig.

### Setup- & Scanner-Befehle

| Befehl | Beschreibung |
|--------|--------------|
| `/rd_tor_setup` | Tor-Editor wie ox_doorlock (Panels + Koordinaten) |
| `/rd_tor_bind [1-3]` | Schnell-Bindung eines Tores |
| `/rd_tor_test` | Bewegungstest für angeschautes Objekt |
| `/rd_tor_scan [radius]` | Listet nahe Objekte mit Modell-Hash in F8 |
| `/rd_tor_copy` | Gibt aktuelle Position als `vec4` aus |
| `/rd_tor_status` | Zeigt Bindungsstatus aller Tore in F8 |

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
