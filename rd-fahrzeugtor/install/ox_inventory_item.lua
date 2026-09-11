-- In ox_inventory/data/items.lua einfügen:

['tor_fernbedienung'] = {
    label = 'Tor-Fernbedienung',
    weight = 150,
    stack = false,
    close = true,
    description = 'Fernbedienung für Fahrzeugtore – öffnet die Steuerung für das nächste Tor in Reichweite.',
    client = {
        export = 'rd-fahrzeugtor.openNearestGate',
    },
},
