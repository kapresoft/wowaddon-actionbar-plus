--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local pformat = ns.pformat
local p = O.Logger:NewLogger('ActionBarButtonTemplateMixin')
local ButtonEvents = ABP_ActionBarButtonEventsFrameMixin

--[[-----------------------------------------------------------------------------
New Library
-------------------------------------------------------------------------------]]
--- @alias ActionBarButtonTemplate ActionBarButtonTemplateMixin | _CheckButton
--- @class ActionBarButtonTemplateMixin
local L = {
    --- @type fun():ActionButtonWidget
    widget = nil
}
ABP_ActionBarButtonTemplateMixin = L

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
---@param o ActionBarButtonTemplateMixin | _CheckButton
local function PropsAndMethods(o)

    function o:OnLoad()
        p:log(10, 'OnLoad: %s buttonSize: %s', self:GetName(),
                tostring(self:GetAttribute("buttonSize")))

        CreateAndInitFromMixin(ns.O.ActionButtonWidgetMixin, self)

        -- not sure if we need this
        --ButtonEvents:RegisterFrame(self)

        -- cvar ActionButtonUseKeyDown set to 1
        self:RegisterForDrag("LeftButton", "RightButton")
        self:RegisterForClicks("AnyDown")
    end

    ---@param button ButtonName
    ---@param down ButtonDown
    function o:PreClick(button, down)
        p:log(10, 'PreClick')
        self:UpdateState(button, down)
    end

    ---@param button ButtonName
    ---@param down ButtonDown
    function o:PostClick(button, down)
        p:log(10, 'PostClick')
        self:UpdateState(button, down)
    end

    function o:OnDragStart(...)
        p:log('OnDragStart[%s]: args=%s', self:GetName(), pformat({...}))
    end

    function o:OnDragStop(...)
        p:log('OnDragStart[%s]: args=%s', self:GetName(), pformat({...}))
    end

    function o:OnReceiveDrag()
        self.widget():OnReceiveDragHandler()
    end

    function o:OnEnter(...)
        p:log(10, 'OnEnter[%s]: args=%s', self:GetName(), pformat({...}))
        --self:RegisterForClicks("AnyUp")
        GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
        GameTooltip:AddLine(self:GetName())
        GameTooltip:Show()
    end

    function o:OnLeave(...)
        p:log(10, 'OnLeave[%s]: args=%s', self:GetName(), pformat({...}))
        --self:RegisterForClicks("AnyDown")
        GameTooltip:Hide()
    end

    ---@param button ButtonName
    ---@param down ButtonDown
    function o:UpdateState(button, down)

    end

    function o:OnMouseUp(frame, button)
        self:SetChecked(false)
    end

    -- This doesn't get called
    function o:OnEvent(event)
        p:log('ActionBarButtonCodeMixin::OnEvent: %s', self:GetName())
    end

end; PropsAndMethods(L)
