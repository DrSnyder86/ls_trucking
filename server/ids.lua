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
    length = length or 5

    local chars = {
        randomCharacter(PLATE_LETTERS),
        randomCharacter(PLATE_DIGITS)
    }

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
    return ('%s%s'):format(prefix, Ids.GeneratePlateSuffix(5))
end

function Ids.GenerateContractId(src)
    return ('LSFC-%s-%s'):format(src, math.random(10000, 99999))
end

LS_Trucking.Ids = Ids
