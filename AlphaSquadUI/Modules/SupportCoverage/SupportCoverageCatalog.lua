-- Ąlpha Şquad UI - Support Coverage U50 catalog
-- Data is intentionally separated from the engine so patch updates can be audited safely.

local SC = AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end

SC.Catalog = SC.Catalog or {}
local Catalog = SC.Catalog

Catalog.patch = "U50"
Catalog.reviewedAt = "2026-09-15"
Catalog.profileOrder = {"trial", "dungeon"}
Catalog.bossArmor = 18200
Catalog.criticalDamageCap = 125

local function E(key, label, category, kind, options)
    options = options or {}
    options.key = key
    options.label = label
    options.category = category
    options.kind = kind
    return options
end

Catalog.effects = {
    -- Core offensive group buffs
    major_courage = E("major_courage", "Major Courage", "offense", "buff", {priority="core", group=true}),
    minor_courage = E("minor_courage", "Minor Courage", "offense", "buff", {priority="core", group=true}),
    major_slayer = E("major_slayer", "Major Slayer", "offense", "buff", {priority="core", group=true}),
    minor_slayer = E("minor_slayer", "Minor Slayer", "offense", "buff", {priority="baseline", personal=true}),
    major_force = E("major_force", "Major Force", "critical", "buff", {priority="core", group=true, critDamage=20}),
    minor_force = E("minor_force", "Minor Force", "critical", "buff", {priority="core", personal=true, critDamage=10}),
    major_berserk = E("major_berserk", "Major Berserk", "offense", "buff", {priority="advanced", group=true}),
    minor_berserk = E("minor_berserk", "Minor Berserk", "offense", "buff", {priority="core", group=true}),
    major_brutality_sorcery = E("major_brutality_sorcery", "Major Brutality / Sorcery", "offense", "buff", {priority="core", group=true}),
    minor_brutality_sorcery = E("minor_brutality_sorcery", "Minor Brutality / Sorcery", "offense", "buff", {priority="core", group=true}),
    major_savagery_prophecy = E("major_savagery_prophecy", "Major Savagery / Prophecy", "offense", "buff", {priority="core", group=true}),
    minor_savagery_prophecy = E("minor_savagery_prophecy", "Minor Savagery / Prophecy", "offense", "buff", {priority="core", group=true}),

    -- Enemy damage amplification / critical support
    major_vulnerability = E("major_vulnerability", "Major Vulnerability", "debuff", "debuff", {priority="core", boss=true}),
    minor_vulnerability = E("minor_vulnerability", "Minor Vulnerability", "debuff", "debuff", {priority="core", boss=true}),
    major_brittle = E("major_brittle", "Major Brittle", "critical", "debuff", {priority="advanced", boss=true, critDamage=20}),
    minor_brittle = E("minor_brittle", "Minor Brittle", "critical", "debuff", {priority="core", boss=true, critDamage=10}),
    elemental_catalyst = E("elemental_catalyst", "Elemental Catalyst", "critical", "unique", {priority="core", boss=true, critDamage=15}),
    zens_redress = E("zens_redress", "Z'en's Redress", "debuff", "unique", {priority="core", boss=true}),
    martial_knowledge = E("martial_knowledge", "Martial Knowledge", "debuff", "unique", {priority="core", boss=true}),
    -- The stable key remains "stagger" for SavedVariables and wire compatibility.
    -- Update 49 renamed the live debuff to Heat Shock when Stone Giant became Magma Fist.
    stagger = E("stagger", "Heat Shock", "debuff", "unique", {
        priority="core", boss=true, stacks=3, abilityIds={134340}, aliases={"Stagger"},
    }),
    encratis = E("encratis", "Encratis", "debuff", "unique", {priority="situational", boss=true}),
    off_balance = E("off_balance", "Off Balance", "advanced", "status", {priority="situational", boss=true}),

    -- Penetration budget
    major_breach = E("major_breach", "Major Breach", "penetration", "debuff", {priority="core", boss=true, penetration=5948}),
    minor_breach = E("minor_breach", "Minor Breach", "penetration", "debuff", {priority="core", boss=true, penetration=2974}),
    crusher = E("crusher", "Crusher Enchantment", "penetration", "unique", {priority="core", boss=true, variablePenetration=true}),
    alkosh = E("alkosh", "Roar of Alkosh", "penetration", "unique", {priority="core", boss=true, variablePenetration=true}),
    crimson_oath = E("crimson_oath", "Crimson Oath's Rive", "penetration", "unique", {priority="situational", boss=true}),
    -- Tremorscale scales from the triggering tank's higher resistance and is capped by the live set rule.
    -- Presence is useful coverage information, but a static contribution would make the penetration budget lie.
    tremorscale = E("tremorscale", "Tremorscale", "penetration", "unique", {priority="situational", boss=true}),

    -- Unique offensive / group utility sets
    powerful_assault = E("powerful_assault", "Powerful Assault", "offense", "unique", {priority="core", group=true, coverageLimit=6}),
    pearlescent_ward = E("pearlescent_ward", "Pearlescent Ward", "offense", "unique", {priority="core", group=true}),
    lucent_echoes = E("lucent_echoes", "Lucent Echoes", "critical", "unique", {priority="situational", group=true, critDamage=11}),
    pillagers_profit = E("pillagers_profit", "Pillager's Profit", "sustain", "unique", {priority="core", group=true}),
    xoryns_masterpiece = E("xoryns_masterpiece", "Xoryn's Masterpiece", "sustain", "unique", {priority="situational", group=true}),
    spaulder_of_ruin = E("spaulder_of_ruin", "Spaulder of Ruin", "offense", "unique", {priority="situational", group=true}),
    ozezan = E("ozezan", "Ozezan the Inferno", "defense", "unique", {priority="progression", group=true}),
    nazaray = E("nazaray", "Nazaray", "debuff", "unique", {priority="situational", boss=true}),
    symphony = E("symphony", "Symphony of Blades", "sustain", "unique", {priority="progression", group=true}),
    yolnahkriin = E("yolnahkriin", "Yolnahkriin", "offense", "unique", {priority="situational", group=true}),
    master_restoration = E("master_restoration", "Grand Rejuvenation", "sustain", "unique", {priority="progression", group=true}),
    jorvulds_guidance = E("jorvulds_guidance", "Jorvuld's Guidance", "sustain", "unique", {priority="situational", group=true}),
    serpents_disdain = E("serpents_disdain", "Serpent's Disdain", "debuff", "unique", {priority="situational", boss=true}),

    -- Sustain / ultimate economy
    major_heroism = E("major_heroism", "Major Heroism", "sustain", "buff", {priority="advanced", group=true}),
    minor_heroism = E("minor_heroism", "Minor Heroism", "sustain", "buff", {priority="situational", group=true}),
    minor_magickasteal = E("minor_magickasteal", "Minor Magickasteal", "sustain", "debuff", {priority="progression", boss=true}),
    minor_lifesteal = E("minor_lifesteal", "Minor Lifesteal", "sustain", "debuff", {priority="progression", boss=true}),
    major_intellect = E("major_intellect", "Major Intellect", "sustain", "buff", {priority="baseline", personal=true}),
    minor_intellect = E("minor_intellect", "Minor Intellect", "sustain", "buff", {priority="situational", group=true}),
    major_endurance = E("major_endurance", "Major Endurance", "sustain", "buff", {priority="baseline", personal=true}),
    minor_endurance = E("minor_endurance", "Minor Endurance", "sustain", "buff", {priority="situational", group=true}),
    major_fortitude = E("major_fortitude", "Major Fortitude", "sustain", "buff", {priority="baseline", personal=true}),
    minor_fortitude = E("minor_fortitude", "Minor Fortitude", "sustain", "buff", {priority="situational", group=true}),

    -- Defensive/progression coverage
    major_resolve = E("major_resolve", "Major Resolve", "defense", "buff", {priority="progression", group=true}),
    minor_resolve = E("minor_resolve", "Minor Resolve", "defense", "buff", {priority="progression", group=true}),
    major_protection = E("major_protection", "Major Protection", "defense", "buff", {priority="situational", group=true}),
    minor_protection = E("minor_protection", "Minor Protection", "defense", "buff", {priority="progression", group=true}),
    major_evasion = E("major_evasion", "Major Evasion", "defense", "buff", {priority="situational", group=true}),
    minor_evasion = E("minor_evasion", "Minor Evasion", "defense", "buff", {priority="situational", group=true}),
    major_vitality = E("major_vitality", "Major Vitality", "defense", "buff", {priority="progression", group=true}),
    minor_vitality = E("minor_vitality", "Minor Vitality", "defense", "buff", {priority="progression", group=true}),
    major_mending = E("major_mending", "Major Mending", "defense", "buff", {priority="situational", group=true}),
    minor_mending = E("minor_mending", "Minor Mending", "defense", "buff", {priority="situational", group=true}),
    minor_toughness = E("minor_toughness", "Minor Toughness", "defense", "buff", {priority="progression", group=true}),
    major_aegis = E("major_aegis", "Major Aegis", "defense", "buff", {priority="situational", personal=true}),
    minor_aegis = E("minor_aegis", "Minor Aegis", "defense", "buff", {priority="baseline", personal=true}),
    major_maim = E("major_maim", "Major Maim", "defense", "debuff", {priority="progression", boss=true}),
    minor_maim = E("minor_maim", "Minor Maim", "defense", "debuff", {priority="progression", boss=true}),
    major_cowardice = E("major_cowardice", "Major Cowardice", "defense", "debuff", {priority="situational", boss=true}),
    minor_cowardice = E("minor_cowardice", "Minor Cowardice", "defense", "debuff", {priority="progression", boss=true}),

    -- Advanced status effects
    chilled = E("chilled", "Chilled", "advanced", "status", {priority="advanced", boss=true}),
    concussion = E("concussion", "Concussion", "advanced", "status", {priority="advanced", boss=true}),
    burning = E("burning", "Burning", "advanced", "status", {priority="advanced", boss=true}),
    sundered = E("sundered", "Sundered", "advanced", "status", {priority="advanced", boss=true}),
    poisoned = E("poisoned", "Poisoned", "advanced", "status", {priority="advanced", boss=true}),
    diseased = E("diseased", "Diseased", "advanced", "status", {priority="advanced", boss=true}),
    hemorrhaging = E("hemorrhaging", "Hemorrhaging", "advanced", "status", {priority="advanced", boss=true}),
    overcharged = E("overcharged", "Overcharged", "advanced", "status", {priority="advanced", boss=true}),
}

