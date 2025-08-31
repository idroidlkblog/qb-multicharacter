fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kakarot'
description 'Allows players to create multiple characters'
version '1.2.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/auth.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@qb-apartments/config.lua',
    'server/main.lua',
    'server/auth.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/login.html',
    'html/style.css',
    'html/login-style.css',
    'html/reset.css',
    'html/vue.js',
    'html/swal2.js',
    'html/profanity.js',
    'html/translations.js',
    'html/validation.js',
    'html/app.js',
    'html/login-app.js'
}

dependencies {
    'qb-core',
    'qb-spawn',
    'fivem-bcrypt-async'
}
