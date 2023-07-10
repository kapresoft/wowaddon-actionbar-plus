--[[-----------------------------------------------------------------------------
Lua Vars
-------------------------------------------------------------------------------]]
local sformat = string.format

--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
--- @type _GamedTooltip
local GameTooltip = GameTooltip
---### See: Interface/SharedXML/Constants.lua
local DESC_FORMAT = HIGHLIGHT_FONT_COLOR_CODE .. '\n%s' .. FONT_COLOR_CODE_CLOSE

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub

local Assert, String = O.Assert, O.String
local PH = O.PickupHandler
local IsBlank, IsNotBlank, AssertNotNil, IsNil =
String.IsBlank, String.IsNotBlank, Assert.AssertNotNil, Assert.IsNil
local WAttr, EMPTY_ICON = GC.WidgetAttributes, GC.Textures.TEXTURE_EMPTY
local BaseAPI = O.BaseAPI

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]

--- @class EquipmentSetDragEventHandler : DragEventHandler
local L = LibStub:NewLibrary(M.EquipmentSetDragEventHandler); if not L then return end
local p = L.logger()

--- @class EquipmentSetAttributeSetter : BaseAttributeSetter
local S = LibStub:NewLibrary(M.EquipmentSetAttributeSetter)

--- @type BaseAttributeSetter
local BaseAttributeSetter = LibStub(M.BaseAttributeSetter)

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]

--- @param equipmentSet EquipmentSetInfo
--- @return Profile_EquipmentSet
local function ToProfileEquipmentSet(equipmentSet)
    return {
        type = WAttr.EQUIPMENT_SET,
        name = equipmentSet.name,
        id = equipmentSet.id,
        icon = equipmentSet.icon,
    }
end

--- @param w ButtonUIWidget
local function ClickEquipmentSetButton(w)
    if w:IsMissingEquipmentSet() then return end

    local equipmentSet = w:GetEquipmentSetData()
    local index = BaseAPI:GetEquipmentSetIndex(equipmentSet.id)

    local btnName = 'GearSetButton' .. (index)
    if _G[btnName] then _G[btnName]:Click() end
end
--- @param w ButtonUIWidget
local function ClickEquipmentSetButtonDelayed(w)
    C_Timer.After(0.2, function() ClickEquipmentSetButton(w) end)
end

--- @param w ButtonUIWidget
---@param profile Profile_Config
local function OpenEquipmentMgrConditionally(w, profile)
    if profile.equipmentset_open_equipment_manager == true then
        --- @type _Frame
        local gmDlg = GearManagerDialog
        if gmDlg and gmDlg:IsVisible() then ClickEquipmentSetButtonDelayed(w) return end
    end

    --- Buttons:
    --- • GearManagerToggleButton (pre-retail)
    --- • PaperDollSidebarTab3 (retail)
    --- @type _Button
    local gmButton = GearManagerToggleButton or PaperDollSidebarTab3
    if profile.equipmentset_open_equipment_manager ~= true then return end
    C_Timer.After(0.1, function()
        gmButton:Click()
        ClickEquipmentSetButtonDelayed(w)
    end)
end

--- @param w ButtonUIWidget
---@param profile Profile_Config
local function GlowButtonConditionally(w, profile)
    if profile.equipmentset_show_glow_when_active ~= true then return end
    local btn = w.button()
    ActionButton_ShowOverlayGlow(btn)
    C_Timer.After(0.8, function() ActionButton_HideOverlayGlow(btn) end)
end

--- @param evt string
--- @param w ButtonUIWidget
local function OnClick(evt, w, ...)
    assert(w, "ButtonUIWidget is missing")
    p:log(30, 'Message[%s]: %s', evt, w:GetName())
    if not w:CanChangeEquipmentSet() or InCombatLockdown() then return end
    if w:IsMissingEquipmentSet() then return end

    --- @type _Frame
    local PDF = PaperDollFrame
    C_EquipmentSet.UseEquipmentSet(w:GetEquipmentSetData().id)
    -- PUT_DOWN_SMALL_CHAIN
    -- GUILD_BANK_OPEN_BAG
    PlaySound(SOUNDKIT.GUILD_BANK_OPEN_BAG)

    local profile = w:GetProfileConfig()
    if profile.equipmentset_open_character_frame then
        if not PDF:IsVisible() then
            ToggleCharacter('PaperDollFrame')
            OpenEquipmentMgrConditionally(w, profile)
        else OpenEquipmentMgrConditionally(w, profile) end
    end
