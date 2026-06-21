LS_Trucking = LS_Trucking or {}

local Framework = {}
local detectedFramework = nil
local QBCore = nil
local ESX = nil
local NDCore = nil

local function ResourceStarted(resource)
    return GetResourceState(resource) == 'started'
end

local function SafeExport(resource, exportName, ...)
    if not ResourceStarted(resource) then return false, nil end

    local args = { ... }
    local ok, result = pcall(function()
        return exports[resource][exportName](exports[resource], table.unpack(args))
    end)
    if ok and result ~= nil then return true, result end
    local firstOk = ok

    ok, result = pcall(function()
        return exports[resource][exportName](table.unpack(args))
    end)
    if ok then return true, result end

    return firstOk, nil
end

local function CallMethod(target, names, ...)
    if not target then return false, nil end

    local args = { ... }
    for _, name in ipairs(names) do
        local fn = target[name]
        if type(fn) == 'function' then
            local ok, result = pcall(fn, target, table.unpack(args))
            if ok and result ~= nil then return true, result end
            local firstOk = ok

            ok, result = pcall(fn, table.unpack(args))
            if ok then return true, result end

            if firstOk then return true, nil end
        end
    end

    return false, nil
end

local function GetLicenseIdentifier(src)
    if GetPlayerIdentifierByType then
        local license = GetPlayerIdentifierByType(src, 'license')
        if license and license ~= '' then return license end
    end

    local count = GetNumPlayerIdentifiers(src) or 0
    for i = 0, count - 1 do
        local identifier = GetPlayerIdentifier(src, i)
        if identifier and identifier:find('license:', 1, true) == 1 then return identifier end
    end

    return nil
end

local function DetectFramework()
    local configured = Config.Framework or 'auto'

    if configured == 'qb' or configured == 'qbox' or configured == 'esx' or configured == 'nd' or configured == 'nd_core' or configured == 'standalone' then
        return configured == 'nd_core' and 'nd' or configured
    end

    if ResourceStarted('qbx_core') then return 'qbox' end
    if ResourceStarted('qb-core') then return 'qb' end
    if ResourceStarted('es_extended') then return 'esx' end
    if ResourceStarted('ND_Core') then return 'nd' end

    return 'standalone'
end

function Framework.Init()
    detectedFramework = DetectFramework()

    if detectedFramework == 'qb' and ResourceStarted('qb-core') then
        local ok, core = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if ok then QBCore = core end
    elseif detectedFramework == 'esx' and ResourceStarted('es_extended') then
        local ok, core = SafeExport('es_extended', 'getSharedObject')
        if ok and core then
            ESX = core
        else
            pcall(function()
                TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            end)
        end
    elseif detectedFramework == 'nd' and ResourceStarted('ND_Core') then
        local ok, core = SafeExport('ND_Core', 'GetCoreObject')
        if ok and core then
            NDCore = core
        else
            ok, core = SafeExport('ND_Core', 'getCoreObject')
            if ok and core then NDCore = core end
        end
    end

    return detectedFramework
end

function Framework.GetName()
    if not detectedFramework then Framework.Init() end
    return detectedFramework or 'standalone'
end

function Framework.IsStandalone()
    return Framework.GetName() == 'standalone' or Config.Framework == 'standalone'
end

function Framework.GetPlayer(src)
    local framework = Framework.GetName()

    if framework == 'qb' and QBCore and QBCore.Functions and QBCore.Functions.GetPlayer then
        return QBCore.Functions.GetPlayer(src)
    end

    if framework == 'qbox' then
        local ok, player = SafeExport('qbx_core', 'GetPlayer', src)
        if ok and player then return player end
    end

    if framework == 'esx' and ESX and ESX.GetPlayerFromId then
        return ESX.GetPlayerFromId(src)
    end

    if framework == 'nd' then
        if NDCore then
            local ok, player = CallMethod(NDCore, { 'getPlayer', 'GetPlayer', 'fetchPlayer', 'FetchPlayer' }, src)
            if ok and player then return player end
        end

        for _, exportName in ipairs({ 'getPlayer', 'GetPlayer', 'fetchPlayer', 'FetchPlayer' }) do
            local ok, player = SafeExport('ND_Core', exportName, src)
            if ok and player then return player end
        end
    end

    return nil
end

local function GetPlayerField(player, names)
    for _, name in ipairs(names) do
        if player and player[name] ~= nil then return player[name] end
    end
    return nil
