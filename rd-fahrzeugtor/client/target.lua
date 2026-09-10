function RegisterGateTarget(gateId, entity)
    exports.ox_target:addLocalEntity(entity, {
        {
            name = ('rd_fahrzeugtor_%s'):format(gateId),
            icon = 'fa-solid fa-warehouse',
            label = 'Tor steuern',
            distance = 2.5,
            onSelect = function()
                OpenGateUI(gateId)
            end,
        },
    })
end
