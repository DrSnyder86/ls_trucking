-- Qbox / ox_lib radial menu examples
-- Place this in a client file or adapt the entries into your qbx radial setup.
-- This format uses ox_lib radial item keys: id/label/icon/onSelect.

lib.addRadialItem({
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
    }
})

-- Alternate qbx_radialmenu export style, if your server uses it:
-- exports.qbx_radialmenu:AddOption({
--     id = 'ls_trucking_dispatch',
--     label = 'Freight Dispatch',
--     icon = 'truck-fast',
--     onSelect = function()
--         TriggerEvent('ls_trucking:client:openDispatch')
--     end
-- })