end

local function NormalizeBoolean(value)
    if type(value) == 'boolean' then return value end
    if type(value) == 'number' then return value ~= 0 end

    if type(value) == 'string' then
        local normalized = value:lower()
        if normalized == 'true' or normalized == '1' or normalized == 'yes' or normalized == 'on' then return true end
        if normalized == 'false' or normalized == '0' or normalized == 'no' or normalized == 'off' then return false end
    end

    return nil
end

function Framework.GetIdentifier(src)
    local player = Framework.GetPlayer(src)

    if player then
        if player.PlayerData and player.PlayerData.citizenid then return player.PlayerData.citizenid end

        local ok, identifier = CallMethod(player, { 'getIdentifier', 'GetIdentifier' })
        if ok and identifier then return identifier end

        local field = GetPlayerField(player, { 'citizenid', 'citizenId', 'identifier', 'license', 'id', 'charid', 'charId', 'characterId' })
        if field then return tostring(field) end
    end

    if Framework.GetName() == 'esx' or Framework.GetName() == 'nd' then
        local license = GetLicenseIdentifier(src)
        if license then return license end
    end

    return ('source:%s'):format(src)
end

function Framework.GetCharacterName(src)
    local player = Framework.GetPlayer(src)

    if player then
        if player.PlayerData and player.PlayerData.charinfo then
            local c = player.PlayerData.charinfo
            return ('%s %s'):format(c.firstname or 'Unknown', c.lastname or 'Driver')
        end

        local ok, name = CallMethod(player, { 'getName', 'GetName', 'getFullName', 'GetFullName' })
        if ok and name and name ~= '' then return tostring(name) end

        local firstName = GetPlayerField(player, { 'firstname', 'firstName', 'first_name' })
        local lastName = GetPlayerField(player, { 'lastname', 'lastName', 'last_name' })
        if firstName or lastName then
            return ('%s %s'):format(firstName or 'Unknown', lastName or 'Driver')
        end

        local field = GetPlayerField(player, { 'name', 'fullname', 'fullName' })
        if field then return tostring(field) end
    end

    return GetPlayerName(src) or 'Driver'
end

local function NormalizeJob(job)
    if type(job) == 'string' then
        return {
            name = job,
            label = job,
            gradeName = 'None',
            gradeLevel = 0,
            text = ('%s - None'):format(job)
        }
    end

    if type(job) ~= 'table' then
        return {
            name = 'unemployed',
            label = 'Unemployed',
            gradeName = 'None',
            gradeLevel = 0,
            text = 'Unemployed - None'
        }
    end

    local jobName = job.name or job.id or job.job or 'unemployed'
    local jobLabel = job.label or job.nameLabel or job.title or jobName
    local gradeName = 'None'
    local gradeLevel = 0
    local onDuty = nil

    if type(job.grade) == 'table' then
        gradeName = job.grade.name or job.grade.label or tostring(job.grade.level or job.grade.grade or job.grade.value or 'None')
        gradeLevel = tonumber(job.grade.level or job.grade.grade or job.grade.value or 0) or 0
    elseif job.grade ~= nil then
        gradeLevel = tonumber(job.grade) or 0
        gradeName = tostring(job.grade)
    end

    if job.grade_name then gradeName = job.grade_name end
    if job.grade_label then gradeName = job.grade_label end
    if job.gradeName then gradeName = job.gradeName end
    if job.gradeLabel then gradeName = job.gradeLabel end
    if job.rankName then gradeName = job.rankName end
    if job.grade_level then gradeLevel = tonumber(job.grade_level) or gradeLevel end
    if job.gradeLevel then gradeLevel = tonumber(job.gradeLevel) or gradeLevel end
    if job.rank then gradeLevel = tonumber(job.rank) or gradeLevel end

    for _, field in ipairs({ 'onduty', 'onDuty', 'duty', 'isDuty', 'isOnDuty', 'service', 'inService' }) do
        local dutyValue = NormalizeBoolean(job[field])
        if dutyValue ~= nil then
            onDuty = dutyValue
            break
        end
    end

    if onDuty == nil and type(job.metadata) == 'table' then
        for _, field in ipairs({ 'onduty', 'onDuty', 'duty', 'isDuty', 'isOnDuty', 'service', 'inService' }) do
            local dutyValue = NormalizeBoolean(job.metadata[field])
            if dutyValue ~= nil then
                onDuty = dutyValue
                break
            end
        end
    end

    return {
        name = jobName,
        label = jobLabel,
        gradeName = gradeName,
        gradeLevel = gradeLevel,
        onDuty = onDuty,
        text = ('%s - %s'):format(jobLabel, gradeName)
    }
