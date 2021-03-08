game {'gta5'}

fx_version 'cerulean'
author 'AvarianKnight'
description 'VOIP built using FiveM\'s built in mumble.'

lua54 'yes'

shared_script 'shared.lua'

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
    'ui/css/*.css',
    'ui/js/*.js',
    'ui/index.html',
}

ui_page 'ui/index.html'

provides {
	'mumble-voip'
}
