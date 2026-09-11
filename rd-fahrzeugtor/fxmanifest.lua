fx_version 'cerulean'
game 'gta5'

name 'rd-fahrzeugtor'
description 'Steuert vorhandene MLO-Tore über das FiveM Door-System und ox_target'
author 'RD-Szene'
version '2.0.0'

lua54 'yes'

shared_scripts {
    'config.lua',
    'config/presets/maavim_rettungswache.lua',
}

client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'ox_target',
}
