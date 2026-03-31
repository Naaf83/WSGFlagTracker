-- WSGFlagTracker.lua
-- Displays two clickable frames showing Alliance and Horde flag carriers in Warsong Gulch

local addonName = "WSGFlagTracker"

WSGFlagTrackerDB = WSGFlagTrackerDB or {}

local allianceFlagCarrier = nil
local hordeFlagCarrier = nil
local isInWSG = false

local ALLIANCE_COLOR = { r = 0.0, g = 0.44, b = 0.87 }
local HORDE_COLOR    = { r = 0.87, g = 0.12, b = 0.12 }
local FRAME_WIDTH    = 220
local FRAME_HEIGHT   = 50

-------------------------------------------------------------------------------
-- Check if player is in WSG
-------------------------------------------------------------------------------
local function IsInWSG()
    local _, instanceType = IsInInstance()
    if instanceType ~= "pvp" then return false end
    local zone = GetRealZoneText()
    return (zone == "Warsong Gulch")
end

-------------------------------------------------------------------------------
-- Target a player by name
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

    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 16, edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    })

    local color = (side == "Alliance") and ALLIANCE_COLOR or HORDE_COLOR
    f:SetBackdropBorderColor(color.r, color.g, color.b, 1)
    f:SetBackdropColor(0.05, 0.05, 0.05, 0.85)

    local iconTex = (side == "Alliance")
        and "Interface\\BattlefieldFrame\\BattlefieldAllianceBanner"
        or  "Interface\\BattlefieldFrame\\BattlefieldHordeBanner"

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetSize(36, 36)
    icon:SetPoint("LEFT", f, "LEFT", 8, 0)
    icon:SetTexture(iconTex)
    f.icon = icon

    local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", f, "TOPLEFT", 50, -8)
    label:SetText(side .. " FC")
    label:SetTextColor(color.r, color.g, color.b, 1)
    f.label = label

    local nameText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 50, 8)
    nameText:SetText("No flag carrier")
    nameText:SetTextColor(0.8, 0.8, 0.8, 1)
    f.nameText = nameText

    f:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            local carrier = (side == "Alliance") and allianceFlagCarrier or hordeFlagCarrier
            if carrier then TargetByName(carrier) end
        elseif button == "RightButton" then
            local carrier = (side == "Alliance") and allianceFlagCarrier or hordeFlagCarrier
            if carrier then
                print("|cff00ccff[WSGFlagTracker]|r " .. side .. " FC: " .. carrier)
            end
        end
    end)
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp")

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
-- Main container
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
    if allianceFlagCarrier then
        allianceFrame.nameText:SetText(allianceFlagCarrier)
        allianceFrame.nameText:SetTextColor(0.2, 1.0, 0.2, 1)
        allianceFrame:SetBackdropBorderColor(0.2, 1.0, 0.2, 1)
    else
        allianceFrame.nameText:SetText("No flag carrier")
        allianceFrame.nameText:SetTextColor(0.8, 0.8, 0.8, 1)
        allianceFrame:SetBackdropBorderColor(ALLIANCE_COLOR.r, ALLIANCE_COLOR.g, ALLIANCE_COLOR.b, 1)
    end

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
-- Show/hide based on zone
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
-- Parse BG system messages
--
-- Actual in-game message formats observed in Classic Era 1.15.8:
--   "The Alliance Flag was picked up by Jeebay!"
--   "The Horde flag was picked up by Pornhad!"
--   "The Alliance Flag was dropped by Jeebay!"
--   "The Horde flag was dropped by Pornhad!"
--   "The Alliance Flag was returned to its base by Eduard!"
--   "The Horde flag was returned to its base by Emolex-Ashbringer!"
--
-- Note: "Flag" is capitalised for Alliance, lowercase for Horde.
-- Patterns are case-insensitive via string.lower() to handle both.
-------------------------------------------------------------------------------
local function OnBGSystemMessage(self, event, msg)
    if not isInWSG or not msg then return end

    local lmsg = msg:lower()
    local name

    -- Alliance flag picked up (by a Horde player)
    name = lmsg:match("the alliance flag was picked up by (.+)!")
    if name then
        -- Grab original-case name from original msg
        hordeFlagCarrier = msg:match("[Tt]he [Aa]lliance [Ff]lag was picked up by (.+)!")
        UpdateFrames()
        return
    end

    -- Horde flag picked up (by an Alliance player)
    name = lmsg:match("the horde flag was picked up by (.+)!")
    if name then
        allianceFlagCarrier = msg:match("[Tt]he [Hh]orde [Ff]lag was picked up by (.+)!")
        UpdateFrames()
        return
    end

    -- Alliance flag dropped or returned or captured → clear Horde carrier
    if lmsg:match("the alliance flag was dropped by")
    or lmsg:match("the alliance flag was returned")
    or lmsg:match("captured the alliance flag") then
        hordeFlagCarrier = nil
        UpdateFrames()
        return
    end

    -- Horde flag dropped or returned or captured → clear Alliance carrier
    if lmsg:match("the horde flag was dropped by")
    or lmsg:match("the horde flag was returned")
    or lmsg:match("captured the horde flag") then
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
            if WSGFlagTrackerDB.point then
                local p = WSGFlagTrackerDB.point
                mainFrame:ClearAllPoints()
                mainFrame:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
            end
            print("|cff00ccff[WSGFlagTracker]|r Loaded. Tracks flag carriers in Warsong Gulch.")
        end
    elseif event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA"
        or event == "ZONE_CHANGED" then
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
