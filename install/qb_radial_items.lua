-- QB-RadialMenu examples
-- Add these entries to qb-radialmenu/config.lua under Config.MenuItems.
-- These use the standard QB radial item format: id/title/icon/type/event/shouldClose.

{
    id = 'ls_trucking_dispatch',
    title = 'Dispatch',
    icon = 'truck-fast',
    type = 'client',
    event = 'ls_trucking:client:openDispatch',
    shouldClose = true
},
{
    id = 'ls_trucking_receiver',
    title = 'Receiver',
    icon = 'walkie-talkie',
    type = 'client',
    event = 'ls_trucking:client:toggleReceiver',
    shouldClose = true
},
{
    id = 'ls_trucking_dock',
    title = 'Dock',
    icon = 'window-restore',
    type = 'client',
    event = 'ls_trucking:client:toggleDock',
    shouldClose = true
},
{
    id = 'ls_trucking_cancel',
    title = 'Cancel',
    icon = 'ban',
    type = 'client',
    event = 'ls_trucking:client:cancelActiveContract',
    shouldClose = true
}
