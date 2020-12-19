game { 'gta5' }

fx_version 'adamant'
author 'AvarianKnight'
description 'VOIP built using FiveM\'s built in mumble.'

shared_script 'config.lua'

client_scripts {
	'client/main.lua',
    'client/module/*.lua',
}

server_scripts {
    'server/server.lua',
    'server/module/*.lua'
}

files {
    'ui/*.ogg',
    'ui/css/app.css',
    'ui/js/app.js',
    'ui/js/chunk-vendors.js',
    'ui/index.html',
}

ui_page 'ui/index.html'