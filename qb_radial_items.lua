-- QB-RadialMenu examples
-- Add these entries to qb-radialmenu/config.lua under Config.MenuItems.
-- These use the standard QB radial item format: id/title/icon/type/event/shouldClose.

{
    id = 'ls_trucking_dispatch',
    title = 'Freight Dispatch',
    icon = 'truck-fast',
    type = 'client',
    event = 'ls_trucking:client:openDispatch',
    shouldClose = true
},
{
    id = 'ls_trucking_miniui',
    title = 'Toggle Trucking UI',
    icon = 'tablet-screen-button',
    type = 'client',
    event = 'ls_trucking:client:toggleMiniUI',
    shouldClose = true
}
