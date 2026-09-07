LS_Trucking = LS_Trucking or {}

local CompanyGarage = {}
local serverContext = {}
local VehicleTypeOrder = { 'van', 'boxtruck', 'trailer' }

local function Trim(value)
    return tostring(value or ''):match('^%s*(.-)%s*$') or ''
end

local function NormalizeIdPart(value)
    return Trim(value):lower():gsub('[^%w_-]+', '_'):gsub('_+', '_'):gsub('^_+', ''):gsub('_+$', '')
end

local function VehicleModel(vehicleData)
    vehicleData = vehicleData or {}
    return tostring(vehicleData.model or vehicleData.truck or '')
end

function CompanyGarage.ResolveVehicleId(vehicleType, vehicleData, vehicleIndex)
    vehicleData = vehicleData or {}
    local configured = NormalizeIdPart(vehicleData.garageId)
    if configured ~= '' then return configured:sub(1, 96) end

    local typePart = NormalizeIdPart(vehicleType)
    local modelPart = NormalizeIdPart(VehicleModel(vehicleData))
    if modelPart == '' then modelPart = ('slot_%s'):format(tonumber(vehicleIndex) or 1) end
    return ('company_%s_%s'):format(typePart, modelPart):sub(1, 96)
end

function CompanyGarage.ValidateConfig()
    local seen = {}

    for _, vehicleType in ipairs(VehicleTypeOrder) do
        for vehicleIndex, vehicleData in ipairs((Config.JobVehicles or {})[vehicleType] or {}) do
            local garageId = CompanyGarage.ResolveVehicleId(vehicleType, vehicleData, vehicleIndex)
            if seen[garageId] then
                return false, ('Duplicate company garageId "%s" is used by %s and %s.'):format(
                    garageId,
                    seen[garageId],
                    ('%s[%s]'):format(vehicleType, vehicleIndex)
                )
            end
            seen[garageId] = ('%s[%s]'):format(vehicleType, vehicleIndex)
        end
    end

    return true
end

function CompanyGarage.ConfigureServer(context)
    serverContext = context or {}
end

local function RowGarageId(row)
    return NormalizeIdPart(row and row.garage_id)
end

local function SameModel(row, model)
    return Trim(row and row.vehicle_model):lower() == Trim(model):lower()
end

local function UpdateAssignment(row, garageId, vehicleType, vehicleIndex, vehicleData)
    local model = VehicleModel(vehicleData)
    local label = tostring(vehicleData.label or model or 'Company Vehicle')
    local changed = RowGarageId(row) ~= garageId
        or tostring(row.vehicle_type or '') ~= tostring(vehicleType or '')
        or tonumber(row.vehicle_index) ~= tonumber(vehicleIndex)
        or tostring(row.vehicle_label or '') ~= label
        or tostring(row.vehicle_model or '') ~= model

    if changed then
        MySQL.update.await([[
            UPDATE trucking_garage
            SET garage_id = ?, vehicle_type = ?, vehicle_index = ?, vehicle_label = ?, vehicle_model = ?
            WHERE id = ?
        ]], { garageId, vehicleType, vehicleIndex, label, model, row.id })

        row.garage_id = garageId
        row.vehicle_type = vehicleType
        row.vehicle_index = vehicleIndex
        row.vehicle_label = label
        row.vehicle_model = model
    end

    return row
end

local function FindLegacyRow(rows, claimed, vehicleType, vehicleIndex, model)
    for _, row in ipairs(rows) do
        if not claimed[row.id]
            and RowGarageId(row) == ''
            and tostring(row.vehicle_type or '') == tostring(vehicleType or '')
            and tonumber(row.vehicle_index) == tonumber(vehicleIndex)
            and SameModel(row, model)
        then
            return row
        end
    end

    for _, row in ipairs(rows) do
        if not claimed[row.id]
            and RowGarageId(row) == ''
            and tostring(row.vehicle_type or '') == tostring(vehicleType or '')
            and SameModel(row, model)
        then
            return row
        end
    end

    return nil
end

