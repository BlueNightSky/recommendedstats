-- RecommendedStats :: Flavor/TBC.lua
-- The version layer for Burning Crusade Classic (TBC Anniversary, 2.5.x), loaded by
-- RecommendedStats_TBC.toc in place of Flavor/Retail.lua. Same fields as Retail.lua; differences:
--   - Stats are Crit, Hit and Haste RATINGS, read as melee, ranged or spell rating depending on the
--     spec (casters and healers spell, hunters ranged, everyone else melee). Every target is a
--     measured median from the logs, so no caps. A stat top players of a spec don't carry has no
--     target and no row. Expertise is left out until its log value is checked (src/classic/tbc.js).
--   - No specializations: the spec is the talent tree with the most points. Feral Combat is Feral
--     (cat) or Guardian (bear) depending on whether you're in Bear or Dire Bear Form.
--   - Raid only, no Analyzer link, no secret values, and a ranged slot in the BiS window.
-- ⚠ Not yet checked in a TBC Anniversary client. For testers: GetTalentTabInfo's returns, the
--   CR_* values, and that the panel follows a respec and a bear form change.

RecommendedStats = RecommendedStats or {}
local RS = RecommendedStats
local L = RecommendedStats_Locale

local F = { id = "TBC" }
RS.Flavor = F

F.CONTENTS = { "RAID" }
F.TARGET_UNIT = "rating"
F.MAX_ROWS = 3
F.HAS_ANALYZER = false
F.RANGED_SLOT = true
F.IsSecret = function() return false end

F.STATS = { "crit", "hit", "haste" }

--------------------------------------------------------------------------------
-- Spec: the tree with the most points
--------------------------------------------------------------------------------
-- Talent tabs in the game's order, per class.
local TREES = {
    WARRIOR = { "ARMS", "FURY", "PROTECTION" },
    PALADIN = { "HOLY", "PROTECTION", "RETRIBUTION" },
    HUNTER  = { "BEASTMASTERY", "MARKSMANSHIP", "SURVIVAL" },
    ROGUE   = { "ASSASSINATION", "COMBAT", "SUBTLETY" },
    PRIEST  = { "DISCIPLINE", "HOLY", "SHADOW" },
    SHAMAN  = { "ELEMENTAL", "ENHANCEMENT", "RESTORATION" },
    MAGE    = { "ARCANE", "FIRE", "FROST" },
    WARLOCK = { "AFFLICTION", "DEMONOLOGY", "DESTRUCTION" },
    DRUID   = { "BALANCE", "FERAL", "RESTORATION" },
}

-- Which rating each spec's stats read: "spell", "ranged" or "melee".
local SPELL_SPECS = {
    MAGE_ARCANE = true, MAGE_FIRE = true, MAGE_FROST = true,
    WARLOCK_AFFLICTION = true, WARLOCK_DEMONOLOGY = true, WARLOCK_DESTRUCTION = true,
    PRIEST_DISCIPLINE = true, PRIEST_HOLY = true, PRIEST_SHADOW = true,
    DRUID_BALANCE = true, DRUID_RESTORATION = true,
    SHAMAN_ELEMENTAL = true, SHAMAN_RESTORATION = true, PALADIN_HOLY = true,
}

-- Points spent in one tab. Older clients return name, icon, points; newer ones id, name,
-- description, icon, points.
local function TabPoints(i)
    local a, b, c, d, e = GetTalentTabInfo(i)
    if type(a) == "string" then return c or 0, a end
    return e or 0, b
end

local BEAR_FORMS = { [5] = true, [8] = true } -- Bear Form, Dire Bear Form

-- The tree index with the most points and its localized name, or nil before talents load.
local function MainTree()
    if not GetTalentTabInfo then return nil end
    local best, bestPoints, bestName = nil, 0, nil
    for i = 1, 3 do
        local ok, points, name = pcall(TabPoints, i)
        if ok and points and points > bestPoints then best, bestPoints, bestName = i, points, name end
    end
    return best, bestName
end

function F.GetSpecToken()
    local _, class = UnitClass("player")
    local tree = MainTree()
    local token = tree and TREES[class] and TREES[class][tree]
    if token == "FERAL" and GetShapeshiftFormID and BEAR_FORMS[GetShapeshiftFormID() or 0] then
        return "GUARDIAN"
    end
    return token
