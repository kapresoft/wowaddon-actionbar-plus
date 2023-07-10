--This mixin handles events for the addon
--
--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
local CreateFrame, FrameUtil = CreateFrame, FrameUtil
local RegisterFrameForEvents, RegisterFrameForUnitEvents = FrameUtil.RegisterFrameForEvents, FrameUtil.RegisterFrameForUnitEvents

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, GC, LibStub = ns.O, ns.O.GlobalConstants, ns.O.LibStub

local BaseAPI, API, pformat = O.BaseAPI, O.API, ns.pformat
local E, MSG, UnitId = GC.E, GC.M,  GC.UnitId
local B = O.BaseAPI
local AceEvent, Table = O.AceLibrary.AceEvent, O.Table
local SizeOfTable, IsEmptyTable = Table.Size, Table.IsEmpty
local CURSOR_ITEM_TYPE = 1

--[[-----------------------------------------------------------------------------
Interface
-------------------------------------------------------------------------------]]
local ABPI = function() return O.ActionbarPlusAPI  end
local AU = function() return O.PlayerAuraUtil  end

--- @class EventFrameInterface : _Frame
local _EventFrame = {
    --- @type EventContext
    ctx = {}
}

--- @class EventContext
local _EventContext = {
    --- @type EventFrameInterface
    frame = {},
    --- @type ActionbarPlus
    addon = {},
    --- @type ButtonFactory
    buttonFactory = {},
    --- @type WidgetMixin
    widgetMixin = {},
}

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @class ActionbarPlusEventMixin : BaseLibraryObject_WithAceEvent
local L = LibStub:NewLibrary(ns.M.ActionbarPlusEventMixin)
AceEvent:Embed(L)
local p = L:GetLogger()

--- @param abp ActionbarPlus
L:RegisterMessage(MSG.OnAddOnInitialized, function(msg, abp)
    p:log(10, 'MSG::R: %s', msg)
    abp.addonEvents():RegisterEvents()
end)

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- @param f EventFrameInterface
--- @param event string
local function OnPlayerCombatEvent(f, event, ...)
    -- p:log(40, 'Event[%s] received...', event)
    if E.PLAYER_REGEN_ENABLED == event then
        f.ctx.buttonFactory:Fire(E.OnPlayerLeaveCombat)
    end

    f.ctx.buttonFactory:Fire(E.OnUpdateItemStates)
    -- This second fire is for fail-safety
    C_Timer.After(2, function() f.ctx.buttonFactory:Fire(E.OnUpdateItemStates) end)
end

--- @param f EventFrameInterface
--- @param event string
local function OnUpdateBindings(f, event, ...)
    if E.UPDATE_BINDINGS ~= event then return end
    f.ctx.buttonFactory:UpdateKeybindText()
end

--- @param f EventFrameInterface
--- @param event string
local function OnPetBattleEvent(f, event, ...)
    if E.PET_BATTLE_OPENING_START == event then
        f.ctx.buttonFactory:Fire(E.OnActionbarHideGroup)
        return
    end
    f.ctx.buttonFactory:Fire(E.OnActionbarShowGroup)
end

--- @param f EventFrameInterface
--- @param event string
local function OnVehicleEvent(f, event, ...)
    local unitTarget = ...
    if UnitId.player ~= unitTarget then return end
    if E.UNIT_ENTERED_VEHICLE == event then
        f.ctx.buttonFactory:Fire(E.OnActionbarHideGroup)
        return
    end
    f.ctx.buttonFactory:Fire(E.OnActionbarShowGroup)
end

--- @param f EventFrameInterface
--- @param event string
local function OnActionbarGrid(f, event, ...)
    p:log(30, 'Event received: %s', event)
    if InCombatLockdown() then return end
    if E.ACTIONBAR_SHOWGRID == event then
        f.ctx.buttonFactory:Fire(E.OnActionbarShowGrid)
        return
    end
    f.ctx.buttonFactory:Fire(E.OnActionbarHideGrid)
end

