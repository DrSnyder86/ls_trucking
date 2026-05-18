-- add this table to the jobitems section in qbx_radialmenu/config/client.lua
trucker = {
            {
                id = 'ls_trucking_dispatch',
                label = 'Freight Dispatch',
                icon = 'truck-fast',
                onSelect = function()
                    TriggerEvent('ls_trucking:client:openDispatch')
                end
            },
            {
                id = 'ls_trucking_miniui',
                label = 'Toggle Trucking UI',
                icon = 'tablet-screen-button',
                onSelect = function()
                    TriggerEvent('ls_trucking:client:toggleMiniUI')
                end
            },
        },
