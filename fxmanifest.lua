fx_version 'adamant'

games {
	'gta5'
}

author 'GIMI, foregz, Albo1125'
version '2.0.2'
description 'Fire Script'

client_scripts {
	"config.lua",
	"client/utils.lua",
	"client/fire.lua",
	"client/dispatch.lua",
	"client/main.lua",
}

server_scripts {
	"config.lua",
	"server/utils.lua",
	"server/whitelist.lua",
	"server/fire.lua",
	"server/dispatch.lua",
	"server/main.lua",
}

files {
	'data/firescript_alarm.dat54.rel',
	'toneaudio/firescript_alarm.awc',
}

data_file 'AUDIO_WAVEPACK' 'toneaudio'
data_file 'AUDIO_SOUNDDATA' 'data/firescript_alarm.dat'
