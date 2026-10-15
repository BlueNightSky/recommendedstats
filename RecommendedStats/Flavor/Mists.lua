-- RecommendedStats :: Flavor/Mists.lua
-- The version layer for Mists of Pandaria Classic (5.5.x), loaded by RecommendedStats_Mists.toc in
-- place of Flavor/Retail.lua. Same fields as Retail.lua (see that file for what each one is for);
-- the differences:
--   - No Versatility. Hit and Expertise are CAPS (Data_Mists/Caps.lua) rather than top-player
--     targets: Blizzard's Classic API doesn't report them, so the build ships the known caps.
--   - Targets are ratings (TARGET_UNIT "rating"). MoP's rating-to-percent conversion is linear at a
--     given level, so a target rating converts exactly with the player's own rating/percent ratio.
--   - Percents are the gear part only (GetCombatRatingBonus), matching what the targets measure
--     (Blizzard's rating_normalized), not the character sheet total with buffs and passives.
--   - Raid only (no Mythic+), no Analyzer link, no secret values.
-- ⚠ Not yet checked in a MoP Classic client (scope.md, step 4). Things for testers to confirm:
--   GetCombatRatingBonus/CR_* values, the spirit-to-hit conversion showing in CR_HIT_SPELL for
--   Balance, Shadow and Elemental, and GetSpecializationInfo's spec ids.

RecommendedStats = RecommendedStats or {}
local RS = RecommendedStats
local L = RecommendedStats_Locale

local F = { id = "MISTS" }
RS.Flavor = F

F.CONTENTS = { "RAID" }
F.TARGET_UNIT = "rating"
F.MAX_ROWS = 5 -- Haste, Crit, Mastery + up to two caps
F.HAS_ANALYZER = false
F.IsSecret = function() return false end

F.STATS = { "haste", "crit", "mastery" }
F.CAP_STATS = { "spellHit", "hit", "expertise" } -- a spec's Caps.lua entry has at most two of these
-- Read off items in the BiS window (spell and melee hit are the same item stat).
F.ITEM_STATS = { "haste", "crit", "mastery", "hit", "expertise" }

local function bonus(cr) return function() return GetCombatRatingBonus(cr) end end

-- perPct: rating per 1% at level 90 (per mastery point for mastery), only used while the player has
-- none of that stat to take the ratio from.
F.STAT_INFO = {
    haste = {
        label = L.STAT_HASTE, short = L.STAT_HASTE_SHORT, rating = CR_HASTE_MELEE, perPct = 425,
        percent = bonus(CR_HASTE_MELEE), itemKeys = { "ITEM_MOD_HASTE_RATING_SHORT" },
    },
    crit = {
        label = L.STAT_CRIT, short = L.STAT_CRIT_SHORT, rating = CR_CRIT_MELEE, perPct = 600,
        percent = bonus(CR_CRIT_MELEE), itemKeys = { "ITEM_MOD_CRIT_RATING_SHORT" },
    },
    mastery = {
        label = L.STAT_MASTERY, short = L.STAT_MASTERY_SHORT, rating = CR_MASTERY, perPct = 600,
        percent = bonus(CR_MASTERY), itemKeys = { "ITEM_MOD_MASTERY_RATING_SHORT" },
    },
    spellHit = {
        label = L.STAT_SPELLHIT, short = L.STAT_SPELLHIT_SHORT, rating = CR_HIT_SPELL, perPct = 340,
        percent = bonus(CR_HIT_SPELL), itemKeys = { "ITEM_MOD_HIT_RATING_SHORT" },
    },
    hit = {
        label = L.STAT_HIT, short = L.STAT_HIT_SHORT, rating = CR_HIT_MELEE, perPct = 340,
        percent = bonus(CR_HIT_MELEE), itemKeys = { "ITEM_MOD_HIT_RATING_SHORT" },
    },
    expertise = {
        label = L.STAT_EXPERTISE, short = L.STAT_EXPERTISE_SHORT, rating = CR_EXPERTISE, perPct = 340,
        percent = bonus(CR_EXPERTISE), itemKeys = { "ITEM_MOD_EXPERTISE_RATING_SHORT" },
    },
}

local function rating(stat)
    local cr = F.STAT_INFO[stat].rating
    return GetCombatRating and cr and GetCombatRating(cr) or 0
end

function F.ReadStats()
    local out = {}
    for _, stat in ipairs(F.STATS) do out[stat] = F.STAT_INFO[stat].percent() end
    return out
end

function F.ReadRatings()
    local out = {}
    for _, stat in ipairs(F.STATS) do out[stat] = rating(stat) end
    return out
end

-- A rating as the percent GetCombatRatingBonus would show for it on this character.
function F.RatingToPercent(stat, value)
    local info = F.STAT_INFO[stat]
    local r = rating(stat)
    if r > 0 then return value * info.percent() / r end
    return value / info.perPct
end

-- Current percent and rating of a capped stat (Core.lua's cap rows).
function F.ReadCap(stat)
    local info = F.STAT_INFO[stat]
    if not (info and info.rating) then return nil end
    return info.percent(), rating(stat)
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
-- Spec (MoP Classic uses the same spec ids as retail; Combat is 260 there)
--------------------------------------------------------------------------------
local SPEC_TOKENS = {
    [71]  = "ARMS",           [72]  = "FURY",         [73]  = "PROTECTION",      -- Warrior
    [65]  = "HOLY",           [66]  = "PROTECTION",   [70]  = "RETRIBUTION",     -- Paladin
    [253] = "BEASTMASTERY",   [254] = "MARKSMANSHIP", [255] = "SURVIVAL",        -- Hunter
    [259] = "ASSASSINATION",  [260] = "COMBAT",       [261] = "SUBTLETY",        -- Rogue
    [256] = "DISCIPLINE",     [257] = "HOLY",         [258] = "SHADOW",          -- Priest
    [250] = "BLOOD",          [251] = "FROST",        [252] = "UNHOLY",          -- Death Knight
    [262] = "ELEMENTAL",      [263] = "ENHANCEMENT",  [264] = "RESTORATION",     -- Shaman
    [62]  = "ARCANE",         [63]  = "FIRE",         [64]  = "FROST",           -- Mage
    [265] = "AFFLICTION",     [266] = "DEMONOLOGY",   [267] = "DESTRUCTION",     -- Warlock
    [268] = "BREWMASTER",     [269] = "WINDWALKER",   [270] = "MISTWEAVER",      -- Monk
    [102] = "BALANCE",        [103] = "FERAL",        [104] = "GUARDIAN",  [105] = "RESTORATION", -- Druid
}

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
function F.GetItemLevel(link)
    if not link then return 0 end
    local getter = (C_Item and C_Item.GetDetailedItemLevelInfo) or GetDetailedItemLevelInfo
    return (getter and getter(link)) or 0
end