--- See Also: [https://wowpedia.fandom.com/wiki/CURSOR_CHANGED](https://wowpedia.fandom.com/wiki/CURSOR_CHANGED)
--- @param f EventFrameInterface
--- @param event string
local function OnCursorChangeInBags(f, event, ...)
    local isDefault, newCursorType, oldCursorType, oldCursorVirtualID = ...
    if true == isDefault and oldCursorType == CURSOR_ITEM_TYPE then
        f.ctx.buttonFactory:Fire(E.OnActionbarHideGrid)
        ABP.ActionbarEmptyGridShowing = false
        return
    end
    if InCombatLockdown() then return end
    if newCursorType ~= CURSOR_ITEM_TYPE then return end
    f.ctx.buttonFactory:Fire(E.OnActionbarShowGrid)
    ABP.ActionbarEmptyGridShowing = true
end

--- Non-Instant Start-Cast Handler
--- @param f EventFrameInterface
local function OnSpellCastStart(f, ...)
    --todo next: include item spells (i.e., quest items)
    local spellCastEvent = B:ParseSpellCastEventArgs(...)
    if UnitId.player ~= spellCastEvent.unitTarget then return end
    --p:log(50, 'OnSpellCastStart: %s', spellCastEvent)
    local w = f.ctx
    --- @param fw FrameWidget
    w.buttonFactory:fevf(function(fw)
        fw:fesmb(spellCastEvent.spellID, function(btnWidget)
            btnWidget:SetHighlightInUse() end)
    end)

    ---@param handlerFn ButtonHandlerFunction
    local function CallbackFn(handlerFn) ABPI():UpdateM6Macros(handlerFn) end
    L:SendMessage(MSG.OnSpellCastStartExt, ns.M.ActionbarPlusEventMixin, CallbackFn)

end

--- i.e. Casting a portal and moving triggers this event
--- @param f EventFrameInterface
local function OnSpellCastStop(f, ...)
    local spellCastEvent = B:ParseSpellCastEventArgs(...)
    if UnitId.player ~= spellCastEvent.unitTarget then return end
    p:log(30, 'OnSpellCastStop: %s', spellCastEvent)
    local w = f.ctx
    w.buttonFactory:fevf(function(fw)
        fw:fesmb(spellCastEvent.spellID, function(btn)
            btn:ResetHighlight() end)
    end)
    ---@param handlerFn ButtonHandlerFunction
    local function CallbackFn(handlerFn) ABPI():UpdateM6Macros(handlerFn) end
    L:SendMessage(MSG.OnSpellCastStopExt, ns.M.ActionbarPlusEventMixin, CallbackFn)
end

--- i.e. Conjure mana gem when there is already a mana gem in bag
--- @param f EventFrameInterface
local function OnSpellCastFailed(f, ...)
    local spellCastEvent = B:ParseSpellCastEventArgs(...)
    if UnitId.player ~= spellCastEvent.unitTarget then return end
    p:log(30, 'OnSpellCastFailed: %s', spellCastEvent)
    local w = f.ctx
    w.buttonFactory:fevf(function(fw)
        fw:fesmb(spellCastEvent.spellID, function(btn)
            btn:SetButtonStateNormal() end)
    end)

    ---@param handlerFn ButtonHandlerFunction
    local function CallbackFn(handlerFn) ABPI():UpdateM6Macros(handlerFn) end
    L:SendMessage(MSG.OnSpellCastFailedExt, ns.M.ActionbarPlusEventMixin, CallbackFn)

end

--- This handles 3-state spells like mage blizzard, hunter flares,
--- or basic campfire in retail
--- @param f EventFrameInterface
local function OnSpellCastSent(f, ...)
    local spellCastSentEvent = B:ParseSpellCastSentEventArgs(...)
    if not spellCastSentEvent or spellCastSentEvent.unit ~= UnitId.player then return end
    local w = f.ctx
    --- @param fw FrameWidget
    w.buttonFactory:fevf(function(fw)
        fw:fesmb(spellCastSentEvent.spellID, function(btn)
            btn:SetButtonStateNormal() end)
    end)
    ---@param handlerFn ButtonHandlerFunction
    local function CallbackFn(handlerFn) ABPI():UpdateM6Macros(handlerFn) end
    L:SendMessage(MSG.OnSpellCastSentExt, ns.M.ActionbarPlusEventMixin, CallbackFn)
end

--- @param f EventFrameInterface
local function OnSpellCastSucceeded(f, ...)
    --- @type ButtonFactory
    local bf = f.ctx.buttonFactory

    bf:fevf(function(fw)
        fw:feb(function(bw)
            if bw:IsSpell() then
                C_Timer.NewTicker(0.1, function() bw:UpdateSpellState() end, 2)
            elseif bw:IsItemOrMacro() then
                C_Timer.NewTicker(0.1, function() bw:UpdateItemOrMacroState() end, 2)
            end
        end)
    end)
    L:SendMessage(GC.M.OnSpellCastSucceeded, ns.M.ActionbarPlusEventMixin)
end

--- @param f EventFrameInterface
--- @param event string
local function OnActionbarEvents(f, event, ...)
    --p:log('e[%s]: %s', event, {...})
    if E.UNIT_SPELLCAST_START == event then
        OnSpellCastStart(f, ...)
    elseif E.UNIT_SPELLCAST_STOP == event then
        OnSpellCastStop(f, ...)
    elseif E.UNIT_SPELLCAST_SENT == event then
        OnSpellCastSent(f, ...)
    elseif E.UNIT_SPELLCAST_SUCCEEDED == event then
        OnSpellCastSucceeded(f, ...)
    elseif E.UNIT_SPELLCAST_FAILED_QUIET == event then
        OnSpellCastFailed(f, ...)
    end
end

--- @param eventWidget EventContext
local function OnStealth(eventWidget)
    --- @param fw FrameWidget
    eventWidget.buttonFactory:fevf(function(fw)
        --- @param bw ButtonUIWidget
        fw:fevb(
                function(bw) return bw:IsStealthSpell() end,
                function(bw)
                    local icon = API:GetSpellIcon(bw:GetSpellData())
                    bw:SetIcon(icon)
                end)
    end)
end

--- @param eventWidget EventContext
local function OnShapeShift(eventWidget)
    --- @param fw FrameWidget
    eventWidget.buttonFactory:fevf(function(fw)
        --- @param bw ButtonUIWidget
        fw:fevb(function(bw) return bw:IsShapeshiftSpell() end,
                function(bw)
                    local icon = API:GetSpellIcon(bw:GetSpellData())
                    bw:SetIcon(icon)
                end)
    end)
end

--- @param eventContext EventContext
local function OnStealthIconUpdate(eventContext)
    eventContext.buttonFactory:fevf(function(fw)
        fw:fevb(function(bw) return bw:IsStealthSpell() end,
                function(bw)
                    local icon = API:GetSpellIcon(bw:GetSpellData())
                    bw:SetIcon(icon)
                end)
    end)
end

--- Sequence is UPDATE_SHAPESHIFT_FORM, UPDATE_STEALTH, UPDATE_SHAPESHIFT_FORM; for this reason
--- @param f EventFrameInterface
--- @param event string
local function OnShapeshiftOrStealthEvent(f, event, ...)
    local eventWidget = f.ctx
    if E.UPDATE_STEALTH == event then
        OnStealth(eventWidget)
    elseif E.UPDATE_SHAPESHIFT_FORM == event then
        OnShapeShift(eventWidget)
    end
end

--- @param f EventFrameInterface
--- @param event string
---@param updateInfo UnitAuraUpdateInfo
local function OnPlayerAura(f, event, unitTarget, updateInfo)
    --p:log('E[%s]: unit=%s u=[%s] (%s)', event, unitTarget, pformat(updateInfo), GetTime())
    if GC.UnitId.player ~= unitTarget then return end

    local playerAuras = AU():GetPlayerSpellsFromAura(updateInfo)
    if SizeOfTable(playerAuras) > 0 then L:SendMessage(MSG.OnPlayerAurasAdded, playerAuras) end

    local removedAuras = AU():GetRemovedAuras(updateInfo)
    if SizeOfTable(removedAuras) > 0 then
        for rID, aura in pairs(removedAuras) do
            L:SendMessage(MSG.OnPlayerAuraRemoved, aura)
            AU():RemoveAura(aura)
        end
    end
end

--- @param f EventFrameInterface
--- @param event string
local function OnBagEvent(f, event, ...)

    L:SendMessage(MSG.OnBagUpdate, ns.M.ActionbarPlusEventMixin)

    ---@param handlerFn ButtonHandlerFunction
    local function CallbackFn(handlerFn) ABPI():UpdateM6Macros(handlerFn) end
    L:SendMessage(MSG.OnBagUpdateExt, ns.M.ActionbarPlusEventMixin, CallbackFn)
end

--- @param f EventFrameInterface
--- @param event string
local function OnMessageTransmitter(f, event, ...) L:SendMessage(GC.newMsg(event), ns.name, ...) end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- @param addon ActionbarPlus
function L:Init(addon)
    self.addon = addon
    self.buttonFactory = O.ButtonFactory
    self.widgetMixin = O.WidgetMixin
end

--- @return EventFrameInterface
function L:CreateEventFrame()
    local f = CreateFrame("Frame", nil, self.addon.frame)
    f.ctx = self:CreateContext(f)
    return f
end

--- @param eventFrame _Frame
--- @return EventContext
function L:CreateContext(eventFrame)
    local ctx = {
        frame = eventFrame,
        addon = self.addon,
        buttonFactory = self.buttonFactory,
        widgetMixin = self.widgetMixin
    }
    return ctx
end

function L:RegisterActionbarsEventFrame()
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnActionbarEvents)
    RegisterFrameForUnitEvents(f, {
        E.UNIT_SPELLCAST_START,
        E.UNIT_SPELLCAST_STOP,
        E.UNIT_SPELLCAST_SENT,
        E.UNIT_SPELLCAST_SUCCEEDED,
        E.UNIT_SPELLCAST_FAILED_QUIET,
    })