end

function Framework.GetJobInfo(src)
    local player = Framework.GetPlayer(src)
    local job = nil

    if player then
        if player.PlayerData and player.PlayerData.job then
            job = player.PlayerData.job
        elseif player.job then
            job = player.job
        elseif player.jobInfo then
            job = player.jobInfo
        else
            local ok, result = CallMethod(player, { 'getJob', 'GetJob' })
            if ok then job = result end
        end
    end

    return NormalizeJob(job)
end

function Framework.HasRequiredJob(src)
    if not Config.RequireJob then return true end
    return Framework.GetJobInfo(src).name == Config.JobName
end

function Framework.SetDuty(src, onDuty)
    onDuty = onDuty == true

    local framework = Framework.GetName()
    local player = Framework.GetPlayer(src)

    if framework == 'qb' and player and player.Functions and player.Functions.SetJobDuty then
        local ok = pcall(function()
            player.Functions.SetJobDuty(onDuty)
        end)

        if ok then
            TriggerClientEvent('QBCore:Client:SetDuty', src, onDuty)
            TriggerEvent('QBCore:Server:SetDuty', src, onDuty)
            return true
        end
    end

    if framework == 'qbox' then
        for _, exportName in ipairs({ 'SetJobDuty', 'SetDuty' }) do
            local ok = SafeExport('qbx_core', exportName, src, onDuty)
            if ok then return true end
        end
    end

    return false
end

local function GetMoneyAccount()
    return Config.PayToBank and 'bank' or 'cash'
end

local function GetAccountBalance(player, account)
    if not player then return nil end
    account = account or 'cash'

    if account == 'cash' or account == 'money' then
        local ok, balance = CallMethod(player, { 'getMoney', 'GetMoney' })
        if ok and balance ~= nil then return tonumber(balance) end

        for _, field in ipairs({ 'cash', 'money' }) do
            if player[field] ~= nil then return tonumber(player[field]) end
        end
    end

    local ok, accountData = CallMethod(player, { 'getAccount', 'GetAccount' }, account)
    if ok and type(accountData) == 'table' then
        return tonumber(accountData.money or accountData.balance or accountData.amount)
    elseif ok and accountData ~= nil then
        return tonumber(accountData)
    end

    ok, accountData = CallMethod(player, { 'getMoney', 'GetMoney' }, account)
    if ok and accountData ~= nil then return tonumber(accountData) end

    local accounts = player.accounts or player.account
    if type(accounts) == 'table' then
        local data = accounts[account]
        if type(data) == 'table' then
            return tonumber(data.money or data.balance or data.amount)
        end

        if data ~= nil then return tonumber(data) end
    end

    return nil
end

