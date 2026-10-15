-- RecommendedStats :: UI/TalentsWindowMists.lua
-- MoP Classic talents: one pick in each of six tiers (levels 15 to 90) plus glyphs, so no tree to
-- draw. Each tier shows what most top players picked on their best ranked kill, the runner-up, and
-- marks the player's own pick. Loaded only by RecommendedStats_Mists.toc; retail has
-- UI/TalentsWindow.lua (C_Traits loadouts) instead.
--
-- Data (Data_Mists/Talents.lua, RecommendedStatsNode src/classic/build.js):
--   RecommendedStatsData_Talents[CLASS_SPEC_RAID] = {
--       n = players,
--       tiers = { { spellID, pct, altSpellID?, altPct? } x6 },   in tier order
--       glyphs = { { spellID, pct }, ... },                       most used first
--   }
-- "Yours" is IsPlayerSpell on the tier's spell: a chosen talent is a known spell, which needs no
-- talent-API version differences. Glyphs aren't marked (no equally simple check).

local RS = RecommendedStats
local L = RecommendedStats_Locale

local W, PAD = 440, 14
local TIER_H, GLYPH_H = 44, 22
local TIER_LEVELS = { 15, 30, 45, 60, 75, 90 }
local GOOD = { 0.35, 0.85, 0.4 }
local DIM = { 0.6, 0.6, 0.6 }

local frame, titleText, sampleText, emptyText, glyphHeader
local tierRows, glyphRows = {}, {}

local function SpellNameIcon(id)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(id), C_Spell.GetSpellTexture(id)
    end
    local name, _, icon = GetSpellInfo(id)
    return name, icon
end

local function ShowSpellTip(owner, spellID)
    if not spellID then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(spellID)
    GameTooltip:Show()
end

local function CreateTierRow(i)
    local row = CreateFrame("Frame", nil, frame)
    row:SetSize(W - PAD * 2, TIER_H)
    row:SetPoint("TOPLEFT", PAD, -46 - (i - 1) * (TIER_H + 4))

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(1, 1, 1, 0.03)

    row.level = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.level:SetPoint("LEFT", 6, 0)
    row.level:SetWidth(52)
    row.level:SetJustifyH("LEFT")
    row.level:SetText(L.MISTS_TALENTS_TIER:format(TIER_LEVELS[i]))

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(32, 32)
    row.icon:SetPoint("LEFT", row.level, "RIGHT", 4, 0)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, -1)
    row.name:SetJustifyH("LEFT")

    row.pct = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.pct:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 8, 1)
    row.pct:SetJustifyH("LEFT")

    row.yours = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.yours:SetPoint("LEFT", row.name, "RIGHT", 6, 0)
    row.yours:SetTextColor(GOOD[1], GOOD[2], GOOD[3])
    row.yours:SetText(L.MISTS_TALENTS_YOURS)

    row.alt = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.alt:SetPoint("RIGHT", -8, 0)
    row.alt:SetJustifyH("RIGHT")

    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self) ShowSpellTip(self, self.spellID) end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return row
end

local function CreateGlyphRow(i)
    local row = CreateFrame("Frame", nil, frame)
    local colW = (W - PAD * 2 - 8) / 2
    row:SetSize(colW, GLYPH_H)
    local col, line = (i - 1) % 2, math.floor((i - 1) / 2)
    row:SetPoint("TOPLEFT", glyphHeader, "BOTTOMLEFT", col * (colW + 8), -6 - line * (GLYPH_H + 2))

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(18, 18)
    row.icon:SetPoint("LEFT", 2, 0)

    row.pct = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.pct:SetPoint("RIGHT", -4, 0)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.name:SetPoint("RIGHT", row.pct, "LEFT", -6, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)

    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self) ShowSpellTip(self, self.spellID) end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return row
end

