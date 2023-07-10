--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
---@type _GameTooltip
local GameTooltip = GameTooltip

--[[-----------------------------------------------------------------------------
Lua Vars
-------------------------------------------------------------------------------]]
local format, strlower = string.format, string.lower

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub

local Assert, String = O.Assert, O.String
local IsBlank, IsNotBlank, AssertNotNil = String.IsBlank, String.IsNotBlank, Assert.AssertNotNil
local API = O.API
local BAttr, WAttr, UAttr = GC.ButtonAttributes,  GC.WidgetAttributes, GC.UnitIDAttributes

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
---@class SpellAttributeSetter : BaseAttributeSetter
local L = LibStub:NewLibrary(M.SpellAttributeSetter); if not L then return end
local p = L:GetLogger()

---@type BaseAttributeSetter
local Base = LibStub(M.BaseAttributeSetter)

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]

---@param btnUI ButtonUI The UIFrame
---@param btnData Profile_Button The button data
function L:SetAttributes(btnUI, btnData)
    local w = btnUI.widget
    w:ResetWidgetAttributes()

    local spellInfo = w:GetSpellData()
    if type(spellInfo) ~= 'table' then return end
    if not spellInfo.id then return end
    AssertNotNil(spellInfo.id, 'btnData[spell].spellInfo.id')

    local spellIcon = GC.Textures.TEXTURE_EMPTY
    if spellInfo.icon then spellIcon = API:GetSpellIcon(spellInfo) end
    w:SetIcon(spellIcon)

    btnUI:SetAttribute(BAttr.UNIT2, UAttr.FOCUS)

    btnUI:SetAttribute(WAttr.TYPE, WAttr.SPELL)
    local spellAttrValue = API:GetSpellAttributeValue(spellInfo)
    btnUI:SetAttribute(WAttr.SPELL, spellAttrValue)

    self:OnAfterSetAttributes(btnUI)
end

---@param btn ActionButtonWidget The UIFrame
function L:SetAttributesV2(btn)
    local w = btn.widget
    btn:ResetWidgetAttributes()

    local spellInfo = btn:GetSpellData()
    if type(spellInfo) ~= 'table' then return end
    if not spellInfo.id then return end
    AssertNotNil(spellInfo.id, 'btnData[spell].spellInfo.id')

    local spellIcon = GC.Textures.TEXTURE_EMPTY
    if spellInfo.icon then spellIcon = API:GetSpellIcon(spellInfo) end
    btn:SetIcon(spellIcon)
    btn:SetAttribute(WAttr.TYPE, WAttr.SPELL)
    local spellAttrValue = API:GetSpellAttributeValue(spellInfo)
    btn:SetAttribute(WAttr.SPELL, spellAttrValue)
    --self:OnAfterSetAttributes(btn)
end

---@param btnUI ButtonUI
function L:ShowTooltip(btnUI)
    local w = btnUI.widget
    if not w:ConfigContainsValidActionType() then return end

    local spellInfo = w:GetSpellData()
    if w:IsInvalidSpell(spellInfo) then return end

    GameTooltip:SetSpellByID(spellInfo.id)

    -- Replace 'Spell' with 'Spell (Rank #Rank)'
    if (IsNotBlank(spellInfo.rank)) then
        GameTooltip:AppendText(format(' |cff565656(%s)|r', spellInfo.rank))
    end

end

L.mt.__index = Base
L.mt.__call = L.SetAttributes