end

function L:RegisterShapeshiftOrStealthEventFrame()
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnShapeshiftOrStealthEvent)
    RegisterFrameForEvents(f, { E.UPDATE_STEALTH, E.UPDATE_SHAPESHIFT_FORM })
end

function L:RegisterKeybindingsEventFrame()
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnUpdateBindings)
    RegisterFrameForEvents(f, { E.UPDATE_BINDINGS })
end

function L:RegisterVehicleFrame()
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnVehicleEvent)
    RegisterFrameForUnitEvents(f, { E.UNIT_ENTERED_VEHICLE, E.UNIT_EXITED_VEHICLE }, GC.UnitId.player)
end

function L:RegisterActionbarGridEventFrame()
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnActionbarGrid)
    RegisterFrameForEvents(f, { E.ACTIONBAR_SHOWGRID, E.ACTIONBAR_HIDEGRID })
end

function L:RegisterCursorChangesInBagEvents()
    if BaseAPI:IsClassicEra() then return end
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnCursorChangeInBags)
    -- Note that this event does not fire in WoW Classic (i.e. 1.14.x)
    -- for non-consumable items in the bag like quest items
    RegisterFrameForEvents(f, { E.CURSOR_CHANGED })
end

function L:RegisterPetBattleFrame()
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnPetBattleEvent)
    RegisterFrameForEvents(f, { E.PET_BATTLE_OPENING_START, E.PET_BATTLE_CLOSE })
