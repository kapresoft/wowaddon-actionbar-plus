--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, GC = ns.O, ns.O.GlobalConstants

local AceEvent, M, TA =  O.AceLibrary.AceEvent, GC.M, GC.TooltipAnchor

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @class ActionbarPlusTooltipAnchorFrame : _Frame
local _ActionbarPlusTooltipAnchorFrame = {}

--- @class TooltipFrameHandlerWidget
local _TooltipFrameHandlerWidget = {
    --- @type ActionbarPlusTooltipAnchorFrame
    frame = {}
}

--- @class TooltipFrameHandler : BaseLibraryObject_WithAceEvent
local _TooltipFrameHandler = {
    --- @type fun() : Logger
    logger = {}
}

--- @type TooltipFrameHandler
local L = AceEvent:Embed({ logger = function() return ns.O.LogFactory('TooltipFrameHandler') end })
local p = L.logger()

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- @param evt string The event name
--- @param handler TooltipFrameHandler
local OnTooltipFrameUpdate = function(evt, handler, ...)
    local position, val = ...
    p:log(10, '[TooltipFrameHandler|%s] Received: %s=%s', evt, tostring(position), tostring(val))
    if not val then return end
    handler:UpdateTooltipAnchor(val)
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- @param o TooltipFrameHandler
local function MethodsAndProperties(o)

    --- @see Config
    o:RegisterMessage(M.OnTooltipFrameUpdate, function(msg, ...)
        p:log(10, 'MSG::R: %s', msg)
        OnTooltipFrameUpdate(msg, o, ...)
    end)

    --- @type TooltipFrameHandlerWidget
    o.widget = {}

    function o:OnShow()
        self.widget.frame = _G[GC.C.TOOLTIP_ANCHOR_FRAME_NAME]
        if not self.widget.frame then return end
        self.widget.frame:SetSize(1, 1)

        o:RegisterMessage(GC.M.OnAddOnInitialized, function(msg, ...)
            p:log(10, 'MSG::R: %s', msg)
            local names = GC.Profile_Config_Names
            local anchorType = ns.db.profile[names.tooltip_anchor_type] or GC.TooltipAnchor.CURSOR_TOPLEFT
            self:UpdateTooltipAnchor(anchorType)
        end)
    end

    function o:IsCursorAnchorType(anchorType) return O.String.StartsWithIgnoreCase(anchorType, 'cursor_') end

    --- @see TooltipAnchor
    --- @param anchorType string
    function o:UpdateTooltipAnchor(anchorType)
        if not anchorType or self:IsCursorAnchorType(anchorType) then return end

        local f = self.widget.frame
        local padX = 50
        local padY = 50

        f:ClearAllPoints()
        if TA.SCREEN_TOPLEFT == anchorType then
            ns.GameTooltipAnchor = 'ANCHOR_BOTTOMRIGHT'
            f:SetPoint('TOPLEFT', nil, 'TOPLEFT', padX, -(padY))
        elseif TA.SCREEN_TOPRIGHT == anchorType then
            ns.GameTooltipAnchor = 'ANCHOR_BOTTOMLEFT'
            f:SetPoint('TOPRIGHT', nil, 'TOPRIGHT', -(padX), -(padY))
        elseif TA.SCREEN_BOTTOMRIGHT == anchorType then
            ns.GameTooltipAnchor = 'ANCHOR_TOPRIGHT'
            f:SetPoint('BOTTOMRIGHT', nil, 'BOTTOMRIGHT', -(padX), padY)
        elseif TA.SCREEN_BOTTOMLEFT == anchorType then
            ns.GameTooltipAnchor = 'ANCHOR_TOPLEFT'
            f:SetPoint('BOTTOMLEFT', nil, 'BOTTOMLEFT', padX, padY)
        end
    end
end

MethodsAndProperties(L)

ABP_TooltipFrame = L
