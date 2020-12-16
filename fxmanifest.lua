game { 'gta5' }

fx_version 'adamant'
author 'AvarianKnight'
description 'VOIP built using FiveM\'s built in mumble.'

files {
    'ui/*.ogg',
    'ui/index.html'
}

shared_script 'config.lua'

client_scripts {
	'client/main.lua',
    'client/module/*.lua',
}

server_scripts {
    'server/server.lua',
    'server/module/*.lua'
}

ui_page 'ui/index.html'