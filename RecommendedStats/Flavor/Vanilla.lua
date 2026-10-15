-- RecommendedStats :: Flavor/Vanilla.lua
-- The version layer for Classic Era and Season of Discovery (1.15.x), loaded by
-- RecommendedStats_Vanilla.toc in place of Flavor/Retail.lua. Both seasons run on this client;
-- Data_Vanilla and Data_SoD each only load on their own season (a check at the top of every data
-- file), so the rest of the addon never needs to know which one it is.
-- Differences from Retail.lua:
--   - Vanilla has no combat ratings: Hit and Crit come from item effects ("Equip: Improves your
--     chance to hit by 1%."). Targets are the Hit and Crit % top players' GEAR gave on their kill,
--     and your value is your gear's, summed the same way: the RecommendedStatsData_ItemEffects table
--     the build writes (every item top players wore), then the item's tooltip on English clients for
--     anything else. Talents, buffs, enchants, set bonuses and SoD runes aren't counted on either side.
--   - Casters and healers read spell hit/crit effects, everyone else melee/ranged.
--   - The spec is the talent tree with the most points (Feral in Bear Form is Guardian), the same
--     rule the build uses to key its players.
--   - Raid only, no Analyzer link, no secret values, a ranged slot in the BiS window.
-- ⚠ Not yet checked in a client. For testers: C_Seasons picking the right data on Era, Hardcore and
--   SoD realms, and the Hit/Crit rows matching the "Equip:" lines on your gear.

RecommendedStats = RecommendedStats or {}
local RS = RecommendedStats
local L = RecommendedStats_Locale

local F = { id = "VANILLA" }
RS.Flavor = F

F.CONTENTS = { "RAID" }
F.TARGET_UNIT = "percent"
F.MAX_ROWS = 2
F.HAS_ANALYZER = false
F.RANGED_SLOT = true
F.IsSecret = function() return false end

F.STATS = { "hit", "crit" }
F.ITEM_STATS = {} -- Vanilla items have no rating stats to read off for the BiS window

--------------------------------------------------------------------------------
-- Spec: the tree with the most points (same as Flavor/TBC.lua)
--------------------------------------------------------------------------------
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

local SPELL_SPECS = {
    MAGE_ARCANE = true, MAGE_FIRE = true, MAGE_FROST = true,
    WARLOCK_AFFLICTION = true, WARLOCK_DEMONOLOGY = true, WARLOCK_DESTRUCTION = true,
    PRIEST_DISCIPLINE = true, PRIEST_HOLY = true, PRIEST_SHADOW = true,
    DRUID_BALANCE = true, DRUID_RESTORATION = true,
    SHAMAN_ELEMENTAL = true, SHAMAN_RESTORATION = true, PALADIN_HOLY = true,
}

local function TabPoints(i)
    local a, b, c, d, e = GetTalentTabInfo(i)
    if type(a) == "string" then return c or 0, a end
    return e or 0, b
end

local BEAR_FORMS = { [5] = true, [8] = true }
local DEFENSIVE_STANCE = 18

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
    -- Most Era warrior tanks run a Fury-heavy tree; the data keeps them as Protection, so a warrior
    -- in Defensive Stance gets the tank data whatever the tree.
    if class == "WARRIOR" and GetShapeshiftFormID and GetShapeshiftFormID() == DEFENSIVE_STANCE then
        return "PROTECTION"
    end
    return token
end

function F.GetSpec()
    return MainTree()
end

function F.GetSpecName()
    local _, name = MainTree()
    if F.GetSpecToken() == "GUARDIAN" then return (name or "") .. " (" .. L.TBC_BEAR .. ")" end
    return name or ""
end

function F.GetTreePoints()
    local out = {}
    for i = 1, 3 do
        local ok, points, name = pcall(TabPoints, i)
        out[i] = { points = ok and points or 0, name = ok and name or ("#" .. i) }
    end
    return out
end

local function UsesSpell()
    local _, class = UnitClass("player")
    local spec = F.GetSpecToken()
    return spec and SPELL_SPECS[class .. "_" .. spec] or false
end

--------------------------------------------------------------------------------
-- Gear Hit and Crit
--------------------------------------------------------------------------------
-- h melee/ranged hit, sh spell hit, c physical crit, sc spell crit (as in the build's table).
local scanTip
local tooltipCache = {}

-- English tooltips only: the same "Equip:" phrases the build reads from Blizzard's item data.
local function TooltipEffects(itemID, link)
    if tooltipCache[itemID] then return tooltipCache[itemID] end
    if GetLocale() ~= "enUS" then return nil end
    scanTip = scanTip or CreateFrame("GameTooltip", "RecommendedStatsVanillaScan", nil, "GameTooltipTemplate")
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:ClearLines()
    if not pcall(scanTip.SetHyperlink, scanTip, link) then return nil end
    local fx = {}
    local function add(k, v) fx[k] = (fx[k] or 0) + tonumber(v) end
    for i = 1, scanTip:NumLines() do
        local line = _G["RecommendedStatsVanillaScanTextLeft" .. i]
        local t = line and line:GetText()
        t = t and t:lower()
        if t and t:find("^equip:") and not t:find("party member") and not t:find("raid member") then
            local v = t:match("chance to hit with all spells and attacks by (%d+)%%")
            if v then add("h", v); add("sh", v)
            else
                v = t:match("chance to hit with spells by (%d+)%%")
                if v then add("sh", v)
                else
                    v = t:match("chance to hit by (%d+)%%")
                    if v then add("h", v) end
                end
            end
            v = t:match("critical strike with all spells and attacks by (%d+)%%")
            if v then add("c", v); add("sc", v)
            else
                v = t:match("critical strike with spells by (%d+)%%")
                if v then add("sc", v)
                else
                    v = t:match("chance to get a critical strike by (%d+)%%")
                    if v then add("c", v) end
                end
            end
        end
    end
    tooltipCache[itemID] = fx
    return fx
end

local function ItemEffects(slot)
    local id = GetInventoryItemID("player", slot)
    if not id then return nil end
    local effects = RecommendedStatsData_ItemEffects
    local fx = effects and (effects[tostring(id)] or effects[id])
    if fx then return fx end
    local link = GetInventoryItemLink("player", slot)
    return link and TooltipEffects(id, link)
end

-- Your gear's Hit and Crit %, spell or physical to suit your spec.
local function GearStats()
    local h, sh, c, sc = 0, 0, 0, 0
    for slot = 1, 18 do
        if slot ~= 4 then -- shirt
            local fx = ItemEffects(slot)
            if fx then
                h, sh, c, sc = h + (fx.h or 0), sh + (fx.sh or 0), c + (fx.c or 0), sc + (fx.sc or 0)
            end
        end
    end
    if UsesSpell() then return { hit = sh, crit = sc } end
    return { hit = h, crit = c }
end

F.STAT_INFO = {
    hit = { label = L.STAT_HIT_GEAR, short = L.STAT_HIT_SHORT, itemKeys = {}, percent = function() return GearStats().hit end },
    crit = { label = L.STAT_CRIT_GEAR, short = L.STAT_CRIT_SHORT, itemKeys = {}, percent = function() return GearStats().crit end },
}

function F.ReadStats()
    return GearStats()
end

-- No ratings in Vanilla: the panel shows percent only.
function F.ReadRatings()
    return {}
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

local events = CreateFrame("Frame")
for _, e in ipairs({ "CHARACTER_POINTS_CHANGED", "UPDATE_SHAPESHIFT_FORM", "PLAYER_TALENT_UPDATE" }) do
    pcall(events.RegisterEvent, events, e)
end
events:SetScript("OnEvent", function() if RS.Refresh then RS:Refresh() end end)
