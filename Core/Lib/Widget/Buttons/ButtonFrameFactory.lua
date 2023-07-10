--
-- ButtonFrameFactory
-- Creates the actionbar frame (anchor) for the buttons
--
--[[-----------------------------------------------------------------------------
Lua Vars
-------------------------------------------------------------------------------]]
local _G = _G
local format, type, ipairs = string.format, type, ipairs
local tinsert, tsort = table.insert, table.sort

--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
local CreateAnchor, GridLayoutMixin = CreateAnchor, GridLayoutMixin
local UnitOnTaxi = UnitOnTaxi
local CreateFrame = CreateFrame

--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
--- @type _AnchorUtil
local AnchorUtil = AnchorUtil
local C_Timer = C_Timer

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, LibStub = ns:LibPack()

local Assert, Table, P, pformat = O.Assert, O.Table, O.Profile, ns.pformat
local AO = O.AceLibFactory:A()
local AceEvent, AceGUI, LSM = AO.AceEvent, AO.AceGUI, AO.AceLibSharedMedia
local GC = O.GlobalConstants
local E, M = GC.E, GC.M
local configHandler = O.Config

--- @see _ParentFrame.xml
local frameTemplate = 'ActionbarPlusFrameTemplate'

-- post combat updates (SetAttribute* is not allowed during combat)
local PostCombatButtonUpdates = {}

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @class ButtonFrameFactory : BaseLibraryObject
local L = LibStub:NewLibrary(ns.M.ButtonFrameFactory); if not L then return end
local p = L:GetLogger()

--- @class WidgetBase
local WidgetBaseTemplate = {
    --- @param self WidgetBase
    --- @param name string
    ['Fire'] = function(self, name, ...) end,
    --- @param self WidgetBase
    --- @param name string
    --- @param func function The callback function
    ['SetCallback'] = function(self, name, func) end,
}

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- @param widget FrameWidget
--- @param name string The widget name.
local function RegisterWidget(widget, name)
    assert(widget ~= nil)
    assert(name ~= nil)

    local WidgetBase = AceGUI.WidgetBase
    widget.userdata = {}
    widget.events = {}
    widget.base = WidgetBase
    widget.frame.obj = widget
    local mt = {
        __tostring = function() return name  end,
        __index = WidgetBase
    }
    setmetatable(widget, mt)
end

--- @param frameWidget FrameWidget
---@param state boolean
local function EnableMouseAllButtons(frameWidget, state)
    frameWidget:ApplyForEachButton(function(bw)
        if not bw:IsEmpty() then return end
        bw:EnableMouse(state)
    end)
end
--- @param frameWidget FrameWidget
--- @param event string
local function OnEquipmentSetsChanged(frameWidget, event)
    frameWidget:ApplyForEachButtonCondition(function(btnWidget) return btnWidget:IsEquipmentSet() end,
            function(btnWidget) btnWidget:UpdateEquipmentSet() end)
end

--- @param frameWidget FrameWidget
--- @param event string
local function OnEquipmentSwapFinished(frameWidget, event)
    frameWidget:ApplyForEachButtonCondition(function(btnWidget) return btnWidget:IsEquipmentSet() end,
            function(btnWidget)
                O.EquipmentSetAttributeSetter:RefreshTooltipAtMouse(btnWidget.button())
            end)
end

--- @param frameWidget FrameWidget
--- @param event string
local function OnModifierStateChanged(frameWidget, event, sourceName, modifierKey, keyState)
    frameWidget:ApplyForEachMacro(function(w)
        C_Timer.NewTicker(0.01, function()
            w:UpdateMacroState()
            w:UpdateUsable()
        end, 3)
    end)
end

--- @param frameWidget FrameWidget
local function OnCooldownTextSettingsChanged(frameWidget, event)
    --- @param bw ButtonUIWidget
    frameWidget:ApplyForEachButton(function(bw) bw:RefreshTexts()  end)
end
--- @param frameWidget FrameWidget
local function OnTextSettingsChanged(frameWidget, event)
    --- @param bw ButtonUIWidget
    frameWidget:ApplyForEachButton(function(bw) bw:RefreshTexts()  end)
