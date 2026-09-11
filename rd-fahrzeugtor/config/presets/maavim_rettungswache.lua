if not Config.UseMaavimRettungswachePreset then
    return
end

--[[
    MaaviM – Rettungswache MP
    https://store.maavim-modding.com/product/rettungswache-mp

    Koordinaten sind Näherungswerte (Postal 7324).
    Steh vor jedem Tor und nutze /rd_tor_find um model + coords zu prüfen.
]]

Config.Gates = {
    {
        name = 'Tor 1 – Rettungswache',
        coords = vector3(1044.0, -790.47, 31.5),
        distance = 2.5,
    },
    {
        name = 'Tor 2 – Rettungswache',
        coords = vector3(1048.39, -790.47, 31.5),
        distance = 2.5,
    },
    {
        name = 'Tor 3 – Rettungswache',
        coords = vector3(1052.5, -790.47, 31.5),
        distance = 2.5,
    },
}
