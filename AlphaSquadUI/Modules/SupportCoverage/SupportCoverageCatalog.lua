-- Ąlpha Şquad UI - Support Coverage U50 catalog
-- Data is intentionally separated from the engine so patch updates can be audited safely.

local SC = AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end

SC.Catalog = SC.Catalog or {}
local Catalog = SC.Catalog

Catalog.patch = "U50"
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
    stagger = E("stagger", "Stagger", "debuff", "unique", {priority="core", boss=true, stacks=3}),
    encratis = E("encratis", "Encratis", "debuff", "unique", {priority="situational", boss=true}),
    off_balance = E("off_balance", "Off Balance", "advanced", "status", {priority="situational", boss=true}),

    -- Penetration budget
    major_breach = E("major_breach", "Major Breach", "penetration", "debuff", {priority="core", boss=true, penetration=5948}),
    minor_breach = E("minor_breach", "Minor Breach", "penetration", "debuff", {priority="core", boss=true, penetration=2974}),
    crusher = E("crusher", "Crusher Enchantment", "penetration", "unique", {priority="core", boss=true, penetration=1622}),
    alkosh = E("alkosh", "Roar of Alkosh", "penetration", "unique", {priority="core", boss=true, penetration=6000}),
    crimson_oath = E("crimson_oath", "Crimson Oath's Rive", "penetration", "unique", {priority="situational", boss=true}),
    tremorscale = E("tremorscale", "Tremorscale", "penetration", "unique", {priority="situational", boss=true, penetration=880}),

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

-- Set-name fragments are capability hints; exact set IDs and per-bar counts are captured locally.
-- Normalized set-name fragments -> capabilities. Set IDs can be added later without engine changes.
Catalog.setSources = {
    {token="spell power cure", provides={"major_courage"}},
    {token="vestments of olorime", provides={"major_courage"}},
    {token="powerful assault", provides={"powerful_assault"}},
    {token="pearlescent ward", provides={"pearlescent_ward"}},
    {token="lucent echoes", provides={"lucent_echoes"}},
    {token="elemental catalyst", provides={"elemental_catalyst"}},
    {token="z'en's redress", provides={"zens_redress"}},
    {token="zens redress", provides={"zens_redress"}},
    {token="way of martial knowledge", provides={"martial_knowledge"}},
    {token="martial knowledge", provides={"martial_knowledge"}},
    {token="roar of alkosh", provides={"alkosh"}},
    {token="crimson oath", provides={"crimson_oath"}},
    {token="roaring opportunist", provides={"major_slayer"}},
    {token="master architect", provides={"major_slayer"}},
    {token="war machine", provides={"major_slayer"}},
    {token="jorvuld", provides={"jorvulds_guidance"}},
    {token="pillager", provides={"pillagers_profit"}},
    {token="xoryn", provides={"xoryns_masterpiece"}},
    {token="spaulder of ruin", requiredPieces=1, provides={"spaulder_of_ruin"}},
    {token="ozezan", requiredPieces=2, provides={"ozezan","minor_vitality"}},
    {token="nazaray", requiredPieces=2, provides={"nazaray"}},
    {token="symphony of blades", requiredPieces=2, provides={"symphony"}},
    {token="archdruid devyric", requiredPieces=2, provides={"major_vulnerability"}},
    {token="encratis", requiredPieces=2, provides={"encratis"}},
    {token="tremorscale", requiredPieces=2, provides={"tremorscale"}},
    {token="yolnahkriin", provides={"yolnahkriin","minor_courage"}},
    {token="saxhleel", provides={"major_force"}},
    {token="serpent's disdain", provides={"serpents_disdain"}},
    {token="serpents disdain", provides={"serpents_disdain"}},
    {token="grand rejuvenation", requiredPieces=2, provides={"master_restoration"}},
    {token="master's restoration", requiredPieces=2, provides={"master_restoration"}},
    {token="masters restoration", requiredPieces=2, provides={"master_restoration"}},
}

-- Skill / mastery name fragments. These are capability hints, not proof of uptime.
Catalog.skillSources = {
    {token="aggressive horn", provides={"major_force"}},
    {token="ferocious roar", provides={"major_courage"}},
    {token="combat prayer", provides={"minor_berserk","minor_resolve"}},
    {token="elemental drain", provides={"major_breach","minor_magickasteal"}},
    {token="weakness to elements", provides={"major_breach"}},
    {token="elemental susceptibility", provides={"major_breach"}},
    {token="razor caltrops", provides={"major_breach"}},
    {token="stone giant", provides={"stagger"}},
    {token="stagger", provides={"stagger"}},
    {token="igneous weapons", provides={"major_brutality_sorcery"}},
    {token="molten armaments", provides={"major_brutality_sorcery"}},
    {token="frost cloak", provides={"major_resolve"}},
    {token="expansive frost cloak", provides={"major_resolve"}},
    {token="lotus flower", provides={"major_savagery_prophecy"}},
    {token="fetcher infection", provides={"minor_vulnerability"}},
    {token="swarm", provides={"minor_vulnerability"}},
    {token="altar", provides={"minor_lifesteal"}},
    {token="blood altar", provides={"minor_lifesteal"}},
    {token="overflowing altar", provides={"minor_lifesteal"}},
    {token="ring of preservation", provides={"minor_protection"}},
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
    return string.lower(tostring(value or ""))
end

function Catalog:GetEffect(key)
    return self.effects[key]
end

function Catalog:GetProfile(key)
    return self.profiles[key] or self.profiles.full
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

function Catalog:MatchSkillName(skillName)
    local value = Normalize(skillName)
    local found = {}
    for _, source in ipairs(self.skillSources) do
        if value:find(Normalize(source.token), 1, true) then
            for _, key in ipairs(source.provides) do found[key] = true end
        end
    end
    return found
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
Catalog.effects.evasive_trance = E("evasive_trance","Evasive Trance","debuff","unique",{priority="situational",boss=true,wireV1Unavailable=true})
Catalog.masterySources = {
    {name="Tundra's Maw",provides={"major_brittle"}},
    {name="Nature's Bounty",requires="Nature's Gift",rank=2,provides={"major_heroism"}},
    {name="Bright Harbinger",requires="Illuminate",rank=2,provides={"bright_harbinger"}},
    {name="Calculated Defense",provides={"calculated_defense"}},
    {name="Sphere of Influence",provides={"sphere_of_influence"}},
    {name="Share the Spoils",requires="Transfer",rank=2,provides={"share_the_spoils"}},
    {name="Evasive Trance",provides={"evasive_trance"}},
    {name="Lead From the Front",requires="The Storm Voice",rank=2,provides={"major_berserk","major_protection"}},
    {name="Erudite's Rigor",requires="Fatewoven Armor",rank=1,provides={"minor_cowardice","major_vitality"}},
    {name="Ink-Scribe's Verve",provides={"major_force"}},
}
