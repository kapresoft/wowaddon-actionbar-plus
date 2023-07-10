--[[-----------------------------------------------------------------------------
Lua Vars
-------------------------------------------------------------------------------]]
local sformat, slower, tinsert = string.format, string.lower, table.insert

--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
local GameTooltip, C_Timer, ReloadUI, IsShiftKeyDown, StaticPopup_Show =
    GameTooltip, C_Timer, ReloadUI, IsShiftKeyDown, StaticPopup_Show
local TooltipDataProcessor = TooltipDataProcessor
local Enum, EmbeddedItemTooltip, ItemRefTooltip = Enum, EmbeddedItemTooltip, ItemRefTooltip

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub

local AceEvent = O.AceLibrary.AceEvent
local String, Table, A, P, MSG = O.String, O.Table, O.Assert, O.Profile, GC.M
local IsBlankString, IsEmptyTable = String.IsBlank, Table.isEmpty
local ButtonFrameFactory = O.ButtonFrameFactory
local AssertNotNil = A.AssertNotNil
local WAttr = O.GlobalConstants.WidgetAttributes
local SPELL, ITEM, MACRO, MOUNT, COMPANION, BATTLE_PET, EQUIPMENT_SET =
            WAttr.SPELL, WAttr.ITEM, WAttr.MACRO,
            WAttr.MOUNT, WAttr.COMPANION, WAttr.BATTLE_PET,
            WAttr.EQUIPMENT_SET
local E = GC.E
--- @type ButtonUILib
local ButtonUI = O.ButtonUI
local WMX = O.WidgetMixin

--- @class ButtonFactory : BaseLibraryObject_WithAceEvent
local L = LibStub:NewLibrary(M.ButtonFactory); if not L then return end; AceEvent:Embed(L)
local p = L:GetLogger()
local safecall = O.Safecall:New(p)

--- @type table<string, AttributeSetter>
local AttributeSetters = {
    [SPELL]       = O.SpellAttributeSetter,
    [ITEM]        = O.ItemAttributeSetter,
    [MACRO]       = O.MacroAttributeSetter,
    [MOUNT]       = O.MountAttributeSetter,
    [COMPANION]   = O.CompanionAttributeSetter,
    [BATTLE_PET]   = O.BattlePetAttributeSetter,
    [EQUIPMENT_SET] = O.EquipmentSetAttributeSetter,
}

L.FRAMES = {}

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
local function InitButtonGameTooltipHooksLegacy()
    GameTooltip:HookScript(E.OnShow, function(tooltip, ...)
        if not WMX:IsTypeMacro(tooltip:GetOwner()) then return end
        WMX:SetupTooltipKeybindingInfo(tooltip)
    end)
    GameTooltip:HookScript(E.OnTooltipSetSpell, function(tooltip, ...)
        if WMX:IsTypeMacro(tooltip:GetOwner()) then return end
        WMX:SetupTooltipKeybindingInfo(tooltip)
    end)
    GameTooltip:HookScript(E.OnTooltipSetItem, function(tooltip, ...)
        if WMX:IsTypeMacro(tooltip:GetOwner()) then return end
        WMX:SetupTooltipKeybindingInfo(tooltip)
    end)
end

local function InitButtonGameTooltipHooksUsingTooltipDataProcessor()
    ---For macros not using spells
    GameTooltip:HookScript("OnShow", function(tooltip, ...)
        if not WMX:IsTypeMacro(tooltip:GetOwner()) then return end
        WMX:SetupTooltipKeybindingInfo(tooltip)
    end)

    local onTooltipSetSpellFunction = function(tooltip, tooltipData)
        if WMX:IsTypeMacro(tooltip:GetOwner()) then return end
        if (tooltip == GameTooltip or tooltip == EmbeddedItemTooltip) then
            WMX:SetupTooltipKeybindingInfo(tooltip)
        end
    end
    local onTooltipSetItemFunction = function(tooltip, tooltipData)
        if WMX:IsTypeMacro(tooltip:GetOwner()) then return end
        if (tooltip == GameTooltip or tooltip == ItemRefTooltip) then
            WMX:SetupTooltipKeybindingInfo(tooltip)
        end
    end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, onTooltipSetSpellFunction)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, onTooltipSetItemFunction)
end

local function InitButtonGameTooltipHooks()
    if TooltipDataProcessor then
        InitButtonGameTooltipHooksUsingTooltipDataProcessor()
        return
    end
    InitButtonGameTooltipHooksLegacy()
end

--- @param btnWidget ButtonUIWidget
local function OnMacroChanged(btnWidget)
    AttributeSetters[MACRO]:SetAttributes(btnWidget.button())
end

--- Autocorrect bad data if we have button data with
--- btnData[type] but no btnData.type
--- @param btnWidget ButtonUIWidget
--- @param btnData Profile_Button
local function GuessButtonType(btnWidget, btnData)
    for buttonType in pairs(AttributeSetters) do
        -- return the first data found
        if not IsEmptyTable(btnData[buttonType]) then
            return buttonType
        end
    end
    return nil
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
function L:Init()
    local frameNames = ButtonFrameFactory:CreateActionbarFrames()
    for i in ipairs(frameNames) do
        local f = self:CreateActionbarGroup(i)
        tinsert(self.FRAMES, f)
        f:ShowGroupIfEnabled()
        f:ScrubEmptyButtons()
    end
end