-- Native set IDs are authoritative and language-independent. Name fragments are retained only
-- as readable metadata and as a fallback for clients that cannot expose a usable native ID.
Catalog.setSources = {
    -- Native set IDs are language-independent. Perfected variants resolve to
    -- their base ID through GetItemSetUnperfectedSetId before matching here.
    {setId=185, token="spell power cure", provides={"major_courage"}},
    {setId=391, token="vestments of olorime", provides={"major_courage"}},
    {setId=180, token="powerful assault", provides={"powerful_assault"}},
    {setId=648, token="pearlescent ward", provides={"pearlescent_ward"}},
    {setId=768, token="lucent echoes", provides={"lucent_echoes"}},
    {setId=516, token="elemental catalyst", provides={"elemental_catalyst"}},
    {setId=455, token="z'en's redress", provides={"zens_redress"}},
    {setId=455, token="zens redress", provides={"zens_redress"}},
    {setId=147, token="way of martial knowledge", provides={"martial_knowledge"}},
    {setId=147, token="martial knowledge", provides={"martial_knowledge"}},
    {setId=232, token="roar of alkosh", provides={"alkosh"}},
    {setId=602, token="crimson oath", provides={"crimson_oath"}},
    {setId=496, token="roaring opportunist", provides={"major_slayer"}},
    {setId=332, token="master architect", provides={"major_slayer"}},
    {setId=331, token="war machine", provides={"major_slayer"}},
    {setId=346, token="jorvuld", provides={"jorvulds_guidance"}},
    {setId=649, token="pillager", provides={"pillagers_profit"}},
    {setId=769, token="xoryn", provides={"xoryns_masterpiece"}},
    {setId=627, token="spaulder of ruin", requiredPieces=1, provides={"spaulder_of_ruin"}},
    {setId=687, token="ozezan", requiredPieces=2, provides={"ozezan","minor_vitality"}},
    {setId=633, token="nazaray", requiredPieces=2, provides={"nazaray"}},
    {setId=436, token="symphony of blades", requiredPieces=2, provides={"symphony"}},
    {setId=666, token="archdruid devyric", requiredPieces=2, provides={"major_vulnerability"}},
    {setId=577, token="encratis", requiredPieces=2, provides={"encratis"}},
    {setId=276, token="tremorscale", requiredPieces=2, provides={"tremorscale"}},
    {setId=446, token="yolnahkriin", provides={"yolnahkriin","minor_courage"}},
    {setId=585, token="saxhleel", provides={"major_force"}},
    {setId=641, token="serpent's disdain", provides={"serpents_disdain"}},
    {setId=641, token="serpents disdain", provides={"serpents_disdain"}},
    {setId=318, token="grand rejuvenation", requiredPieces=2, provides={"master_restoration"}},
    {setId=318, token="master's restoration", requiredPieces=2, provides={"master_restoration"}},
    {setId=318, token="masters restoration", requiredPieces=2, provides={"master_restoration"}},
}

-- Native slot IDs are authoritative and language-independent. Localized names are derived once
-- from these IDs at runtime; English fragments are a final compatibility fallback only. A listed
-- skill is a capability hint, never proof that its effect is active.
Catalog.skillSources = {
    {abilityIds={40223}, tokens={"aggressive horn"}, provides={"major_force"}},
    {abilityIds={39113}, tokens={"ferocious roar"}, provides={"major_courage"}},
    {abilityIds={40094}, tokens={"combat prayer"}, provides={"minor_berserk","minor_resolve"}},
    {abilityIds={39095}, tokens={"elemental drain"}, provides={"major_breach","minor_magickasteal"}},
    {abilityIds={29173}, tokens={"weakness to elements"}, provides={"major_breach"}},
    {abilityIds={39089}, tokens={"elemental susceptibility"}, provides={"major_breach"}},
    {abilityIds={40242}, tokens={"razor caltrops"}, provides={"major_breach"}},
    {abilityIds={31816}, tokens={"magma fist","stone giant"}, provides={"stagger"}},
    {abilityIds={31874}, tokens={"igneous weapons"}, provides={"major_brutality_sorcery"}},
    {abilityIds={31888}, tokens={"molten armaments"}, provides={"major_brutality_sorcery"}},
    {abilityIds={86122,86126,86130}, tokens={"frost cloak","expansive frost cloak","ice fortress"}, provides={"major_resolve"}},
    {abilityIds={86023,86027,86031}, tokens={"swarm","fetcher infection","growing swarm"}, provides={"minor_vulnerability"}},
    {abilityIds={39489,41958,41967}, tokens={"blood altar","overflowing altar","sanguine altar"}, provides={"minor_lifesteal"}},
    {abilityIds={40169}, tokens={"ring of preservation"}, provides={"minor_protection"}},
}

Catalog.enchantSources = {
    crusher = {"crusher"},
}

Catalog.profiles = {
    full = {
        label = "FULL OPTIMIZATION",
        requirements = {
            "major_courage","minor_courage","major_slayer","major_force","minor_berserk",
            "major_vulnerability","minor_vulnerability","minor_brittle",
            "major_breach","minor_breach","powerful_assault","pearlescent_ward",
            "elemental_catalyst","zens_redress","martial_knowledge","stagger",
            "alkosh","pillagers_profit",
        },
    },
    progression = {
        label = "PROGRESSION",
        requirements = {
            "major_courage","major_slayer","major_force","minor_berserk",
            "major_vulnerability","minor_vulnerability","minor_brittle",
            "major_breach","minor_breach","powerful_assault","pearlescent_ward",
            "minor_toughness","major_resolve","minor_resolve","major_vitality",
            "minor_vitality","major_maim","minor_maim","minor_lifesteal",
            "minor_magickasteal","symphony","ozezan",
        },
    },
    damage = {
        label = "DAMAGE CORE",
        requirements = {
            "major_courage","major_slayer","major_force","minor_berserk",
            "major_vulnerability","minor_vulnerability","minor_brittle",
            "major_breach","minor_breach","powerful_assault","elemental_catalyst",
            "zens_redress","martial_knowledge","stagger",
        },
    },
    trash = {
        label = "TRASH",
        requirements = {
            "major_courage","major_slayer","major_force","major_breach","minor_breach",
            "powerful_assault","pearlescent_ward","major_vulnerability",
        },
    },
    boss = {
        label = "BOSS",
        requirements = {
            "major_courage","major_slayer","major_force","minor_berserk",
            "major_vulnerability","minor_vulnerability","minor_brittle",
            "major_breach","minor_breach","powerful_assault","elemental_catalyst",
            "zens_redress","martial_knowledge","stagger",
        },
    },
    custom = {
        label = "CUSTOM",
        requirements = {},
    },
}

Catalog.categories = {
    offense = "OFFENSE",
    penetration = "PENETRATION",
    critical = "CRITICAL",
    debuff = "DAMAGE AMP",
    sustain = "SUSTAIN",
    defense = "DEFENSE",
    advanced = "ADVANCED",
}

local function Normalize(value)
    if AlphaSquadUI.Utils and AlphaSquadUI.Utils.Normalize then
        return AlphaSquadUI.Utils.Normalize(value)
    end
    return string.lower(tostring(value or ""):gsub("%^.*$", ""):gsub("’", "'"))
end

function Catalog:GetEffect(key)
    return self.effects[key]
end

function Catalog:GetProfile(key)
    return self.profiles[key] or self.profiles.trial or self.profiles.full
end

