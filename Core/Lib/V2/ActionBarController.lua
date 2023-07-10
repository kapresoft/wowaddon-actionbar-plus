--[[-----------------------------------------------------------------------------
File: ActionBarControllerMixin
Notes:
  - ActionBarControllerMixin <<extends>> _Frame
  - Load this after ActionBarController
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
local pformat = ns.pformat
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local Table, AceEvent = O.Table, O.AceLibrary.AceEvent
local IsEmptyTable = Table.IsEmpty

local p = O.Logger:NewLogger('ActionBarController')
--- @type table<number, string> array of frame names
local actionBars = {}

--[[-----------------------------------------------------------------------------
New Library
-------------------------------------------------------------------------------]]
--- @alias ActionBarController ActionBarControllerMixin | ActionBarBuilder | _Frame
--- @class ActionBarControllerMixin
local L = {}
--- #### See: ActionBarController.xml
ABP_ActionBarControllerMixin = L

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- self is Blizzard Frame
--- @param o ActionBarControllerMixin | ActionBarBuilder | _Frame
local function PropsAndMethods(o)

    function o:OnLoad()
        p:log(10, 'OnLoad: %s', self:GetName())
        ns.O.ActionBarController = self

        --ManyBars
        self:RegisterEvent("PLAYER_ENTERING_WORLD");

        --self:RegisterEvent("ACTIONBAR_PAGE_CHANGED");

        -- This is used for shapeshifts/stances
        -- self:RegisterEvent("UPDATE_BONUS_ACTIONBAR");

        --MainBar Only

        --Alternate Only
        --if ClassicExpansionAtLeast(LE_EXPANSION_WRATH_OF_THE_LICH_KING) then
        --    self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR");
        --    self:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR");
        --end

        --Shapeshift/Stance Only
        --self:RegisterEvent("UPDATE_SHAPESHIFT_FORM");
        --self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS");
        --self:RegisterEvent("UPDATE_SHAPESHIFT_USABLE");

        -- Possess Bar
        --self:RegisterEvent("UPDATE_POSSESS_BAR");

        -- MultiBarBottomLeft
        -- self:RegisterEvent("ACTIONBAR_SHOW_BOTTOMLEFT");
    end

    --- #### SEE: Interface/FrameXML/ActionBarController.lua#ActionBarController_UpdateAll()
    --- @param event string
    function o:OnEvent(event, ...)
        local arg1, arg2 = ...;
        p:log(10, 'OnEvent[%s]: args=[%s]', event, ns.pformat({...}))
        if ( event == "PLAYER_ENTERING_WORLD" ) then
            self:OnPlayerEnteringWord()
        end
    end

    function o:OnPlayerEnteringWord()
        self:UpdateAll()
    end

    --- #### SEE: Interface/FrameXML/ActionButton.lua#ActionButton_UpdateAction()
    ---@param force Boolean
    function o:UpdateAll(force)
        local frames = O.ActionBarActionEventsFrame.frames
        p:log(0, 'UpdateAll()::ActionButton Count: %s', #frames)
        -- If we have a skinned vehicle bar or skinned override bar, display the OverrideActionBar
        if not frames then return end
        for k, actionButton in pairs(frames) do
            p:log('ActionButton: Update()')
            --actionButton:Update(force)
        end
    end

end; PropsAndMethods(L)

--[[-----------------------------------------------------------------------------
Register Message:
• ActionBarController should be triggered by the 'OnAddOnReady' to guarntee that
  the add-on & db has been initialized.
-------------------------------------------------------------------------------]]
AceEvent:RegisterMessage(GC.M.OnAddOnReady, function(msg)
    p:log(10, 'MSG::R: %s', msg)
    if IsEmptyTable(actionBars) then ns.O.ActionBarController:Build() end
end)
