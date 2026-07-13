LS_Trucking = LS_Trucking or {}

local Editor = {}
local editorTrailer = nil
local editorKey = nil
local editorProps = {}
local selectedIndex = 1
local nudgeStep = 0.05
local editorCamera = nil
local cameraState = {
    yaw = 0.0,
    distance = 10.0,
    height = 3.2,
    targetHeight = 1.0
}

local DEFAULT_PROP = {
    model = 'xm3_prop_xm3_box_wood03a',
    offset = { x = 0.0, y = 0.0, z = 0.85 },
    rotation = { x = 0.0, y = 0.0, z = 0.0 }
}

local function Notify(message, notifyType)
    if lib and lib.notify then
        lib.notify({
            title = 'LS Freight Trailer Editor',
            description = message,
            type = notifyType or 'inform'
        })
    else
        print(('[LS Freight Trailer Editor] %s'):format(message))
    end
end

local function TrailerCargoProps()
    return LS_Trucking and LS_Trucking.TrailerCargoProps or {}
end

local function LoadModel(modelName)
    if not modelName then return nil end

    local model = type(modelName) == 'number' and modelName or joaat(modelName)
    if not IsModelInCdimage(model) then
        Notify(('Model does not exist: %s'):format(tostring(modelName)), 'error')
        return nil
    end

    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(0)
    end

    if not HasModelLoaded(model) then
        Notify(('Timed out loading model: %s'):format(tostring(modelName)), 'error')
        return nil
    end

    return model
end

local function ReadVec3(value, fallback)
    fallback = fallback or { x = 0.0, y = 0.0, z = 0.0 }
    if not value then return { x = fallback.x, y = fallback.y, z = fallback.z } end

    local valueType = type(value)
    if valueType ~= 'table' and valueType ~= 'vector3' and valueType ~= 'vector4' then
        return { x = fallback.x, y = fallback.y, z = fallback.z }
    end

    return {
        x = tonumber(value.x) or tonumber(value[1]) or fallback.x,
        y = tonumber(value.y) or tonumber(value[2]) or fallback.y,
        z = tonumber(value.z) or tonumber(value[3]) or fallback.z
    }
end

local function CopyProp(prop)
    prop = type(prop) == 'table' and prop or DEFAULT_PROP
    return {
        model = prop.model or DEFAULT_PROP.model,
        offset = ReadVec3(prop.offset, DEFAULT_PROP.offset),
        rotation = ReadVec3(prop.rotation, DEFAULT_PROP.rotation)
    }
end

