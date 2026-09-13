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
    crusher = E("crusher", "Crusher Enchantment", "penetration", "unique", {priority="core", boss=true, penetration=1622}),
    alkosh = E("alkosh", "Roar of Alkosh", "penetration", "unique", {priority="core", boss=true, penetration=6000}),
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
    {abilityIds={85539,85854,85855}, tokens={"lotus flower","green lotus","lotus blossom"}, provides={"major_savagery_prophecy"}},
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
    if value ~= "" then AddProvided(found, self.localizedSkillNameIndex[value]) end

    -- Old clients and unusual hotbar overrides may expose neither a canonical ID nor a localized
    -- name for the seed ID. Preserve the previous English fragment matching as a last resort.
    if next(found) == nil and value ~= "" then
        for _, source in ipairs(self.skillSources) do
            local tokens = source.tokens or (source.token and {source.token}) or {}
            for _, token in ipairs(tokens) do
                if value:find(Normalize(token), 1, true) then
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
    {abilityId=238232,name="Lead From the Front",requires="The Storm Voice",requiresIds={44951},rank=2,
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
