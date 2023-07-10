--[[-----------------------------------------------------------------------------
Lua Vars
-------------------------------------------------------------------------------]]
local tinsert = table.insert

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]

--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local p = ns.O.Logger:NewLogger('ActionBarButtonEventsFrameMixin')

--- @alias ActionBarButtonEventsFrame ActionBarButtonEventsFrameMixin|_Frame
--- @class ActionBarButtonEventsFrameMixin : _Frame_
local L = {}
--- type table<number, _CheckButton>
---L.frames = {}

--- @type ActionBarButtonEventsFrame
ABP_ActionBarButtonEventsFrameMixin = L
ns.O.ActionBarButtonEventsFrame = L

-- The role of this Lua file is to handle individual button events
-- See Also: ActionBarActionEventsFrameMixin.lua
function L:OnLoad()
    p:log(10, 'OnLoad...')

    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    --self:RegisterEvent("ACTIONBAR_SHOWGRID");
    --self:RegisterEvent("ACTIONBAR_HIDEGRID");
    --self:RegisterEvent("ACTIONBAR_SLOT_CHANGED");
    --self:RegisterEvent("UPDATE_BINDINGS");
    --self:RegisterEvent("UPDATE_SHAPESHIFT_FORM");
    --self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
    --self:RegisterEvent("PET_BAR_UPDATE");
    --self:RegisterEvent("UNIT_FLAGS");
    --self:RegisterEvent("UNIT_AURA");
    --self:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED");

end

--- Pass event down to the buttons
--- @param event string
function L:OnEvent(event, ...)
    p:log(10, 'OnEvent...')

    --[[for k, frame in pairs(self.frames) do
        ABP_ActionButtonUtil:OnEvent(frame, event, ...);
    end]]
end
--[[
---@param frame table<number, _CheckButton>
function L:RegisterFrame(frame) tinsert(self.frames, frame) end

---@param frame table<number, _CheckButton>
function L:UnregisterFrame(frame)
    -- implement me if needed
end]]




