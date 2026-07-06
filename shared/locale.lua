LS_Trucking = LS_Trucking or {}
LS_Trucking.Locales = LS_Trucking.Locales or {}

local function replaceToken(template, key, value)
    return template:gsub(('{%s}'):format(key), function()
        return tostring(value)
    end)
end

function LS_Trucking.T(key, values)
    local locale = (Config and Config.Locale) or 'en'
    local translations = LS_Trucking.Locales[locale] or LS_Trucking.Locales.en or {}
    local fallback = LS_Trucking.Locales.en or {}
    local text = translations[key] or fallback[key] or key

    if type(values) == 'table' then
        for token, value in pairs(values) do
            text = replaceToken(text, token, value)
        end
    end

    return text
end

T = LS_Trucking.T
