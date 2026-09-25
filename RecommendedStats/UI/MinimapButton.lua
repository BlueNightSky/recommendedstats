-- RecommendedStats :: UI/MinimapButton.lua
-- Minimap button via LibDataBroker-1.1 + LibDBIcon-1.0 (Libs\Libs.xml) rather than a hand-rolled
-- frame — this is the convention minimap-button-organizer addons (Bartender4's collector,
-- standalone "hide minimap buttons" addons, etc.) actually detect and manage, which a fully
-- custom button never gets picked up by.
--
-- Depends on Core.lua providing:
--   RS:TogglePanelsShown() / RS:OpenOptions() (UI/OptionsPanel.lua)
--   RS:GetShowMinimapIcon() -- initial shown state; RS:SetShowMinimapIcon() (Core.lua) toggles
--     the button directly via RS.minimapButton once this file has set it below
--   RS.skinListeners (table) -- re-tints the icon on a skin change

local RS = RecommendedStats
local L = RecommendedStats_Locale

local LDB = LibStub("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")

local dataObject = LDB:NewDataObject("RecommendedStats", {
    type = "launcher",
    icon = "Interface\\AddOns\\RecommendedStats\\icon",
    OnClick = function(_, mouseButton)
        if mouseButton == "RightButton" then
            if RS.OpenOptions then RS:OpenOptions() end
        else
            RS:TogglePanelsShown()
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine(L.ADDON_TITLE)
        tooltip:AddLine(L.MINIMAP_TOOLTIP_LEFT, 0.9, 0.9, 0.9)
        tooltip:AddLine(L.MINIMAP_TOOLTIP_RIGHT, 0.9, 0.9, 0.9)
    end,
})

-- LibDBIcon reads/writes this table itself (minimapPos, hide) — handing it the per-character
-- table (RecommendedStatsDBChar, ## SavedVariablesPerCharacter in the .toc) is what makes the
-- button's dragged position per-character rather than shared account-wide.
RecommendedStatsDBChar = RecommendedStatsDBChar or {}
RecommendedStatsDBChar.minimapIcon = RecommendedStatsDBChar.minimapIcon or {}

-- One-time migration: the old hand-rolled button stored its angle as the account-wide
-- RecommendedStatsDB.minimapAngle. LibDBIcon's field is named/shaped differently
-- (minimapPos, degrees 0-360 same as before) and lives per-character, so carry it over once.
do
    RecommendedStatsDB = RecommendedStatsDB or {}
    if RecommendedStatsDBChar.minimapIcon.minimapPos == nil and RecommendedStatsDB.minimapAngle ~= nil then
        RecommendedStatsDBChar.minimapIcon.minimapPos = RecommendedStatsDB.minimapAngle
        RecommendedStatsDB.minimapAngle = nil
    end
end

if icon:IsRegistered("RecommendedStats") then
    -- Almost certainly a duplicate copy of this addon in AddOns/ (a leftover folder from
    -- installing via CurseForge and Wago, or a manual update that didn't replace the old one) —
    -- registering the same LDB name twice makes LibDBIcon hard-error and abort the REST of this
    -- file for whichever copy loses the race, silently leaving the minimap button backed by
    -- whichever copy's config table won instead. That reads exactly like "my dragged position
    -- never saves" even though nothing about persistence itself is broken, so surface it clearly
    -- instead of letting it fail as an easy-to-miss Lua error.
    print("|cffff4444RecommendedStats|r: minimap icon was already registered — you likely have a duplicate copy of this addon in AddOns. Remove the old folder and /reload.")
else
    icon:Register("RecommendedStats", dataObject, RecommendedStatsDBChar.minimapIcon)
end

-- Shim so Core.lua's RS:SetShowMinimapIcon() (an existing account-wide preference toggle,
-- unrelated to the position fix above) can keep calling :SetShown without knowing this is now
-- backed by LibDBIcon instead of a plain frame.
RS.minimapButton = {
    SetShown = function(_, shown)
        if shown then icon:Show("RecommendedStats") else icon:Hide("RecommendedStats") end
    end,
}
if not RS:GetShowMinimapIcon() then icon:Hide("RecommendedStats") end

--------------------------------------------------------------------------------
-- Skins — LibDataBroker's dataobj.iconR/iconG/iconB are a public, sanctioned way to recolor
-- the icon (LibDBIcon listens for the attribute-changed callback and re-tints live); setting
-- them to 1,1,1 under Default explicitly resets rather than relying on them defaulting to
-- untinted, since once set they stick until something sets them back.
--------------------------------------------------------------------------------
local function ApplySkinToButton()
    local r, g, b = 1, 1, 1
    if RS:GetSkin() ~= "DEFAULT" then
        local c = RS:GetAccentColor()
        r, g, b = c[1], c[2], c[3]
    end
    dataObject.iconR, dataObject.iconG, dataObject.iconB = r, g, b
end
ApplySkinToButton()
table.insert(RS.skinListeners, ApplySkinToButton)
