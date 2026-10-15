-- RecommendedStats :: Flavor/Retail.lua
-- The version layer. Everything that differs between game versions (which secondary stats exist,
-- how they're read, how the spec is found, item level) lives here, behind RS.Flavor, so Core.lua
-- and the windows never call those APIs directly. Each game version ships its own file with the
-- same fields (Flavor/Mists.lua and so on, listed by that version's .toc), and only one of them is
-- ever loaded. Loaded right after the locales, before Data/ and Core.lua.

RecommendedStats = RecommendedStats or {}
local RS = RecommendedStats
local L = RecommendedStats_Locale

local F = { id = "RETAIL" }
RS.Flavor = F

-- The secondary stats this version has, in display order. Every stat table in the data
-- (Data/StatTargets.lua, Data/StatWeights.lua) is keyed by these names.
F.STATS = { "haste", "crit", "mastery", "versatility" }

-- Per stat:
--   label, short  display names (locale)
--   rating        the CR_ constant GetCombatRating reads for it
--   percent       the getter whose total percent matches the character sheet (see Core.lua's
--                 note above ReadStats for why these and not GetCombatRatingBonus)
--   itemKeys      C_Item.GetItemStats keys, first present wins (UI/BiSWindow.lua)
F.STAT_INFO = {
    haste = {
        label = L.STAT_HASTE, short = L.STAT_HASTE_SHORT, rating = CR_HASTE_MELEE,
        percent = function() return GetHaste() end,
        itemKeys = { "ITEM_MOD_HASTE_RATING_SHORT" },
    },
    crit = {
        label = L.STAT_CRIT, short = L.STAT_CRIT_SHORT, rating = CR_CRIT_MELEE,
        percent = function() return GetCritChance() end, -- casters: GetSpellCritChance()
        itemKeys = { "ITEM_MOD_CRIT_RATING_SHORT" },
    },
    mastery = {
        label = L.STAT_MASTERY, short = L.STAT_MASTERY_SHORT, rating = CR_MASTERY,
        percent = function() return GetMasteryEffect() end,
        itemKeys = { "ITEM_MOD_MASTERY_RATING_SHORT" },
    },
    versatility = {
        label = L.STAT_VERSATILITY, short = L.STAT_VERSATILITY_SHORT, rating = CR_VERSATILITY_DAMAGE_DONE,
        percent = function() return GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) end,
        itemKeys = { "ITEM_MOD_VERSATILITY", "ITEM_MOD_VERSATILITY_DAMAGE_DONE_SHORT" },
    },
}

-- {stat = total percent} for every stat in F.STATS. Values can be secret (Core.lua's Evaluate).
function F.ReadStats()
    local out = {}
    for _, stat in ipairs(F.STATS) do out[stat] = F.STAT_INFO[stat].percent() end
    return out
end

-- {stat = raw combat rating}; nil for a stat the client can't read. Can be secret too.
function F.ReadRatings()
    local out = {}
    for _, stat in ipairs(F.STATS) do
        local ratingType = F.STAT_INFO[stat].rating
        out[stat] = GetCombatRating and ratingType and GetCombatRating(ratingType)
    end
    return out
end

function F.StatLabel(stat)
    local info = F.STAT_INFO[stat]
    return info and info.label or stat
end

function F.StatShort(stat)
    local info = F.STAT_INFO[stat]
    return info and info.short or stat
end

--------------------------------------------------------------------------------
-- Spec
--------------------------------------------------------------------------------
-- Spec ID -> the token used in data keys ("MAGE_FROST_RAID").
local SPEC_TOKENS = {
    [71]  = "ARMS",           [72]  = "FURY",         [73]   = "PROTECTION",      -- Warrior
    [65]  = "HOLY",           [66]  = "PROTECTION",   [70]   = "RETRIBUTION",     -- Paladin
    [253] = "BEASTMASTERY",   [254] = "MARKSMANSHIP", [255]  = "SURVIVAL",        -- Hunter
    [259] = "ASSASSINATION",  [260] = "OUTLAW",       [261]  = "SUBTLETY",        -- Rogue
    [256] = "DISCIPLINE",     [257] = "HOLY",         [258]  = "SHADOW",          -- Priest
    [250] = "BLOOD",          [251] = "FROST",        [252]  = "UNHOLY",          -- Death Knight
    [262] = "ELEMENTAL",      [263] = "ENHANCEMENT",  [264]  = "RESTORATION",     -- Shaman
    [62]  = "ARCANE",         [63]  = "FIRE",         [64]   = "FROST",           -- Mage
    [265] = "AFFLICTION",     [266] = "DEMONOLOGY",   [267]  = "DESTRUCTION",     -- Warlock
    [268] = "BREWMASTER",     [269] = "WINDWALKER",   [270]  = "MISTWEAVER",      -- Monk
    [102] = "BALANCE",        [103] = "FERAL",        [104]  = "GUARDIAN",   [105] = "RESTORATION", -- Druid
    [577] = "HAVOC",          [581] = "VENGEANCE",    [1480] = "DEVOURER",       -- Demon Hunter
    [1467] = "DEVASTATION",   [1468] = "PRESERVATION", [1473] = "AUGMENTATION",   -- Evoker
}

-- The active spec's ID and localized name, or nil before the spec is known (early login).
function F.GetSpec()
    local idx = GetSpecialization and GetSpecialization()
    if not idx then return nil end
    local specID, name = GetSpecializationInfo(idx)
    return specID, name
end

function F.GetSpecToken()
    local specID = F.GetSpec()
    return specID and SPEC_TOKENS[specID]
end

function F.GetSpecName()
    local _, name = F.GetSpec()
    return name or ""
end

--------------------------------------------------------------------------------
-- Items
--------------------------------------------------------------------------------
-- Effective item level of an item link, 0 when unknown.
function F.GetItemLevel(link)
    if not link then return 0 end
    local getter = (C_Item and C_Item.GetDetailedItemLevelInfo) or GetDetailedItemLevelInfo
    return (getter and getter(link)) or 0
end