function CompanyGarage.GetFleetAssignments(citizenid)
    local rows = MySQL.query.await('SELECT * FROM trucking_garage WHERE citizenid = ?', { citizenid }) or {}
    local assignments = {}
    local claimed = {}

    for _, row in ipairs(rows) do
        local garageId = RowGarageId(row)
        if garageId ~= '' and not assignments[garageId] then
            assignments[garageId] = row
            claimed[row.id] = true
        end
    end

    for _, vehicleType in ipairs(VehicleTypeOrder) do
        for vehicleIndex, vehicleData in ipairs((Config.JobVehicles or {})[vehicleType] or {}) do
            local garageId = CompanyGarage.ResolveVehicleId(vehicleType, vehicleData, vehicleIndex)
            local row = assignments[garageId]

            if not row then
                row = FindLegacyRow(rows, claimed, vehicleType, vehicleIndex, VehicleModel(vehicleData))
                if row then
                    claimed[row.id] = true
                    assignments[garageId] = row
                end
            end

            if row then
                UpdateAssignment(row, garageId, vehicleType, vehicleIndex, vehicleData)
            end
        end
    end

    return assignments
end

local function RepairPlate(row, vehicleData)
    if not row then return nil end

    local canonical = serverContext.CanonicalPlateText
        and serverContext.CanonicalPlateText(row.plate)
        or Trim(row.plate):upper():gsub('%s+', ''):sub(1, 8)
    local hasConflict = serverContext.StoredVehiclePlateConflict
        and serverContext.StoredVehiclePlateConflict(canonical, row.id, 0)
        or false

    if canonical ~= '' and canonical == tostring(row.plate or '') and not hasConflict then
        return row
    end

    local repairedPlate = canonical
    if repairedPlate == '' or hasConflict then
        repairedPlate = serverContext.GenerateUniqueVehiclePlate(vehicleData.platePrefix)
    end

    local repairedProps = row.props
    if serverContext.SanitizeVehicleProps then
        local sanitized, propsError = serverContext.SanitizeVehicleProps(row.props, repairedPlate)
        if not propsError then repairedProps = sanitized end
    end

    MySQL.update.await('UPDATE trucking_garage SET plate = ?, props = ? WHERE id = ?', {
        repairedPlate,
        repairedProps,
        row.id
    })
    row.plate = repairedPlate
    row.props = repairedProps
    return row
end

function CompanyGarage.EnsureVehicle(citizenid, vehicleType, vehicleIndex)
    vehicleIndex = tonumber(vehicleIndex) or 1
    local vehicleData = (Config.JobVehicles or {})[vehicleType]
        and Config.JobVehicles[vehicleType][vehicleIndex]
        or nil
    if not vehicleData then return nil end

    local garageId = CompanyGarage.ResolveVehicleId(vehicleType, vehicleData, vehicleIndex)
    local row = CompanyGarage.GetFleetAssignments(citizenid)[garageId]

    if not row then
        local model = serverContext.GetGarageVehicleModel
            and serverContext.GetGarageVehicleModel(vehicleType, vehicleData)
            or VehicleModel(vehicleData)
        local plate = serverContext.GenerateUniqueVehiclePlate(vehicleData.platePrefix)

        MySQL.insert.await([[
            INSERT IGNORE INTO trucking_garage
                (citizenid, garage_id, vehicle_type, vehicle_index, vehicle_label, vehicle_model, plate, props, stored)
            VALUES (?, ?, ?, ?, ?, ?, ?, NULL, 1)
        ]], { citizenid, garageId, vehicleType, vehicleIndex, vehicleData.label, model, plate })

        row = MySQL.single.await('SELECT * FROM trucking_garage WHERE citizenid = ? AND garage_id = ?', {
            citizenid,
            garageId
        })
    end

    if not row then return nil end
    UpdateAssignment(row, garageId, vehicleType, vehicleIndex, vehicleData)
    return RepairPlate(row, vehicleData)
end

function CompanyGarage.TryCheckout(citizenid, rowId)
    local changed = MySQL.update.await(
        'UPDATE trucking_garage SET stored = 0 WHERE citizenid = ? AND id = ? AND stored = 1',
        { citizenid, tonumber(rowId) or 0 }
    ) or 0
    return changed > 0
end

function CompanyGarage.SetStored(citizenid, garageId, stored)
    garageId = NormalizeIdPart(garageId)
    if garageId == '' then return 0 end
    return MySQL.update.await(
        'UPDATE trucking_garage SET stored = ? WHERE citizenid = ? AND garage_id = ?',
        { stored == false and 0 or 1, citizenid, garageId }
    ) or 0
end

function CompanyGarage.RestoreAll(citizenid)
    return MySQL.update.await('UPDATE trucking_garage SET stored = 1 WHERE citizenid = ? AND stored = 0', {
        citizenid
    }) or 0
end

LS_Trucking.CompanyGarage = CompanyGarage
