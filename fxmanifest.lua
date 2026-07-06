fx_version 'cerulean'
game 'gta5'
this_is_a_map 'yes'

author 'Drsnyder'
description 'Los Santos Freight Co. Trucker Job'
version '1.2.0'
repository 'https://github.com/DrSnyder86/ls_trucking'


lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua',
    'locales/*.lua',
    'shared/locale.lua',
    'config/service_bay.lua',
    'config/random_events.lua',
    'config/vehicles.lua',
    'config/route_trailers.lua',
    'config/items.lua',
    'config/contracts.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/compat.lua',
    'server/ids.lua',
    'server/framework.lua',
    'server/contractors.lua',
    'server/route_summary.lua',
    'server/depot_vehicles.lua',
    'server/cargo.lua',
    'server/routes.lua',
    'server/service_bay.lua',
    'server/admin.lua',
    'server/dispatch_data.lua',
    'server/job_blips.lua',
    'server/main.lua'
}

client_scripts {
    'client/compat.lua',
    'client/route_history.lua',
    'client/freight_handoff.lua',
    'client/receiver_vehicle_controls.lua',
    'client/spawn_utils.lua',
    'client/trailer_cargo_props.lua',
    'client/trailer_cargo_tester.lua',
    'client/trailer_cargo_editor.lua',
    'client/trailer_drop_marker.lua',
    'client/depot_vehicles.lua',
    'client/route_state.lua',
    'client/routes.lua',
    'client/contractor_ui.lua',
    'client/service_bay.lua',
    'client/job_blips.lua',
    'client/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/css/*.css',
    'html/vendor/fontawesome/css/*.css',
    'html/vendor/fontawesome/webfonts/*.woff2',
    'html/locales/*.js',
    'html/js/*.js',
    'html/service_bay.js',
    'html/sounds/*.wav',
    'images/.gitkeep',
    'images/*.png',
    'images/*.jpg',
    'images/*.jpeg',
    'images/*.webp',
    'images/**/*.png',
    'images/**/*.jpg',
    'images/**/*.jpeg',
    'images/**/*.webp',
    'inventory_images/*.png',
    'data/**/*.meta'
}

-- Optional custom vehicle metadata streaming
data_file 'HANDLING_FILE' 'data/**/handling.meta'
data_file 'VEHICLE_METADATA_FILE' 'data/**/vehicles.meta'
data_file 'CARCOLS_FILE' 'data/**/carcols.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/**/carvariations.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/**/vehiclelayouts.meta'
data_file 'DLCTEXT_FILE' 'data/**/dlctext.meta'
data_file 'CONTENT_UNLOCKING_META_FILE' 'data/**/contentunlocks.meta'
