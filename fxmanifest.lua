fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'Sporny (Converted for RSGCore)'
description 'RSG-Stable - Horse Purchasing & Customization'
version '1.1.0'

dependencies {
    'rsg-core',
    'ox_lib'
}

shared_scripts {
    '@rsg-core/shared/locale.lua',
    'locale/en.lua',
    'config.lua'
}
client_scripts {
    'horse_comp.lua',
    'client/main.lua'
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}
ui_page 'html/index.html'
files {
    'html/*',
    'html/fonts/*',
    'html/img/*'
}

lua54 'yes'