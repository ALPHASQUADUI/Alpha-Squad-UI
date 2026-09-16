-- Addon presentation and verified game names only; source data stays untouched.
local ASUI = AlphaSquadUI
local Localization = { dictionaries = {}, bindings = setmetatable({}, { __mode = "k" }), callbacks = {} }
ASUI.Localization = Localization
local unpack = unpack or table.unpack
local valid = { en = true, fr = true }
local nativeNames = {}

-- Curated game-name records use stable IDs; they never rewrite links, player
-- names, descriptions or wire data. Uncatalogued names remain native text.
function Localization.RegisterNativeNames(kind, entries)
    if (kind ~= "ability" and kind ~= "set") or type(entries) ~= "table" then return false end
    local target = nativeNames[kind] or {}
    nativeNames[kind] = target
    for id, names in pairs(entries) do
        if type(id) == "number" and id > 0 and id <= 2147483647 and id % 1 == 0
            and type(names) == "table" and type(names.en) == "string" and names.en ~= ""
            and type(names.fr) == "string" and names.fr ~= "" then
            target[id] = { en = names.en, fr = names.fr }
        end
    end
    return true
end
function Localization.GetNativeName(kind, id, fallback)
    local entries = nativeNames[kind]
    local names = entries and type(id) == "number" and entries[id]
    return names and names[Localization.GetLanguage()] or (type(fallback) == "string" and fallback or "")
end

local function GameLanguage()
    local language = type(GetCVar) == "function" and GetCVar("language.2") or "en"
    return type(language) == "string" and language:lower() == "fr" and "fr" or "en"
end
local function Signature(text)
    local result = {}
    for token in text:gmatch("%%[-+#0]*%d*%.?%d*[cdeEfgGiouXxqs%%]") do
        if token ~= "%%" then result[#result + 1] = token:sub(-1) end
    end
    return table.concat(result, ",")
end

function Localization.Register(language, dictionary)
    if (language ~= "en" and language ~= "fr") or type(dictionary) ~= "table" then return false end
    local target = Localization.dictionaries[language] or {}
    Localization.dictionaries[language] = target
    for source, translation in pairs(dictionary) do
        if type(source) == "string" and type(translation) == "string"
            and Signature(source) == Signature(translation) then
            target[source] = translation
        end
    end
    return true
end

function Localization.GetLanguage()
    -- Safe during manifest loading: SavedVariables are opened only at initialization.
    if not Localization.language then Localization.language = GameLanguage() end
    return Localization.language
end
-- Contextual headings must not reuse navigation's "BACK" (French: "Retour").
Localization.Register("en", { ["BACK WEAPON BAR"] = "BACK" })
function ASUI.L(source, ...)
    if source == nil then return "" end
    source = tostring(source)
    local dictionary = Localization.dictionaries[Localization.GetLanguage()]
    local translated = dictionary and dictionary[source] or source
    if select("#", ...) == 0 then return translated end
    local ok, result = pcall(string.format, translated, ...)
    if ok then return result end
    -- A bad optional extension translation must not prevent the window opening.
    ok, result = pcall(string.format, source, ...)
    return ok and result or source
end

local function Paint(control, entry)
    local source = type(entry.source) == "function" and entry.source() or entry.source
    control:SetText(ASUI.L(source, unpack(entry.args, 1, entry.args.n)))
end
function Localization.Bind(control, source, ...)
    if not control or type(control.SetText) ~= "function" then return control end
    local entry = { source = source, args = { n = select("#", ...), ... } }
    Localization.bindings[control] = entry
    Paint(control, entry)
    return control
end
function Localization.Unbind(control)
    Localization.bindings[control] = nil
end
function Localization.RegisterCallback(key, callback)
    if type(key) ~= "string" or type(callback) ~= "function" then return false end
    Localization.callbacks[key] = callback
    return true
end
function Localization.UnregisterCallback(key)
    Localization.callbacks[key] = nil
end
function Localization.Refresh()
    if Localization.refreshing then return end
    Localization.refreshing = true
    local successful = true
    for control, entry in pairs(Localization.bindings) do
        if not pcall(Paint, control, entry) then successful = false end
    end
    -- Callbacks repaint dynamic values and reflow existing windows after static text.
    local callbacks = {}
    for key, callback in pairs(Localization.callbacks) do callbacks[#callbacks + 1] = { key, callback } end
    table.sort(callbacks, function(a, b) return a[1] < b[1] end)
    for _, entry in ipairs(callbacks) do
        if not pcall(entry[2], Localization.GetLanguage()) then successful = false end
    end
    Localization.refreshing = false
    return successful
end
function Localization.Initialize()
    if Localization.sv then return end
    local preferences = ASUI.Preferences
    if not preferences or not preferences.Initialize then return end
    preferences.Initialize()
    if not preferences.sv then return end
    Localization.sv = preferences.sv
    local preference = Localization.sv.language
    -- Seed once from the supported client language. Legacy automatic and invalid
    -- values migrate to an explicit choice so later client changes do not undo it.
    if not valid[preference] then preference = GameLanguage(); Localization.sv.language = preference end
    local language = preference
    local changed = Localization.language and Localization.language ~= language
    Localization.language = language
    if changed then Localization.Refresh() end
end
function Localization.GetPreference()
    Localization.Initialize()
    return Localization.sv and Localization.sv.language or Localization.GetLanguage()
end
function Localization.SetLanguage(preference)
    if not valid[preference] or Localization.refreshing then return false end
    Localization.Initialize()
    if not Localization.sv then return false end
    local language = preference
    local changed = Localization.sv.language ~= preference or Localization.GetLanguage() ~= language
    Localization.sv.language = preference
    Localization.language = language
    if changed then Localization.Refresh() end
    return true
end
