LS_Trucking = LS_Trucking or {}

local Ids = {}

local PLATE_LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
local PLATE_DIGITS = '0123456789'
local PLATE_CHARACTERS = PLATE_LETTERS .. PLATE_DIGITS

local function normalizePlateText(plate)
    return tostring(plate or ''):gsub('%s+', ''):upper()
end

local function randomCharacter(characters)
    local index = math.random(1, #characters)
    return characters:sub(index, index)
end

function Ids.GeneratePlateSuffix(length)
    length = math.max(1, tonumber(length) or 5)

    local chars = {}
    if length >= 1 then chars[1] = randomCharacter(PLATE_LETTERS) end
    if length >= 2 then chars[2] = randomCharacter(PLATE_DIGITS) end

    for i = 3, length do
        chars[i] = randomCharacter(PLATE_CHARACTERS)
    end

    for i = #chars, 2, -1 do
        local swapIndex = math.random(1, i)
        chars[i], chars[swapIndex] = chars[swapIndex], chars[i]
    end

    return table.concat(chars)
end

function Ids.GeneratePlate(prefix)
    prefix = normalizePlateText(prefix or 'LSF')
    if prefix == '' then prefix = 'LSF' end
    if #prefix > 3 then prefix = prefix:sub(1, 3) end
    return ('%s%s'):format(prefix, Ids.GeneratePlateSuffix(8 - #prefix))
end

function Ids.GenerateContractId(src)
    return ('LSFC-%s-%s'):format(src, math.random(10000, 99999))
end

LS_Trucking.Ids = Ids