end
--- @param frameWidget FrameWidget
local function OnMouseOverGlowSettingsChanged(frameWidget, event)
    --- @param bw ButtonUIWidget
    frameWidget:ApplyForEachButton(function(bw) bw:RefreshHighlightEnabled() end)
end

--- @param frameWidget FrameWidget
local function OnButtonSizeChanged(frameWidget, event)
    --- @param bw ButtonUIWidget
    frameWidget:ApplyForEachButton(function(bw)
        bw:SetButtonProperties()
        bw:RefreshTexts()
        bw:UpdateKeybindTextState()
    end)
    frameWidget:SetFrameDimensions()
    frameWidget:LayoutButtonGrid()
end

--- @param frameWidget FrameWidget
local function OnButtonCountChanged(frameWidget, event, sourceFrameIndex)
    if sourceFrameIndex ~= frameWidget:GetFrameIndex() then return end
    if not frameWidget:IsShownInConfig() then return end

    local barConfig = frameWidget:GetConfig()
    local widget = barConfig.widget
    local bf = O.ButtonFactory
    frameWidget:SetFrameDimensions()

    bf:CreateButtons(frameWidget, widget.rowSize, widget.colSize)
    frameWidget:HideUnusedButtons()

    frameWidget:SetInitialState()
    frameWidget:ShowGroupIfEnabled()

    --- @param bw ButtonUIWidget
    frameWidget:ApplyForEachButton(function(bw)
        bw:SetButtonProperties()
        bw:RefreshTexts()
        bw:UpdateKeybindTextState()
    end)

    frameWidget:SaveAndScrubDeletedButtons(true)
end

--- @param frameWidget FrameWidget
local function OnActionbarFrameAlphaUpdated(frameWidget, event, sourceFrameIndex)
    frameWidget:UpdateButtonAlpha()
end
--- @param frameWidget FrameWidget
local function OnActionbarShowEmptyButtonsUpdated(frameWidget, event, sourceFrameIndex)
    frameWidget:UpdateEmptyButtonsSettings()
end

--- Show delayed due to anchor not setting until UI is fully loaded
--- Event is fired from ActionbarPlus#OnAddonLoaded.
--- Avoid taint() and return if in combat
--- @param w FrameWidget
local function OnAddOnReady(w, msg)
    if InCombatLockdown() then return end
    C_Timer.After(0.1, function() w:InitAnchor() end)
end

---Fired by FrameHandle when dragging stopped
--- @param frameWidget FrameWidget
--- @param event string
local function OnDragStop_FrameHandle(frameWidget, event) frameWidget:UpdateAnchor() end

--- @param frameWidget FrameWidget
local function OnActionbarShowGrid(frameWidget, e, ...)
    frameWidget:ApplyForEachButton(function(bw)
        bw:ShowEmptyGridEvent()
        C_Timer.After(0.1, function() bw:EnableMouse(true) end)
    end)
end
--- @param frameWidget FrameWidget
local function OnActionbarHideGrid(frameWidget, e, ...)
    frameWidget:ApplyForEachButton(function(bw) bw:HideEmptyGridEvent() end)
    C_Timer.After(2, function()
        EnableMouseAllButtons(frameWidget, GetCursorInfo() ~= nil)
    end)
end

--- @param frameWidget FrameWidget
local function OnHideWhenTaxiChanged(frameWidget, e, ...)
    if not UnitOnTaxi(GC.UnitId.player) then return end
    local WMX = O.WidgetMixin
    local isShown = WMX:IsHideWhenTaxi() ~= true
    WMX:ShowActionbars(isShown)
end

--- @param frameWidget FrameWidget
local function OnMouseOverFrameHandleConfigChanged(frameWidget, e, ...) frameWidget.frameHandle:UpdateBackdropState() end

--- @param frameWidget FrameWidget
local function OnFrameHandleAlphaConfigChanged(frameWidget, e, ...)
    local barConf = frameWidget:GetConfig()
    frameWidget.frameHandle:SetAlpha(barConf.widget.frame_handle_alpha or 1.0)
end

