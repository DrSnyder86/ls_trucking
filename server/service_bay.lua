LS_Trucking = LS_Trucking or {}

local ServiceBay = {}
local registered = false

local function GetConfig()
    return Config.ServiceBay or {}
end

local function GetServiceBayCoords()
    local cfg = GetConfig()
    return cfg.coords or (Config.Depot and (Config.Depot.vehicleReturn or Config.Depot.terminal))
end

local function ClampHealth(value, fallback)
    value = tonumber(value)
    if not value then return fallback or 1000.0 end
    return math.max(0.0, math.min(1000.0, value))
end

local function NormalizeSource(source)
    source = tostring(source or ''):lower()
    if source == 'contractor' then return 'contractor' end
    return 'garage'
end

local function GetDiscountPercent(ctx, citizenid)
    local cfg = GetConfig().RepDiscount or {}
    if cfg.Enabled == false then return 0 end

    local points = 0
    local stats = ctx.GetTruckingStats and ctx.GetTruckingStats(citizenid) or nil
    if stats then points = points + (tonumber(stats.reputation) or 0) end

    if cfg.IncludeContractorRep ~= false and ctx.GetContractorProfile then
        local profile = ctx.GetContractorProfile(citizenid) or {}
        points = points + (tonumber(profile.contractor_rep) or 0)
    end

    local perPercent = math.max(1, tonumber(cfg.PointsPerPercent) or 12)
    local maxPercent = math.max(0, tonumber(cfg.MaxPercent) or 35)
    return math.min(maxPercent, math.floor(points / perPercent))
end

local function RateLimit(ctx, src, action)
    if not ctx.CheckRateLimit then return true end
    local cooldown = ctx.GetSecurityCooldown and ctx.GetSecurityCooldown('ServiceBay', 1500) or 1500
    local ok, remaining = ctx.CheckRateLimit(src, ('service_bay_%s'):format(action or 'default'), cooldown)
    if ok then return true end
    return false, ctx.RateLimitResponse and ctx.RateLimitResponse(remaining) or T('service.wait')
end

local function ValidateVehicle(ctx, src, vehicleData)
    vehicleData = vehicleData or {}
    local cfg = GetConfig()
    if cfg.Enabled == false then return false, T('service.disabled') end

    local access = ctx.GetUIAccess and ctx.GetUIAccess(src) or { allowed = true }
    if access and access.allowed == false then return false, access.message or T('service.no_access') end

    local coords = GetServiceBayCoords()
    if ctx.RequireServerNear then
        local near, message = ctx.RequireServerNear(src, coords, ctx.GetDistanceLimit and ctx.GetDistanceLimit('ServiceBay', 16.0) or 16.0, T('service.need_area'))
        if not near then return false, message or T('service.need_area') end
    end

    local citizenid = ctx.GetCitizenId and ctx.GetCitizenId(src) or nil
    if not citizenid or citizenid == '' then return false, T('service.character_unknown') end

    local source = NormalizeSource(vehicleData.source)
    local plate = ctx.NormalizePlateText and ctx.NormalizePlateText(vehicleData.plate) or tostring(vehicleData.plate or ''):upper():gsub('%s+', '')
    if plate == '' then return false, T('service.plate_unreadable') end

    if source == 'contractor' then
        local id = tonumber(vehicleData.id) or 0
        if id <= 0 then return false, T('service.contractor_record_missing') end
        local row = ctx.GetContractorVehicleById and ctx.GetContractorVehicleById(citizenid, id) or nil
        if not row then return false, T('service.contractor_not_owned') end
        local rowPlate = ctx.NormalizePlateText and ctx.NormalizePlateText(row.plate) or tostring(row.plate or ''):upper():gsub('%s+', '')
        if rowPlate ~= plate then return false, T('service.contractor_plate_mismatch') end
        return true, citizenid, source, row
    end

    local vehicleType = tostring(vehicleData.type or '')
    local vehicleIndex = tonumber(vehicleData.index) or 0
    if vehicleType == '' or vehicleIndex <= 0 then return false, T('service.garage_record_missing') end

    local row = ctx.EnsureGarageVehicle and ctx.EnsureGarageVehicle(citizenid, vehicleType, vehicleIndex) or nil
    if not row then return false, T('service.garage_unverified') end
    local rowPlate = ctx.NormalizePlateText and ctx.NormalizePlateText(row.plate) or tostring(row.plate or ''):upper():gsub('%s+', '')
    if rowPlate ~= plate then return false, T('service.garage_plate_mismatch') end
    return true, citizenid, source, row
