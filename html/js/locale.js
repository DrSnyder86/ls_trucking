(function () {
    const fallbackLocale = 'en';
    let activeLocale = fallbackLocale;

    function normalizeLocale(locale) {
        const value = String(locale || fallbackLocale).trim().toLowerCase();
        if (!value) return fallbackLocale;
        return value.replace('_', '-');
    }

    function localeTable(locale) {
        const locales = window.LSTruckingLocales || {};
        const normalized = normalizeLocale(locale);
        return locales[normalized] || locales[normalized.split('-')[0]] || locales[fallbackLocale] || {};
    }

    function formatText(template, params = {}) {
        return String(template).replace(/\{([^}]+)\}/g, (_, key) => {
            const value = params[key.trim()];
            return value === undefined || value === null ? '' : String(value);
        });
    }

    window.LSTruckingUI = window.LSTruckingUI || {};

    window.LSTruckingUI.setLocale = function setLocale(locale) {
        activeLocale = normalizeLocale(locale);
        document.documentElement.lang = activeLocale;
        return activeLocale;
    };

    window.LSTruckingUI.t = function t(key, params = {}, fallback = '') {
        const table = localeTable(activeLocale);
        const fallbackTable = localeTable(fallbackLocale);
        const template = table[key] || fallbackTable[key] || fallback || key;
        return formatText(template, params);
    };

    window.LSTruckingUI.configureLocale = function configureLocale(data = {}) {
        const config = data.config || {};
        const locale = data.locale || config.locale || config.Locale || fallbackLocale;
        return window.LSTruckingUI.setLocale(locale);
    };
})();

function uiText(key, params = {}, fallback = '') {
    return window.LSTruckingUI.t(key, params, fallback);
}

function configureUILocale(data = {}) {
    return window.LSTruckingUI.configureLocale(data);
}