---Sometimes there's a delay. Fire immediately, then after a few seconds
--- @param frameWidget FrameWidget
local function OnActionbarShowGroup(frameWidget, e, ...)
    if  true ~= P:IsBarEnabled(frameWidget.index) then return end
    frameWidget:ShowGroup()
    C_Timer.After(5, function() frameWidget:ShowGroup() end)
end

---Sometimes there's a delay. Fire immediately, then after a few seconds
--- @param frameWidget FrameWidget
local function OnPlayerLeaveCombat(frameWidget, e, ...)
    OnActionbarShowGroup(frameWidget, e, ...)
    L:PostCombatUpdateComplete()
end

--- @param frameWidget FrameWidget
local function OnActionbarHideGroup(frameWidget, e, ...)
    frameWidget:HideGroup()
    C_Timer.After(5, function() frameWidget:HideGroup() end)
end

--- @param frameWidget FrameWidget
local function OnUpdateItemStates(frameWidget, e, ...)
    --- @param bw ButtonUIWidget
    frameWidget:ApplyForEachItem(function(bw) bw:UpdateItemState() end)
end

---@param widget FrameWidget
local function RegisterCallbacks(widget)
    --- Use new AceEvent each time or else, the message handler will only be called once
    local AceEventInCallback = ns:AceEvent()
    AceEventInCallback:RegisterMessage(M.OnAddOnReady, function(msg) OnAddOnReady(widget, msg) end)
    AceEventInCallback:RegisterMessage(M.EQUIPMENT_SETS_CHANGED, function(msg) OnEquipmentSetsChanged(widget, msg) end)
    AceEventInCallback:RegisterMessage(M.EQUIPMENT_SWAP_FINISHED, function(msg) OnEquipmentSwapFinished(widget, msg) end)
    AceEventInCallback:RegisterMessage(M.MODIFIER_STATE_CHANGED, function(msg, ...) OnModifierStateChanged(widget, msg, ...) end)
    AceEventInCallback:RegisterMessage(M.OnPlayerAurasAdded, function(msg, playerAuras)
        O.PlayerAuraUtil.OnPlayerAurasAdded(widget, playerAuras) end)
    AceEventInCallback:RegisterMessage(M.OnPlayerAuraRemoved, function(msg, playerAura)
        O.PlayerAuraUtil.OnPlayerAuraRemoved(widget, playerAura) end)

    widget:SetCallback(E.OnCooldownTextSettingsChanged, OnCooldownTextSettingsChanged)
    widget:SetCallback(E.OnTextSettingsChanged, OnTextSettingsChanged)
    widget:SetCallback(E.OnMouseOverGlowSettingsChanged, OnMouseOverGlowSettingsChanged)
    widget:SetCallback(E.OnButtonSizeChanged, OnButtonSizeChanged)
    widget:SetCallback(E.OnButtonCountChanged, OnButtonCountChanged)
    widget:SetCallback(O.FrameHandleMixin.E.OnDragStop_FrameHandle, OnDragStop_FrameHandle)

    widget:SetCallback(E.OnActionbarFrameAlphaUpdated, OnActionbarFrameAlphaUpdated)
    widget:SetCallback(E.OnActionbarShowEmptyButtonsUpdated, OnActionbarShowEmptyButtonsUpdated)
    widget:SetCallback(E.OnActionbarShowGrid, OnActionbarShowGrid)
    widget:SetCallback(E.OnActionbarHideGrid, OnActionbarHideGrid)

    widget:SetCallback(E.OnHideWhenTaxiChanged, OnHideWhenTaxiChanged)
    widget:SetCallback(E.OnFrameHandleMouseOverConfigChanged, OnMouseOverFrameHandleConfigChanged)
    widget:SetCallback(E.OnFrameHandleAlphaConfigChanged, OnFrameHandleAlphaConfigChanged)
    widget:SetCallback(E.OnActionbarHideGroup, OnActionbarHideGroup)
    widget:SetCallback(E.OnActionbarShowGroup, OnActionbarShowGroup)
    widget:SetCallback(E.OnUpdateItemStates, OnUpdateItemStates)
    widget:SetCallback(E.OnPlayerLeaveCombat, OnPlayerLeaveCombat)

    --todo next: move events from ButtonUI to here 'coz it's more performant/efficient
    --widget:SetCallback("OnUnitSpellcastSent", OnUnitSpellcastSent)
    --widget:SetCallback("OnCurrentSpellcastChanged", OnCurrentSpellcastChanged)
