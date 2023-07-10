--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub

local p = ns.O.Logger:NewLogger('ActionBarActionEventsFrameMixin')

--- @alias ActionBarActionEventsFrame ActionBarActionEventsFrameMixin|_Frame
--- @class ActionBarActionEventsFrameMixin : _Frame_
local L = {}
--- @type table<number, ActionButton>
L.frames = {}

--- @type ActionBarActionEventsFrame
ABP_ActionBarActionEventsFrameMixin = L

-- The role of this class is to handle "Action Events" as a whole
-- for all action bars.
-- See Also ActionBarButtonEventsFrameMixin.lua
function L:OnLoad()
    p:log(10, 'OnLoad...')
    ns.O.ActionBarActionEventsFrame = self

    --self:RegisterEvent("ACTIONBAR_UPDATE_STATE");			not updating state from lua anymore, see SetActionUIButton
    self:RegisterEvent("ACTIONBAR_UPDATE_USABLE");
    --self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");		not updating cooldown from lua anymore, see SetActionUIButton
    self:RegisterEvent("SPELL_UPDATE_CHARGES");
    self:RegisterEvent("UPDATE_INVENTORY_ALERTS");
    self:RegisterEvent("PLAYER_TARGET_CHANGED");
    self:RegisterEvent("TRADE_SKILL_SHOW");
    self:RegisterEvent("TRADE_SKILL_CLOSE");
    self:RegisterEvent("PLAYER_ENTER_COMBAT");
    self:RegisterEvent("PLAYER_LEAVE_COMBAT");
    self:RegisterEvent("START_AUTOREPEAT_SPELL");
    self:RegisterEvent("STOP_AUTOREPEAT_SPELL");
    --self:RegisterEvent("UNIT_INVENTORY_CHANGED");
    self:RegisterEvent("LEARNED_SPELL_IN_TAB");
    --self:RegisterEvent("PET_STABLE_UPDATE");
    --self:RegisterEvent("PET_STABLE_SHOW");
    --self:RegisterEvent("LOSS_OF_CONTROL_ADDED");
    --self:RegisterEvent("LOSS_OF_CONTROL_UPDATE");
    self:RegisterEvent("SPELL_UPDATE_ICON");
end

--- #### SEE: Interface/FrameXML/ActionButton.lua#ActionBarActionEventsFrame_OnEvent()
--- Pass event down to the buttons
--- @param event string
function L:OnEvent(event, ...)
    p:log(0, 'OnEvent(%s): args=%s', event, ns.pformat({...}))

    for k, actionButton in pairs(self.frames) do
        p:log('Calling OnEvent[%s]', actionButton:GetName())
        actionButton:OnEvent(event, ...);
    end
end

---@param frame ActionButton
function L:RegisterFrame(frame)
    p:log(10, 'Frame Registered: %s', frame:GetName())
    self.frames[frame] = frame
    frame.eventRegistered = true
end

---@param frame ActionButton
function L:UnregisterFrame(frame)
    self.frames[frame] = nil
    frame.eventRegistered = false
end