end

--[[-----------------------------------------------------------------------------
Methods: BattlePetDragEventHandler
-------------------------------------------------------------------------------]]
--- @param e EquipmentSetDragEventHandler
local function eventHandlerMethods(e)

    --- @param cursorInfo CursorInfo
    function e:Supports(cursorInfo)
        if not C_EquipmentSet then return false end
        if not C_EquipmentSet.CanUseEquipmentSets() then return false end

        local equipmentSetCursor = BaseAPI:ToEquipmentSetCursor(cursorInfo)
        if not equipmentSetCursor then return false end
        return true
    end

    --- @param btnUI ButtonUI
    --- @param cursorInfo CursorInfo
    function e:Handle(btnUI, cursorInfo)

        local equipmentSetInfo = BaseAPI:GetEquipmentSetInfo(cursorInfo)
        if not equipmentSetInfo then return end

        local config = btnUI.widget:conf()
        local equipmentSet = ToProfileEquipmentSet(equipmentSetInfo)
        p:log(30, 'equipmentSet: %s', equipmentSet)

        PH:PickupExisting(btnUI.widget)
        config[WAttr.TYPE] = equipmentSet.type
        config[WAttr.EQUIPMENT_SET] = equipmentSet

        S(btnUI, config)
    end

end

--[[-----------------------------------------------------------------------------
Methods: BattlePetAttributeSetter
-------------------------------------------------------------------------------]]
--- @param a EquipmentSetAttributeSetter
local function attributeSetterMethods(a)

    --- @param btnUI ButtonUI
    function a:SetAttributes(btnUI)
        local w = btnUI.widget
        w:ResetWidgetAttributes()
        local equipmentSet = w:GetEquipmentSetData()
        if w:IsInvalidEquipmentSet(equipmentSet) then return end

        local icon = EMPTY_ICON
        if equipmentSet.icon then icon = equipmentSet.icon end

        w:SetIcon(icon)
        self:HandleGameTooltipCallbacks(btnUI)
    end

    --- @param btnUI ButtonUI
    function a:RefreshTooltipAtMouse(btnUI)
        --- @type ButtonUI
        local f = GetMouseFocus()
        if not f then return end
        if f:GetName() ~= btnUI:GetName() then return end

        self:RefreshTooltip(f)
        local w = btnUI.widget
        local profile = w:GetProfileConfig()
        GlowButtonConditionally(w, profile)
    end

    --- @param btnUI ButtonUI
    function a:RefreshTooltip(btnUI)
        C_Timer.After(0.2, function() S:ShowTooltip(btnUI) end)
    end

    --- @param btnUI ButtonUI
    function a:ShowTooltip(btnUI)
        if not btnUI then return end
        local w = btnUI.widget
        if w:IsEmpty() or w:IsMissingEquipmentSet() then return end
        local equipmentSet = w:FindEquipmentSet()
        -- retail GameTooltip uses setID
        GameTooltip:SetEquipmentSet(equipmentSet.id)
        if equipmentSet.isEquipped then
            -- todo next: localize
            local equippedLabel = ns:K().CH:FormatColor('0073FF', ' (Equipped)')
            GameTooltip:AppendText(equippedLabel)
        end
    end
end

--- @return EquipmentSetAttributeSetter
function L:GetAttributeSetter() return S end

--[[-----------------------------------------------------------------------------
Init
-------------------------------------------------------------------------------]]
local function Init()
    eventHandlerMethods(L)
    attributeSetterMethods(S)

    S.mt.__index = BaseAttributeSetter
    S.mt.__call = S.SetAttributes

    ns:AceEvent():RegisterMessage(GC.M.OnButtonClickEquipmentSet, OnClick)
end

Init()