end

--- @param widget FrameWidget
local function RegisterEvents(widget)
    --- @param w FrameWidget
    local function OnPlayerEnterCombatFrameWidget(w) w:SetCombatLockState() end
    --- @param w FrameWidget
    local function OnPlayerLeaveCombatFrameWidget(w) w:SetCombatUnlockState() end

    widget:RegisterEvent(E.PLAYER_REGEN_DISABLED, OnPlayerEnterCombatFrameWidget, widget)
    widget:RegisterEvent(E.PLAYER_REGEN_ENABLED, OnPlayerLeaveCombatFrameWidget, widget)
    --todo next: move events from ButtonUI to here 'coz it's more performant/efficient
end


--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- @param widget __FrameWidget | _Frame
local function WidgetMethods(widget)
    local AssertThatMethodArgIsNotNil = Assert.AssertThatMethodArgIsNotNil

    local profile = widget.profile
    local frame = widget.frame

    function widget:GetName() return widget.frame:GetName() end

    ---@param btnIndex Index
    function widget:GetButtonName(btnIndex) return self:GetName() .. 'Button' .. btnIndex end

    --- @deprecated Use self#GetIndex()
    function widget:GetFrameIndex() return self:GetIndex() end
    function widget:GetIndex() return self.index end

    --- @return Profile_Bar
    function widget:conf() return profile:GetBar(self:GetIndex()) end

    --- @deprecated Use #conf
    --- @return Profile_Bar
    function widget:GetConfig() return profile:GetBar(self:GetIndex()) end

    function widget:InitAnchor()
        local anchor = P:GetAnchor(self.index)
        local relativeTo = anchor.relativeTo and _G[anchor.relativeTo] or nil
        if GC:IsVerboseLogging() and frame:IsShown() then
            p:log('InitAnchor| anchor-from-profile[f.%s]: %s', self.index, anchor)
        end
        if InCombatLockdown() then return end
        frame:ClearAllPoints()
        frame:SetPoint(anchor.point, relativeTo , anchor.relativePoint, anchor.x, anchor.y)
    end

    function widget:UpdateAnchor()
        local n = frame:GetNumPoints()
        if n <= 0 then return end

        --- @type _RegionAnchor
        local frameAnchor = AnchorUtil.CreateAnchorFromPoint(frame, 1)
        P:SaveAnchor(frameAnchor, self.index)
    end

    function widget:ResetAnchor()
        local f = self.frame
        f:ClearAllPoints()
        f:SetPoint('CENTER', nil, 'CENTER', 0, 0)
        self:UpdateAnchor()
    end

    function widget:IsLockedInCombat() return profile:IsBarLockedInCombat(self:GetFrameIndex()) end
    function widget:SetCombatLockState() if self:IsLockedInCombat() then self:LockGroup() end end
    function widget:SetCombatUnlockState() if self:IsLockedInCombat() then self:UnlockGroup() end end

    --- @return boolean
    function widget:IsFrameEnabledInConfig() return P:IsBarNameEnabled(self:GetName()) end

    function widget:SetFrameState(isEnabled)
        local frameIndex = self:GetIndex()
        AssertThatMethodArgIsNotNil(frameIndex, 'frameIndex', 'SetFrameState(frameIndex)')
        P:SetBarEnabledState(frameIndex, isEnabled)
        if isEnabled then
            if self.ShowGroup then self:ShowGroup() end
            return
        end
        if self.HideGroup then self:HideGroup() end
    end

    -- Not sure what the use case is for this
    -- Synchronize UI and Profile data
    --[[function widget:IsShownInConfigSynchronize()
        local frameIndex = self:GetIndex()
        AssertThatMethodArgIsNotNil(frameIndex, 'frameIndex', 'IsShownInConfig(frameIndex)')
        local actualFrameIsShown = frame:IsShown()
        P:SetBarEnabledState(frameIndex, actualFrameIsShown)
        return P:IsBarEnabled(frameIndex)
    end]]

    -- Synchronize UI and Profile data
    function widget:IsShownInConfig() return P:IsBarEnabled(self.index) end

    function widget:IsShowIndex() return P:IsShowIndex(self:GetFrameIndex()) end
    function widget:IsShowKeybindText() return P:IsShowKeybindText(self:GetFrameIndex()) end

    --- @param state boolean true will show button indices
    function widget:ShowButtonIndices(state)
        local theState = (state == true)
        self:GetConfig().show_button_index = theState
        --- @param bw ButtonUIWidget
        self:ApplyForEachButton(function(bw) bw:ShowIndex(theState) end)
    end
    --- @param state boolean true will show button indices
    function widget:ShowKeybindText(state)
        local theState = (state == true)
        self:GetConfig().show_keybind_text = theState
        --- @param bw ButtonUIWidget
        self:ApplyForEachButton(function(bw)
            bw:ShowKeybindText(theState)
            bw:UpdateKeybindTextState()
        end)
    end

    function widget:UpdateKeybindText()
        self:ShowKeybindText(self:IsShowKeybindText())
    end

    --- @param applyFunction ButtonHandlerFunction | "function(btnWidget) print(btnWidget:GetName()) end"
    function widget:ApplyForEachButton(applyFunction)
        if self:HasEmptyButtons() then return end
        -- `_` is the index
        --- @param btn ButtonUI
        for _, btn in ipairs(self.buttonFrames) do applyFunction(btn.widget) end
    end

    --- @param applyFunction ButtonHandlerFunction | "function(btnWidget) print(btnWidget:GetName()) end"
    function widget:ApplyForEachButtonNoCond(applyFunction)
        --- @param btn ButtonUI
        for _, btn in ipairs(self.buttonFrames) do
            applyFunction(btn.widget)
        end
    end

    --- @param applyFunction ButtonHandlerFunction | "function(btnWidget) print(btnWidget:GetName()) end"
    function widget:ApplyForEachItem(applyFunction)
        if self:HasEmptyButtons() then return end
        -- `_` is the index
        --- @param btn ButtonUI
        for _, btn in ipairs(self.buttonFrames) do
            if btn.widget:IsItem() then applyFunction(btn.widget) end
        end
    end

    --- @param matchSpellId number
    --- @param applyFunction ButtonHandlerFunction | "function(btnWidget) print(btnWidget:GetName()) end"
    function widget:ApplyForEachSpellOrMacroButtons(matchSpellId, applyFunction)
        self:fevb(function(btnWidget)
            return btnWidget:IsMatchingMacroOrSpell(matchSpellId)
        end, applyFunction)
    end
    --- Alias for #ApplyForEachSpellOrMacroButtons(matchSpellId, applyFunction)
    --- @param matchSpellId number
    --- @param applyFunction ButtonHandlerFunction | "function(btnWidget) print(btnWidget:GetName()) end"
    function widget:fesmb(matchSpellId, applyFunction)
        self:ApplyForEachSpellOrMacroButtons(matchSpellId, applyFunction)
    end

    --- @param applyFunction ButtonHandlerFunction | "function(btnWidget) print(btnWidget:GetName()) end"
    function widget:ApplyForEachMacro(applyFunction)
        self:fevb(function(btnWidget) return btnWidget:IsMacro() end, applyFunction)
    end

    --- Apply for each button with a filter
    --- @param predicateFn ButtonPredicateFunction | "function(btnWidget) return true end"
    --- @param applyFn ButtonHandlerFunction | "function(btnWidget) print(btnWidget:GetName()) end"
    function widget:ApplyForEachButtonCondition(predicateFn, applyFn)
        if self:HasEmptyButtons() then return end
        -- `_` is the index
        --- @param btn ButtonUI
        for _, btn in ipairs(self.buttonFrames) do
            if true == predicateFn(btn.widget) then applyFn(btn.widget) end
        end
    end
    --- Alias for #ApplyForEachButtonCondition(predicateFn, applyFn)
    --- @param predicateFn ButtonPredicateFunction | "function(btnWidget) return true end"
    --- @param applyFn ButtonHandlerFunction | "function(btnWidget) print(btnWidget:GetName()) end"
    function widget:fevb(predicateFn, applyFn) self:ApplyForEachButtonCondition(predicateFn, applyFn) end

    --- Alias for #ApplyForEachButton(applyFn)
    --- @param applyFunction ButtonHandlerFunction | "function(btnWidget) print(btnWidget:GetName()) end"
    function widget:feb(applyFunction) self:ApplyForEachButton(applyFunction) end

    function widget:SetGroupState(isShown)
        if isShown == true then
            if self.ShowGroup then self:ShowGroup() end
            return
        end
        if self.HideGroup then self:HideGroup() end
    end

    function widget:ToggleVisibility()
        local barData = self:GetConfig()
        local enabled = barData.enabled
        barData.enabled = not enabled
        if enabled then
            self:HideGroup()
            return
        end

        self:ShowGroup()
    end

    function widget:LockGroup() if InCombatLockdown() then return end; self.frameHandle:Hide() end
    function widget:UnlockGroup() if InCombatLockdown() then return end; self.frameHandle:Show() end
    function widget:Hide() if InCombatLockdown() then return end; frame:Hide() end
    function widget:Show() if InCombatLockdown() then return end; frame:Show() end

    function widget:HideGroup()
        self:Hide()
        self:HideButtons()
    end

    function widget:ShowGroup()
        self:InitAnchor()
        self:Show()
        self:ShowButtons()
    end

    --- @param predicateFn ButtonHandlerFunction | "function(btnWidget) return btnWidget:IsEmpty() end"
    --- @return ButtonUI
    function widget:FindFirst(predicateFn)
        for _, btn in ipairs(self.buttonFrames) do
            if predicateFn(btn.widget) then return btn end
        end
    end

    ---@param btnName string
    function widget:SaveButton(btnName)
        --- @type ButtonUI
        local sourceBtn = _G[btnName]; if not sourceBtn then return end
        local sourceWidget = sourceBtn.widget; if sourceWidget:IsEmpty() then return end

        local targetBtn = self:FindFirst(function(btnWidget)
            if btnWidget:IsEmpty() then return btnWidget end
        end)
        if not targetBtn then return end
        local conf = sourceWidget:conf()

        local btnWidget = targetBtn.widget
        local setter = btnWidget:GetAttributesSetter(conf.type)
        if setter then
            Mixin(btnWidget:conf(), conf)
            setter:SetAttributes(btnWidget.button())
            btnWidget:UpdateStateDelayed()
            btnWidget:EnableMouse(true)
        end
        sourceWidget:SetButtonAsEmpty()
    end

    function widget:ScrubEmptyButtons()
        local barConf = self:conf()
        self:ApplyForEachButtonNoCond(function(bw)
            P:CleanupActionTypeData(bw)
        end)
        self:SaveAndScrubDeletedButtons()
    end

    --- @param saveExisting BooleanOptional
    function widget:SaveAndScrubDeletedButtons(saveExisting)
        local save = saveExisting == true

        local barConf = self:conf()
        local start = (barConf.widget.rowSize * barConf.widget.colSize) + 1

        for i = start, configHandler.maxButtons do
            local btnName = self:GetButtonName(i)
            if save == true then self:SaveButton(btnName) end
            if barConf.buttons[btnName] then barConf.buttons[btnName] = nil end
        end
    end

    function widget:HideUnusedButtons()
        local start = self:GetButtonCount() + 1
        local max =  O.Config.maxButtons
        for i=start, max do
            --- @type ButtonUI
            local existingBtn = self:GetButtonUI(i)
            if existingBtn then existingBtn.widget:Hide() end
        end
    end

    function widget:ShowGroupIfEnabled()
        if self:IsFrameEnabledInConfig() then
            self:ShowGroup()
            return
        end
        self:HideGroup()
    end

    function widget:ShowButtons()
        local isShowKeybindText = self:IsShowKeybindText()
        --- @param bw ButtonUIWidget
        self:ApplyForEachButton(function(bw)
            bw:ShowKeybindText(isShowKeybindText)
            bw:Show()
        end)
    end

    --- @param state boolean
    function widget:UpdateActionButtonMouseoverState(state)
        --- @param bw ButtonUIWidget
        self:ApplyForEachButton(function(bw)
            bw:SetHighlightEnabled(state)
        end)
    end

    function widget:HideButtons()
        --- @param bf ButtonUI
        for _, bf in ipairs(self.buttonFrames) do
            bf.widget:Hide()
        end
    end

    --- @param buttonFrame ButtonUI
    function widget:AddButtonFrame(buttonFrame)
        if not buttonFrame then return end
        tinsert(self.buttonFrames, buttonFrame)
    end

    function widget:GetButtonCount() return #self.buttonFrames end
    function widget:HasEmptyButtons() return self:GetButtonCount() <= 0 end
    --- hard code max button column size for now
    function widget:GetMaxButtonColSize() return 40 end
    function widget:GetButtons() return self.buttonFrames end

    function widget:GetButtonFrames() return self.buttonFrames end
    function widget:IsRendered() return self.rendered end
    function widget:IsNotRendered() return not self:IsRendered() end
    function widget:MarkRendered() self.rendered = true end

    function widget:SetInitialState()
        self:MarkRendered()
        self:SetLockedState()
        self:ShowButtonIndices(self:IsShowIndex())
        self:ShowKeybindText(self:IsShowKeybindText())
        self:SetInitialStateOnFrameHandle()
        self:UpdateButtonAlpha()
        C_Timer.After(0.1, function()
            self:ApplyForEachButton(function(bw)
                if not bw:IsEmpty() then return end
                bw:EnableMouse(false)
            end)
        end)
    end

    function widget:SetInitialStateOnFrameHandle() self.frameHandle:UpdateBackdropState() end

    function widget:UpdateButtonAlpha()
        local barConf = self:GetConfig()
        local buttonAlpha = barConf.widget.buttonAlpha
        if not buttonAlpha or buttonAlpha < 0 then buttonAlpha = 1.0 end
        self:ApplyForEachButton(function(bw)
            bw.button():SetAlpha(buttonAlpha)
        end)
    end

    function widget:UpdateEmptyButtonsSettings()
        --- @param bw ButtonUIWidget
        self:ApplyForEachButton(function(bw)
            if not bw:IsEmpty() then return end
            bw:SetTextureAsEmpty()
            bw:UpdateKeybindTextState()
        end)
    end

    function widget:SetLockedState()
        local frameIndex = self:GetIndex()
        if P:IsBarLockedAlways(frameIndex) then
            self:LockGroup()
        else P:IsBarUnlocked(frameIndex)
            self:UnlockGroup()
        end
    end

    function widget:RefreshActionbarFrame()
        self:SetFrameDimensions()
        --- @param bw ButtonUIWidget
        self:ApplyForEachButton(function(bw) bw:SetButtonProperties() end)
    end

    function widget:SetFrameDimensions()
        local barData = self:GetConfig()
        local widgetData = barData.widget
        local f = self.frame
        local frameHandle = self.frameHandle
        local widthAdj = self.padding
        local heightAdj = self.padding + self.dragHandleHeight
        local frameWidth = (widgetData.colSize * widgetData.buttonSize) + widthAdj
        frameHandle:SetWidth(frameWidth)
        frameHandle:SetHeight(self.frameHandleHeight)

        f:SetWidth(frameWidth)
        f:SetHeight((widgetData.rowSize * widgetData.buttonSize) + heightAdj)

        --TODO: Clears the backdrop
        -- frame backdrop when button is empty state
        --f:ClearBackdrop()
        --f:SetBackdrop(BACKDROP_GOLD_DIALOG_32_32)
        --f:ApplyBackdrop()
        --f:SetAlpha(0)
    end

    function widget:ClearButtons() self.buttonFrames = {} end

    --- @param buttonIndex number
    function widget:GetButtonName(buttonIndex)
        return format('%sButton%s', self:GetName(), tostring(buttonIndex))
    end

    --- @return ButtonUI
    function widget:GetButtonUI(buttonIndex) return _G[self:GetButtonName(buttonIndex)] end

    function widget:LayoutButtonGrid()
        local barConfig = self:GetConfig()
        local buttonSize = barConfig.widget.buttonSize
        local paddingX = self.horizontalButtonPadding
        local paddingY = self.verticalButtonPadding
        local horizontalSpacing = buttonSize;
        local verticalSpacing = buttonSize;
        local stride = barConfig.widget.colSize;
        -- TopLeftToBottomRight
        -- TopLeftToBottomRightVertical
        local layout = AnchorUtil.CreateGridLayout(GridLayoutMixin.Direction.TopLeftToBottomRight,
                stride, paddingX, paddingY, horizontalSpacing, verticalSpacing);
        --- Offset from the anchor point
        --- @param row number
        --- @param col number
        function layout:GetCustomOffset(row, col) return 0, 0 end

        --- @type _AnchorMixin
        local anchor = CreateAnchor("TOPLEFT", self:GetName(), "TOPLEFT", 0, -2);
        AnchorUtil.GridLayout(self.buttonFrames, anchor, layout);
    end
