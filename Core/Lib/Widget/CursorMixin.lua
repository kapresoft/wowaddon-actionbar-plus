--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local W = GC.WidgetAttributes
local IsBlank, IsNotBlank = O.String.IsBlank, O.String.IsNotBlank

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @class CursorMixin : BaseLibraryObject
local L = LibStub:NewLibrary(M.CursorMixin); if not L then return end
local p = L:GetLogger()

-- Add to Modules.lua
--CursorMixin = 'CursorMixin',
--
----- @type CursorMixin
--CursorMixin = {},
--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- @param cursorInfo CursorInfo
local function GetMacroSubType(cursorInfo)
    if cursorInfo.type ~= W.MACRO then return nil end
    local macroSlot = cursorInfo.info1; if IsBlank(macroSlot) then return end
    local macroName = GetMacroInfo(macroSlot)
    if GC:IsM6Macro(macroName) then return W.MACRO_SUBTYPE_M6 end
    return nil
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- @param cursorInfo CursorInfo
function L:Init(cursorInfo)
    self.cursorInfo = cursorInfo
    if not self.cursorInfo then return end
    self.cursorInfo.subType = GetMacroSubType(self.cursorInfo)
end
function L:IsM6Macro() return self.cursorInfo.subType == W.MACRO_SUBTYPE_M6 end

--- @return boolean
function L:IsValid()
    if not self.cursorInfo or IsBlank(self.cursorInfo.type) then
        p:log(20, 'Received drag event with invalid cursor info. Skipping...')
        -- This can happen if a chat tab or others
        -- is dragged into the action bar.
        return false
    end
    p:log(20, 'Cursor is valid: %s', self.cursorInfo)
    return true
end
--- @return ActionTypeName
function L:GetType() return self.cursorInfo.type end

--- @return string The cursor subType, i.e. 'm6'
function L:GetSubType() return self.cursorInfo.subType end

--- @return CursorInfo
function L:GetCursor() return self.cursorInfo end

function L:ClearCursor() ClearCursor() end

function L:IsSpell() return 'spell' == self:GetType() end
function L:IsItem() return 'item' == self:GetType() end
function L:IsMacro() return 'macro' == self:GetType() end
function L:IsMount() return 'mount' == self:GetType() end
function L:IsBattlePet() return 'battlepet' == self:GetType() end
function L:IsPetAction() return 'petaction' == self:GetType() end
function L:IsMoney() return 'money' == self:GetType() end
function L:IsEquipmentSet() return 'equipmentset' == self:GetType() end
function L:IsCompanion() return 'companion' == self:GetType() end
function L:IsMacroText() return 'macrotext' == self:GetType() end
