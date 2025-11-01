fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'
author 'Quantum Projects Community' 
description 'Quantum Beekeeping | Dev: Artmines'
quantum_discord 'https://discord.gg/kJ8ZrGM8TS'
use_experimental_fxv2_oal 'yes'
version '1.0.3'

shared_scripts {
    '@ox_lib/init.lua',
    '@rsg-core/shared/locale.lua',
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
}

client_scripts {
    'client/*.lua',
    'client/modules/*.lua'
}

dependencies {
    'rsg-core',
    'ox_lib',
    'PolyZone'
}

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/script.js',
    'html/imgs/*.png',
    'locales/*.json',
    'stream/bee_house_gk_ytyp.ytyp'   -- I RECOMMEND PLACING THIS IN ANOTHER FOLDER IF YOU RESTART SCRIPT YOU MAY CRASH DUE TO STREAMING
}
data_file 'DLC_ITYP_REQUEST' 'stream/bee_house_gk_ytyp.ytyp' -- I RECOMMEND PLACING THIS IN ANOTHER FOLDER IF YOU RESTART SCRIPT YOU MAY CRASH DUE TO STREAMING

lua54 'yes'
ui_page 'html/index.html'