end

local function PriceUpgrade(item)
    local prices = (GetConfig().Prices or {}).Upgrades or {}
    local key = tostring(item.key or '')
    local cfg = prices[key]
    local target = tonumber(item.target) or 1

    if item.remove == true or target <= 0 then
        if key == 'turbo' or key == 'tires' or type(cfg) == 'table' then return 0 end
        return nil
    end

    if key == 'turbo' then
        local stages = GetConfig().TurboStages
        if type(stages) == 'table' then
            for _, stage in ipairs(stages) do
                if math.floor(tonumber(stage.level) or 0) == math.floor(target) then
                    return math.max(0, math.floor(tonumber(stage.price) or 0))
                end
            end
            return nil
        end

        if target > 1 then return nil end
        return math.max(0, tonumber(prices.turbo) or 0)
    end
    if key == 'tires' then return math.max(0, tonumber(prices.tires) or 0) end

    if type(cfg) ~= 'table' then return nil end
    target = math.max(1, math.min(5, target))
    return math.max(0, math.floor((tonumber(cfg.base) or 0) + ((target - 1) * (tonumber(cfg.step) or 0))))
end

local function PriceService(item)
    local prices = (GetConfig().Prices or {}).Service or {}
    local key = tostring(item.key or '')
    if key ~= 'drivetrain' and key ~= 'body' and key ~= 'full' then return nil end
    return math.max(0, tonumber(prices[key]) or 0)
end

local function PriceAppearance(item)
    local prices = (GetConfig().Prices or {}).Appearance or {}
    local key = tostring(item.key or '')
    if key == 'livery' then return math.max(0, tonumber(prices.livery) or 0) end
    if key == 'extra' then return math.max(0, tonumber(prices.extra) or 0) end
    return nil
end

local function CalculateInvoice(cart, discountPercent)
    if type(cart) ~= 'table' then return nil, T('service.no_work_order') end
    if #cart <= 0 then return nil, T('service.select_item') end
    if #cart > 30 then return nil, T('service.too_many_items') end

    local subtotal = 0
    local count = 0
    local serviceKeys = {}

    for _, item in ipairs(cart) do
        if type(item) ~= 'table' then return nil, T('service.invalid_item') end
        local kind = tostring(item.kind or '')
        local price

        if kind == 'service' then
            price = PriceService(item)
            serviceKeys[tostring(item.key or '')] = true
        elseif kind == 'upgrade' then
            price = PriceUpgrade(item)
        elseif kind == 'appearance' then
            price = PriceAppearance(item)
        else
            return nil, T('service.invalid_item_type')
        end

        if price == nil then return nil, T('service.invalid_item_selected') end
        subtotal = subtotal + price
        count = count + 1
    end

    if serviceKeys.full then
        local servicePrices = (GetConfig().Prices or {}).Service or {}
        if serviceKeys.drivetrain then subtotal = subtotal - math.max(0, tonumber(servicePrices.drivetrain) or 0) end
        if serviceKeys.body then subtotal = subtotal - math.max(0, tonumber(servicePrices.body) or 0) end
    end

    subtotal = math.max(0, math.floor(subtotal))
    discountPercent = math.max(0, math.min(90, tonumber(discountPercent) or 0))
    local discount = math.floor(subtotal * (discountPercent / 100.0))
    local total = math.max(0, subtotal - discount)

    return {
        itemCount = count,
        subtotal = subtotal,
        discountPercent = discountPercent,
        discount = discount,
        total = total
    }
end

