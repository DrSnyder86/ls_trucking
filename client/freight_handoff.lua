LS_Trucking = LS_Trucking or {}

local FreightHandoff = {}
local pedGreetingTimes = {}
local nativeRadioAudioToken = 0
local lastNativeRadioAudioAt = 0

local function IsDrivingAssignedVehicle(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return false end

    local ped = PlayerPedId()
    if not IsPedInVehicle(ped, vehicle, false) then return false end

    local audio = Config.RadioMessageAudio or {}
    return audio.DriverOnly == false or GetPedInVehicleSeat(vehicle, -1) == ped
end

function FreightHandoff.PlayNativeRadioMessageAudio(vehicle)
    local audio = Config.RadioMessageAudio or {}
    if audio.Enabled == false or audio.NativeInJobVehicle == false or not IsDrivingAssignedVehicle(vehicle) then return false end

    local now = GetGameTimer()
    if now - lastNativeRadioAudioAt < math.max(0, tonumber(audio.Cooldown) or 225) then return true end
    lastNativeRadioAudioAt = now

    nativeRadioAudioToken = nativeRadioAudioToken + 1
    local token = nativeRadioAudioToken
    local soundSet = audio.SoundSet or 'CB_RADIO_SFX'
    PlaySoundFrontend(-1, audio.StartSound or 'Start_Squelch', soundSet, true)

    SetTimeout(math.max(150, tonumber(audio.EndDelay) or 575), function()
        if token ~= nativeRadioAudioToken then return end
        PlaySoundFrontend(-1, audio.EndSound or 'End_Squelch', soundSet, true)
    end)

    return true
end

function FreightHandoff.PlayPedGreeting(ped, scenario)
    local handoff = Config.FreightHandoff or {}
    if handoff.Enabled == false or handoff.PedGreeting == false or not ped or not DoesEntityExist(ped) then return end

    local now = GetGameTimer()
    local cooldown = math.max(1000, tonumber(handoff.GreetingCooldown) or 15000)
    if now - (pedGreetingTimes[ped] or 0) < cooldown then return end
    pedGreetingTimes[ped] = now

    TaskTurnPedToFaceEntity(ped, PlayerPedId(), 750)

    local speeches = handoff.GreetingSpeech
    if type(speeches) ~= 'table' or #speeches == 0 then speeches = { 'GENERIC_HI' } end
    local speech = speeches[math.random(1, #speeches)] or 'GENERIC_HI'
    local speechParams = handoff.SpeechParams or 'SPEECH_PARAMS_FORCE_NORMAL_CLEAR'

    if PlayPedAmbientSpeechNative then
        pcall(PlayPedAmbientSpeechNative, ped, speech, speechParams)
    elseif PlayAmbientSpeech1 then
        pcall(PlayAmbientSpeech1, ped, speech, speechParams)
    end

    if scenario and scenario ~= '' then
        SetTimeout(2200, function()
            if DoesEntityExist(ped) then TaskStartScenarioInPlace(ped, scenario, 0, true) end
        end)
    end
end

function FreightHandoff.ClearPed(ped)
    if ped then pedGreetingTimes[ped] = nil end
end

function FreightHandoff.BuildManifest(activeContract, mode, pedLabel)
    if not activeContract then return nil end

    local trailer = mode == 'trailer'
    local loadLabel = trailer
        and (activeContract.trailerContents or activeContract.trailerLabel or 'Assigned Trailer Freight')
        or (activeContract.cargoLabel or activeContract.cargo or 'Delivery Cargo')
    local quantityLabel = trailer
        and ('1 x %s'):format(activeContract.trailerLabel or 'Assigned Trailer')
        or ('%s route item(s)'):format(activeContract.requiredCargo or 0)
    local vehicleLabel = activeContract.vehicleLabel or 'Assigned Vehicle'

    if trailer and activeContract.trailerLabel then
        vehicleLabel = ('%s / %s'):format(vehicleLabel, activeContract.trailerLabel)
    end

    return {
        contractId = activeContract.contractId,
        routeLabel = activeContract.routeLabel or activeContract.label,
        loadLabel = loadLabel,
        quantityLabel = quantityLabel,
        vehicleLabel = vehicleLabel,
        plate = activeContract.plate,
        locationLabel = pedLabel or (trailer and activeContract.trailerDrop and activeContract.trailerDrop.label) or (activeContract.pickup and activeContract.pickup.label)
    }
end

LS_Trucking.FreightHandoff = FreightHandoff
