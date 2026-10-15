-- RecommendedStats :: UI/TalentsWindowTBC.lua
-- TBC Anniversary talents: the logs only record the points spent in each tree, so this shows the
-- splits top players run (most common first, with how many run each) against your own. Loaded only
-- by RecommendedStats_TBC.toc (and the Era one later); retail has UI/TalentsWindow.lua.
--
-- Data (Data_TBC/Talents.lua, RecommendedStatsNode src/classic/build.js):
--   RecommendedStatsData_Talents[CLASS_SPEC_RAID] = {
--       n = players,
--       builds = { { split = { a, b, c }, pct }, ... },   most common first, up to 3
--       median = { a, b, c },
--   }

local RS = RecommendedStats
local L = RecommendedStats_Locale

local W, PAD, ROW_H = 400, 14, 26
local GOOD = { 0.35, 0.85, 0.4 }

local frame, titleText, headerCells, yoursRow, sampleText, emptyText
local buildRows = {}

-- One line: a label, then the three trees' points in fixed columns.
local function CreateLine(y, font)
    local row = CreateFrame("Frame", nil, frame)
    row:SetSize(W - PAD * 2, ROW_H)
    row:SetPoint("TOPLEFT", PAD, y)
    row.label = row:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    row.label:SetPoint("LEFT", 4, 0)
    row.label:SetWidth(130)
    row.label:SetJustifyH("LEFT")
    row.cells = {}
    for i = 1, 3 do
        local c = row:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
        c:SetPoint("LEFT", 140 + (i - 1) * 72, 0)
        c:SetWidth(68)
        c:SetJustifyH("CENTER")
        row.cells[i] = c
    end
    return row
end

local function EnsureFrame()
    if frame then return end
    frame = CreateFrame("Frame", "RecommendedStatsTalentsTBC", UIParent, "BackdropTemplate")
    frame:SetSize(W, 60 + ROW_H * 6 + 30)
    frame:SetFrameStrata("HIGH")
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    frame:SetBackdropColor(0.043, 0.047, 0.063, 0.97)
    local accent = RS:GetAccentColor()
    frame:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.7)
    RS:MakeMovable(frame, "talentsTBCPos", function()
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    end)
    tinsert(UISpecialFrames, "RecommendedStatsTalentsTBC")

    titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", PAD, -14)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    headerCells = CreateLine(-44, "GameFontNormalSmall")
    for i = 1, 3 do buildRows[i] = CreateLine(-44 - ROW_H * i) end
    yoursRow = CreateLine(-44 - ROW_H * 4 - 8)
    yoursRow.label:SetText(L.MISTS_TALENTS_YOURS)
    yoursRow.label:SetTextColor(GOOD[1], GOOD[2], GOOD[3])

    sampleText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sampleText:SetPoint("BOTTOMLEFT", PAD, 12)
    emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyText:SetPoint("CENTER")
    emptyText:SetText(L.MISTS_TALENTS_NONE)
    emptyText:Hide()

    frame:SetScript("OnShow", function() RS:RenderTalentsTBC() end)
end

function RS:RenderTalentsTBC()
    if not (frame and frame:IsShown()) then return end
    local Flavor = RS.Flavor
    titleText:SetText(L.MISTS_TALENTS_TITLE:format(Flavor.GetSpecName()))

    local trees = Flavor.GetTreePoints()
    headerCells.label:SetText("")
    for i = 1, 3 do headerCells.cells[i]:SetText(trees[i].name) end

    local key = RS:GetKeyFor("RAID")
    local data = key and RecommendedStatsData_Talents and RecommendedStatsData_Talents[key]
    local builds = data and data.builds or {}
    emptyText:SetShown(#builds == 0)
    sampleText:SetText(#builds > 0 and L.MISTS_TALENTS_SAMPLE:format(data.n or 0) or "")

    for i, row in ipairs(buildRows) do
        local b = builds[i]
        if b then
            row.label:SetText(L.TBC_TALENTS_BUILD:format(b.pct or 0))
            for t = 1, 3 do row.cells[t]:SetText(tostring(b.split[t] or 0)) end
            row:Show()
        else
            row:Hide()
        end
    end
    for t = 1, 3 do yoursRow.cells[t]:SetText(tostring(trees[t].points)) end
end

function RS:ToggleTalents()
    EnsureFrame()
    frame:SetShown(not frame:IsShown())
end

table.insert(RS.listeners, function() RS:RenderTalentsTBC() end)
local events = CreateFrame("Frame")
for _, e in ipairs({ "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE" }) do pcall(events.RegisterEvent, events, e) end
events:SetScript("OnEvent", function() RS:RenderTalentsTBC() end)

table.insert(RS.skinListeners, function(accent)
    if frame then frame:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.7) end
end)
