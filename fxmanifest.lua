fx_version 'cerulean'
game 'gta5'

author 'Drsnyder'
name 'ls_trucking'
description 'Los Santos Freight Trucking for QB/Qbox'
version '1.0.0'
repository 'https://github.com/DrSnyder86/ls_trucking'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua',
    'config/contracts.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/sounds/*.wav',
    -- 'images/.gitkeep',
    -- 'images/*.png',
    -- 'images/*.jpg',
    -- 'images/*.jpeg',
    -- 'images/*.webp',
    -- 'inventory_images/*.png'
}
