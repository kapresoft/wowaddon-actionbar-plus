--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local pformat = ns.pformat
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub

local A, AT, W = O.Assert, O.ActionType, GC.WidgetAttributes
local AssertThatMethodArgIsNotNil = A.AssertThatMethodArgIsNotNil
local SPELL, ITEM, MACRO, MACRO_TEXT, MOUNT, COMPANION, BATTLE_PET =
    W.SPELL, W.ITEM, W.MACRO, W.MACRO_TEXT,
    W.MOUNT, W.COMPANION, W.BATTLE_PET



--[[-----------------------------------------------------------------------------
Interface
-------------------------------------------------------------------------------]]
--- @class DragEventHandler : BaseLibraryObject
local DragEventHandler = {
    --- @param self DragEventHandler
    --- @param btnUI ButtonUI
    --- @param cursorInfo CursorInfo
    ['Handle'] = function(self, btnUI, cursorInfo)  end,
    --- @param self DragEventHandler
    --- @param btn ActionButtonWidget
    --- @param cursor CursorUtil
    ['HandleV2'] = function(self, btn, cursor)  end
}

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
---@class ReceiveDragEventHandler : BaseLibraryObject
local L = LibStub:NewLibrary(M.ReceiveDragEventHandler); if not L then return end
local p = L.logger()

--- Handlers with Interface Method ==> `Handler:Handle(btnUI, spellCursorInfo)`
--- README: Also need to add the attribute setterin in ButtonFactor#AttributeSetters
--- @type table<string, DragEventHandler>
local handlers = {
    [W.SPELL] = O.SpellDragEventHandler,
    [W.ITEM] = O.ItemDragEventHandler,
    [W.MACRO] = O.MacroDragEventHandler,
    [W.MOUNT] = O.MountDragEventHandler,
    [W.COMPANION] = O.CompanionDragEventHandler,
    [W.BATTLE_PET] = O.BattlePetDragEventHandler,
    [W.MACRO_TEXT] = O.MacroDragEventHandler,
    [W.EQUIPMENT_SET] = O.EquipmentSetDragEventHandler,
}

---@param cursor CursorUtil
function L:IsSupportedCursorType(cursor)
    local handler = handlers[cursor:GetType()]
    if not (handler and handler.Handle) then return false end

    -- Optional method Supports():boolean
    if handler.Supports then return handler:Supports(cursor:GetCursor()) end

    return true
end

---@param cursor CursorUtil
---@param btnUI ButtonUI
function L:Handle(btnUI, cursor)
    local cursorInfo = cursor:GetCursor()
    AssertThatMethodArgIsNotNil(btnUI, 'btnUI', 'Handle(btnUI, actionType)')
    AssertThatMethodArgIsNotNil(cursorInfo, 'cursorInfo', 'Handle(btnUI, cursorInfo)')
    p:log(10, 'Handle| CursorInfo: %s', pformat:B()(cursorInfo))
    local actionType = cursorInfo.type

    if not self:IsSupportedCursorType(cursor) then return end

    handlers[actionType]:Handle(btnUI, cursorInfo)
    btnUI.widget:CleanupActionTypeData()
end

--- @param btn ActionButtonWidget
--- @param cursor CursorUtil
function L:HandleV2(btn, cursor)
    local handler = handlers[cursor:GetType()]; if not handler then return end
    local cursorInfo = cursor:GetCursor()
    p:log(10, 'HandleV2: CursorInfo=%s handler=%s',
            pformat:B()(cursorInfo), tostring(handler))

    if not self:IsSupportedCursorType(cursor) then return end
    if handler.HandleV2 then return handler:HandleV2(btn, cursor) end
    --btnUI.widget:CleanupOtherActionTypeData(cursor:GetType())
end