end

function F.GetSpec()
    local tree, name = MainTree()
    return tree, name
end

function F.GetSpecName()
    local _, name = MainTree()
    if F.GetSpecToken() == "GUARDIAN" then return (name or "") .. " (" .. L.TBC_BEAR .. ")" end
    return name or ""
end

-- Points in each tree, for the talents window.
function F.GetTreePoints()
    local out = {}
    for i = 1, 3 do
        local ok, points, name = pcall(TabPoints, i)
        out[i] = { points = ok and points or 0, name = ok and name or ("#" .. i) }
    end
    return out
end

local function RatingKind()
    local _, class = UnitClass("player")
    local spec = F.GetSpecToken()
    if spec and SPELL_SPECS[class .. "_" .. spec] then return "spell" end
    if class == "HUNTER" then return "ranged" end
    return "melee"
end

--------------------------------------------------------------------------------
-- Stats
--------------------------------------------------------------------------------
local CR = {
    crit  = { melee = CR_CRIT_MELEE, ranged = CR_CRIT_RANGED, spell = CR_CRIT_SPELL },
    hit   = { melee = CR_HIT_MELEE,  ranged = CR_HIT_RANGED,  spell = CR_HIT_SPELL },
    haste = { melee = CR_HASTE_MELEE, ranged = CR_HASTE_RANGED, spell = CR_HASTE_SPELL },
}
-- Rating per 1% at level 70, only used while the player has none of that stat to take the ratio
-- from.
local PER_PCT = {
    crit  = { melee = 22.08, ranged = 22.08, spell = 22.08 },
    hit   = { melee = 15.77, ranged = 15.77, spell = 12.62 },
    haste = { melee = 15.77, ranged = 15.77, spell = 15.77 },
}

-- STAT_INFO[stat].rating follows the spec (melee, ranged or spell), so it's looked up on access.
local function StatInfo(stat, label, short, itemKeys)
    local info = { label = label, short = short, itemKeys = itemKeys }
    info.percent = function() return GetCombatRatingBonus(CR[stat][RatingKind()]) end
    return setmetatable(info, { __index = function(_, k)
        if k == "rating" then return CR[stat][RatingKind()] end
        if k == "perPct" then return PER_PCT[stat][RatingKind()] end
    end })
end

F.STAT_INFO = {
    crit = StatInfo("crit", L.STAT_CRIT, L.STAT_CRIT_SHORT, { "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_CRIT_SPELL_RATING_SHORT" }),
    hit = StatInfo("hit", L.STAT_HIT, L.STAT_HIT_SHORT, { "ITEM_MOD_HIT_RATING_SHORT", "ITEM_MOD_HIT_SPELL_RATING_SHORT" }),
    haste = StatInfo("haste", L.STAT_HASTE, L.STAT_HASTE_SHORT, { "ITEM_MOD_HASTE_RATING_SHORT", "ITEM_MOD_HASTE_SPELL_RATING_SHORT" }),
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

function F.RatingToPercent(stat, value)
    local info = F.STAT_INFO[stat]
    local r = rating(stat)
    if r > 0 then return value * info.percent() / r end
    return value / info.perPct
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
-- Items
--------------------------------------------------------------------------------
function F.GetItemLevel(link)
    if not link then return 0 end
    local getter = (C_Item and C_Item.GetDetailedItemLevelInfo) or GetDetailedItemLevelInfo
    local ilvl = getter and getter(link)
    if not ilvl then
        local info = (C_Item and C_Item.GetItemInfo) or GetItemInfo
        ilvl = info and select(4, info(link))
    end
    return ilvl or 0
end

-- No PLAYER_SPECIALIZATION_CHANGED here: refresh on a respec or a form change instead.
local events = CreateFrame("Frame")
for _, e in ipairs({ "CHARACTER_POINTS_CHANGED", "UPDATE_SHAPESHIFT_FORM", "PLAYER_TALENT_UPDATE" }) do
    pcall(events.RegisterEvent, events, e)
end
events:SetScript("OnEvent", function() if RS.Refresh then RS:Refresh() end end)