end

--- Use PLAYER_REGIN[ENABLED|DISABLED] is more reliable than using
--- PLAYER_[ENTER|LEAVE]_COMBAT event
function L:RegisterCombatFrame()
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnPlayerCombatEvent)
    RegisterFrameForEvents(f, { E.PLAYER_REGEN_ENABLED, E.PLAYER_REGEN_DISABLED })
end
function L:RegisterBagEvents()
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnBagEvent)
    RegisterFrameForEvents(f, { E.BAG_UPDATE, E.BAG_UPDATE_DELAYED })
end
function L:RegisterEventToMessageTransmitter()
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnMessageTransmitter)
    --- @see GlobalConstants#M (Messages)
    RegisterFrameForEvents(f, {
        E.PLAYER_ENTERING_WORLD,
        E.EQUIPMENT_SETS_CHANGED, E.EQUIPMENT_SWAP_FINISHED,
        E.PLAYER_MOUNT_DISPLAY_CHANGED, E.ZONE_CHANGED_NEW_AREA,
        E.MODIFIER_STATE_CHANGED,
    })
end
function L:RegisterPlayerEnteringWorld()
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnPlayerEnteringWorld)
    RegisterFrameForEvents(f, { E.PLAYER_ENTERING_WORLD })
end
function L:RegisterPlayerAura()
    local f = self:CreateEventFrame()
    f:SetScript(E.OnEvent, OnPlayerAura)
    RegisterFrameForUnitEvents(f, { E.UNIT_AURA }, GC.UnitId.player)
end

function L:RegisterEvents()
    if GC.V2 == true then return end

    p:log(30, 'RegisterEvents called..')
    self:RegisterActionbarsEventFrame()
    self:RegisterKeybindingsEventFrame()
    self:RegisterActionbarGridEventFrame()
    self:RegisterCursorChangesInBagEvents()
    self:RegisterShapeshiftOrStealthEventFrame()
    self:RegisterCombatFrame()
    self:RegisterBagEvents()
    self:RegisterEventToMessageTransmitter()
    self:RegisterPlayerEnteringWorld()
    --self:RegisterPlayerAura()
    if B:SupportsPetBattles() then self:RegisterPetBattleFrame() end
    --TODO: Need to investigate Wintergrasp (hides/shows intermittently)
    if B:SupportsVehicles() then self:RegisterVehicleFrame() end
end
