fx_version 'cerulean'
game 'gta5'

name 'rd-fahrzeugtor'
description 'Realistisches Fahrzeugtor-System mit ox_target, UI-Steuerung, Fernbedienung, Sounds und Warnleuchte'
author 'RD-Szene'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/*.lua',
}

client_scripts {
    'client/target.lua',
    'client/sounds.lua',
    'client/warning_light.lua',
    'client/main.lua',
    'client/nui.lua',
    'client/remote.lua',
}

server_scripts {
    'server/*.lua',
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