function Framework.AddMoney(src, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end

    local account = GetMoneyAccount()
    local player = Framework.GetPlayer(src)

    if player and player.Functions and player.Functions.AddMoney then
        return player.Functions.AddMoney(account, amount, reason or 'ls-trucking-payment') ~= false
    end

    if Framework.GetName() == 'qbox' then
        local ok = pcall(function()
            exports.qbx_core:AddMoney(src, account, amount, reason or 'ls-trucking-payment')
        end)
        if ok then return true end
    end

    if Framework.GetName() == 'esx' and player then
        if account == 'cash' or account == 'money' then
            local ok, result = CallMethod(player, { 'addMoney', 'AddMoney' }, amount, reason or 'ls-trucking-payment')
            if ok then return result ~= false end
        end

        local ok, result = CallMethod(player, { 'addAccountMoney', 'AddAccountMoney' }, account, amount, reason or 'ls-trucking-payment')
        if ok then return result ~= false end
    end

    if Framework.GetName() == 'nd' and player then
        local ok, result = CallMethod(player, { 'addMoney', 'AddMoney', 'addCash', 'AddCash' }, account, amount, reason or 'ls-trucking-payment')
        if ok then return result ~= false end

        ok, result = CallMethod(player, { 'addMoney', 'AddMoney', 'addCash', 'AddCash' }, amount, account, reason or 'ls-trucking-payment')
        if ok then return result ~= false end
    end

    if Framework.GetName() == 'nd' then
        for _, exportName in ipairs({ 'addMoney', 'AddMoney', 'addCash', 'AddCash' }) do
            local ok, result = SafeExport('ND_Core', exportName, src, amount, account, reason or 'ls-trucking-payment')
            if ok then return result ~= false end
        end
    end

    return Framework.IsStandalone()
end

function Framework.RemoveMoney(src, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end

    local account = GetMoneyAccount()
    local player = Framework.GetPlayer(src)

    local balance = GetAccountBalance(player, account)
    if balance ~= nil and balance < amount then return false end

    if player and player.Functions and player.Functions.RemoveMoney then
        return player.Functions.RemoveMoney(account, amount, reason or 'ls-trucking-charge') == true
    end

    if Framework.GetName() == 'qbox' then
        local ok, result = pcall(function()
            return exports.qbx_core:RemoveMoney(src, account, amount, reason or 'ls-trucking-charge')
        end)
        if ok then return result ~= false end
    end

    if Framework.GetName() == 'esx' and player then
        if account == 'cash' or account == 'money' then
            local ok, result = CallMethod(player, { 'removeMoney', 'RemoveMoney' }, amount, reason or 'ls-trucking-charge')
            if ok then return result ~= false end
        end

        local ok, result = CallMethod(player, { 'removeAccountMoney', 'RemoveAccountMoney' }, account, amount, reason or 'ls-trucking-charge')
        if ok then return result ~= false end
    end

    if Framework.GetName() == 'nd' and player then
        local ok, result = CallMethod(player, { 'removeMoney', 'RemoveMoney', 'deductMoney', 'DeductMoney', 'removeCash', 'RemoveCash' }, account, amount, reason or 'ls-trucking-charge')
        if ok then return result ~= false end

        ok, result = CallMethod(player, { 'removeMoney', 'RemoveMoney', 'deductMoney', 'DeductMoney', 'removeCash', 'RemoveCash' }, amount, account, reason or 'ls-trucking-charge')
        if ok then return result ~= false end
    end

    if Framework.GetName() == 'nd' then
        for _, exportName in ipairs({ 'removeMoney', 'RemoveMoney', 'deductMoney', 'DeductMoney', 'removeCash', 'RemoveCash' }) do
            local ok, result = SafeExport('ND_Core', exportName, src, amount, account, reason or 'ls-trucking-charge')
            if ok then return result ~= false end
        end
    end

    return Framework.IsStandalone()
end

local function HasAceAdmin(src)
    if not src or src == 0 then return true end

    if IsPlayerAceAllowed(src, 'command') or IsPlayerAceAllowed(src, 'admin') or IsPlayerAceAllowed(src, 'group.admin') then
        return true
    end

    local adminAces = (Config.Security and Config.Security.AdminAces) or { 'ls_trucking.admin', 'ls_trucking.debug' }
    for _, ace in ipairs(adminAces) do
        if ace and ace ~= '' and IsPlayerAceAllowed(src, ace) then
            return true
        end
    end

    return false
end

function Framework.IsAdmin(src)
    if HasAceAdmin(src) then return true end

    local player = Framework.GetPlayer(src)

    if Framework.GetName() == 'qb' and QBCore and QBCore.Functions and QBCore.Functions.HasPermission then
        if QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god') then
            return true
        end
    end

    if Framework.GetName() == 'qbox' and player then
        for _, permission in ipairs({ 'admin', 'god' }) do
            local ok, allowed = pcall(function() return exports.qbx_core:HasPermission(src, permission) end)
            if ok and allowed then return true end
        end
    end

    if Framework.GetName() == 'esx' and player then
        local ok, group = CallMethod(player, { 'getGroup', 'GetGroup' })
        group = ok and group or player.group
        if group == 'admin' or group == 'superadmin' or group == 'god' then return true end
    end

    if Framework.GetName() == 'nd' and player then
        local ok, allowed = CallMethod(player, { 'hasPermission', 'HasPermission', 'isAdmin', 'IsAdmin' }, 'admin')
        if ok and allowed then return true end

        local group = player.group or player.permission or player.rank
        if group == 'admin' or group == 'superadmin' or group == 'god' then return true end
    end

    return false
end

LS_Trucking.Framework = Framework
