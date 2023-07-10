--[[-----------------------------------------------------------------------------
Notes:
  - ActionBarBuilderMixin <<extends>> _Frame
  - Load this before ActionBarController
  - See: ActionBarController.xml
-------------------------------------------------------------------------------]]

--[[-----------------------------------------------------------------------------
Lua Vars
-------------------------------------------------------------------------------]]
local tinsert, tsort = table.insert, table.sort
local sformat = string.format

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local pformat = ns.pformat
local p = O.Logger:NewLogger('ActionBarBuilder')

local CHECK_BUTTON_TEMPLATE = 'ABP_ActionBarButtonTemplate1'
local ACTION_BAR_FRAME_TEMPLATE = 'ABP_ActionBarFrameTemplate1'

--- @type table<number, string> array of frame names
local actionBars = {}

--[[-----------------------------------------------------------------------------
New Library
-------------------------------------------------------------------------------]]
--- @alias ActionBarBuilder ActionBarBuilderMixin | _Frame
--- @class ActionBarBuilderMixin
local L = {}
ABP_ActionBarBuilderMixin = L
ns.O.ActionBarBuilder = L

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
local function SetupButtonOne()
    local actionBar = ActionbarPlusF1
    if not (actionBar and actionBar.Button1) then return end
    --- @type ActionButton
    local b = actionBar.Button1
    b:SetAttribute('type', 'spell')
    local spell, _, icon = GetSpellInfo('Arcane Intellect')
    p:log(10, 'spell: %s icon: %s', tostring(spell), tostring(icon))
    b:SetAttribute('spell', spell)
    b:SetNormalTexture(icon)
    b:SetPushedTexture(icon)
    if b:GetNormalTexture() then
        b:GetNormalTexture():SetAllPoints(b)
    end

