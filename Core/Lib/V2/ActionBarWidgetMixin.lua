--[[-----------------------------------------------------------------------------
ActionBarWidgetMixin: Similar to FrameWidget
-------------------------------------------------------------------------------]]

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local p, pformat = O.Logger:NewLogger('ActionBarWidgetMixin'), ns.pformat

--[[-----------------------------------------------------------------------------
New Library
-------------------------------------------------------------------------------]]
--- @alias ActionBarWidget ActionbarWidgetMixin
--- @class ActionbarWidgetMixin
local L = {
    index = -1,
    --- @type fun():ActionBarFrame
    frame = nil,
    --- @type table<Index, ActionButton>
    children = nil,
    frameHandleHeight = 4,
    dragHandleHeight = 0,
    padding = 2,
    horizontalButtonPadding = 1,
    verticalButtonPadding = 1,

    --- @type FrameStrata
    frameStrata = 'MEDIUM',
    --- @type FrameLevel
    frameLevel = 1,
}
ns.O.ActionbarWidgetMixin = L


--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
---@param o ActionbarWidgetMixin
local function PropsAndMethods(o)

    o.Profile = O.Profile

    --- ### Usage:
    --- ```
    --- frameWidget = CreateAndInitFromMixin('ActionBarWidgetMixin', actionBarFrame)
    --- ```
    ---@param actionBarFrame ActionBarFrame
    ---@param index Index The frame Index
    function o:Init(actionBarFrame, index)
        self.index = index
        self.children = {}
        self.frame = function() return actionBarFrame end
        self.frame().widget = function() return self end
    end

    --- @return Profile_Bar
    function o:conf() return self.Profile:GetBar(self.index) end

    --- @param btn ActionButton
    function o:AddButton(btn) table.insert(self.children, btn) end

    function o:GetButtons() return self.children end

    function o:InitAnchor()
        local anchor = O.Profile:GetAnchor(self.index); if not anchor then return nil end

        local relativeTo = anchor.relativeTo and _G[anchor.relativeTo] or nil
        local frame = self.frame()
        if GC:IsVerboseLogging() and frame:IsShown() then
            p:log('InitAnchor| anchor-from-profile[f.%s]: %s', self.index, anchor)
        end
        if InCombatLockdown() then return end
        frame:ClearAllPoints()
        frame:SetPoint(anchor.point, relativeTo , anchor.relativePoint, anchor.x, anchor.y)
    end

    function o:UpdateAnchor()
        local frame = self.frame()
        local n = frame:GetNumPoints()
        if n <= 0 then return end

        --- @type _RegionAnchor
        local frameAnchor = AnchorUtil.CreateAnchorFromPoint(frame, 1)
        O.Profile:SaveAnchor(frameAnchor, self.index)

        p:log(20, 'OnDragStop_FrameHandle| new-anchor[f #%s]: %s', self.index, pformat:D2()(frameAnchor))
    end



end; PropsAndMethods(L)
