-- RecommendedStats :: UI/TalentsWindow.lua
-- One window (opened by the "Talents" button on the main panel, or /rs talents) with a Raid /
-- Mythic+ toggle, a boss-or-dungeon dropdown, and the talent tree itself: class, hero and spec
-- trees laid out with the game's own node coordinates, the best-matching real top-player build
-- highlighted in gold, per-talent pick rates in the tooltips, and a button to copy the loadout
-- string for importing. Talents.lua does the data work.
-- Separate from the main panel because the tree needs roughly 900px of width. Deliberately does
-- not touch Blizzard's talent frame (no tab injection), so it can't taint it or collide with other
-- addons that extend it.

local RS = RecommendedStats
local L = RecommendedStats_Locale

--------------------------------------------------------------------------------
-- Shared bits
--------------------------------------------------------------------------------
local GOLD           = { 1, 0.82, 0.2 }
local GREY           = { 0.28, 0.29, 0.33 }
local DIM            = { 0.62, 0.62, 0.66 }
local LINE_ON        = { 1, 0.82, 0.2, 0.85 }
local LINE_OFF       = { 0.45, 0.46, 0.5, 0.35 }
local DEFAULT_BORDER = { 0.25, 0.27, 0.33 }
local TAB_ACTIVE_BG  = { 0.16, 0.17, 0.22, 1 }
local TAB_IDLE_BG    = { 0.043, 0.047, 0.063, 1 }

local function BorderColor()
    if RS:GetSkin() == "DEFAULT" then return DEFAULT_BORDER end
    return RS:GetAccentColor()
end

local function StyleBackdrop(frame)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    frame:SetBackdropColor(0.043, 0.047, 0.063, 0.97)
    local b = BorderColor()
    frame:SetBackdropBorderColor(b[1], b[2], b[3], 0.7)
end