end

--- @return _Frame
function L:GetFrameByIndex(frameIndex)
    local frameName = P:GetFrameNameByIndex(frameIndex)
    return _G[frameName]
end

function L:IsFrameShownByIndex(frameIndex)
    return self:GetFrameByIndex(frameIndex):IsShown()
end

--- @param btnWidget ButtonUIWidget
function L:AddPostCombatUpdate(btnWidget) table.insert(PostCombatButtonUpdates, btnWidget) end

function L:PostCombatUpdateComplete()
    local count = #PostCombatButtonUpdates
    if count <= 0 then return end
    --- @param widget ButtonUIWidget
    for i, widget in ipairs(PostCombatButtonUpdates) do
        widget:SetButtonAttributes()
        PostCombatButtonUpdates[i] = nil
    end
end

function L:CreateActionbarFrames()
    local frameNames = {}
    for i=1, P:GetActionbarFrameCount() do
        local actionbarFrame = self:CreateFrame(i)
        tinsert(frameNames, actionbarFrame:GetName())
    end
    tsort(frameNames)
    return frameNames
end

--- @param frameIndex number
--- @return _Frame
function L:CreateFrame(frameIndex)
    local frameName = GC:GetFrameName(frameIndex)
    return CreateFrame('Frame', frameName, nil, GC.C.FRAME_TEMPLATE)
