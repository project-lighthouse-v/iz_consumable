fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'iz_consumable'
description 'Persistent consumable items for ox_inventory'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua'
}

server_scripts {
    'server/server.lua'
}

client_scripts {
    'client/client.lua'
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'qbx_core',
    'qbx_smallresources'
}