function ServiceBay.RegisterServer(ctx)
    if registered then return end
    registered = true
    ctx = ctx or {}

    lib.callback.register('ls_trucking:server:getServiceBayAccess', function(src, vehicleData)
        local ok, rateMessage = RateLimit(ctx, src, 'access')
        if not ok then return { success = false, message = rateMessage } end

        local valid, citizenid, sourceOrMessage = ValidateVehicle(ctx, src, vehicleData)
        if not valid then return { success = false, message = citizenid or sourceOrMessage or 'Service bay access denied.' } end

        return {
            success = true,
            discountPercent = GetDiscountPercent(ctx, citizenid),
            paymentLabel = Config.PayToBank and 'Bank Account' or 'Cash Account',
            paymentMethod = Config.PayToBank and 'bank' or 'cash'
        }
    end)

    lib.callback.register('ls_trucking:server:purchaseServiceBayCart', function(src, data)
        local ok, rateMessage = RateLimit(ctx, src, 'purchase')
        if not ok then return { success = false, message = rateMessage } end

        data = data or {}
        local valid, citizenid, sourceOrMessage = ValidateVehicle(ctx, src, data.vehicle)
        if not valid then return { success = false, message = citizenid or sourceOrMessage or 'Service bay access denied.' } end

        local discountPercent = GetDiscountPercent(ctx, citizenid)
        local invoice, invoiceError = CalculateInvoice(data.cart, discountPercent)
        if not invoice then return { success = false, message = invoiceError or 'Invalid service bay invoice.' } end

        local paymentMethod = tostring(data.paymentMethod or ''):lower()
        if paymentMethod ~= 'cash' and paymentMethod ~= 'bank' then paymentMethod = nil end

        if invoice.total > 0 and (not ctx.RemoveMoney or not ctx.RemoveMoney(src, invoice.total, 'ls-trucking-service-bay', paymentMethod)) then
            return { success = false, message = ('Service bay invoice requires $%s.'):format(invoice.total) }
        end

        return { success = true, invoice = invoice, paymentMethod = paymentMethod or (Config.PayToBank and 'bank' or 'cash'), message = ('Service bay invoice paid: $%s.'):format(invoice.total) }
    end)

    lib.callback.register('ls_trucking:server:saveServiceBayVehicle', function(src, data)
        local ok, rateMessage = RateLimit(ctx, src, 'save')
        if not ok then return { success = false, message = rateMessage } end

        data = data or {}
        local valid, citizenid, source, row = ValidateVehicle(ctx, src, data.vehicle)
        if not valid then return { success = false, message = citizenid or source or 'Service bay access denied.' } end

        local props, propsError = ctx.SanitizeVehicleProps and ctx.SanitizeVehicleProps(data.props) or nil, nil
        if ctx.SanitizeVehicleProps then
            props, propsError = ctx.SanitizeVehicleProps(data.props)
        end
        if propsError then return { success = false, message = propsError } end

        local plate = tostring((data.vehicle or {}).plate or (row and row.plate) or '')
        if source == 'contractor' then
            local fuel = math.max(0.0, math.min(100.0, tonumber(data.fuel) or tonumber(row.fuel) or 100.0))
            local engineHealth = ClampHealth(data.engineHealth, tonumber(row.engine_health) or 1000.0)
            local bodyHealth = ClampHealth(data.bodyHealth, tonumber(row.body_health) or 1000.0)
            local mileage = math.max(0.0, tonumber(data.mileage) or tonumber(row.mileage) or 0.0)

            MySQL.update.await([[UPDATE trucking_contractor_vehicles SET plate = ?, props = ?, fuel = ?, engine_health = ?, body_health = ?, mileage = ? WHERE citizenid = ? AND id = ?]], {
                plate,
                props,
                fuel,
                engineHealth,
                bodyHealth,
                mileage,
                citizenid,
                row.id
            })
        else
            MySQL.update.await([[UPDATE trucking_garage SET plate = ?, props = ? WHERE citizenid = ? AND vehicle_type = ? AND vehicle_index = ?]], {
                plate,
                props,
                citizenid,
                tostring((data.vehicle or {}).type or row.vehicle_type or ''),
                tonumber((data.vehicle or {}).index) or tonumber(row.vehicle_index) or 1
            })
        end

        return { success = true, message = T('service.work_order_saved') }
    end)
end

LS_Trucking.ServiceBay = ServiceBay