function L:Fire(event, sourceEvent, ...)
    local args = ...
    --- @param frameWidget FrameWidget
    self:ApplyForEachFrames(function(frameWidget)
        if frameWidget then frameWidget:Fire(event, sourceEvent, args) end
    end)
end

function L:FireOnFrame(frameIndex, event, sourceEvent, ...)
    local args = ...
    self.FRAMES[frameIndex]:Fire(event, sourceEvent, args)
end

--- @param applyFunction FrameHandlerFunction | "function(frameWidget) print(frameWidget:GetName()) end"
function L:ApplyForEachFrames(applyFunction)
    local frames = P:GetAllFrameNames()
    if #frames <= 0 then return end
    -- `_` is the index
    for _,f in ipairs(frames) do applyFunction(_G[f].widget) end
end

--- @param applyFunction FrameHandlerFunction | "function(frameWidget) print(frameWidget:GetName()) end"
function L:ApplyForEachVisibleFrames(applyFunction)
    local frames = P:GetAllFrameNames()
    if #frames <= 0 then return end
    -- `_` is the index
    for _,f in ipairs(frames) do
        if _G[f] then
            --- @type FrameWidget
            local fw = _G[f].widget
            if fw and fw:IsShownInConfig() then applyFunction(fw) end
        end
    end
end
--- Alias for #ApplyForEachVisibleFrames(applyFunction)
--- @param applyFunction FrameHandlerFunction | "function(frameWidget) print(frameWidget:GetName()) end"
function L:fevf(applyFunction) self:ApplyForEachVisibleFrames(applyFunction) end

function L:UpdateKeybindText()
    local frames = P:GetAllFrameNames()
    for i,name in ipairs(frames) do
        local f = _G[name]
        if f and f.widget then
            --- @type FrameWidget
            local fw = f.widget
            if P:IsBarIndexEnabled(i) then fw:UpdateKeybindText() end
        end
    end
end

function L:RefreshActionbar(frameIndex)
    P:GetFrameWidgetByIndex(frameIndex):RefreshActionbarFrame()
end

function L:CreateActionbarGroup(frameIndex)
    local barConfig = P:GetBar(frameIndex)
    local widget = barConfig.widget
    --- @type FrameWidget
    local f = ButtonFrameFactory(frameIndex)
    self:CreateButtons(f, widget.rowSize, widget.colSize)
    f:SetInitialState()
    return f
end

--- @param fw FrameWidget
function L:CreateButtons(fw, rowSize, colSize)
    fw:ClearButtons()
    local index = 0
    for row=1, rowSize do
        for col=1, colSize do
            index = index + 1
            local btnUI = fw:GetButtonUI(index)
            if not btnUI then btnUI = self:CreateSingleButton(fw, row, col, index).button() end
            fw:AddButtonFrame(btnUI)
        end
    end
    fw:LayoutButtonGrid()
end

--- @param frameWidget FrameWidget
--- @param row number
--- @param col number
--- @param btnIndex number The button index number
--- @return ButtonUIWidget
function L:CreateSingleButton(frameWidget, row, col, btnIndex)
    local btnWidget = ButtonUI:WidgetBuilder():Create(frameWidget, row, col, btnIndex)
    btnWidget:SetButtonAttributes()
    btnWidget:SetCallback("OnMacroChanged", OnMacroChanged)
    btnWidget:UpdateStateDelayed(0.05)
    btnWidget:CleanupActionTypeData()
    return btnWidget
end

function L:IsValidDragSource(cursorInfo)
    if String.IsBlank(cursorInfo.type) then
        -- This can happen if a chat tab or others is dragged into
        -- the action bar.
        self:log(5, 'Received drag event with invalid cursor info. Skipping...')
        return false
    end

    return true
end

--[[-----------------------------------------------------------------------------
Event Handlers
-------------------------------------------------------------------------------]]
--- Update Items and Macros referencing items
local function OnBagUpdate()
    L:ApplyForEachVisibleFrames(function(fw)
        fw:ApplyForEachButtonCondition(
                function(bw) return bw:IsItemOrMacro() end,
                function(bw)
                    local success, itemInfo = safecall(function() return bw:GetItemData() end)
                    if not (success and itemInfo) then return end
                    bw:UpdateItemOrMacroState()
                end)
    end)
end

--- This event includes ZONE_CHANGED_NEW_AREA because the player could be mounted before
--- entering the portal and get dismounted upon zoning in to the new area
local function OnPlayerMount()
    L:ApplyForEachVisibleFrames(function(fw)
        fw:ApplyForEachButtonCondition(
                function(bw) return bw:IsMount() end,
                function(bw) O.MountAttributeSetter:SetAttributes(bw.button(), 'event') end
        )
    end)
end

--[[-----------------------------------------------------------------------------
Initializer
-------------------------------------------------------------------------------]]
local function InitButtonFactory()
    if GC.V2 == true then return end

    InitButtonGameTooltipHooks()

    L:RegisterMessage(MSG.OnAddOnInitialized, function(msg)
        p:log(10, 'MSG::R: %s', msg)
        L:Init()
    end)

    L:RegisterMessage(MSG.OnBagUpdate, OnBagUpdate)
    L:RegisterMessage(MSG.PLAYER_MOUNT_DISPLAY_CHANGED, OnPlayerMount)
    L:RegisterMessage(MSG.ZONE_CHANGED_NEW_AREA, OnPlayerMount)
end

InitButtonFactory()