end

---@param frameIndex number
function L:Constructor(frameIndex)

    --- @class __ActionbarFrame
    local f = self:GetFrameByIndex(frameIndex) or self:CreateFrame(frameIndex)
    --- @alias ActionbarFrame __ActionbarFrame|_Frame

    --TODO: NEXT: Move frame strata to Settings
    local frameStrata = 'MEDIUM'
    f:SetFrameStrata(frameStrata)
    ---Alpha needs to be zero so that we can hide the buttons
    f:SetAlpha(0)

    --- @alias FrameWidget __FrameWidget | _Frame
    --- @class __FrameWidget : WidgetBase
    local __widget = {
        profile = P,
        index = frameIndex,
        frameHandleHeight = 4,
        dragHandleHeight = 0,
        padding = 2,
        --todo next: add to options UI
        horizontalButtonPadding = 1,
        verticalButtonPadding = 1,
        frameStrata = frameStrata,
        frameLevel = 1,
        --- @type ActionbarFrame
        frame = f,
        --- @type FrameHandle
        frameHandle = nil,
        rendered = false,
        buttons = {},
        --- @type table<number, ButtonUI>
        buttonFrames = {}
    }

    --- @type FrameWidget
    local widget = __widget

    -- Allows call to Use callbacks / RegisterEvent
    AceEvent:Embed(widget)

    widget.frame = f
    f.widget = widget

    widget.frameHandle = ABP_CreateFrameHandle(widget)
    widget.frameHandle:Show()

    RegisterWidget(widget, f:GetName() .. '::Widget')
    WidgetMethods(widget)
    RegisterCallbacks(widget)
    RegisterEvents(widget)

    widget:SetFrameDimensions()

    return widget
end

L.mt.__call = L.Constructor