function Catalog:GetRequirements(profileKey, saved)
    local result = {}
    local seen = {}
    local profile = self:GetProfile(profileKey)

    for _, key in ipairs(profile.requirements or {}) do
        if self.effects[key] and not seen[key] then
            result[#result + 1] = key
            seen[key] = true
        end
    end

    if saved and saved.profileOverrides and type(saved.profileOverrides[profileKey]) == "table" then
        for key, enabled in pairs(saved.profileOverrides[profileKey]) do
            if enabled and self.effects[key] and not seen[key] and not (saved.profileOverrides and saved.profileOverrides[profileKey] and saved.profileOverrides[profileKey][key] == false) then
                result[#result + 1] = key
                seen[key] = true
            elseif enabled == false and seen[key] then
                for i = #result, 1, -1 do
                    if result[i] == key then table.remove(result, i) end
                end
                seen[key] = nil
            end
        end
    end

    if saved and type(saved.customRequirements) == "table" then
        for key, enabled in pairs(saved.customRequirements) do
            if enabled and self.effects[key] and not seen[key] and not (saved.profileOverrides and saved.profileOverrides[profileKey] and saved.profileOverrides[profileKey][key] == false) then
                result[#result + 1] = key
                seen[key] = true
            end
        end
    end

    local overrides=saved and saved.profileOverrides and saved.profileOverrides[profileKey]
    for index=#result,1,-1 do
        local key=result[index]
        local explicit
        if type(overrides)=="table" then explicit=overrides[key] end
        local rule=saved and type(saved.effectRules)=="table" and saved.effectRules[key]
        if explicit==false or (explicit~=true and type(rule)=="table" and rule.enabled==false) then
            table.remove(result,index)
        end
    end

    table.sort(result, function(a, b)
        local ea, eb = self.effects[a], self.effects[b]
        if ea.category ~= eb.category then return ea.category < eb.category end
        return ea.label < eb.label
    end)

    return result
end

function Catalog:MatchSetName(setName)
    local value = Normalize(setName)
    local found = {}
    for _, source in ipairs(self.setSources) do
        if value:find(Normalize(source.token), 1, true) then
            for _, key in ipairs(source.provides) do found[key] = true end
        end
    end
    return found
end

local function AddProvided(target, source)
    for index, value in pairs(source or {}) do
        local key = type(index) == "number" and value or (value == true and index or nil)
        if key then target[key] = true end
    end
end

function Catalog:BuildSkillIndexes()
    self.skillIdIndex, self.localizedSkillNameIndex = {}, {}
    local nameGetter = type(GetAbilityName) == "function" and GetAbilityName or nil
    self.skillIndexNameGetter = nameGetter

    for _, source in ipairs(self.skillSources) do
        for _, rawId in ipairs(source.abilityIds or {}) do
            local id = tonumber(rawId)
            if id and id == id and id ~= math.huge and id ~= -math.huge
                and id > 0 and id <= 2147483647 and id % 1 == 0 then
                self.skillIdIndex[id] = self.skillIdIndex[id] or {}
                AddProvided(self.skillIdIndex[id], source.provides)

                if nameGetter then
                    local ok, localizedName = pcall(nameGetter, id)
                    localizedName = ok and Normalize(localizedName) or ""
                    if localizedName ~= "" then
                        self.localizedSkillNameIndex[localizedName] = self.localizedSkillNameIndex[localizedName] or {}
                        AddProvided(self.localizedSkillNameIndex[localizedName], source.provides)
                    end
                end
            end
        end
    end
end

function Catalog:MatchSkill(abilityId, skillName)
    local currentNameGetter = type(GetAbilityName) == "function" and GetAbilityName or nil
    if not self.skillIdIndex or self.skillIndexNameGetter ~= currentNameGetter then self:BuildSkillIndexes() end

    local found = {}
    abilityId = tonumber(abilityId)
    if abilityId and abilityId == abilityId and abilityId ~= math.huge and abilityId ~= -math.huge
        and abilityId > 0 and abilityId <= 2147483647 and abilityId % 1 == 0 then
        AddProvided(found, self.skillIdIndex[abilityId])
    end

    local value = Normalize(skillName)
    if abilityId and currentNameGetter then
        local ok, nativeName = pcall(currentNameGetter, abilityId)
        if ok and type(nativeName) == "string" and nativeName ~= "" then value = Normalize(nativeName) end
    end
    if value ~= "" then AddProvided(found, self.localizedSkillNameIndex[value]) end

    -- Old clients and unusual hotbar overrides may expose neither a canonical ID nor a localized
    -- name for the seed ID. Preserve the previous English fragment matching as a last resort.
    if next(found) == nil and value ~= "" then
        for _, source in ipairs(self.skillSources) do
            local tokens = source.tokens or (source.token and {source.token}) or {}
            for _, token in ipairs(tokens) do
                if value == Normalize(token) then
                    AddProvided(found, source.provides)
                    break
                end
            end
        end
    end
    return found
end

function Catalog:MatchSkillName(skillName)
    return self:MatchSkill(nil, skillName)
end

function Catalog:GetAllEffectKeys()
    local keys = {}
    for key in pairs(self.effects) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b)
        local ea, eb = self.effects[a], self.effects[b]
        if ea.category ~= eb.category then return ea.category < eb.category end
        return ea.label < eb.label
    end)
    return keys
end

-- Legacy protocol v1 indices are frozen. Never derive wire IDs from sorted UI labels.
Catalog.wireV1Keys = {
    "burning",
    "chilled",
    "concussion",
    "diseased",
    "hemorrhaging",
    "off_balance",
    "overcharged",
    "poisoned",
    "sundered",
    "elemental_catalyst",
    "lucent_echoes",
    "major_brittle",
    "major_force",
    "minor_brittle",
    "minor_force",
    "encratis",
    "major_vulnerability",
    "martial_knowledge",
    "minor_vulnerability",
    "nazaray",
    "serpents_disdain",
    "stagger",
    "zens_redress",
    "major_aegis",
    "major_cowardice",
    "major_evasion",
    "major_maim",
    "major_mending",
    "major_protection",
    "major_resolve",
    "major_vitality",
    "minor_aegis",
    "minor_cowardice",
    "minor_evasion",
    "minor_maim",
    "minor_mending",
    "minor_protection",
    "minor_resolve",
    "minor_toughness",
    "minor_vitality",
    "ozezan",
    "major_berserk",
    "major_brutality_sorcery",
    "major_courage",
    "major_savagery_prophecy",
    "major_slayer",
    "minor_berserk",
    "minor_brutality_sorcery",
    "minor_courage",
    "minor_savagery_prophecy",
    "minor_slayer",
    "pearlescent_ward",
    "powerful_assault",
    "spaulder_of_ruin",
    "yolnahkriin",
    "crimson_oath",
    "crusher",
    "major_breach",
    "minor_breach",
    "alkosh",
    "tremorscale",
    "master_restoration",
    "jorvulds_guidance",
    "major_endurance",
    "major_fortitude",
    "major_heroism",
    "major_intellect",
    "minor_endurance",
    "minor_fortitude",
    "minor_heroism",
    "minor_intellect",
    "minor_lifesteal",
    "minor_magickasteal",
    "pillagers_profit",
    "symphony",
    "xoryns_masterpiece",
}

-- U50 mastery capability metadata, checked against official live patch notes (693682).
-- These are conditional build capabilities, not observations or guaranteed uptime.
Catalog.effects.bright_harbinger = E("bright_harbinger","Bright Harbinger","offense","unique",{priority="situational",group=true,wireV1Unavailable=true})
Catalog.effects.calculated_defense = E("calculated_defense","Calculated Defense","offense","unique",{priority="situational",group=true,wireV1Unavailable=true})
Catalog.effects.sphere_of_influence = E("sphere_of_influence","Sphere of Influence","sustain","unique",{priority="situational",group=true,wireV1Unavailable=true})
Catalog.effects.share_the_spoils = E("share_the_spoils","Share the Spoils","sustain","unique",{priority="situational",group=true,wireV1Unavailable=true})
-- Keep the original internal key for SavedVariables/wire compatibility. The
-- mastery shipped as Cutthroat's Focus; Evasive Trance was its pre-release name.
Catalog.effects.evasive_trance = E("evasive_trance","Cutthroat's Focus","debuff","unique",{priority="situational",boss=true,wireV1Unavailable=true})
Catalog.masterySources = {
    {abilityId=263519,name="Tundra's Maw",provides={"major_brittle"}},
    {abilityId=263523,name="Bountiful Harvest",aliases={"Nature's Bounty"},requires="Nature's Gift",
        requiresIds={85879},rank=2,provides={"major_heroism"}},
    {abilityId=263587,name="Bright Harbinger",requires="Illuminate",requiresIds={45215},rank=2,
        provides={"bright_harbinger"}},
    {abilityId=263873,name="Calculated Defense",provides={"calculated_defense"}},
    {abilityId=263874,name="Sphere of Influence",provides={"sphere_of_influence"}},
    {abilityId=263607,name="Share the Spoils",requires="Transfer",requiresIds={45145},rank=2,
        provides={"share_the_spoils"}},
    {abilityId=263606,name="Cutthroat's Focus",aliases={"Evasive Trance"},provides={"evasive_trance"}},
    {abilityId=263247,name="Lead From the Front",requires="The Storm Voice",requiresIds={},
        requiresPassive={lineId=36,texture="ability_dragonknight_031_u49_new.dds"},rank=2,
        provides={"major_berserk","major_protection"}},
    {abilityId=263412,name="Erudite's Rigor",requires="Fatewoven Armor",
        requiresIds={183648,185908,186477},rank=1,provides={"minor_cowardice","major_vitality"}},
    {abilityId=263416,name="Ink-Scribe's Verve",provides={"major_force"}},
}

-- Protocol v2 only appends keys. The frozen v1 indices above remain compatible
-- with older test clients while the five U50 mastery capabilities become shareable.
-- Keep this list at 81 entries: cap4 bits 9-23 carry the detail fingerprint.
Catalog.wireV2Keys = {}
for index, key in ipairs(Catalog.wireV1Keys) do Catalog.wireV2Keys[index] = key end
for _, key in ipairs({
    "bright_harbinger",
    "calculated_defense",
    "sphere_of_influence",
    "share_the_spoils",
    "evasive_trance",
}) do
    Catalog.wireV2Keys[#Catalog.wireV2Keys + 1] = key
end


-- Pre-combat catalog. A source on either usable bar is a build capability; it is never
-- proof that a recipient has an active buff. Frozen legacy packet indices above stay intact.
Catalog.referenceUrls = {
    "https://forums.elderscrollsonline.com/en/discussion/693682/update-50-live-patch-notes-all-platforms",
    "https://github.com/Baertram/LibSets",
    "https://eso-hub.com/en/buffs-debuffs",
    "https://hyperioxes.com/eso/healer/sets",
    "https://hyperioxes.com/eso/tank/sets",
}

local function AddEffect(key, label, category, description, options)
    options = options or {}
    options.description = description
    options.priority = options.priority or "situational"
    options.wireV1Unavailable = true
    if not options.personal and not options.boss then options.group = true end
    Catalog.effects[key] = E(key, label, category, options.boss and "debuff" or "unique", options)
end

-- U50 class buffs are separate. A Sorcerer does not automatically provide Minor Savagery,
-- nor does a Templar's Minor Sorcery prove Minor Brutality. Keep combined keys for old saves.
AddEffect("minor_brutality", "Minor Brutality", "offense", "+10% Weapon Damage for affected group members.")
AddEffect("minor_sorcery", "Minor Sorcery", "offense", "+10% Spell Damage for affected group members.")
AddEffect("minor_savagery", "Minor Savagery", "critical", "+1314 Weapon Critical rating for affected group members.")
AddEffect("minor_prophecy", "Minor Prophecy", "critical", "+1314 Spell Critical rating for affected group members.")
AddEffect("war_horn_resources", "War Horn - Max Resources", "offense", "+10% Max Magicka and Max Stamina. This benefit is separate from Major Force.")
AddEffect("empower", "Empower", "offense", "Improves Heavy Attack damage against monsters. Enable for Heavy Attack builds; it is not an increase to every damage source.")
AddEffect("traumatic_burns", "Traumatic Burns", "debuff", "The enemy takes 5% more Flame Damage after direct damage from an Ardent Flame ability.", {boss=true})
AddEffect("runic_sunder", "Runic Sunder", "penetration", "Steals 2200 Armor from the enemy. The resistance reduction benefits attacks against that enemy; the Armor gained belongs to the Arcanist.", {boss=true, penetration=2200})
AddEffect("crystal_weapon", "Crystal Weapon - Armor Reduction", "penetration", "The triggered attack reduces the target's Armor by 1000 for 5 seconds.", {boss=true, penetration=1000})
AddEffect("warriors_opportunity", "Warrior's Opportunity", "debuff", "Traveling Knife with this Signature increases the enemy's Martial Damage taken by 8% for 5 seconds.", {boss=true})
AddEffect("dragonknight_standard", "Dragonknight Standard", "offense", "The standard's area improves group Weapon and Spell Damage and reduces damage taken. Standard of Might's extra caster bonuses are personal.")
AddEffect("vitalizing_glyphic", "Vitalizing Glyphic", "offense", "The glyphic provides healing and up to 200 Weapon and Spell Damage, depending on its Health.")
AddEffect("feeding_frenzy", "Feeding Frenzy", "offense", "The Werewolf synergy gives its user 6% damage done and Minor Force. Each beneficiary must activate the synergy.")
AddEffect("resource_synergy", "Resource Synergy", "sustain", "Energy Orb or a Spear Shards morph provides an activatable resource return. A synergy must be activated by its intended recipient.")
AddEffect("group_cleanse", "Group Cleanse", "defense", "A skill or Champion star can remove eligible negative effects from allies. Boss mechanics may be unpurgeable.")
AddEffect("group_shield", "Group Damage Shield", "defense", "An equipped skill, set or Champion star can protect allies with a damage shield. Recipient limits and shield conditions differ.")
AddEffect("weakening", "Weakening Enchantment", "defense", "A weapon enchantment lowers the enemy's Weapon and Spell Damage. Its strength depends on the weapon and enchantment.", {boss=true})
AddEffect("enlivening_overflow", "Enlivening Overflow", "sustain", "This slotted Champion star grants resource Recovery after overhealing an ally; the amount scales with the healer's Max Magicka.")
AddEffect("from_the_brink", "From the Brink", "defense", "This slotted Champion star shields an ally healed below 25% Health; each target has a cooldown.")
AddEffect("cleansing_revival", "Cleansing Revival", "defense", "This slotted Champion star removes eligible negative effects when healing an ally below 25% Health.")
AddEffect("salve_of_renewal", "Salve of Renewal", "defense", "This slotted Champion star heals around an ally after removing a negative effect.")
AddEffect("veils_forfeit", "Veil's Forfeit", "debuff", "This Necromancer mastery extends Major Vulnerability applied by its owner by 50%. It does not create Vulnerability by itself.", {boss=true})
for _, entry in ipairs({
    {"banner_magical", "Banner Bearer - Magical Damage", "6% Magical Damage done"},
    {"banner_martial", "Banner Bearer - Martial Damage", "6% Martial Damage done"},
    {"banner_direct", "Banner Bearer - Direct Damage", "6% Direct Damage done"},
    {"banner_dot", "Banner Bearer - Damage over Time", "6% Damage over Time done"},
    {"banner_aoe", "Banner Bearer - Area Damage", "6% Area Damage done"},
    {"banner_defense", "Banner Bearer - Damage Reduction", "6% damage taken reduction"},
    {"banner_sustain", "Banner Bearer - Cost Reduction", "8% non-Ultimate ability cost reduction"},
}) do
    AddEffect(entry[1], entry[2], "offense", "The equipped Focus grants " .. entry[3] .. " to allies in the banner's 8 meter aura. Different Focus effects are distinct; the same effect does not become additive by adding another wearer.")
end

local descriptions = {
    major_courage="Adds 430 Weapon and Spell Damage. Spell Power Cure, Vestment of Olorime and Ferocious Roar are alternative providers of the same named buff.",
    minor_courage="Adds 215 Weapon and Spell Damage. Arcanist's Domain, Claw of Yolnahkriin and other sources replace one another for the same recipient.",
    major_slayer="Adds 10% damage done in dungeons, trials and arenas. Roaring Opportunist, Master Architect and War Machine supply the same buff, with limited recipients per application.",
    minor_slayer="Adds 5% damage done in PvE instances to the wearer. Another player's three-piece bonus does not cover your damage dealers.",
    major_force="Adds 20 percentage points of Critical Damage, subject to each player's critical damage cap.",
    minor_force="Adds 10 percentage points of Critical Damage. Many damage dealers already provide this to themselves; check the intended recipients before assigning a support source.",
    major_berserk="Increases damage done by 10%. Storm Atronach requires its synergy; Lead from the Front requires the selected mastery and its prerequisite.",
    minor_berserk="Increases damage done by 5%. Combat Prayer and the matching Banner Bearer Affix provide it to allies; personal skills do not prove group coverage.",
    major_brutality_sorcery="Major Brutality adds 20% Weapon Damage; Major Sorcery adds 20% Spell Damage. Igneous Weapons can supply both to allies. Personal potions only supply their user.",
    minor_brutality_sorcery="Legacy combined view. In U50, Minor Brutality and Minor Sorcery are different effects with different class providers. Use the separate entries in Trial and Dungeon.",
    major_savagery_prophecy="Personal readiness check: Major Savagery / Prophecy add 2629 Weapon / Spell Critical rating. Lotus and personal potions are not automatically distributed to the group.",
    minor_savagery_prophecy="Legacy combined view. In U50, Minor Savagery and Minor Prophecy remain distinct. Use their separate entries to evaluate the actual composition.",
    major_vulnerability="The target takes 10% more damage. Colossus, Turning Tide and Archdruid Devyric are alternative providers of the same debuff.",
    minor_vulnerability="The target takes 5% more damage. Concussion, Fetcher Infection, Boneyard and Colorless Pool are examples of alternative sources.",
    major_brittle="The target takes 20 additional percentage points of Critical Damage. Tundra's Maw requires Chilled; Nunatak requires its sequence of hits. Check each damage dealer's cap.",
    minor_brittle="The target takes 10 additional percentage points of Critical Damage. Chilled requires an Ice Staff on the active bar; Colorless Pool and compatible Scribing provide alternatives.",
    elemental_catalyst="Flame, Frost and Shock damage from the wearer produce three separate weaknesses. Full strength requires all three: up to 15 percentage points of Critical Damage taken.",
    zens_redress="Touch of Z'en amplifies damage taken by up to 5%, requiring five qualifying damage-over-time effects belonging to its wearer.",
    martial_knowledge="A Light Attack below 50% Stamina applies 8% increased damage taken for 5 seconds, with an 8 second cooldown.",
    stagger="Magma Fist applies Heat Shock, adding 66 damage taken per stack, up to three stacks. This is flat damage per hit, not a percentage damage multiplier.",
    encratis="Encratis's Behemoth improves Flame Damage taken by enemies and reduces Flame Damage taken by allies in its aura. Its value depends on actual Flame Damage in the encounter.",
    off_balance="Useful for Exploiter, Heavy Attacks and resource return. Bosses have an immunity interval; owning a source does not mean permanent availability.",
    major_breach="Reduces enemy Physical and Spell Resistance by 5948. Avoid buying a second source solely to stack the same named debuff.",
    minor_breach="Reduces enemy Physical and Spell Resistance by 2974. Pierce Armor, Deep Fissure and Sundered are common sources.",
    crusher="Reduces enemy Armor through an unsuppressed, charged weapon enchantment. Weapon size, Infused and Torug's Pact change the reduction; the baseline value is not every tank's final contribution.",
    alkosh="A synergy activation triggers Armor reduction, scaling with the wearer's Weapon Damage up to 6000. Equipping five pieces does not prove the maximum value.",
    crimson_oath="Applying an eligible Major or Minor buff in combat triggers 3541 Armor reduction on nearby enemies. Check remaining penetration needs before adding another source.",
    tremorscale="Taunting triggers an Armor reduction that scales with the wearer's higher resistance. No fixed value is assumed from set presence alone.",
    powerful_assault="An Assault ability used in combat provides 307 Weapon and Spell Damage to the wearer and up to five allies within 12 meters per application.",
    pearlescent_ward="Up to 180 Weapon and Spell Damage for the group, based on living members. Its defensive benefit grows as group members die.",
    lucent_echoes="Above 50% wearer Health, other eligible allies gain 11 percentage points of Critical Damage and Healing. Other wearers do not receive the bonus.",
    pillagers_profit="Spending Ultimate distributes Ultimate to other nearby group members. It does not restore the wearer's own Ultimate and has a recipient cooldown.",
    xoryns_masterpiece="An aura increases group Max Magicka and Max Stamina by 1667. It is a maximum-resource bonus, not direct resource recovery.",
    spaulder_of_ruin="Aura of Pride grants 260 Weapon and Spell Damage to up to six allies within 12 meters. The wearer pays a resource Recovery penalty and must toggle the aura on.",
    ozezan="Healing grants Minor Vitality; overhealing grants an additional Armor bonus. Both are short effects tied to actual healed recipients.",
    nazaray="Spending Ultimate extends existing Major and Minor debuffs on nearby enemies. It creates none of them and does not extend every unique debuff.",
    symphony="Healing another group member below 50% of their dominant resource restores that resource over time, subject to a per-recipient cooldown.",
    yolnahkriin="Claw of Yolnahkriin supplies Minor Courage after a taunt. It is an alternative source of Minor Courage, not an additional unique damage bonus.",
    master_restoration="The initial Grand Healing heal supplies repeated Magicka and Stamina returns to its recipients. The restoration staff must complete its two-piece bonus on a usable bar.",
    jorvulds_guidance="Extends Major and Minor buffs and damage shields applied by the wearer in combat. It does not extend all unique effects or enemy debuffs.",
    serpents_disdain="Extends Status Effects applied by the wearer. The U50 Tundra's Maw interaction is conditional; this set is not a general Major/Minor debuff extender.",
    bright_harbinger="The selected Templar mastery upgrades Illuminate: 300 Weapon and Spell Damage for allies. The Templar's own larger bonus is personal.",
    calculated_defense="The selected Sorcerer mastery grants 6% Weapon and Spell Damage to nearby group members if its initial shield survives for 0.5 seconds.",
    sphere_of_influence="The selected Sorcerer mastery adds a shield and resource Recovery to the allies actually affected by its shield trigger.",
    share_the_spoils="The selected Nightblade mastery upgrades Transfer: 250 Magicka, 250 Stamina and 2 Ultimate for the group per eligible trigger.",
    evasive_trance="Cutthroat's Focus applies 5% increased damage taken to an attacker after its special dodge succeeds. Against monsters the debuff lasts 20 seconds.",
}
for key, description in pairs(descriptions) do Catalog.effects[key].description = description end
Catalog.effects.encratis.label = "Encratis's Behemoth"
Catalog.effects.yolnahkriin.label = "Claw of Yolnahkriin"
Catalog.effects.major_savagery_prophecy.group = nil
Catalog.effects.major_savagery_prophecy.personal = true
Catalog.effects.major_mending.group = nil
Catalog.effects.major_mending.personal = true
Catalog.effects.minor_mending.group = nil
Catalog.effects.minor_mending.personal = true
Catalog.effects.major_aegis.personal = nil
Catalog.effects.major_aegis.group = true
-- These rows describe available group suppliers; personal potion/buff observations
-- are not promoted into capability owners. Group auras need only one source owner.
for _,key in ipairs({"major_intellect","major_endurance","major_fortitude","major_aegis"}) do
    Catalog.effects[key].personal=nil
    Catalog.effects[key].group=true
end
Catalog.effects.minor_force.group = true
Catalog.effects.minor_force.personal = nil
Catalog.effects.minor_brutality_sorcery.legacy = true
Catalog.effects.minor_savagery_prophecy.legacy = true

local numericBuffs = {
    major_heroism="3 Ultimate every 1.5 seconds", minor_heroism="1 Ultimate every 1.5 seconds",
    major_intellect="30% Magicka Recovery", minor_intellect="15% Magicka Recovery",
    major_endurance="30% Stamina Recovery", minor_endurance="15% Stamina Recovery",
    major_fortitude="30% Health Recovery", minor_fortitude="15% Health Recovery",
    major_resolve="5948 Armor", minor_resolve="2974 Armor",
    major_protection="10% damage taken reduction", minor_protection="5% damage taken reduction",
    major_evasion="20% area damage taken reduction", minor_evasion="10% area damage taken reduction",
    major_vitality="12% healing received and shield strength", minor_vitality="6% healing received and shield strength",
    major_mending="16% healing done by the recipient", minor_mending="8% healing done by the recipient",
    minor_toughness="10% Max Health", major_aegis="10% damage reduction against PvE instance monsters",
    minor_aegis="5% damage reduction against PvE instance monsters",
}
for key, value in pairs(numericBuffs) do Catalog.effects[key].description = Catalog.effects[key].label .. " grants " .. value .. "." end
Catalog.effects.minor_maim.description="Reduces the enemy's damage done by 5%. Chilled, Heroic Slash and several class abilities provide it."
Catalog.effects.major_maim.description="Reduces the enemy's damage done by 10%. A defense option for dangerous phases, not a damage amplifier."
Catalog.effects.minor_cowardice.description="Reduces the enemy's Weapon and Spell Damage by 215. Its practical value depends on the enemy's attacks."
Catalog.effects.major_cowardice.description="Reduces the enemy's Weapon and Spell Damage by 430. Its practical value depends on the enemy's attacks."
Catalog.effects.minor_magickasteal.description="Attackers restore 168 Magicka, at most once per second. This is direct resource return, distinct from Recovery."
Catalog.effects.minor_lifesteal.description="Attackers heal for 600 Health, at most once per second. It does not replace healing for a lethal mechanic."
local statusDescriptions={
    chilled="Applies Minor Maim. Minor Brittle additionally requires an active Ice Staff; Tundra's Maw can add Major Brittle.",
    concussion="Applies Minor Vulnerability and enables Off Balance with a Lightning Wall.",
    sundered="Applies Minor Breach. Its extra offensive benefit for the attacker is personal.",
    overcharged="Applies Minor Magickasteal.",
    diseased="Applies Minor Defile, which matters only when the enemy's healing or shields are relevant.",
    burning="A Flame damage status. It can enable status-dependent builds, but is not itself a group damage amplifier.",
    poisoned="A Poison damage status. It can enable status-dependent builds, but is not itself a group damage amplifier.",
    hemorrhaging="A Bleed damage status. It can enable status-dependent builds, but is not itself a group damage amplifier.",
}
for key, value in pairs(statusDescriptions) do Catalog.effects[key].description=value end

-- Each source records the trigger alongside its contribution. Optional source-specific entries
-- are useful for an exact build request but are not all mandatory in the default composition.
local function AddSet(id, key, label, category, description, provides, pieces, options)
    if not Catalog.effects[key] then AddEffect(key, label, category, description, options) end
    local keys={key}
    for _, effectKey in ipairs(provides or {}) do if effectKey~=key then keys[#keys+1]=effectKey end end
    Catalog.setSources[#Catalog.setSources+1]={setId=id,token=string.lower(label),label=label,
        requiredPieces=pieces or 5,provides=keys,conditions=description,groupSource=true}
end
AddSet(622, "turning_tide", "Turning Tide", "debuff", "Block, then Bash with Flowing Water to apply Major Vulnerability in a cone.", {"major_vulnerability"}, 5, {boss=true})
AddSet(816, "dolorous_arena", "Dolorous Arena", "penetration", "Block near the enemy to build up to three Armor reduction stacks, 1843 each. Full strength is conditional.", {}, 5, {boss=true})
AddSet(50, "morag_tong", "The Morag Tong", "debuff", "Direct damage makes the enemy take 10% more Poison and Disease Damage for 5 seconds.", {}, 5, {boss=true})
AddSet(731, "sluthrugs_hunger", "Sluthrug's Hunger", "debuff", "Heal allies to grant Blood Hungry and deal direct damage to apply Bloodied. The 4% damage relationship requires both effects.", {}, 5, {boss=true})
AddSet(817, "recovery_convergence", "Recovery Convergence", "sustain", "Reach the overheal threshold in combat and activate Convergence Release to restore Magicka and Stamina to nearby group members.", {}, 5, {boss=false})
AddSet(588, "stone_talkers_oath", "Stone-Talker's Oath", "sustain", "A fully charged Heavy Attack places a mark; its explosion restores resources based on stored damage to allies in range.", {}, 5, {boss=false})
AddSet(452, "hollowfang_thirst", "Hollowfang Thirst", "sustain", "A critical heal or hit creates a delayed blood ball; nearby allies gain Magicka and Minor Vitality.", {"minor_vitality"}, 5, {boss=false})
AddSet(124, "worms_raiment", "The Worm's Raiment", "sustain", "Grants 145 Magicka Recovery to the wearer and up to eleven nearby group members.", {}, 5, {boss=false})
AddSet(123, "hircines_veneer", "Hircine's Veneer", "sustain", "Grants 145 Stamina Recovery to the wearer and up to eleven nearby group members.", {}, 5, {boss=false})
AddSet(492, "kynes_wind", "Kyne's Wind", "sustain", "Overhealing creates a short-lived area restoring Magicka and Stamina. Allies must stand in the area.", {}, 5, {boss=false})
AddSet(685, "apocryphal_inspiration", "Apocryphal Inspiration", "sustain", "Provides Major Intellect, Endurance and Fortitude in an aura. Many players already obtain these buffs from personal potions.", {"major_intellect","major_endurance","major_fortitude"}, 5, {boss=false})
AddSet(571, "drakes_rush", "Drake's Rush", "sustain", "Bash to grant Major Heroism to the wearer and up to three nearby group members. Useful for four-player groups.", {"major_heroism"}, 5, {boss=false})
AddSet(518, "arkasis", "Arkasis's Genius", "sustain", "Drink a potion in combat to grant Ultimate to the wearer and up to three group members; subject to its cooldown.", {}, 5, {boss=false})
AddSet(634, "nunatak", "Nunatak", "critical", "Frost damage creates an area; four hits on the same target trigger Major Brittle.", {"major_brittle"}, 2, {boss=true})
AddSet(609, "magma_incarnate", "Magma Incarnate", "offense", "A single-target heal starts a bounce granting Minor Courage and Minor Resolve. It is not guaranteed to reach twelve players.", {"minor_courage","minor_resolve"}, 2, {boss=false})
AddSet(672, "phoenix_moth_theurge", "Phoenix Moth Theurge", "offense", "Healing grants Minor Courage and Minor Force to the recipient, with a per-target cooldown.", {"minor_courage","minor_force"}, 5, {boss=false})
AddSet(738, "the_blind", "The Blind", "critical", "A critical heal grants a shield and Minor Force while it holds, then briefly after it ends.", {"minor_force","group_shield"}, 2, {boss=false})
AddSet(849, "glittering_goad", "Glittering Goad", "critical", "A Bash or Heavy Attack starts a damage effect. Completion applies Minor Brittle; early target death instead restores nearby group resources.", {"minor_brittle"}, 2, {boss=true})
AddSet(268, "sentinel", "Sentinel of Rkugamz", "sustain", "Healing summons an area restoring Health, Magicka and Stamina. The effective area is small.", {}, 2, {boss=false})
AddSet(535, "lady_thorn", "Lady Thorn", "defense", "A Health-cost skill creates a synergy; activating it applies Major Maim to nearby enemies.", {"major_maim"}, 2, {boss=true})
AddSet(164, "lord_warden", "Lord Warden", "defense", "Taking damage can create a nearby group Armor area. Allies must remain in its area.", {}, 2, {boss=false})
AddSet(349, "thurvokun", "Thurvokun", "defense", "Taking damage creates a bile area that applies Minor Maim and Diseased to enemies.", {"minor_maim","diseased"}, 2, {boss=true})
AddSet(734, "anthelmirs_construct", "Anthelmir's Construct", "penetration", "A fully charged Heavy Attack triggers an axe and scaling Armor reduction. Retrieving the axe changes the cooldown.", {}, 2, {boss=true})
AddSet(341, "earthgore", "Earthgore", "defense", "Healing an ally below 50% Health creates emergency healing and removes eligible ground effects. It cannot cleanse arbitrary boss mechanics.", {}, 2, {boss=false})
AddSet(691, "cryptcanon_vestments", "Cryptcanon Vestments", "sustain", "Replaces the wearer's Ultimate cast with Ultimate sharing among other living group members. Its Minor Heroism is personal.", {}, 1, {boss=false})
AddSet(676, "syrabanes_ward", "Syrabane's Ward", "defense", "Blocking creates an allied defensive zone and immobilizes the wearer. The Recovery benefit does not apply to the wearer.", {}, 1, {boss=false})
AddSet(562, "force_overflow", "Force Overflow", "sustain", "Force Siphon at short range creates a link restoring resources to allies inside the link.", {}, 2, {boss=false})
AddSet(416, "menders_ward", "Mender's Ward", "defense", "Steadfast Ward grants Major Vitality to the shielded target.", {"major_vitality","group_shield"}, 2, {boss=false})
AddSet(558, "void_bash", "Void Bash", "defense", "Power Bash pulls eligible enemies and applies Major Maim. Pull immunity still applies.", {"major_maim"}, 2, {boss=true})
AddSet(261, "gossamer", "Gossamer", "defense", "Healing an ally supplies short-duration Major Evasion.", {"major_evasion"}, 5, {boss=false})
AddSet(686, "abyssal_brace", "Abyssal Brace", "defense", "While blocking, grants Minor Evasion to group members within twelve meters.", {"minor_evasion"}, 5, {boss=false})
AddSet(471, "hitis_hearth", "Hiti's Hearth", "defense", "Healing abilities create a healing aura that reduces the recipients' Sprint, Block and Roll Dodge costs.", {}, 5, {boss=false})
AddSet(122, "ebon_armory", "Ebon Armory", "defense", "Adds 1000 Max Health to the wearer and nearby group members. Useful only when that Health threshold is needed.", {}, 5, {boss=false})
AddSet(110, "sanctuary", "Sanctuary", "defense", "Nearby group members receive 10% stronger incoming healing. The aura has a short range.", {}, 5, {boss=false})
AddSet(184, "brands_of_imperium", "Brands of Imperium", "defense", "Taking damage can create a group shield in a small nearby area.", {"group_shield"}, 5, {boss=false})
AddSet(574, "foolkillers_ward", "Foolkiller's Ward", "defense", "Blocking grants a short direct-damage shield to the wearer and three group members; breaking it restores resources.", {"group_shield"}, 5, {boss=false})
AddSet(476, "grave_guardian", "Grave Guardian", "defense", "Blocking provides an Armor aura to nearby allies. Additional Armor can exceed the recipient's mitigation cap.", {}, 5, {boss=false})
AddSet(181, "meritorious_service", "Meritorious Service", "defense", "Using a Support ability in combat grants Armor to the wearer and five nearby group members.", {}, 5, {boss=false})
AddSet(494, "vrols_command", "Vrol's Command", "defense", "A fully charged Heavy Attack grants Major Aegis to the wearer and eleven nearby allies.", {"major_aegis"}, 5, {boss=false})
AddSet(333, "inventors_guard", "Inventor's Guard", "defense", "An Ultimate grants Major Aegis to the wearer and five nearby allies.", {"major_aegis"}, 5, {boss=false})
AddSet(330, "automated_defense", "Automated Defense", "defense", "An Ultimate grants Major Aegis to the wearer and five nearby allies.", {"major_aegis"}, 5, {boss=false})
AddSet(388, "aegis_of_galenwe", "Aegis of Galenwe", "offense", "Blocking grants Empower to nearby allies. Most useful for Heavy Attack builds without a personal source.", {"empower"}, 5, {boss=false})
AddSet(229, "twilight_remedy", "Twilight Remedy", "critical", "An ally must activate a synergy created by the wearer to receive healing and Minor Force.", {"minor_force"}, 5, {boss=false})
AddSet(172, "infallible_mage", "Infallible Mage", "debuff", "A fully charged Heavy Attack applies Minor Vulnerability. The three-piece Minor Slayer is personal.", {"minor_vulnerability"}, 5, {boss=true})
AddSet(141, "healing_mage", "Healing Mage", "defense", "Area healing applies Minor Cowardice to nearby enemies. This is not the old unique Mending debuff.", {"minor_cowardice"}, 5, {boss=true})
AddSet(77, "crusader", "Crusader", "offense", "An eligible movement or pull attack creates an area supplying Minor Courage.", {"minor_courage"}, 5, {boss=false})
AddSet(729, "gardener_of_seasons", "Gardener of Seasons", "sustain", "Green Balance abilities trigger seasonal effects. Spring supplies Minor Heroism on overheal; Fall supplies different defensive effects.", {}, 5, {boss=false})
AddSet(722, "reawakened_hierophant", "Reawakened Hierophant", "defense", "Non-Ultimate Curative Runeforms supplies a shield, Minor Heroism or Major Protection according to Crux. These are alternative results.", {}, 5, {boss=false})
AddSet(762, "saint_and_seducer", "The Saint and the Seducer", "debuff", "Cycles through a personal Major buff and its associated enemy Minor debuff. Random rotation cannot guarantee a specific required debuff.", {}, 1, {boss=true})


-- Set IDs identify the set family; Perfected and normal pieces contribute to the same effect.
-- Keep source labels in English even when a client supplies a localized item name.
local knownNames={
    [185]="Spell Power Cure", [391]="Vestment of Olorime", [180]="Powerful Assault",
    [648]="Pearlescent Ward", [768]="Lucent Echoes", [516]="Elemental Catalyst",
    [455]="Z'en's Redress", [147]="Way of Martial Knowledge", [232]="Roar of Alkosh",
    [602]="Crimson Oath's Rive", [496]="Roaring Opportunist", [332]="Master Architect",
    [331]="War Machine", [346]="Jorvuld's Guidance", [649]="Pillager's Profit",
    [769]="Xoryn's Masterpiece", [627]="Spaulder of Ruin", [687]="Ozezan the Inferno",
    [633]="Nazaray", [436]="Symphony of Blades", [666]="Archdruid Devyric",
    [577]="Encratis's Behemoth", [276]="Tremorscale", [446]="Claw of Yolnahkriin",
    [585]="Saxhleel Champion", [641]="Serpent's Disdain", [318]="Grand Rejuvenation",
}
Catalog.setNameById={}
local setRecipientLimits={[180]=6,[571]=4,[518]=4,[609]=4,[574]=4,[181]=6}
for _, source in ipairs(Catalog.setSources) do
    source.groupSource=true
    source.recipientLimit=setRecipientLimits[source.setId]
    source.label=source.label or knownNames[source.setId] or source.token
    Catalog.setNameById[source.setId]=source.label
    source.conditions=source.conditions or (Catalog.effects[source.provides[1]] and Catalog.effects[source.provides[1]].description)
end

local function AddSkill(ids, name, provides, condition)
    Catalog.skillSources[#Catalog.skillSources+1]={abilityIds=ids,tokens={string.lower(name)},
        label=name,provides=provides,conditions=condition,groupSource=true}
end
AddSkill({38563}, "War Horn", {"war_horn_resources"}, "Cast the Ultimate in range of the intended allies.")
AddSkill({40220}, "Sturdy Horn", {"war_horn_resources"}, "Cast the Ultimate in range of the intended allies.")
AddSkill({40223}, "Aggressive Horn", {"war_horn_resources"}, "The maximum-resource buff is distinct from its Major Force.")
AddSkill({23634,23492,23495}, "Storm Atronach", {"major_berserk"}, "An ally must activate Charged Lightning; simply casting the Ultimate is insufficient.")
AddSkill({122174,122395,122388}, "Frozen Colossus", {"major_vulnerability"}, "The target must be struck by the Colossus.")
AddSkill({38250}, "Pierce Armor", {"major_breach","minor_breach"}, "Taunt the intended target; both Breach debuffs are applied.")
AddSkill({38256}, "Ransack", {"major_breach"}, "The Breach debuff affects the enemy; the defensive benefit is personal.")
AddSkill({28306}, "Puncture", {"major_breach"}, "Taunt the intended target.")
AddSkill({38264}, "Heroic Slash", {"minor_maim"}, "Hit the intended enemy; Heroism from this skill is personal.")
AddSkill({115252,117805,117850}, "Boneyard", {"minor_vulnerability"}, "The target must stand in Boneyard. Major Breach requires the Unnerving morph.")
AddSkill({117805}, "Unnerving Boneyard", {"major_breach"}, "The target must stand in the area.")
AddSkill({33357,36968,36967}, "Mark Target", {"major_breach"}, "Apply the mark to the intended target. Reaper's Mark's Major Berserk is personal.")
AddSkill({25493}, "Lotus Fan", {"minor_vulnerability"}, "The enemy must be struck by the attack.")
AddSkill({25484}, "Ambush", {"minor_vulnerability"}, "The enemy must be struck by the attack.")
AddSkill({46331}, "Crystal Weapon", {"crystal_weapon"}, "The imbued Light or Heavy Attacks must hit the target.")
AddSkill({86130}, "Ice Fortress", {}, "Its Major Resolve affects nearby allies; Minor Protection belongs only to the caster.")
AddSkill({85862}, "Enchanted Growth", {"minor_intellect","minor_endurance"}, "Heal the intended recipients; morph names differ but the shared recovery buffs remain.")
AddSkill({29482}, "Regenerative Ward", {"minor_intellect","minor_endurance"}, "The recovery buffs affect nearby group members; the primary shield is personal.")
AddSkill({36028}, "Refreshing Path", {"minor_intellect","minor_endurance"}, "Allies must enter the path.")
AddSkill({26807}, "Radiant Aura", {"minor_intellect","minor_endurance","minor_fortitude"}, "Activate the skill to distribute the buffs; merely slotting it only affects the caster.")
AddSkill({26858}, "Luminous Shards", {"resource_synergy"}, "The intended ally must activate the Shards synergy.")
AddSkill({26869}, "Blazing Spear", {"resource_synergy"}, "The intended ally must activate Blessed Shards to restore the appropriate resource.")
AddSkill({42038}, "Energy Orb", {"resource_synergy"}, "An ally must activate the resource synergy.")
AddSkill({28988,32958,32947}, "Dragonknight Standard", {"dragonknight_standard"}, "Allies must remain inside the standard's area.")
AddSkill({17874}, "Magma Shell", {"group_shield"}, "Cast near the intended allies; the wearer's damage cap is personal.")
AddSkill({29071,29224,32673}, "Obsidian Shield", {"group_shield"}, "The shield affects nearby allies; Major Mending is for the caster.")
AddSkill({38571,40232,40234}, "Purge", {"group_cleanse"}, "Removes eligible negative effects from nearby group members.")
AddSkill({22265,22259,22262}, "Cleansing Ritual", {"group_cleanse"}, "Allies must activate Purify. The caster's immediate cleanse is personal.")

-- New or substantially reworked abilities use an explicit name fallback until a native identity
-- is verified. Such hints remain conditional and are never promoted to observed evidence.
AddSkill({183555}, "Arcanist's Domain", {"minor_courage","minor_intellect","minor_endurance","minor_fortitude"}, "Allies must be in the domain. Inspired Scholarship is not this group aura.")
AddSkill({186229}, "Zenas' Empowering Disc", {"minor_courage","minor_intellect","minor_endurance","minor_fortitude"}, "Group members must enter the domain.")
AddSkill({186234}, "Reconstructive Domain", {"minor_courage","minor_intellect","minor_endurance","minor_fortitude"}, "Group members must enter the domain.")
AddSkill({183267}, "Rune of the Colorless Pool", {"minor_brittle","minor_vulnerability"}, "Apply to the intended enemy; these debuffs do not require a successful stun.")
AddSkill({183430}, "Runic Sunder", {"runic_sunder","minor_maim"}, "Taunt the intended target; its unique Armor reduction is separate from Breach.")
AddSkill({183709}, "Vitalizing Glyphic", {"vitalizing_glyphic"}, "The glyphic's Health controls the strength; place it near allies.")
AddSkill({193794}, "Glyphic of the Tides", {"vitalizing_glyphic"}, "The glyphic's Health controls the strength; place it near allies.")
AddSkill({193558}, "Resonating Glyphic", {"vitalizing_glyphic"}, "The glyphic's Health controls the strength; place it near allies.")
AddSkill({29059,33142}, "Hearthfire", {"minor_heroism","minor_fortitude"}, "Heal the intended allies within the area.")
AddSkill({20779,21435}, "Fire Keeper", {"minor_heroism","minor_fortitude"}, "Heal the intended allies within the area.")
AddSkill({32710,33099}, "Hearth and Home", {"minor_heroism","minor_fortitude"}, "The recovery and Heroism buffs affect healed allies; Major Protection is personal.")
-- Roar owns Feeding Frenzy in U50; the synergy is not itself a slottable ability.
AddSkill({32633,39113,39114}, "Roar", {"feeding_frenzy","minor_force"}, "Transform into a Werewolf, cast Roar or either morph, then have each beneficiary activate Feeding Frenzy.")
AddSkill({39114}, "Deafening Roar", {"major_maim","major_cowardice"}, "Transform into a Werewolf and hit the intended enemy with the roar.")
AddSkill({86015}, "Deep Fissure", {"major_breach","minor_breach"}, "The subterranean attack must hit the intended enemy.")

Catalog.passiveSources = {
    {name="Elder Dragon",abilityIds={29460,44951},rank=1,skillLineIds={36},trigger="CAST_LINE",provides={"minor_brutality"},conditions="Learn the passive and slot a Draconic Power ability, then cast it to buff the group."},
    {name="Traumatic Burns",abilityIds={29430,45012},rank=1,skillLineIds={35},trigger="CAST_LINE",provides={"traumatic_burns"},conditions="Learn the passive and deal direct damage with an Ardent Flame ability."},
    {name="Illuminate",abilityIds={31743,45215},rank=1,skillLineIds={44},trigger="CAST_LINE",provides={"minor_sorcery"},conditions="Learn Illuminate and cast a slotted Dawn's Wrath ability."},
    {name="Exploitation",abilityIds={31389,45181},rank=1,skillLineIds={41},trigger="CAST_LINE",provides={"minor_prophecy"},conditions="Learn Exploitation and cast a slotted Dark Magic ability. Font of Power can broaden its trigger."},
    {name="Hemorrhage",abilityIds={36641,45060},rank=1,skillLineIds={38},trigger="CRITICAL_DAMAGE",provides={"minor_savagery"},conditions="Learn Hemorrhage, keep an Assassination ability slotted, and deal Critical Damage. Its Critical Damage bonus is personal."},
    {name="Maturation",abilityIds={85880,85881},rank=1,trigger="ANY_HEAL",provides={"minor_toughness"},conditions="Learn Maturation and heal an ally. The passive does not require a Green Balance heal."},
}

-- Learned ability IDs are the shared authority, never the peer's display names.
-- The U49 Storm Voice passive moved to Draconic Power. Resolve its learned ID
-- through native definition keys + its native texture instead of guessing one
-- of the similarly named combat-effect/bundle IDs. This works in every locale
-- and does not inspect the viewer's purchased rank or active skill lines.
function Catalog:GetLearnedSourceRank(masteries, ids, passive)
    local learned=type(masteries)=="table" and masteries.learnedIds or {}
    learned=type(learned)=="table" and learned or {}
    local maximum=0
    local function Rank(value)
        return type(value)=="number" and value==value and value>=1 and value<=10 and value%1==0 and value or 0
    end
    for _,id in ipairs(ids or {}) do maximum=math.max(maximum,Rank(learned[id])) end
    if not passive or type(GetAbilityIcon)~="function" or type(GetSpecificSkillAbilityKeysByAbilityId)~="function"
        or type(IsSkillAbilityPassive)~="function" or type(GetSkillLineId)~="function" then return maximum end
    local inspected=0
    for id,reportedRank in pairs(learned) do
        inspected=inspected+1
        if inspected>128 then break end
        if Rank(reportedRank)>maximum and type(id)=="number" and id>0 and id<=2147483647 and id%1==0 then
            local ok,icon=pcall(GetAbilityIcon,id)
            icon=ok and type(icon)=="string" and icon:lower():gsub("\\","/") or ""
            if icon=="/esoui/art/icons/"..passive.texture or icon=="esoui/art/icons/"..passive.texture then
                local found,skillType,lineIndex,skillIndex,_,nativeRank=pcall(GetSpecificSkillAbilityKeysByAbilityId,id)
                if found and SKILL_TYPE_CLASS~=nil and skillType==SKILL_TYPE_CLASS then
                    local lineOK,lineId=pcall(GetSkillLineId,skillType,lineIndex)
                    local passiveOK,isPassive=pcall(IsSkillAbilityPassive,skillType,lineIndex,skillIndex)
                    if lineOK and lineId==passive.lineId and passiveOK and isPassive==true then
                        maximum=math.max(maximum,math.min(Rank(reportedRank),Rank(nativeRank)))
                    end
                end
            end
        end
    end
    return maximum
end

Catalog.profiles.trial={label="TRIAL",groupSize=12,requirements={
    "major_courage","minor_courage","major_slayer","minor_berserk","major_berserk",
    "major_force","minor_brutality","minor_sorcery","minor_savagery","minor_prophecy",
    "major_vulnerability","minor_vulnerability","major_breach","minor_breach","minor_brittle",
    "crusher","powerful_assault","resource_synergy",
}}
Catalog.profiles.dungeon={label="DUNGEON",groupSize=4,requirements={
    "major_courage","minor_courage","minor_berserk","major_slayer","major_force",
    "major_vulnerability","minor_vulnerability","major_breach","minor_breach",
    "minor_brittle","crusher","resource_synergy",
}}

-- Champion node IDs, not the abilities emitted when the star procs.
-- Verified against the author's native client dump and DynamicCP's node mapping:
-- https://github.com/uberswe/eso-data/blob/3b37ba3960d7c2c6fc591a94a7ea082e4d565f7d/ChampionDumper.lua
-- https://github.com/Kyzderp/DynamicCP/blob/c86bfd2d4d749f3c7c37db510ead3cdb62534205/data/convertDataIndices.lua
Catalog.championSources={
    {name="Enlivening Overflow",championIds={263},provides={"enlivening_overflow"},conditions="Invest enough points to activate the slotted Champion star and overheal allies; values scale with Max Magicka."},
    {name="Hope Infusion",championIds={261},provides={"minor_heroism"},conditions="Invest enough points to activate the slotted Champion star and heal an ally below 50% Health."},
    {name="From the Brink",championIds={262},provides={"from_the_brink","group_shield"},conditions="Invest enough points to activate the slotted Champion star and heal an ally below 25% Health."},
    {name="Cleansing Revival",championIds={29},provides={"cleansing_revival","group_cleanse"},conditions="Invest enough points to activate the slotted Champion star and heal an ally below 25% Health; only eligible effects can be removed."},
    {name="Salve of Renewal",championIds={260},provides={"salve_of_renewal"},conditions="Invest enough points to activate the slotted Champion star and remove a negative effect from an ally."},
}
Catalog.masterySources[#Catalog.masterySources+1]={abilityId=263554,name="Veil's Forfeit",provides={"veils_forfeit"},
    conditions="Select the mastery and bring a source of Major Vulnerability; only this Necromancer's applications are extended."}
for _,source in ipairs(Catalog.masterySources) do
    if source.name=="Bountiful Harvest" then source.requiredSkillLineIds={128} end
    if source.name=="Bright Harbinger" then source.requiredSkillLineIds={44} end
    if source.name=="Share the Spoils" then source.requiredSkillLineIds={40} end
    if source.name=="Erudite's Rigor" then source.requiredSlottedIds={183648,185908,186477} end
end

-- New effects stay optional until enabled for a list. No profile requires every competing set.
-- Major/Minor duplicates never stack; limited targets can still justify more than one provider.
for key, effect in pairs(Catalog.effects) do
    effect.providers={}
    effect.conditions=effect.conditions or (effect.personal and
        "Verify this on each intended player. A personal effect on its owner does not prove a group source." or
        "A complete equipped build proves an available source. Its trigger, target, range and recipient limit still apply when used.")
    effect.duplicateRule=effect.duplicateRule or ((effect.kind=="buff" or key:find("^major_") or key:find("^minor_")) and
        "The same named buff or debuff does not stack on one recipient. Multiple providers can be useful for separate targets, range or a planned rotation." or
        "Check duplicate sources on the same recipient or target. A second copy is not assumed to add the same unique bonus; different effects can complement each other.")
    effect.description=effect.description or (effect.label .. " is an optional source or effect for the selected group composition.")
end
local function AddProvider(key, source, kind)
    local effect=Catalog.effects[key]
    if not effect then return end
    local name=source.label or source.name or source.token or (source.tokens and source.tokens[1]) or "Source"
    for _, current in ipairs(effect.providers) do if current.name==name then return end end
    effect.providers[#effect.providers+1]={name=name,kind=kind,conditions=source.conditions or effect.conditions}
end
for _, source in ipairs(Catalog.setSources) do for _, key in ipairs(source.provides) do AddProvider(key,source,"set") end end
local skillLabels={
    [40223]="Aggressive Horn",[39113]="Ferocious Roar",[40094]="Combat Prayer",
    [39095]="Elemental Drain",[29173]="Weakness to Elements",[39089]="Elemental Susceptibility",
    [40242]="Razor Caltrops",[31816]="Magma Fist",[31874]="Igneous Weapons",[31888]="Molten Armaments",
    [86122]="Frost Cloak",[86023]="Swarm",[39489]="Blood Altar",[40169]="Ring of Preservation",
}
for _, source in ipairs(Catalog.skillSources) do
    source.label=source.label or skillLabels[(source.abilityIds or {})[1]]
    source.groupSource=source.personal~=true
    source.label=source.label or (source.tokens and source.tokens[1]) or source.token
    source.conditions=source.conditions or "Slot this ability on a usable bar and meet its actual cast, target and recipient conditions."
    for _, key in ipairs(source.provides) do AddProvider(key,source,"skill") end
end
for _, source in ipairs(Catalog.masterySources) do
    source.conditions=source.conditions or ((Catalog.effects[source.provides[1]] or {}).description or "Select this mastery and learn its required passive rank.")
    for _, key in ipairs(source.provides) do AddProvider(key,source,"mastery") end
end
for _, source in ipairs(Catalog.passiveSources) do for _, key in ipairs(source.provides) do AddProvider(key,source,"passive") end end
for _, source in ipairs(Catalog.championSources) do for _, key in ipairs(source.provides) do AddProvider(key,source,"champion") end end
local informationalSources={
    minor_brittle={{name="Chilled with an active Ice Staff",conditions="Chilled must be applied while the Ice Staff bar is active; an unused back-bar staff alone is insufficient."}},
    minor_breach={{name="Sundered",conditions="A source must actually apply this Status Effect."}},
    minor_vulnerability={{name="Concussion",conditions="A source must actually apply this Status Effect."}},
    minor_magickasteal={{name="Overcharged",conditions="A source must actually apply this Status Effect."}},
    major_heroism={{name="Bountiful Harvest",conditions="Selected Warden mastery, Nature's Gift rank 2 and a qualifying Green Balance overheal."}},
    minor_heroism={{name="Hope Infusion",conditions="Slotted Champion star; heal an ally below 50% Health."}},
    group_cleanse={{name="Cleansing Revival",conditions="Slotted Champion star; heal an ally below 25% Health."}},
}
for key, sources in pairs(informationalSources) do for _, source in ipairs(sources) do AddProvider(key,source,"conditional") end end

function Catalog:GetEffectTooltip(key)
    local L=AlphaSquadUI.L or function(text) return text end
    local effect=self.effects[key]
    if not effect then return L("Coverage information is unavailable.") end
    local lines={L(effect.label), L(effect.description), "", L("Before combat:") .. " " .. L(effect.conditions)}
    local providers=effect.providers or {}
    if #providers>0 then
        lines[#lines+1]=""; lines[#lines+1]=L("Possible sources:")
        for _, source in ipairs(providers) do
            lines[#lines+1]="- " .. L(source.name) .. ": " .. L(source.conditions)
        end
    end
    lines[#lines+1]=""; lines[#lines+1]=L("Duplicates:") .. " " .. L(effect.duplicateRule)
    if effect.personal then lines[#lines+1]=L("Personal readiness: inspect each player's build.") end
    lines[#lines+1]=L("Tracking can be enabled or disabled separately for Trial and Dungeon.")
    return table.concat(lines,"\n")
end

function Catalog:GetSourceTooltip(key, sourceName)
    local L=AlphaSquadUI.L or function(text) return text end
    local effect=self.effects[key]
    if not effect then return sourceName and tostring(sourceName) or L("Source") end
    for _, source in ipairs(effect.providers or {}) do
        if Normalize(source.name)==Normalize(sourceName) then return L(source.name) .. "\n" .. L(source.conditions) end
    end
    return tostring(sourceName or L(effect.label)) .. "\n" .. L(effect.description) .. "\n" .. L(effect.conditions)
end


function Catalog:FindSkillSources(abilityId, skillName)
    local getter=type(GetAbilityName)=="function" and GetAbilityName or nil
    if not self.providerIdIndex or self.providerNameGetter~=getter then
        self.providerIdIndex,self.providerNameIndex,self.providerNameGetter={},{},getter
        local function Index(target,key,source)
            if key==nil or key=="" then return end
            target[key]=target[key] or {}
            for _,existing in ipairs(target[key]) do if existing==source then return end end
            target[key][#target[key]+1]=source
        end
        for _,source in ipairs(self.skillSources or {}) do
            for _,id in ipairs(source.abilityIds or {}) do
                Index(self.providerIdIndex,id,source)
                if getter then
                    local ok,name=pcall(getter,id)
                    if ok and type(name)=="string" and name~="" then Index(self.providerNameIndex,Normalize(name),source) end
                end
            end
            for _,token in ipairs(source.tokens or {}) do Index(self.providerNameIndex,Normalize(token),source) end
        end
    end
    local name = Normalize(skillName)
    if abilityId and getter then
        local ok, nativeName = pcall(getter, abilityId)
        if ok and type(nativeName)=="string" and nativeName~="" then name=Normalize(nativeName) end
    end
    local found,seen={},{}
    for _,list in ipairs({self.providerIdIndex[abilityId] or {},self.providerNameIndex[name] or {}}) do
        for _,source in ipairs(list) do
            if not seen[source] then found[#found+1]=source;seen[source]=true end
        end
    end
    return found
end

-- Grimoire/script identities are read from the native APIs using the submitted IDs.
-- These native texture names identify the documented script definitions in all client languages.
-- A valid combination is still required; neither a peer's display text nor a grimoire alone is enough.
Catalog.scribingTextures={
    banner="ability_grimoire_support.dds",
    bannerFocus={
        ["scribing_primary_flame.dds"]="banner_dot",
        ["scribing_primary_magicka.dds"]="banner_magical",
        ["scribing_primary_bonusarmor.dds"]="banner_defense",
        ["scribing_primary_multihit.dds"]="banner_aoe",
        ["scribing_primary_physical.dds"]="banner_martial",
        ["scribing_primary_resourcerestore.dds"]="banner_sustain",
        ["scribing_primary_shock.dds"]="banner_direct",
    },
    bannerAffix={
        ["scribing_tertiary_berserk.dds"]={"minor_berserk"},
        ["scribing_tertiary_courage.dds"]={"minor_courage"},
        ["scribing_tertiary_heroism.dds"]={"minor_heroism"},
        ["scribing_tertiary_intellectendurance.dds"]={"minor_intellect","minor_endurance"},
        ["scribing_tertiary_protection.dds"]={"minor_protection"},
        ["scribing_tertiary_resolve.dds"]={"minor_resolve"},
    },
}
for texture,key in pairs(Catalog.scribingTextures.bannerFocus) do
    local effect=Catalog.effects[key]
    effect.nativeIcon="/esoui/art/icons/"..texture
    effect.providers[#effect.providers+1]={name="Banner Bearer",kind="scribing",conditions="Slot a valid Banner Bearer recipe with the matching Focus. Enable the banner and keep intended allies in its aura."}
end
for _,keys in pairs(Catalog.scribingTextures.bannerAffix) do
    for _,key in ipairs(keys) do
        Catalog.effects[key].providers[#Catalog.effects[key].providers+1]={name="Banner Bearer Affix",kind="scribing",conditions="The exact Banner Bearer Affix must be shared. The same Affix on a different grimoire may be personal."}
    end
end

-- Exact native grimoire identities and per-grimoire script effects. A shared
-- Affix texture is NOT a shared recipient rule or Major/Minor tier. These
-- matrices come from the native script tooltips listed in CATALOG_EVIDENCE.
-- Beneficial scripts require an ally-targeting Focus except Mender's link.
local function Affixes(definition)
    local result={}
    for texture,keys in pairs(definition) do
        result["scribing_tertiary_"..texture..".dds"]=type(keys)=="table" and keys or {keys}
    end
    return result
end
Catalog.scribingGrimoires={
    ["ability_grimoire_1handed.dds"]={name="Shield Throw",
        enemy=Affixes({cowardice="major_cowardice",maim="major_maim",offbalance="off_balance"})},
    ["ability_grimoire_2handed.dds"]={name="Smash",healing=true,shield=true,
        enemy=Affixes({breach="minor_breach",maim="minor_maim"}),
        ally=Affixes({berserk="minor_berserk",force="minor_force",vitality="minor_vitality"})},
    ["ability_grimoire_assault.dds"]={name="Trample",
        enemy=Affixes({vulnerability="minor_vulnerability",cowardice="minor_cowardice",offbalance="off_balance"})},
    ["ability_grimoire_bow.dds"]={name="Vault",healing=true,
        enemy=Affixes({vulnerability="minor_vulnerability",maim="minor_maim",lifesteal="minor_lifesteal",offbalance="off_balance"}),
        ally=Affixes({berserk="minor_berserk",force="minor_force",intellectendurance={"minor_intellect","minor_endurance"}})},
    ["ability_grimoire_dualwield.dds"]={name="Traveling Knife",warriorsOpportunity=true,
        enemy=Affixes({vulnerability="minor_vulnerability",maim="minor_maim",lifesteal="minor_lifesteal",offbalance="off_balance"})},
    ["ability_grimoire_fightersguild.dds"]={name="Torchbearer",healing=true,
        enemy=Affixes({breach="minor_breach",cowardice="minor_cowardice"}),
        ally=Affixes({heroism="minor_heroism",resolve="minor_resolve",vitality="minor_vitality"})},
    ["ability_grimoire_magesguild.dds"]={name="Ulfsild's Contingency",healing=true,shield=true,
        enemy=Affixes({breach="minor_breach",vulnerability="minor_vulnerability",magickasteal="minor_magickasteal"}),
        ally=Affixes({force="minor_force",protection="minor_protection",resolve="minor_resolve",intellectendurance={"minor_intellect","minor_endurance"}})},
    ["ability_grimoire_soulmagic1.dds"]={name="Wield Soul",healing=true,shield=true,
        enemy=Affixes({breach="major_breach",cowardice="major_cowardice",maim="major_maim"}),
        ally=Affixes({empower="empower",resolve="major_resolve",vitality="major_vitality",intellectendurance={"major_intellect","major_endurance"}})},
    ["ability_grimoire_soulmagic2.dds"]={name="Soul Burst",healing=true,shield=true,
        enemy=Affixes({breach="minor_breach",maim="minor_maim",magickasteal="minor_magickasteal"}),
        ally=Affixes({courage="minor_courage",resolve="minor_resolve",intellectendurance={"minor_intellect","minor_endurance"}})},
    ["ability_grimoire_staffdestro.dds"]={name="Elemental Explosion",
        enemy=Affixes({brittle="minor_brittle",cowardice="minor_cowardice",lifesteal="minor_lifesteal",
            magickasteal="minor_magickasteal",offbalance="off_balance"})},
    ["ability_grimoire_staffresto.dds"]={name="Mender's Bond",healing=true,shield=true,link=true,
        enemy=Affixes({breach="minor_breach",brittle="minor_brittle",maim="minor_maim",vulnerability="minor_vulnerability"}),
        ally=Affixes({courage="minor_courage",empower="empower",force="minor_force",heroism="minor_heroism",protection="minor_protection",
            vitality="minor_vitality",intellectendurance={"minor_intellect","minor_endurance"}})},
}
Catalog.scribingEnemyFocus={}
for _,texture in ipairs({"bleeding","disease","flame","frost","magicka","physical","poison","shock",
    "immobilized","knockback","pull","stunned","taunt","trauma"}) do
    Catalog.scribingEnemyFocus["scribing_primary_"..texture..".dds"]=true
end
for _,grimoire in pairs(Catalog.scribingGrimoires) do
    for _,recipient in ipairs({"enemy","ally"}) do
        for _,keys in pairs(grimoire[recipient] or {}) do
            for _,key in ipairs(keys) do
                local effect=Catalog.effects[key]
                effect.providers[#effect.providers+1]={name=grimoire.name.." Affix",kind="scribing",
                    conditions=recipient=="enemy" and "Equip the matching Affix in a valid recipe and affect the intended enemy."
                        or "Equip the matching Affix with an ally-targeting Focus. The intended allies must receive the skill or link."}
            end
        end
    end
    if grimoire.shield then
        local effect=Catalog.effects.group_shield
        effect.providers[#effect.providers+1]={name=grimoire.name.." Shield",kind="scribing",conditions="Use the Damage Shield Focus and apply it to the intended allies."}
    end
end
Catalog.effects.warriors_opportunity.providers[#Catalog.effects.warriors_opportunity.providers+1]={
    name="Traveling Knife Signature",kind="scribing",conditions="Equip Warrior's Opportunity in a valid damaging Traveling Knife recipe and hit the intended enemy."}

-- Presentation uses native effect/item textures, never a guessed skill icon.
local displaySources={}
for _,source in ipairs(Catalog.setSources) do
    for _,key in ipairs(source.provides or {}) do
        local effect=Catalog.effects[key]
        if effect and effect.kind~="buff" and not key:find("^major_") and not key:find("^minor_") then
            displaySources[key]=displaySources[key] or source
        end
    end
end
function Catalog:GetDisplayCategory(key)
    local source=displaySources[key]
    if source then return source.requiredPieces==1 and "mythics" or "sets" end
    local effect=self.effects[key]
    return effect and (effect.boss or effect.kind=="debuff" or effect.kind=="status") and "debuffs" or "buffs"
end
local previewCache, effectVisualCache, fallbackCache = {}, {}, {}
local retryAfter, previewRetryAfter = {}, {}
local previewLibrary
local visualProviderByKey={}
for _,source in ipairs(Catalog.masterySources) do
    for _,key in ipairs(source.provides or {}) do
        if source.abilityId then visualProviderByKey[key]=visualProviderByKey[key] or {id=source.abilityId,name=source.name} end
    end
end
for _,source in ipairs(Catalog.skillSources) do
    for _,key in ipairs(source.provides or {}) do
        local id=(source.abilityIds or {})[1]
        if id then visualProviderByKey[key]=visualProviderByKey[key] or {id=id,name=source.label} end
    end
end
local categoryIcons={
    buffs="/esoui/art/addons/gamepad/gp_mod_listing_category_buffsanddebuffs.dds",
    debuffs="/esoui/art/inventory/inventory_tabicon_weapons_up.dds",
    sets="/esoui/art/inventory/inventory_tabicon_armor_up.dds",
    mythics="/esoui/art/crafting/jewelry_tabicon_icon_up.dds",
}
function Catalog:GetCategoryIcon(category)
    return categoryIcons[category] or categoryIcons.buffs
end
local function Native(fn,...)
    if type(fn)~="function" then return nil end
    local ok,a,b,c,d,e,f=pcall(fn,...);if ok then return a,b,c,d,e,f end
end
local function Texture(value)
    if type(value)~="string" or value=="" then return nil end
    local path=value:lower():gsub("\\","/")
    if path:find("missing",1,true) or path:find("placeholder",1,true) then return nil end
    return value
end
local function ValidSetLink(link,setId)
    if type(link)~="string" or link=="" then return false end
    if type(GetItemLinkSetInfo)~="function" then return true end
    local hasSet,_,_,_,_,actualId=Native(GetItemLinkSetInfo,link,false)
    if hasSet~=true then return false end
    local actualBase=Native(GetItemSetUnperfectedSetId,actualId)
    return actualId==setId or (type(actualBase)=="number" and actualBase>0 and actualBase==setId)
end
local function NowForVisuals()
    local now=Native(GetGameTimeMilliseconds)
    return type(now)=="number" and now==now and now>=0 and now<math.huge and now or nil
end
function Catalog:GetSetPreview(setId)
    if type(setId)~="number" or setId<=0 or setId%1~=0 then return nil end
    if previewCache[setId] then return previewCache[setId] end
    if previewLibrary~=LibSets then previewRetryAfter={};previewLibrary=LibSets end
    local now=NowForVisuals()
    if now and previewRetryAfter[setId] and now<previewRetryAfter[setId] then return nil end
    if now then previewRetryAfter[setId]=now+5000 end
    local piece=Native(GetItemSetCollectionPieceInfo,setId,1)
    local link=type(piece)=="number" and piece>0 and Native(GetItemSetCollectionPieceItemLink,piece,LINK_STYLE_DEFAULT or 0,ITEM_TRAIT_TYPE_NONE or 0)
    if not ValidSetLink(link,setId) then
        -- Crafted sets do not have collectible pieces. LibSets is optional and already loaded
        -- when available; ask its public API for one reference item, then verify it natively.
        local lib=LibSets
        local itemId=type(lib)=="table" and Native(lib.GetSetItemId,setId)
        link=type(itemId)=="number" and itemId>0 and Native(lib.buildItemLink,itemId)
    end
    if not ValidSetLink(link,setId) then return nil end
    local icon=Texture(Native(GetItemLinkIcon,link))
    if not icon then return nil end
    local result={link=link,icon=icon,reference=true,iconKind="set",isFallback=false}
    previewCache[setId]=result;return result
end
function Catalog:GetEffectVisual(key)
    if effectVisualCache[key] then return effectVisualCache[key] end
    local effect=self.effects[key]
    local category=self:GetDisplayCategory(key)
    fallbackCache[category]=fallbackCache[category] or {icon=self:GetCategoryIcon(category),isFallback=true,iconKind="category",category=category}
    local now=NowForVisuals()
    if now and retryAfter[key] and now<retryAfter[key] then return fallbackCache[category] end
    local source=displaySources[key]
    if source then
        local result=self:GetSetPreview(source.setId)
        if result then effectVisualCache[key]=result;return result end
    elseif effect then
        local icon=Texture(effect.nativeIcon)
        local id=self.visualAbilityIds and self.visualAbilityIds[key] or effect.abilityIds and effect.abilityIds[1]
        local kind="effect"
        local sourceName
        if not icon and id then icon=Texture(Native(GetAbilityIcon,id)) end
        if not icon and visualProviderByKey[key] then
            local provider=visualProviderByKey[key]
            id,sourceName,kind=provider.id,provider.name,"source"
            icon=Texture(Native(GetAbilityIcon,id))
        end
        if not icon then
            for _,cp in ipairs(self.championSources or {}) do
                for _,provided in ipairs(cp.provides or {}) do
                    if provided==key then icon="/esoui/art/champion/stars/slottable.dds";kind="champion";break end
                end
                if icon then break end
            end
        end
        if icon then
            local result={icon=icon,abilityId=id,iconKind=kind,isFallback=false,sourceName=sourceName}
            effectVisualCache[key]=result;return result
        end
    end
    -- Missing native data is retried slowly and never stored as an exact identity.
    if now then retryAfter[key]=now+5000 end
    return fallbackCache[category]
end

-- Native effect identities cross-checked against LuiExtended's MajorMinor registry.
-- https://github.com/DakJaniels/LuiExtended/blob/master/LuiData/Effects/BarHighlight/MajorMinor.lua
Catalog.visualAbilityIds={
    major_aegis=93123,
    major_berserk=61745,
    major_breach=61743,
    major_brittle=145977,
    major_brutality=61665,
    major_courage=66902,
    major_cowardice=111354,
    major_defile=61727,
    major_endurance=61705,
    major_evasion=61716,
    major_expedition=61736,
    major_force=61747,
    major_fortitude=61698,
    major_heroism=61709,
    major_intellect=61707,
    major_maim=61725,
    major_mending=61711,
    major_prophecy=61689,
    major_protection=61722,
    major_resolve=61694,
    major_savagery=61667,
    major_slayer=93109,
    major_sorcery=61687,
    major_vitality=61713,
    major_vulnerability=106754,
    minor_aegis=76618,
    minor_berserk=61744,
    minor_breach=61742,
    minor_brittle=145975,
    minor_brutality=61662,
    minor_courage=121878,
    minor_cowardice=46202,
    minor_defile=61726,
    minor_endurance=61704,
    minor_enervation=47202,
    minor_evasion=61715,
    minor_expedition=61735,
    minor_force=61746,
    minor_fortitude=61697,
    minor_heroism=61708,
    minor_intellect=61706,
    minor_lifesteal=80020,
    minor_magickasteal=26809,
    minor_maim=61723,
    minor_mangle=61733,
    minor_mending=61710,
    minor_prophecy=61691,
    minor_protection=61721,
    minor_resolve=61693,
    minor_savagery=61666,
    minor_slayer=76617,
    minor_sorcery=61685,
    minor_timidity=134149,
    minor_toughness=88490,
    minor_uncertainty=47204,
    minor_vitality=61549,
    minor_vulnerability=61782,
}
Catalog.visualAbilityIds.major_brutality_sorcery=Catalog.visualAbilityIds.major_brutality
Catalog.visualAbilityIds.minor_brutality_sorcery=Catalog.visualAbilityIds.minor_brutality
Catalog.visualAbilityIds.major_savagery_prophecy=Catalog.visualAbilityIds.major_savagery
Catalog.visualAbilityIds.minor_savagery_prophecy=Catalog.visualAbilityIds.minor_savagery

-- Native status effect IDs from the maintained combat-effect registry.
for key,id in pairs({burning=18084,chilled=21481,concussion=21487,overcharged=148797,
    diseased=21925,hemorrhaging=148801,poisoned=21929,sundered=148800,off_balance=62988,empower=61737}) do
    Catalog.visualAbilityIds[key]=id
end