local function EnsureFrame()
    if frame then return end
    frame = CreateFrame("Frame", "RecommendedStatsTalentsMists", UIParent, "BackdropTemplate")
    frame:SetSize(W, 46 + 6 * (TIER_H + 4) + 30 + 4 * (GLYPH_H + 2) + 40)
    frame:SetFrameStrata("HIGH")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1,
    })
    frame:SetBackdropColor(0.043, 0.047, 0.063, 0.97)
    local accent = RS:GetAccentColor()
    frame:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.7)

    RS:MakeMovable(frame, "talentsMistsPos", function()
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    end)
    tinsert(UISpecialFrames, "RecommendedStatsTalentsMists")

    titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", PAD, -14)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    for i = 1, 6 do tierRows[i] = CreateTierRow(i) end

    glyphHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    glyphHeader:SetPoint("TOPLEFT", tierRows[6], "BOTTOMLEFT", 0, -14)
    glyphHeader:SetText(L.MISTS_TALENTS_GLYPHS)
    for i = 1, 8 do glyphRows[i] = CreateGlyphRow(i) end

    sampleText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sampleText:SetPoint("BOTTOMLEFT", PAD, 12)

    emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyText:SetPoint("CENTER")
    emptyText:SetText(L.MISTS_TALENTS_NONE)
    emptyText:Hide()

    frame:SetScript("OnShow", function() RS:RenderTalentsMists() end)
end

function RS:RenderTalentsMists()
    if not (frame and frame:IsShown()) then return end
    titleText:SetText(L.MISTS_TALENTS_TITLE:format(RS.Flavor.GetSpecName()))

    local key = RS:GetKeyFor("RAID")
    local data = key and RecommendedStatsData_Talents and RecommendedStatsData_Talents[key]
    local has = data and data.tiers and #data.tiers > 0
    emptyText:SetShown(not has)
    glyphHeader:SetShown(has)
    sampleText:SetText(has and L.MISTS_TALENTS_SAMPLE:format(data.n or 0) or "")

    for i, row in ipairs(tierRows) do
        local tier = has and data.tiers[i]
        if tier and tier.spellID then
            local name, icon = SpellNameIcon(tier.spellID)
            row.spellID = tier.spellID
            row.icon:SetTexture(icon or 134400)
            row.name:SetText(name or ("#" .. tier.spellID))
            row.pct:SetText(L.MISTS_TALENTS_PICK:format(tier.pct or 0))
            row.yours:SetShown(IsPlayerSpell and IsPlayerSpell(tier.spellID) or false)
            if tier.altSpellID then
                local altName = SpellNameIcon(tier.altSpellID)
                local altMine = IsPlayerSpell and IsPlayerSpell(tier.altSpellID)
                row.alt:SetText(L.MISTS_TALENTS_ALT:format(altName or ("#" .. tier.altSpellID), tier.altPct or 0))
                local c = altMine and GOOD or DIM
                row.alt:SetTextColor(c[1], c[2], c[3])
            else
                row.alt:SetText("")
            end
            row:Show()
        else
            row.spellID = nil
            row:Hide()
        end
    end

    for i, row in ipairs(glyphRows) do
        local g = has and data.glyphs and data.glyphs[i]
        if g and g.spellID then
            local name, icon = SpellNameIcon(g.spellID)
            row.spellID = g.spellID
            row.icon:SetTexture(icon or 134400)
            row.name:SetText(name or ("#" .. g.spellID))
            row.pct:SetText(("%d%%"):format(g.pct or 0))
            row:Show()
        else
            row.spellID = nil
            row:Hide()
        end
    end
end

function RS:ToggleTalents()
    EnsureFrame()
    frame:SetShown(not frame:IsShown())
end

-- Spec, talent and spell-data changes while it's open.
table.insert(RS.listeners, function() RS:RenderTalentsMists() end)
local events = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_TALENT_UPDATE", "SPELLS_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED" }) do
    pcall(events.RegisterEvent, events, e)
end
events:SetScript("OnEvent", function() RS:RenderTalentsMists() end)

table.insert(RS.skinListeners, function(accent)
    if frame then frame:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.7) end
end)
