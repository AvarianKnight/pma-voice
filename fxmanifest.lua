game { 'gta5' }

fx_version 'adamant'
author 'AvarianKnight'
description 'VOIP built using FiveM\'s built in mumble.'
shared_script 'config.lua'

files {
    'ui/*.ogg',
    'ui/index.html'
}

shared_script 'config.lua'

client_scripts {
	'client/main.lua',
    'client/radio.lua',
    'client/phone.lua'
}

server_scripts {
	'server/server.lua'
}

ui_page 'ui/index.html'