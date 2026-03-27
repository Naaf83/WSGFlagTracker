-- WSGFlagTracker.lua
-- Displays two clickable frames showing Alliance and Horde flag carriers in Warsong Gulch

local addonName = "WSGFlagTracker"

-- Saved variables defaults
WSGFlagTrackerDB = WSGFlagTrackerDB or {}

-- State
local allianceFlagCarrier = nil
local hordeFlagCarrier = nil
local isInWSG = false

-- Constants
local ALLIANCE_COLOR = { r = 0.0, g = 0.44, b = 0.87 }
local HORDE_COLOR    = { r = 0.87, g = 0.12, b = 0.12 }
local FRAME_WIDTH    = 220
local FRAME_HEIGHT   = 50

-- WSG Map ID for Classic Era
local WSG_MAP_ID = 489

-------------------------------------------------------------------------------
-- Utility: Check if the player is in WSG
-------------------------------------------------------------------------------
local function IsInWSG()
    local _, instanceType = IsInInstance()
    if instanceType ~= "pvp" then return false end
    local mapID = GetCurrentMapAreaID and GetCurrentMapAreaID() or 0
    -- Fallback: check zone name
    local zone = GetRealZoneText()
    return (zone == "Warsong Gulch") or (mapID == WSG_MAP_ID)
end

-------------------------------------------------------------------------------
-- Utility: Target a player by name
-------------------------------------------------------------------------------
local function TargetByName(name)
    if name then
        TargetUnit(name)
    end
end

-------------------------------------------------------------------------------
-- Frame factory
-------------------------------------------------------------------------------
local function CreateFlagFrame(parent, side)
    local f = CreateFrame("Button", addonName .. side .. "Frame", parent, "BackdropTemplate")
    f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)

    -- Backdrop
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 16, edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    })

    local color = (side == "Alliance") and ALLIANCE_COLOR or HORDE_COLOR
    f:SetBackdropBorderColor(color.r, color.g, color.b, 1)
    f:SetBackdropColor(0.05, 0.05, 0.05, 0.85)

    -- Flag icon
    local iconTex = (side == "Alliance")
        and "Interface\\BattlefieldFrame\\BattlefieldAllianceBanner"
        or  "Interface\\BattlefieldFrame\\BattlefieldHordeBanner"

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetSize(36, 36)
    icon:SetPoint("LEFT", f, "LEFT", 8, 0)
    icon:SetTexture(iconTex)
    f.icon = icon

    -- Side label (e.g. "Alliance FC")
    local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", f, "TOPLEFT", 50, -8)
    label:SetText(side .. " FC")
    label:SetTextColor(color.r, color.g, color.b, 1)
    f.label = label

    -- Carrier name
    local nameText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 50, 8)
    nameText:SetText("No flag carrier")
    nameText:SetTextColor(0.8, 0.8, 0.8, 1)
    f.nameText = nameText

    -- Left-click: target the flag carrier
    f:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            local carrier = (side == "Alliance") and allianceFlagCarrier or hordeFlagCarrier
            if carrier then
                TargetByName(carrier)
            end
        elseif button == "RightButton" then
            -- Right-click context: print name to chat
            local carrier = (side == "Alliance") and allianceFlagCarrier or hordeFlagCarrier
            if carrier then
                print("|cff00ccff[WSGFlagTracker]|r " .. side .. " FC: " .. carrier)
            end
        end
    end)
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- Tooltip
    f:SetScript("OnEnter", function(self)
        local carrier = (side == "Alliance") and allianceFlagCarrier or hordeFlagCarrier
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(side .. " Flag Carrier", color.r, color.g, color.b)
        if carrier then
            GameTooltip:AddLine("Left-click to target: " .. carrier, 1, 1, 1)
            GameTooltip:AddLine("Right-click to print name", 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine("No carrier detected", 0.7, 0.7, 0.7)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Drag to move", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return f
end

-------------------------------------------------------------------------------
-- Main container frame
-------------------------------------------------------------------------------
local mainFrame = CreateFrame("Frame", addonName .. "MainFrame", UIParent)
mainFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT * 2 + 10)
mainFrame:SetPoint("CENTER", UIParent, "CENTER", 400, 200)
mainFrame:SetMovable(true)
mainFrame:SetClampedToScreen(true)
mainFrame:Hide()

local allianceFrame = CreateFlagFrame(mainFrame, "Alliance")
allianceFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, 0)

local hordeFrame = CreateFlagFrame(mainFrame, "Horde")
hordeFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, -(FRAME_HEIGHT + 6))

-------------------------------------------------------------------------------
-- Update displayed names
-------------------------------------------------------------------------------
local function UpdateFrames()
    -- Alliance
    if allianceFlagCarrier then
        allianceFrame.nameText:SetText(allianceFlagCarrier)
        allianceFrame.nameText:SetTextColor(0.2, 1.0, 0.2, 1)
        allianceFrame:SetBackdropBorderColor(0.2, 1.0, 0.2, 1)
    else
        allianceFrame.nameText:SetText("No flag carrier")
        allianceFrame.nameText:SetTextColor(0.8, 0.8, 0.8, 1)
        allianceFrame:SetBackdropBorderColor(ALLIANCE_COLOR.r, ALLIANCE_COLOR.g, ALLIANCE_COLOR.b, 1)
    end

    -- Horde
    if hordeFlagCarrier then
        hordeFrame.nameText:SetText(hordeFlagCarrier)
        hordeFrame.nameText:SetTextColor(1.0, 0.6, 0.1, 1)
        hordeFrame:SetBackdropBorderColor(1.0, 0.6, 0.1, 1)
    else
        hordeFrame.nameText:SetText("No flag carrier")
        hordeFrame.nameText:SetTextColor(0.8, 0.8, 0.8, 1)
        hordeFrame:SetBackdropBorderColor(HORDE_COLOR.r, HORDE_COLOR.g, HORDE_COLOR.b, 1)
    end