end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
---@param o ActionBarBuilderMixin | _Frame
local function PropsAndMethods(o)

    function o:profile() return O.Profile end

    function o:Build()
        local frameNames = L:CreateActionbarFrames()
        tsort(actionBars)

        for i, fn in ipairs(frameNames) do
            local f = self:CreateActionbarGroup(i, fn)
            --f:ShowGroupIfEnabled()
        end

        -- todo: temporary
        SetupButtonOne()
    end

    function o:CreateActionbarFrames()
        local frameCount = 1
        for i=1, frameCount do
            -- ActionBarTemplateMixing#OnLoad() will be triggered after Creation
            local actionBar = self:CreateFrame(i)
            actionBar.widget():InitAnchor()
            if not actionBar:IsVisible() then actionBar:Show() end
        end
        return actionBars
    end

    ---@param frameIndex number
    ---@param frameName string
    function o:CreateActionbarGroup(frameIndex, frameName)
        local barConfig = self:profile():GetBar(frameIndex)
        --local widget = barConfig.widget

        local rowSize = barConfig.widget.rowSize
        local colSize = barConfig.widget.colSize

        local f = _G[frameName]
        f.index = frameIndex
        self:CreateButtons(f, rowSize, colSize)
        --f:SetInitialState()
        return f
    end

    ---@param fw _Frame
    function o:CreateButtons(fw, rowSize, colSize)
        --fw:ClearButtons()
        local index = 0
        local children = fw:GetChildren()
        for row=1, rowSize do
            for col=1, colSize do
                index = index + 1
                --- @type _CheckButton
                local btnUI = fw['Button' .. index]
                if not btnUI then
                    btnUI = self:CreateSingleButton(fw, row, col, index)
                end
                tinsert(children, btnUI)
                p:log(10, 'Button[%s]: id=%s', btnUI:GetName(), btnUI:GetID())
                --fw:AddButtonFrame(btnUI)
            end
        end
        --self:HideUnusedButtons(fw)
        self:LayoutButtonGrid(fw)
    end

    --- @param frameWidget _Frame
    --- @param row number
    --- @param col number
    --- @param btnIndex number The button index number
    --- @return ButtonUIWidget
    function o:CreateSingleButton(frameWidget, row, col, btnIndex)
        local btnIndexName = sformat('Button%s', btnIndex)
        --local btnName = frameWidget:GetName() .. btnIndexName
        local btnName = sformat('$parent%s', btnIndexName)
        --- @type ActionBarButtonTemplate
        local checkButton = CreateFrame('CheckButton', btnName, frameWidget, CHECK_BUTTON_TEMPLATE, btnIndex)
        if checkButton.SetParentKey then checkButton:SetParentKey(btnIndexName) end
        checkButton.widget():SetButtonAttributes()


        -- todo: load button
        -- if not empty
        --checkButton:GetNormalTexture():SetAllPoints(checkButton)

        --checkButton:GetNormalTexture():SetAllPoints(checkButton.icon)

        --checkButton:GetNormalTexture():Hide()
        --checkButton:GetNormalTexture():SetSize(62, 62)
        --local pushedTexture = checkButton:GetPushedTexture()

        --checkButton:GetPushedTexture():SetAllPoints(checkButton)
        --checkButton.icon:SetAllPoints(checkButton)
        --checkButton.Background:SetAllPoints(checkButton)
        --checkButton:GetCheckedTexture():SetAllPoints(checkButton)
        --checkButton:GetHighlightTexture():SetAllPoints(checkButton)
        --btnWidget:SetPoint('LEFT', sformat('$parentButton%s', btnIndex - 1),
        --'RIGHT', 6, 0)
        --[[btnWidget:SetButtonAttributes()
        btnWidget:SetCallback("OnMacroChanged", OnMacroChanged)
        btnWidget:UpdateStateDelayed(0.05)]]
        return checkButton
    end

    --- @param frameIndex number
    --- @return ActionBarFrame
    function o:CreateFrame(frameIndex)
        local frameName = GC:GetFrameName(frameIndex)
        --- @type ActionBarFrame
        local f = CreateFrame('Frame', frameName, nil, ACTION_BAR_FRAME_TEMPLATE, frameIndex)
        f:ClearAllPoints()
        f:SetPoint('CENTER', nil, 'CENTER', 340, 250)
        f:RegisterForDrag('LeftButton')

        CreateAndInitFromMixin(ns.O.ActionbarWidgetMixin, f, frameIndex)
        f.frameIndex = frameIndex
        tinsert(actionBars, f:GetName())

        return f
    end

    --- @param f _Frame
    function o:LayoutButtonGrid(f)

        local backDropPadding = f:GetBackdrop().edgeSize/2
        local horizontalButtonPadding = 8
        local verticalButtonPadding = 8

        local barConfig = self:profile():GetBar(f.index)
        --local buttonSize = barConfig.widget.buttonSize
        local buttonSize = 36
        local paddingX = horizontalButtonPadding
        local paddingY = verticalButtonPadding
        local horizontalSpacing = buttonSize
        local verticalSpacing = buttonSize
        local stride = barConfig.widget.colSize
        -- TopLeftToBottomRight
        -- TopLeftToBottomRightVertical
        local layout = AnchorUtil.CreateGridLayout(GridLayoutMixin.Direction.TopLeftToBottomRight,
                stride, paddingX, paddingY, horizontalSpacing, verticalSpacing);
        --- Offset from the anchor point
        --- @param row number
        --- @param col number
        function layout:GetCustomOffset(row, col) return backDropPadding, -(backDropPadding - 2) end

        --- @type _AnchorMixin
        local anchor = CreateAnchor("TOPLEFT", f:GetName(), "TOPLEFT", 0, -2);
        local buttons = self:GetButtons(f)
        AnchorUtil.GridLayout(buttons, anchor, layout);

        --- @type _Texture
        local bg = f.Background
        local colSize = barConfig.widget.colSize
        local framePadding = 10
        local width = buttonSize * colSize + (horizontalButtonPadding * (colSize - 1)) + (framePadding*2)
        bg:SetSize(width, 100)

    end

    --- @param f _Frame
    function o:GetButtons(f)
        local buttons = {}
        local children = f:GetChildren()
        p:log(10, 'children: %s', #children)
        for i, child in ipairs(children) do
            p:log(10, 'child: %s', child:GetName())
            if child:GetObjectType() == 'CheckButton' then
                tinsert(buttons, child)
            end
        end
        return buttons
    end

end; PropsAndMethods(L)