local function SpellName(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(spellID) end
    return (GetSpellInfo and GetSpellInfo(spellID)) or nil
end

-- { icon=fileID | atlas=name, spellID=, name= } for one trait entry, or nil.
local function EntryVisual(configID, entryID)
    local entryInfo = entryID and C_Traits.GetEntryInfo(configID, entryID)
    if not entryInfo then return nil end

    -- Hero-tree selection node: its entries are the hero sub-trees, not spells.
    if entryInfo.subTreeID and entryInfo.subTreeID ~= 0 and C_Traits.GetSubTreeInfo then
        local st = C_Traits.GetSubTreeInfo(configID, entryInfo.subTreeID)
        if st then return { atlas = st.iconElementID, name = st.name } end
    end

    local def = entryInfo.definitionID and C_Traits.GetDefinitionInfo(entryInfo.definitionID)
    if not def then return nil end
    local spellID = def.overriddenSpellID or def.spellID
    local icon = def.overrideIcon
    if not icon and spellID and C_Spell and C_Spell.GetSpellTexture then icon = C_Spell.GetSpellTexture(spellID) end
    return { icon = icon, spellID = spellID, name = def.overrideName or SpellName(spellID) }
end

local function Percent(count, total)
    if not total or total == 0 then return 0 end
    return math.floor(count / total * 100 + 0.5)
end

local function SourceLine(resolved)
    if resolved.scoped then
        if resolved.current then
            if resolved.content == "RAID" then
                return L.TALENTS_SRC_CURRENT_RAID:format(L.TALENTS_DIFFICULTY[resolved.difficulty] or resolved.difficulty or "?")
            end
            return L.TALENTS_SRC_CURRENT_DUNGEON
        end
        if resolved.content == "RAID" then
            local diff = L.TALENTS_DIFFICULTY[resolved.difficulty] or resolved.difficulty or "?"
            if resolved.difficulty == nil or resolved.difficulty == "mythic" then return L.TALENTS_SRC_RAID:format(diff) end
            return L.TALENTS_SRC_RAID_LOWER:format(diff)
        end
        return L.TALENTS_SRC_DUNGEON
    end
    return resolved.fellBack and L.TALENTS_SRC_FALLBACK or L.TALENTS_SRC_OVERALL
end

--------------------------------------------------------------------------------
-- What the window is showing (persisted per content: a boss slug means nothing under M+)
--------------------------------------------------------------------------------
-- Independent of the stats panel's Raid/Mythic+ setting (browsing dungeon talents shouldn't flip
-- a player's stat targets over), but starts from it the first time.
local function GetContent()
    RecommendedStatsDB = RecommendedStatsDB or {}
    return RecommendedStatsDB.talentsContent or RS:GetContent()
end
local function SetContent(content)
    RecommendedStatsDB = RecommendedStatsDB or {}
    RecommendedStatsDB.talentsContent = content
end

-- Stored scope, validated against what the data actually has now (a data update can drop a
-- boss/dungeon), falling back to Overall. Returns the entry: { value=, name=, dedicated= }.
local function GetEntry(content)
    RecommendedStatsDB = RecommendedStatsDB or {}
    local wanted = RecommendedStatsDB.talentsScope and RecommendedStatsDB.talentsScope[content]
    local entries = RS:GetTalentEntries(content)
    for _, e in ipairs(entries) do
        if e.value == wanted then return e, entries end
    end
    return entries[1], entries
end
local function SetScope(content, scope)
    RecommendedStatsDB = RecommendedStatsDB or {}
    RecommendedStatsDB.talentsScope = RecommendedStatsDB.talentsScope or {}
    RecommendedStatsDB.talentsScope[content] = scope
end

-- Dropdown text: dimmed-down wording for entries that would only show the overall build, and the
-- difficulty for raid bosses that fell back below Mythic.
local function EntryLabel(content, e)
    if e.value == "OVERALL" then return e.name end
    if not e.dedicated then return L.TALENTS_SCOPE_FALLBACK:format(e.name) end
    if content == "RAID" then
        local r = RS:ResolveTalentBuilds(content, e.value)
        if r and r.scoped and r.difficulty and r.difficulty ~= "mythic" then
            return L.TALENTS_SCOPE_DIFFICULTY:format(e.name, L.TALENTS_DIFFICULTY[r.difficulty] or r.difficulty)
        end
    end
    return e.name
end

-- Everything the tree and the copy button need, or nil + a reason to show in the window.
local function BuildCurrent(content, entry)
    local resolved = RS:ResolveTalentBuilds(content, entry.value)
    if not resolved then return nil, L.TALENTS_NO_DATA end
    local tree = RS:GetTalentTreeInfo()
    if not tree then return nil, L.TALENTS_NOT_READY end
    local stats = RS:GetTalentStats(resolved, tree)
    if not stats then return nil, L.TALENTS_DECODE_FAILED end

    local _, specName = GetSpecializationInfoByID(tree.specID)
    return {
        content = content, entry = entry, resolved = resolved, tree = tree, stats = stats,
        title = L.TALENTS_TREE_TITLE:format(specName or "", entry.name),
        subtitle = SourceLine(resolved) .. "  |  " .. L.TALENTS_SAMPLE:format(stats.total, stats.distinct),
    }
end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------
local CANVAS_W, CANVAS_H, PAD = 928, 510, 26
local CONTROLS_H = 34

local frame, titleText, subtitleText, messageText, copyBtn, scopeDropdown, canvas, toggleBtns
local nodePool, linePool = {}, {}
local current -- BuildCurrent's result for whatever is displayed right now, nil when showing a message

local CONTENT_CHOICES = {
    { value = "RAID",       text = L.CONTENT_RAID },
    { value = "MYTHICPLUS", text = L.CONTENT_MYTHICPLUS },
}

local function NodeOnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self.spellID then
        GameTooltip:SetSpellByID(self.spellID)
    else
        GameTooltip:SetText(self.talentName or "?", 1, 1, 1)
    end

    local stats = current and current.stats
    if stats then
        GameTooltip:AddLine(" ")
        local n = stats.nodeCounts[self.nodeID] or 0
        GameTooltip:AddLine(L.TALENTS_PICKED_BY:format(Percent(n, stats.total), n, stats.total), GOLD[1], GOLD[2], GOLD[3])
        if self.options and #self.options > 1 then
            local pc = stats.pickCounts[self.nodeID] or {}
            for i, name in ipairs(self.options) do
                GameTooltip:AddLine(L.TALENTS_OPTION_PICKED_BY:format(name, Percent(pc[i - 1] or 0, stats.total)), 0.8, 0.8, 0.8)
            end
        end
    end
    GameTooltip:Show()
end

local function AcquireNode(i)
    local b = nodePool[i]
    if b then return b end
    b = CreateFrame("Frame", nil, canvas)
    b:EnableMouse(true)
    b.border = b:CreateTexture(nil, "BACKGROUND")
    b.border:SetAllPoints()
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", 2, -2)
    b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    b.rank = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.rank:SetPoint("BOTTOMRIGHT", 4, -4)
    b:SetScript("OnEnter", NodeOnEnter)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    nodePool[i] = b
    return b
end

local function AcquireLine(i)
    local ln = linePool[i]
    if ln then return ln end
    ln = canvas:CreateLine(nil, "BACKGROUND")
    ln:SetThickness(2)
    linePool[i] = ln
    return ln
end

local function HideTree()
    for _, b in ipairs(nodePool) do b:Hide() end
    for _, ln in ipairs(linePool) do ln:Hide() end
end

local function RenderTree()
    local tree, stats = current.tree, current.stats
    local sel = stats.best.sel

    -- Node info once per node. The hero tree holds every hero sub-tree's nodes, so work out which
    -- sub-tree this build actually uses and drop the rest. selectionNodeID is the hero-tree
    -- selection node: the one node whose ENTRIES are the hero sub-trees themselves (same test
    -- EntryVisual uses), so the entry a build picked on it is the authoritative answer.
    local infos, selectionNodeID = {}, nil
    for _, nodeID in ipairs(tree.nodeIDs) do
        local info = C_Traits.GetNodeInfo(tree.configID, nodeID)
        if info and info.ID == nodeID then
            infos[nodeID] = info
            if not selectionNodeID and info.entryIDs and info.entryIDs[1] then
                local first = C_Traits.GetEntryInfo(tree.configID, info.entryIDs[1])
                if first and first.subTreeID and first.subTreeID ~= 0 then selectionNodeID = nodeID end
            end
        end
    end

    local chosenSub
    local selRec = selectionNodeID and sel[selectionNodeID]
    if selRec then
        local entryID = infos[selectionNodeID].entryIDs[(selRec.pick or 0) + 1]
        local entry = entryID and C_Traits.GetEntryInfo(tree.configID, entryID)
        if entry and entry.subTreeID and entry.subTreeID ~= 0 then chosenSub = entry.subTreeID end
    end
    if not chosenSub then
        -- No usable selection node: fall back to the first selected node tagged with a sub-tree. This
        -- alone used to be the ONLY method and picked the wrong hero tree (a Lightsmith build drew
        -- Herald of the Sun's nodes, all grey) — reported 2026-09-26 on a Holy Paladin's M+ builds.
        -- Suspected cause (unverified): a node reads back tagged with the sub-tree active on the
        -- VIEWING character's own config rather than the build's. Only a last resort now.
        for _, nodeID in ipairs(tree.nodeIDs) do
            local info = infos[nodeID]
            if info and sel[nodeID] and info.subTreeID and info.subTreeID ~= 0 then chosenSub = info.subTreeID; break end
        end
    end

    -- Class + spec nodes (subTreeID 0) drive the main layout below. The chosen hero sub-tree's
    -- nodes are tracked separately — see the scale/offset comment for why they get their own
    -- local layout instead of sharing this one.
    local mainShown, heroShown = {}, {}
    local minX, maxX, minY, maxY
    local heroMinX, heroMaxX, heroMinY, heroMaxY
    for _, nodeID in ipairs(tree.nodeIDs) do
        local info = infos[nodeID]
        local sub = info and info.subTreeID or 0
        -- The selection node is placed separately (above the hero tree, see below): its raw position
        -- sits in the gap between the class and spec trees, which both skewed the layout box and
        -- split that gap in two, throwing off where the hero tree gets centred.
        if info and nodeID ~= selectionNodeID then
            if sub == 0 then
                if info.isVisible ~= false then
                    mainShown[#mainShown + 1] = nodeID
                    minX = minX and math.min(minX, info.posX) or info.posX
                    maxX = maxX and math.max(maxX, info.posX) or info.posX
                    minY = minY and math.min(minY, info.posY) or info.posY
                    maxY = maxY and math.max(maxY, info.posY) or info.posY
                end
            elseif sub == chosenSub then
                -- No isVisible check here: the game may flag the nodes of a hero tree the viewing
                -- character hasn't picked as not visible (unverified), which would blank a build
                -- whose hero tree differs from the player's own.
                heroShown[#heroShown + 1] = nodeID
                heroMinX = heroMinX and math.min(heroMinX, info.posX) or info.posX
                heroMaxX = heroMaxX and math.max(heroMaxX, info.posX) or info.posX
                heroMinY = heroMinY and math.min(heroMinY, info.posY) or info.posY
                heroMaxY = heroMaxY and math.max(heroMaxY, info.posY) or info.posY
            end
        end
    end
    if #mainShown == 0 then return end

    -- Game coordinates: posY grows DOWNWARD (verified live 2026-09-22 — a Holy Paladin's entry
    -- nodes sit at the lowest posY, its capstones at the highest, opposite what an earlier
    -- comment here assumed and which rendered every tree upside down), so no flip is needed, just
    -- offset by minY.
    --
    -- Scale/offset come from the class+spec nodes ONLY, not the hero sub-tree — this used to
    -- include hero too, on the assumption its raw coordinates already sit in a clean centre
    -- column between class and spec the way the game's own UI shows it. Reported 2026-09-22 on a
    -- Death Knight San'Layn build: San'Layn's raw X range actually overlaps Blood's spec-tree
    -- range rather than sitting in the gap between Death Knight and Blood, so it rendered on top
    -- of the spec tree instead of beside it. The hero tree is placed below using its own local
    -- shape, centred on the real empty gap this box has between the class and spec trees (gapX),
    -- instead of trusting its raw coordinates.
    local rangeX, rangeY = math.max(maxX - minX, 1), math.max(maxY - minY, 1)
    local scale = math.min((CANVAS_W - 2 * PAD) / rangeX, (CANVAS_H - 2 * PAD) / rangeY)
    local offX = (CANVAS_W - 2 * PAD - rangeX * scale) / 2
    local offY = (CANVAS_H - 2 * PAD - rangeY * scale) / 2
    local size = math.max(18, math.min(38, 600 * scale * 0.78)) -- nodes sit ~600 units apart

    -- Largest gap between consecutive distinct X values among the class+spec nodes, in the same
    -- screen-space X the loop below places them in — the empty band between the class tree's
    -- right edge and the spec tree's left edge, which is where the hero tree belongs.
    local gapX = CANVAS_W / 2
    do
        local xs = {}
        for _, nodeID in ipairs(mainShown) do xs[#xs + 1] = infos[nodeID].posX end
        table.sort(xs)
        local bestGap
        for i = 2, #xs do
            local gap, mid = xs[i] - xs[i - 1], (xs[i] + xs[i - 1]) / 2
            if not bestGap or gap > bestGap then
                bestGap = gap
                gapX = PAD + offX + (mid - minX) * scale
            end
        end
    end

    local displayed, used = {}, 0
    local function PlaceNode(nodeID, screenX, screenY)
        used = used + 1
        local info, rec = infos[nodeID], sel[nodeID]
        local b = AcquireNode(used)
        b:SetSize(size, size)
        b:ClearAllPoints()
        b:SetPoint("CENTER", canvas, "TOPLEFT", screenX, -screenY)
        b.nodeID = nodeID

        -- Which entry to draw: the one this build picked on a choice node, otherwise the first.
        local entryID = info.entryIDs and info.entryIDs[(rec and rec.pick or 0) + 1]
        local vis = EntryVisual(tree.configID, entryID) or {}
        b.spellID, b.talentName = vis.spellID, vis.name

        b.options = nil
        if info.entryIDs and #info.entryIDs > 1 then
            b.options = {}
            for i, eid in ipairs(info.entryIDs) do
                local v = EntryVisual(tree.configID, eid)
                b.options[i] = v and v.name or "?"
            end
        end

        if vis.atlas then
            b.icon:SetTexture(nil)
            b.icon:SetAtlas(vis.atlas)
        else
            b.icon:SetTexture(vis.icon or 134400)
            b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end

        local col = rec and GOLD or GREY
        b.border:SetColorTexture(col[1], col[2], col[3], 1)
        b.icon:SetDesaturated(not rec)
        b.icon:SetAlpha(rec and 1 or 0.55)

        local maxRanks = info.maxRanks or 1
        if rec and maxRanks > 1 then
            b.rank:SetText(("%d/%d"):format(rec.ranks or maxRanks, maxRanks))
            b.rank:Show()
        else
            b.rank:Hide()
        end
        b:Show()
        displayed[nodeID] = b
    end

    for _, nodeID in ipairs(mainShown) do
        local info = infos[nodeID]
        PlaceNode(nodeID, PAD + offX + (info.posX - minX) * scale, PAD + offY + (info.posY - minY) * scale)
    end

    local shown = {}
    for _, nodeID in ipairs(mainShown) do shown[#shown + 1] = nodeID end

    if #heroShown > 0 then
        -- Hero tree's own local shape, scaled the same as class/spec for a consistent icon size,
        -- centred horizontally on gapX and vertically on the class/spec trees' midline — matching
        -- how the game's own UI centres the compact hero diamond between the two full trees.
        local heroCenterX = (heroMinX + heroMaxX) / 2
        local heroCenterY = (heroMinY + heroMaxY) / 2
        local mainCenterScreenY = PAD + offY + (rangeY * scale) / 2
        for _, nodeID in ipairs(heroShown) do
            local info = infos[nodeID]
            PlaceNode(nodeID,
                gapX + (info.posX - heroCenterX) * scale,
                mainCenterScreenY + (info.posY - heroCenterY) * scale)
            shown[#shown + 1] = nodeID
        end

        -- The hero selection node (its icon is the chosen hero tree) sits centred just above the
        -- hero tree, like the emblem above the hero panel in the game's own talent frame.
        if selectionNodeID then
            local heroTopY = mainCenterScreenY + (heroMinY - heroCenterY) * scale
            PlaceNode(selectionNodeID, gapX, math.max(size, heroTopY - size * 1.6))
            shown[#shown + 1] = selectionNodeID
        end
    end

    for i = used + 1, #nodePool do nodePool[i]:Hide() end

    local lineCount = 0
    for _, nodeID in ipairs(shown) do
        for _, edge in ipairs(infos[nodeID].visibleEdges or {}) do
            local to = displayed[edge.targetNode]
            if to then
                lineCount = lineCount + 1
                local ln = AcquireLine(lineCount)
                local c = (sel[nodeID] and sel[edge.targetNode]) and LINE_ON or LINE_OFF
                ln:SetColorTexture(c[1], c[2], c[3], c[4])
                ln:SetStartPoint("CENTER", displayed[nodeID], 0, 0)
                ln:SetEndPoint("CENTER", to, 0, 0)
                ln:Show()
            end
        end
    end
    for i = lineCount + 1, #linePool do linePool[i]:Hide() end
end

-- Rebuilds everything from the stored content + scope: toggle look, dropdown text, header lines,
-- then either the tree or a message when there's nothing to draw.
-- fromMenu is true only for the scope dropdown's own radio click, which is mid-menu and must not
-- rebuild the menu it is closing.
local function Refresh(fromMenu)
    if not (frame and frame:IsShown()) then return end
    local content = GetContent()
    local entry = GetEntry(content)

    -- The dropdown's shown text comes from whichever radio the menu last marked selected, and the
    -- menu is only built from GetContent()'s entries when it is (re)generated — so after a Raid /
    -- Mythic+ toggle (or a spec change, which changes which entries have data) it kept showing the
    -- old content's selection, e.g. a dungeon's name while Raid was up. SetDefaultText below does
    -- not override a selected radio.
    if not fromMenu and scopeDropdown.GenerateMenu then scopeDropdown:GenerateMenu() end

    local accent = RS:GetAccentColor()
    for _, btn in ipairs(toggleBtns) do
        local active = btn.value == content
        btn.bg:SetColorTexture(unpack(active and TAB_ACTIVE_BG or TAB_IDLE_BG))
        local c = active and accent or DIM
        btn.label:SetTextColor(c[1], c[2], c[3])
    end
    scopeDropdown:SetDefaultText(EntryLabel(content, entry))

    local built, reason = BuildCurrent(content, entry)
    if not built then
        current = nil
        HideTree()
        titleText:SetText(entry.name)
        subtitleText:SetText("")
        messageText:SetText(reason)
        messageText:Show()
        copyBtn:Disable()
        return
    end

    current = built
    messageText:Hide()
    copyBtn:Enable()
    titleText:SetText(built.title)
    subtitleText:SetText(built.subtitle)
    RenderTree()
end

local function EnsureWindow()
    if frame then return end

    frame = CreateFrame("Frame", "RecommendedStatsTalents", UIParent, "BackdropTemplate")
    frame:SetSize(CANVAS_W + 32, CANVAS_H + 118 + CONTROLS_H)
    -- Above the character sheet (DIALOG sits over HIGH and below), with SetToplevel + Raise()
    -- below bringing it to the front whenever it's opened or clicked. Not FULLSCREEN_DIALOG:
    -- Blizzard's dropdown menu opens on a lower layer than that, so the scope menu rendered
    -- behind this window. The copy popup (UI/CopyPopup.lua) stays higher than both.
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    StyleBackdrop(frame)
    RS:MakeMovable(frame, "talentsPos", function()
        frame:ClearAllPoints()
        frame:SetPoint("CENTER")
    end)
    tinsert(UISpecialFrames, "RecommendedStatsTalents")

    titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", 16, -14)

    subtitleText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitleText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -4)

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", subtitleText, "BOTTOMLEFT", 0, -4)
    hint:SetText(L.TALENTS_TREE_HINT)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    -- Controls row: Raid / Mythic+ toggle, boss-or-dungeon dropdown, copy button.
    local controlsY = -66
    toggleBtns = {}
    local toggleW = 96
    for i, choice in ipairs(CONTENT_CHOICES) do
        local btn = CreateFrame("Button", nil, frame)
        btn.value = choice.value
        btn:SetSize(toggleW, 24)
        btn:SetPoint("TOPLEFT", 16 + (i - 1) * (toggleW + 4), controlsY)
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.label:SetPoint("CENTER")
        btn.label:SetText(choice.text)
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.06)
        btn:SetScript("OnClick", function(self)
            SetContent(self.value)
            Refresh()
        end)
        toggleBtns[i] = btn
    end

    scopeDropdown = CreateFrame("DropdownButton", "RecommendedStatsTalentsScope", frame, "WowStyle1DropdownTemplate")
    scopeDropdown:SetWidth(320)
    scopeDropdown:SetPoint("TOPLEFT", 16 + 2 * (toggleW + 4) + 12, controlsY + 2)
    scopeDropdown:SetupMenu(function(_, root)
        local content = GetContent()
        for _, e in ipairs(RS:GetTalentEntries(content)) do
            root:CreateRadio(
                EntryLabel(content, e),
                function() return GetEntry(content).value == e.value end,
                function()
                    SetScope(content, e.value)
                    Refresh(true)
                    -- MenuResponse.Refresh was meant to redraw the already-open menu with the new
                    -- selection, but in practice the radio dot never moved until the menu was
                    -- closed and reopened (reported 2026-09-22, and still true after making the
                    -- isSelected check above read live state instead of a stale snapshot — so
                    -- Refresh isn't re-running these checks against an open menu the way it was
                    -- assumed to). Closing on select sidesteps that: it's the one state we've
                    -- confirmed always renders correctly.
                    return MenuResponse.Close
                end
            )
        end
    end)

    copyBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    copyBtn:SetSize(170, 24)
    copyBtn:SetPoint("TOPRIGHT", -16, controlsY)
    copyBtn:SetText(L.TALENTS_COPY_LONG)
    copyBtn:SetScript("OnClick", function()
        if not current then return end
        RS:ShowCopyPopup({ title = L.TALENTS_COPY_TITLE, hint = L.TALENTS_COPY_HINT, text = current.stats.best.code })
    end)

    canvas = CreateFrame("Frame", nil, frame)
    canvas:SetSize(CANVAS_W, CANVAS_H)
    canvas:SetPoint("BOTTOMLEFT", 16, 16)

    messageText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    messageText:SetPoint("CENTER", canvas, "CENTER")
    messageText:SetWidth(500)
    messageText:Hide()

    frame:SetScript("OnShow", function(self)
        self:Raise()
        Refresh()
    end)

    -- CreateFrame returns a SHOWN frame. Without this, the first ToggleTalents() call sees
    -- IsShown() == true right after creation and hides it again, so the first click on the
    -- Talents button appeared to do nothing until it was clicked a second time.
    frame:Hide()
end

function RS:ToggleTalents()
    EnsureWindow()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

--------------------------------------------------------------------------------
-- Keeping an open window correct
--------------------------------------------------------------------------------
-- A spec change swaps the whole tree and the data key. Delayed a beat: the new spec's talent
-- config isn't always ready the instant the event fires.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
events:SetScript("OnEvent", function()
    C_Timer.After(0.5, Refresh)
end)

table.insert(RS.skinListeners, function()
    if frame then
        StyleBackdrop(frame)
        Refresh()
    end
end)
