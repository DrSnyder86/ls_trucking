-- Qbox / ox_lib radial menu examples
-- Place this in a client file or adapt the entries into your qbx radial setup.
-- This format uses ox_lib radial item keys: id/label/icon/onSelect.

lib.addRadialItem({
    {
        id = 'ls_trucking_dispatch',
        label = 'Dispatch',
        icon = 'truck-fast',
        onSelect = function()
            TriggerEvent('ls_trucking:client:openDispatch')
        end
    },
    {
        id = 'ls_trucking_receiver',
        label = 'Receiver',
        icon = 'walkie-talkie',
        onSelect = function()
            TriggerEvent('ls_trucking:client:toggleReceiver')
        end
    },
    {
        id = 'ls_trucking_dock',
        label = 'Dock',
        icon = 'window-restore',
        onSelect = function()
            TriggerEvent('ls_trucking:client:toggleDock')
        end
    },
    {
        id = 'ls_trucking_cancel',
        label = 'Cancel',
        icon = 'ban',
        onSelect = function()
            TriggerEvent('ls_trucking:client:cancelActiveContract')
        end
    }
})

-- Alternate qbx_radialmenu export style, if your server uses it:
-- exports.qbx_radialmenu:AddOption({
--     id = 'ls_trucking_dispatch',
--     label = 'Dispatch',
--     icon = 'truck-fast',
--     onSelect = function()
--         TriggerEvent('ls_trucking:client:openDispatch')
--     end
-- })
-- exports.qbx_radialmenu:AddOption({
--     id = 'ls_trucking_receiver',
--     label = 'Receiver',
--     icon = 'walkie-talkie',
--     onSelect = function()
--         TriggerEvent('ls_trucking:client:toggleReceiver')
--     end
-- })
-- exports.qbx_radialmenu:AddOption({
--     id = 'ls_trucking_dock',
--     label = 'Dock',
--     icon = 'window-restore',
--     onSelect = function()
--         TriggerEvent('ls_trucking:client:toggleDock')
--     end
-- })
-- exports.qbx_radialmenu:AddOption({
--     id = 'ls_trucking_cancel',
--     label = 'Cancel',
--     icon = 'ban',
--     onSelect = function()
--         TriggerEvent('ls_trucking:client:cancelActiveContract')
--     end
-- })
