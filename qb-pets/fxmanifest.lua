fx_version 'cerulean'
game 'gta5'

author 'ShaneeexD'
description 'Allows players to buy pets'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
}

dependencies {
    'qb-core',
    'qb-menu',
    'qb-input', 
    'qb-target', 
}

files {
    'audio/cat_purr.mp3',
    'audio/dog_excited.mp3',
    'audio/whistle.mp3',
    'html/index.html',
}

ui_page 'html/index.html'
