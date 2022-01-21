-- ## External -------------------------------------------------

-- ## Local ----------------------------------------------------
local LibStub, M, Assert, P, _, W, CC = ABP_WidgetConstants:LibPack()
local SpellAttributeSetter = W:SpellAttributeSetter()
local WidgetAttributes = CC.WidgetAttributes
local _API_Spell = _API_Spell

---@class SpellDragEventHandler
local _L = LibStub:NewLibrary(M.SpellDragEventHandler)

-- ## Functions ------------------------------------------------

---spellCursorInfo `{ type = actionType, name='TODO', bookIndex = info1, bookType = info2, id = info3 }`
---@param cursorInfo table Data structure`{ type = actionType, info1 = info1, info2 = info2, info3 = info3 }`
function _L:Handle(btnUI, cursorInfo)
    if not self:IsValid(btnUI, cursorInfo) then return end
    local spellCursorInfo = { type = cursorInfo.type,
                              id = cursorInfo.info3,
                              bookIndex = cursorInfo.info1,
                              bookType = cursorInfo.info2 }
    local spellInfo = _API_Spell:GetSpellInfo(spellCursorInfo.id)
    if Assert.IsNil(spellInfo) then return end

    local actionbarInfo = btnUI:GetActionbarInfo()
    local btnName = btnUI:GetName()
    local barData = P:GetBar(actionbarInfo.index)
    local btnData = barData.buttons[btnName] or P:GetTemplate().Button

    btnData.type = WidgetAttributes.SPELL
    btnData[WidgetAttributes.SPELL] = spellInfo
    barData.buttons[btnName] = btnData

    SpellAttributeSetter(btnUI, btnData)
end

function _L:IsValid(btnUI, cursorInfo)
    return cursorInfo.type == nil or cursorInfo == nil or cursorInfo.id == nil
end