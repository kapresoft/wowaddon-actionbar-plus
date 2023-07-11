--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local pformat = ns.pformat

local SpellAttributeSetter, WAttr, PH = O.SpellAttributeSetter, GC.WidgetAttributes, O.PickupHandler
local API, Assert = O.API, O.Assert
local IsNil = Assert.IsNil

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @class SpellDragEventHandler : DragEventHandler
local L = LibStub:NewLibrary(M.SpellDragEventHandler); if not L then return end
local p = L.logger()

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
---spellCursorInfo `{ type = actionType, name='TODO', bookIndex = info1, bookType = info2, id = info3 }`
---@param btnUI ButtonUI
---@param cursorInfo table Data structure`{ type = actionType, info1 = info1, info2 = info2, info3 = info3 }`
function L:Handle(btnUI, cursorInfo)
    if not self:IsValid(btnUI, cursorInfo) then return end
    local spellCursorInfo = { type = cursorInfo.type,
                              id = cursorInfo.info3,
                              bookIndex = cursorInfo.info1,
                              bookType = cursorInfo.info2 }

    local spellInfo = API:GetSpellInfo(spellCursorInfo.id)
    if IsNil(spellInfo) then return end

    local w = btnUI.widget
    if w:IsPassiveSpell(spellInfo.name) then return end

    local btnData = w:conf()
    PH:PickupExisting(w)
    btnData[WAttr.TYPE] = WAttr.SPELL
    btnData[WAttr.SPELL] = spellInfo

    SpellAttributeSetter(btnUI, btnData)
end



---@param btn ActionButtonWidget
---@param cursor CursorUtil
---@return boolean returns true if the cursor was handled appropriately
function L:HandleV2(btn, cursor)
    local spellCursor = API:ToSpellCursorInfo(cursor:GetCursor())
    p:log(0, 'HandleV2: btn=%s cursor=%s', btn.button():GetName(), pformat(spellCursor))
    if IsPassiveSpell(spellCursor.spellID) then return false end

    local type = spellCursor.type
    local d = btn:config()
    --PH:PickupExisting(btn)
    d[WAttr.TYPE] = type
    d[type] = API:GetSpellInfo(spellCursor.spellID)

    SpellAttributeSetter:SetAttributesV2(btn)

    return true
end


function L:IsValid(btnUI, cursorInfo)
    return cursorInfo.type == nil or cursorInfo == nil or cursorInfo.id == nil
end
