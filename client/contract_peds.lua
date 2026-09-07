LS_Trucking = LS_Trucking or {}

local ContractPeds = {}
local workers = {}
local retired = {}
local sweeping = false

local function DeleteWorker(ped)
    LS_Trucking.FreightHandoff.ClearPed(ped)
    if DoesEntityExist(ped) then DeleteEntity(ped) end
    workers[ped], retired[ped] = nil, nil
end

local function Sweep()
    if sweeping then return end
    sweeping = true
    CreateThread(function()
        while next(retired) do
            local coords = GetEntityCoords(PlayerPedId())
            local distance = math.max(50.0, tonumber((Config.ActiveContractPeds or {}).DespawnDistance) or 130.0)
            for ped in pairs(retired) do
                if not DoesEntityExist(ped)
                    or (#(GetEntityCoords(ped) - coords) >= distance and not IsEntityOnScreen(ped)) then
                    DeleteWorker(ped)
                end
            end
            Wait(2000)
        end
        sweeping = false
    end)
end

function ContractPeds.Track(ped, key, data)
    workers[ped] = { key = key, data = data }
end

function ContractPeds.Reclaim(key, data)
    for ped, worker in pairs(retired) do
        if worker.key == key and worker.data.model == data.model and DoesEntityExist(ped)
            and #(GetEntityCoords(ped) - vector3(data.coords.x, data.coords.y, data.coords.z)) <= 20.0 then
            retired[ped] = nil
            LS_Trucking.FreightHandoff.ClearPed(ped)
            ClearPedTasks(ped)
            FreezeEntityPosition(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            if data.scenario then TaskStartScenarioInPlace(ped, data.scenario, 0, true) end
            workers[ped].data = data
            return ped
        end
    end
end

function ContractPeds.Retire(ped)
    local worker = workers[ped]
    if not worker or retired[ped] then return end
    LS_Trucking.FreightHandoff.ClearPed(ped)
    if not DoesEntityExist(ped) then workers[ped] = nil return end
    retired[ped] = worker
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    SetBlockingOfNonTemporaryEvents(ped, true)
    if worker.data.scenario and worker.data.scenario ~= '' then
        TaskStartScenarioInPlace(ped, worker.data.scenario, 0, true)
    else
        local coords = GetEntityCoords(ped)
        TaskWanderInArea(ped, coords.x, coords.y, coords.z, 8.0, 2.0, 5.0)
    end
    SetPedKeepTask(ped, true)
    Sweep()
end

function ContractPeds.Delete(ped)
    DeleteWorker(ped)
end

function ContractPeds.ClearRetired()
    for ped in pairs(retired) do DeleteWorker(ped) end
end

function ContractPeds.ShouldSpawnPickup(contract)
    return not contract.cargoReady and not contract.loaded and not contract.verifiedCargo
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for ped in pairs(workers) do DeleteWorker(ped) end
end)

LS_Trucking.ContractPeds = ContractPeds