end

-------------------------------------------------------------------------------
-- Show / hide based on zone
-------------------------------------------------------------------------------
local function RefreshVisibility()
    isInWSG = IsInWSG()
    if isInWSG then
        mainFrame:Show()
    else
        mainFrame:Hide()
        allianceFlagCarrier = nil
        hordeFlagCarrier    = nil
        UpdateFrames()
    end
end

-------------------------------------------------------------------------------
-- Parse combat log / system messages for flag carrier events
--
-- In Classic Era, WSG flag events fire as CHAT_MSG_BG_SYSTEM_ALLIANCE /
-- CHAT_MSG_BG_SYSTEM_HORDE with messages like:
--   "%s picked up the Alliance's flag!"
--   "%s captured the Horde's flag!"
--   "The Alliance's flag was dropped by %s!"
--   "The Alliance's flag was returned to its base by %s!"
-- We detect pick-up and capture/return to update or clear the carrier.
-------------------------------------------------------------------------------

-- Patterns (Classic Era global strings — fallback to manual strings)
local PICKUP_ALLIANCE  = "(.+) picked up the Alliance's flag!"
local PICKUP_HORDE     = "(.+) picked up the Horde's flag!"
local DROPPED_ALLIANCE = "The Alliance's flag was dropped by (.+)!"
local DROPPED_HORDE    = "The Horde's flag was dropped by (.+)!"
local CAPTURED_ALLIANCE= "(.+) captured the Alliance's flag!"
local CAPTURED_HORDE   = "(.+) captured the Horde's flag!"
local RETURNED_ALLIANCE= "The Alliance's flag was returned to its base by (.+)!"
local RETURNED_HORDE   = "The Horde's flag was returned to its base by (.+)!"

local function OnBGSystemMessage(self, event, msg)
    if not isInWSG or not msg then return end

    local name

    -- Alliance flag picked up (by Horde player)
    name = msg:match(PICKUP_ALLIANCE)
    if name then
        hordeFlagCarrier = name
        UpdateFrames()
        return
    end

    -- Horde flag picked up (by Alliance player)
    name = msg:match(PICKUP_HORDE)
    if name then
        allianceFlagCarrier = name
        UpdateFrames()
        return
    end

    -- Alliance flag dropped / returned / captured → clear Horde carrier
    if msg:match(DROPPED_ALLIANCE) or msg:match(CAPTURED_ALLIANCE) or msg:match(RETURNED_ALLIANCE) then
        hordeFlagCarrier = nil
        UpdateFrames()
        return
    end

    -- Horde flag dropped / returned / captured → clear Alliance carrier
    if msg:match(DROPPED_HORDE) or msg:match(CAPTURED_HORDE) or msg:match(RETURNED_HORDE) then
        allianceFlagCarrier = nil
        UpdateFrames()
        return
    end
end

-------------------------------------------------------------------------------
-- Event handling
-------------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame", addonName .. "EventFrame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("ZONE_CHANGED")
eventFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
eventFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
eventFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            -- Restore saved position if any
            if WSGFlagTrackerDB.point then
                local p = WSGFlagTrackerDB.point
                mainFrame:ClearAllPoints()
                mainFrame:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
            end
            print("|cff00ccff[WSGFlagTracker]|r Loaded. Tracks flag carriers in Warsong Gulch.")
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" then
        RefreshVisibility()
    elseif event == "CHAT_MSG_BG_SYSTEM_ALLIANCE"
        or event == "CHAT_MSG_BG_SYSTEM_HORDE"
        or event == "CHAT_MSG_BG_SYSTEM_NEUTRAL" then
        OnBGSystemMessage(self, event, ...)
    end
end)

-- Save position on logout
local logoutFrame = CreateFrame("Frame")
logoutFrame:RegisterEvent("PLAYER_LOGOUT")
logoutFrame:SetScript("OnEvent", function()
    local point, _, relPoint, x, y = mainFrame:GetPoint()
    WSGFlagTrackerDB.point = { point = point, relPoint = relPoint, x = x, y = y }
end)

-------------------------------------------------------------------------------
-- Slash commands
-------------------------------------------------------------------------------
SLASH_WSGFT1 = "/wsgft"
SLASH_WSGFT2 = "/wsgflagtracker"
SlashCmdList["WSGFT"] = function(msg)
    msg = msg:lower():trim()
    if msg == "show" then
        mainFrame:Show()
        print("|cff00ccff[WSGFlagTracker]|r Frames shown.")
    elseif msg == "hide" then
        mainFrame:Hide()
        print("|cff00ccff[WSGFlagTracker]|r Frames hidden.")
    elseif msg == "reset" then
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint("CENTER", UIParent, "CENTER", 400, 200)
        WSGFlagTrackerDB.point = nil
        print("|cff00ccff[WSGFlagTracker]|r Position reset.")
    elseif msg == "clear" then
        allianceFlagCarrier = nil
        hordeFlagCarrier    = nil
        UpdateFrames()
        print("|cff00ccff[WSGFlagTracker]|r Carrier data cleared.")
    else
        print("|cff00ccff[WSGFlagTracker]|r Commands:")
        print("  /wsgft show   - Force show frames")
        print("  /wsgft hide   - Hide frames")
        print("  /wsgft reset  - Reset frame position")
        print("  /wsgft clear  - Clear carrier names")
    end
end
