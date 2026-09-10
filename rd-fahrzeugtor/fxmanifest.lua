fx_version 'cerulean'
game 'gta5'

name 'rd-fahrzeugtor'
description 'Realistisches Fahrzeugtor-System mit ox_target, UI-Steuerung, Fernbedienung, Sounds und Warnleuchte'
author 'RD-Szene'
version '1.2.1'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'config/presets/maavim_rettungswache.lua',
    'shared/*.lua',
}

client_scripts {
    'client/target.lua',
    'client/sounds.lua',
    'client/warning_light.lua',
    'client/mlo.lua',
    'client/main.lua',
    'client/autosetup.lua',
    'client/nui.lua',
    'client/remote.lua',
    'client/dev.lua',
    'client/setup_bind.lua',
}

server_scripts {
    'server/main.lua',
    'server/autosetup.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
}

dependencies {
    'ox_lib',
    'ox_target',
}