local function CopyProps(props)
    local copied = {}
    if type(props) == 'table' then
        for _, prop in ipairs(props) do
            copied[#copied + 1] = CopyProp(prop)
        end
    end

    if #copied == 0 then
        copied[1] = CopyProp(DEFAULT_PROP)
    end

    return copied
end

local function Round(value)
    return math.floor((tonumber(value) or 0.0) * 1000.0 + 0.5) / 1000.0
end

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function ApplyExtras(vehicle, extras)
    if not vehicle or vehicle == 0 or not extras then return end

    for extraKey, enabled in pairs(extras) do
        local extraId = tonumber(extraKey)
        if extraId and DoesExtraExist(vehicle, extraId) then
            SetVehicleExtra(vehicle, extraId, enabled and 0 or 1)
        end
    end
end

local function BuildState()
    local trailer = editorKey and Config.RouteTrailers and Config.RouteTrailers[editorKey] or nil
    local props = {}

    for index, prop in ipairs(editorProps) do
        props[#props + 1] = {
            index = index,
            model = prop.model,
            offset = {
                x = Round(prop.offset.x),
                y = Round(prop.offset.y),
                z = Round(prop.offset.z)
            },
            rotation = {
                x = Round(prop.rotation.x),
                y = Round(prop.rotation.y),
                z = Round(prop.rotation.z)
            }
        }
    end

    return {
        key = editorKey or 'unknown',
        label = trailer and trailer.label or 'Trailer',
        model = trailer and trailer.model or 'unknown',
        selectedIndex = selectedIndex,
        step = nudgeStep,
        camera = {
            yaw = Round(cameraState.yaw),
            distance = Round(cameraState.distance),
            height = Round(cameraState.height)
        },
        props = props
    }
end

local function SendState()
    SendNUIMessage({
        action = 'updateTrailerCargoEditor',
        state = BuildState()
    })
end

local function RebuildProps()
    local cargo = TrailerCargoProps()
    if cargo.AttachToTrailer and editorTrailer and DoesEntityExist(editorTrailer) then
        cargo.AttachToTrailer(editorTrailer, editorProps)
    end
end

local function UpdateEditorCamera()
    if not editorCamera or not editorTrailer or not DoesEntityExist(editorTrailer) then return end

    local target = GetEntityCoords(editorTrailer)
    local yaw = math.rad(cameraState.yaw)
    local distance = Clamp(cameraState.distance, 4.0, 22.0)
    local height = Clamp(cameraState.height, 0.8, 9.0)
    local targetHeight = Clamp(cameraState.targetHeight, 0.4, 3.5)
    local camX = target.x + math.cos(yaw) * distance
    local camY = target.y + math.sin(yaw) * distance
    local camZ = target.z + height

    SetCamCoord(editorCamera, camX, camY, camZ)
    PointCamAtCoord(editorCamera, target.x, target.y, target.z + targetHeight)
    SetFocusPosAndVel(target.x, target.y, target.z, 0.0, 0.0, 0.0)
end

local function StopEditorCamera()
    if editorCamera then
        RenderScriptCams(false, true, 250, true, false)
        DestroyCam(editorCamera, false)
        editorCamera = nil
    end

    ClearFocus()
end

local function StartEditorCamera()
    StopEditorCamera()
    if not editorTrailer or not DoesEntityExist(editorTrailer) then return end

    cameraState.yaw = GetEntityHeading(editorTrailer) + 135.0
    cameraState.distance = 10.0
    cameraState.height = 3.2
    cameraState.targetHeight = 1.0

    editorCamera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamFov(editorCamera, 48.0)
    UpdateEditorCamera()
    SetCamActive(editorCamera, true)
    RenderScriptCams(true, true, 250, true, false)
end

local function AdjustCamera(data)
    local control = data.control or data.cameraControl
    local trailerHeading = editorTrailer and DoesEntityExist(editorTrailer) and GetEntityHeading(editorTrailer) or 0.0

    if control == 'left' then
        cameraState.yaw = cameraState.yaw - 12.0
    elseif control == 'right' then
        cameraState.yaw = cameraState.yaw + 12.0
    elseif control == 'zoomIn' then
        cameraState.distance = Clamp(cameraState.distance - 0.75, 4.0, 22.0)
    elseif control == 'zoomOut' then
        cameraState.distance = Clamp(cameraState.distance + 0.75, 4.0, 22.0)
    elseif control == 'up' then
        cameraState.height = Clamp(cameraState.height + 0.35, 0.8, 9.0)
    elseif control == 'down' then
        cameraState.height = Clamp(cameraState.height - 0.35, 0.8, 9.0)
    elseif control == 'targetUp' then
        cameraState.targetHeight = Clamp(cameraState.targetHeight + 0.2, 0.4, 3.5)
    elseif control == 'targetDown' then
        cameraState.targetHeight = Clamp(cameraState.targetHeight - 0.2, 0.4, 3.5)
    elseif control == 'reset' then
        cameraState.yaw = trailerHeading + 135.0
        cameraState.distance = 10.0
        cameraState.height = 3.2
        cameraState.targetHeight = 1.0
    elseif control == 'presetFront' then
        cameraState.yaw = 180.0 - trailerHeading
        cameraState.distance = 9.0
        cameraState.height = 2.5
        cameraState.targetHeight = 1.0
    elseif control == 'presetBack' then
        cameraState.yaw = -trailerHeading
        cameraState.distance = 9.0
        cameraState.height = 2.5
        cameraState.targetHeight = 1.0
    elseif control == 'presetLeft' then
        cameraState.yaw = 270.0 - trailerHeading
        cameraState.distance = 9.0
        cameraState.height = 2.5
        cameraState.targetHeight = 1.0
    elseif control == 'presetRight' then
        cameraState.yaw = 90.0 - trailerHeading
        cameraState.distance = 9.0
        cameraState.height = 2.5
        cameraState.targetHeight = 1.0
    elseif control == 'presetTop' then
        cameraState.yaw = 90.0 - trailerHeading
        cameraState.distance = 4.2
        cameraState.height = 9.0
        cameraState.targetHeight = 0.6
    elseif control == 'drag' then
        local deltaX = tonumber(data.deltaX) or 0.0
        local deltaY = tonumber(data.deltaY) or 0.0
        cameraState.yaw = cameraState.yaw - (deltaX * 0.35)
        cameraState.height = Clamp(cameraState.height - (deltaY * 0.018), 0.8, 9.0)
    elseif control == 'wheel' then
        local deltaY = tonumber(data.deltaY) or 0.0
        if deltaY ~= 0.0 then
            local zoomStep = Clamp(math.abs(deltaY) / 120.0, 0.35, 1.25)
            cameraState.distance = Clamp(cameraState.distance + (deltaY > 0 and zoomStep or -zoomStep), 4.0, 22.0)
        end
    end

    UpdateEditorCamera()
end

local function DeletePreviewTrailer()
    StopEditorCamera()

    if editorTrailer and DoesEntityExist(editorTrailer) then
        local cargo = TrailerCargoProps()
        if cargo.CleanupForTrailer then
            cargo.CleanupForTrailer(editorTrailer)
        end

        SetEntityAsMissionEntity(editorTrailer, true, true)
        DeleteEntity(editorTrailer)
    end

    editorTrailer = nil
end

local function SpawnPreviewTrailer(trailer)
    local model = LoadModel(trailer.model)
    if not model then return nil end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local spawnX = coords.x + forward.x * 7.0
    local spawnY = coords.y + forward.y * 7.0
    local spawnZ = coords.z + 0.5
    local foundGround, groundZ = GetGroundZFor_3dCoord(spawnX, spawnY, spawnZ + 4.0, false)
    if foundGround then spawnZ = groundZ end

    local vehicle = CreateVehicle(model, spawnX, spawnY, spawnZ, GetEntityHeading(ped), true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleDirtLevel(vehicle, 0.0)

    if trailer.livery ~= nil then
        SetVehicleLivery(vehicle, trailer.livery)
    end

    ApplyExtras(vehicle, trailer.extras)
    SetModelAsNoLongerNeeded(model)

    return vehicle
end

local function FormatLuaVec(vec)
    return ('vector3(%.3f, %.3f, %.3f)'):format(Round(vec.x), Round(vec.y), Round(vec.z))
end

local function PrintConfig()
    local lines = {
        ('-- Paste this into Config.RouteTrailers.%s'):format(editorKey or 'trailer_key'),
        'cargoProps = {'
    }

    for _, prop in ipairs(editorProps) do
        lines[#lines + 1] = ('    { model = %q, offset = %s, rotation = %s },'):format(
            tostring(prop.model),
            FormatLuaVec(prop.offset),
            FormatLuaVec(prop.rotation)
        )
    end

    lines[#lines + 1] = '}'
    print(table.concat(lines, '\n'))
    TriggerEvent('chat:addMessage', {
        args = { 'LS Freight', 'Trailer cargoProps printed to F8 console.' }
    })
    Notify('cargoProps printed to F8 console.', 'success')
end

function Editor.Close(skipFocus)
    DeletePreviewTrailer()
    editorKey = nil
    editorProps = {}
    selectedIndex = 1

    SendNUIMessage({ action = 'hideTrailerCargoEditor' })
    if not skipFocus then
        SetNuiFocus(false, false)
    end
end

function Editor.Open(trailerKey)
    trailerKey = trailerKey or 'flatbed_crates'
    local trailer = Config.RouteTrailers and Config.RouteTrailers[trailerKey] or nil
    if not trailer then
        Notify(('Unknown RouteTrailers key: %s'):format(tostring(trailerKey)), 'error')
        return false
    end

    Editor.Close(true)

    editorTrailer = SpawnPreviewTrailer(trailer)
    if not editorTrailer then return false end

    editorKey = trailerKey
    editorProps = CopyProps(trailer.cargoProps)
    selectedIndex = 1
    RebuildProps()
    StartEditorCamera()

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showTrailerCargoEditor',
        state = BuildState()
    })

    Notify(('Editing cargo props for %s.'):format(trailer.label or trailerKey), 'success')
    return true
end

local function GetSelectedProp()
    if #editorProps == 0 then
        editorProps[1] = CopyProp(DEFAULT_PROP)
        selectedIndex = 1
    end

    if selectedIndex < 1 then selectedIndex = 1 end
    if selectedIndex > #editorProps then selectedIndex = #editorProps end
    return editorProps[selectedIndex]
end

local function Nudge(data)
    local prop = GetSelectedProp()
    local field = data.field == 'rotation' and 'rotation' or 'offset'
    local axis = data.axis or 'x'
    if axis == 'pitch' then axis = 'x' end
    if axis == 'roll' then axis = 'y' end
    if axis == 'yaw' then axis = 'z' end
    if axis ~= 'x' and axis ~= 'y' and axis ~= 'z' then return end

    local delta = tonumber(data.delta) or 0.0
    local step = tonumber(data.step) or nudgeStep
    prop[field][axis] = Round((prop[field][axis] or 0.0) + (delta * step))
end

local function SetValue(data)
    local prop = GetSelectedProp()
    local field = data.field == 'rotation' and 'rotation' or 'offset'
    local axis = data.axis or 'x'
    if axis == 'pitch' then axis = 'x' end
    if axis == 'roll' then axis = 'y' end
    if axis == 'yaw' then axis = 'z' end
    if axis ~= 'x' and axis ~= 'y' and axis ~= 'z' then return end

    prop[field][axis] = Round(tonumber(data.value) or prop[field][axis] or 0.0)
end

local function HandleAction(data)
    data = type(data) == 'table' and data or {}
    local action = data.action

    if action == 'close' then
        Editor.Close()
        return
    end

    if not editorTrailer or not DoesEntityExist(editorTrailer) then
        Notify('Open the trailer editor before changing cargo props.', 'error')
        return
    end

    if action == 'select' then
        selectedIndex = math.floor(tonumber(data.index) or selectedIndex)
        GetSelectedProp()
        SendState()
        return
    elseif action == 'step' then
        nudgeStep = math.max(0.001, tonumber(data.step) or nudgeStep)
        SendState()
        return
    elseif action == 'nudge' then
        Nudge(data)
        RebuildProps()
    elseif action == 'setValue' then
        SetValue(data)
        RebuildProps()
    elseif action == 'camera' then
        AdjustCamera(data)
    elseif action == 'setModel' then
        local prop = GetSelectedProp()
        prop.model = data.model or prop.model
        RebuildProps()
    elseif action == 'add' then
        editorProps[#editorProps + 1] = CopyProp(DEFAULT_PROP)
        selectedIndex = #editorProps
        RebuildProps()
    elseif action == 'duplicate' then
        editorProps[#editorProps + 1] = CopyProp(GetSelectedProp())
        selectedIndex = #editorProps
        RebuildProps()
    elseif action == 'delete' then
        if #editorProps > 1 then
            table.remove(editorProps, selectedIndex)
            selectedIndex = math.min(selectedIndex, #editorProps)
            RebuildProps()
        else
            Notify('At least one prop stays in the editor.', 'warning')
        end
    elseif action == 'print' then
        PrintConfig()
    end

    SendState()
end

RegisterNUICallback('trailerCargoEditorAction', function(data, cb)
    HandleAction(data)
    cb(true)
end)

RegisterNUICallback('trailerCargoEditorClose', function(_, cb)
    Editor.Close()
    cb(true)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Editor.Close(true)
end)

LS_Trucking.TrailerCargoEditor = Editor
