--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
local GetSpellSubtext, GetSpellInfo, GetSpellLink = GetSpellSubtext, GetSpellInfo, GetSpellLink
local GetSpellCooldown, GetSpellCooldown
local C_ToyBox, C_Container = C_ToyBox, C_Container
local UnitIsDead, GetUnitName = UnitIsDead, GetUnitName
local UnitClass, IsStealthed, GetShapeshiftForm = UnitClass, IsStealthed, GetShapeshiftForm

--[[-----------------------------------------------------------------------------
Lua Vars
-------------------------------------------------------------------------------]]
local format = string.format
--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O = ns.O
local pformat = ns.pformat

local String = O.String
local IsAnyOf, IsBlank, IsNotBlank, strlower = String.IsAnyOf, String.IsBlank, String.IsNotBlank, string.lower
local DruidAPI, GC = O.DruidAPI, O.GlobalConstants
local BaseAPI, WAttr, UnitId = O.BaseAPI, GC.WidgetAttributes, GC.UnitId
local SPELL, ITEM, MACRO, MOUNT = WAttr.SPELL, WAttr.ITEM, WAttr.MACRO, WAttr.MOUNT

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @class API
local S = {}; ns:Register(ns.M.API, S)
local p = O.LogFactory(ns.M.API)

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--todo next: start using CursorHasSpell(),
--CursorHasItem() - True if the cursor currently holds an item.
--CursorHasMacro() - Returns 1 if the cursor is currently dragging a macro.
--CursorHasMoney() -
-- p:log('cursor-has-spell: %s', CursorHasSpell())
--- @return CursorInfo
function S:GetCursorInfo()
    -- actionType string spell, item, macro, mount, etc..
    local actionType, info1, info2, info3 = GetCursorInfo()
    if IsBlank(actionType) then return nil end
    --- @type CursorInfo
    local c = { type = actionType or '', info1 = info1, info2 = info2, info3 = info3 }

    local info2Lc = strlower(c.info2 or '')
    if c.type == 'companion' and 'mount' == info2Lc then
        c.info2 = info2Lc
        c.originalCursor = { type = c.type, info1 = c.info1, info2 = info2 }
        c.type = c.info2
    end

    return c
end

--- @param cursor CursorInfo
--- @return CursorInfo_Spell
function S:ToSpellCursorInfo(cursor)
    -- actionType string spell, item, macro, mount, etc..
    local actionType, info1, info2, info3 = GetCursorInfo()
    if 'spell' ~= actionType then return nil end
    --- @type CursorInfo_Spell
    local c = { type = cursor.type, spellIndex = info1, bookType = info2,
                spellID = cursor.info3 }
    return c
end

--- @see Blizzard_UnitId
function S:IsValidActionTarget() return self:HasTarget() and not UnitIsDead(UnitId.target) end
function S:HasTarget() return GetUnitName(UnitId.target) ~= nil end

--- @param spell SpellName
--- @param target UnitID
--- @return boolean
function S:IsSpellInRange(spell, target)
    local inRange = IsSpellInRange(spell, target);
    if inRange == nil then return nil end
    return inRange == true or inRange == 1
end

--- @param item ItemName
--- @param target UnitID
--- @return BooleanOptional A return of nil means that the item is not applicable for the target unit
function S:IsItemInRange(item, target)
    local inRange = IsItemInRange(item, target)
    if inRange == nil then return nil end
    return inRange == true or inRange == 1
end

---Note: should call ButtonData:ContainsValidAction() before calling this
--- @param btnConfig Profile_Button
--- @param targetUnit string one of "target", "focus", "mouseover", etc.. See Blizz APIs
--- @return BooleanOptional true, false or nil if not applicable; nil if spell cannot be applied to unit, i.e. targeting a harmful unit on a friendly player
function S:IsActionInRange(btnConfig, targetUnit)
    if btnConfig.type == SPELL then
        return self:IsSpellInRange(btnConfig.spell.name, targetUnit)
    elseif btnConfig.type == MACRO then
        local macroIndex = btnConfig.macro.index
        local spellName = self:GetMacroSpell(macroIndex)
        return self:IsSpellInRange(spellName, targetUnit)
    elseif btnConfig.type == ITEM then
        local itemName = btnConfig.item.name
        return self:IsItemInRange(itemName, targetUnit)
    end

    return false
end

--- @param item Profile_Item
--- @return Profile_Item
function S:UpdateAndGetItemData(item)
    if not item.classID then
        local itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID = GetItemInfoInstant(item.id)
        --p:log(10, 'Item[%s]: retrieved classID=%s subclassID=%s', item.name, classID, subclassID)
        item.classID = classID
        item.subclassID = subclassID
    end
    return item
end

--- ### See: Enum.ItemClass
--- ```
--- Enum.ItemClass = {
---    Armor = 4,
---    Battlepet = 17,
---    Consumable = 0,
---    Container = 1,
---    CurrencyTokenObsolete = 10,
---    Gem = 3,
---    Glyph = 16,
---    ItemEnhancement = 8,
---    Key = 13,
---    Miscellaneous = 15,
---    PermanentObsolete = 14,
---    Profession = 19,
---    Projectile = 6,
---    Questitem = 12,
---    Quiver = 11,
---    Reagent = 5,
---    Recipe = 9,
---    Tradegoods = 7,
---    Weapon = 2,
---    WoWToken = 18
--- }
--- ```
---
--- This updates the item config and retrieve the classID and subClassID data
---@param item Profile_Item
---@param retrieveUpdate OptionalFlag Set to true to retrieve updated item if classID is missing
function S:IsItemConsumable(item, retrieveUpdate)
    local itemData = item
    local doUpdate = retrieveUpdate or true
    if itemData.classID == nil and doUpdate == true then
        itemData = self:UpdateAndGetItemData(item)
        p:log('Retrieved updated item data: %s', item.name)
    end
    return itemData.classID == Enum.ItemClass.Consumable
end

function S:CanApplySpellOnTarget(spellName) return IsSpellInRange(spellName, UnitId.target) ~= nil end


--- @param spellNameOrId SpellID_Name_Or_Index Spell ID or Name
--- @return SpellInfo
function S:GetSpellInfo(spellNameOrId)
    if not spellNameOrId then return nil end

    local name, _, icon, castTime, minRange, maxRange, id = GetSpellInfo(spellNameOrId)
    if not name then return end

    local subTextOrRank = GetSpellSubtext(spellNameOrId)
    local spellLink = GetSpellLink(spellNameOrId)
    --- @type SpellInfo
    local spellInfo = {
        id = id, name = name, icon = icon,
        link = spellLink, castTime = castTime,
        minRange = minRange, maxRange = maxRange, rank = subTextOrRank,
        isShapeshift = false, isStealth = false, isProwl = false }
    self:ApplySpellInfoAttributes(spellInfo)

    return spellInfo
end

function S:ApplySpellInfoAttributes(spellInfo)
    if not spellInfo then return end
    spellInfo.label = spellInfo.name
    if IsNotBlank(spellInfo.rank) then
        -- color codes format: |cAARRGGBB
        local labelFormat = '%s |c00747474(%s)|r'
        spellInfo.label = format(labelFormat, spellInfo.name, spellInfo.rank)
    end
    local rankLc = strlower(spellInfo.rank or '')
    local nameLc = strlower(spellInfo.name or '')

    -- Manual correction since [Moonkin Form] doesn't have rank as 'Shapeshift'
    if WAttr.MOONKIN_FORM == nameLc then spellInfo.rank = 'Shapeshift' end
    if WAttr.SHAPESHIFT == rankLc or WAttr.SHADOWFORM == nameLc then
        spellInfo.isShapeshift = true
    elseif WAttr.STEALTH == nameLc then spellInfo.isStealth = true
    elseif WAttr.PROWL == nameLc then spellInfo.isProwl = true end
end

--- @param macroIndex number
--- @return SpellID
function S:GetMacroSpellID(macroIndex) return macroIndex and GetMacroSpell(macroIndex) end

--- @param macroIndex number
--- @return SpellName, SpellID
function S:GetMacroSpell(macroIndex)
    local spellID = self:GetMacroSpellID(macroIndex)
    return spellID and GetSpellInfo(spellID), spellID
end

--- @param macroIndex number
--- @return Profile_Spell
function S:GetMacroSpellInfo(macroIndex)
    local spellId = self:GetMacroSpellID(macroIndex)
    return spellId and self:GetSpellInfo(spellId)
end
--- @param spellNameOrId string|number
function S:IsPassiveSpell(spellNameOrId) return IsPassiveSpell(spellNameOrId) end

--- @return SpellCooldownDetails
function S:GetSpellCooldownDetails(spellID, optionalSpell)
    local spell = optionalSpell or self:GetSpellInfo(spellID)
    if spell == nil then error("Spell not found: " .. spellID) end
    local start, duration, enabled, modRate = GetSpellCooldown(spellID);
    local cooldown = { start = start, duration = duration, enabled = enabled, modRate = modRate }
    --- @class SpellCooldownDetails
    local details = { spell = spell, cooldown = cooldown }
    return details
end

--- See: [GetSpellCooldown](https://wowpedia.fandom.com/wiki/API_GetSpellCooldown)
--- @param spellNameOrID number|string Spell ID or Name. When passing a name requires the spell to be in your Spellbook.
--- @return SpellCooldown
function S:GetSpellCooldown(spellNameOrID)
    if not spellNameOrID then return nil end
    local spell = self:GetSpellInfo(spellNameOrID)
    if not spell then return nil end

    local start, duration, enabled, modRate = GetSpellCooldown(spellNameOrID);

    --- @type SpellCooldown
    local cd = {
        spell = { name = spell.name, id = spell.id, icon = spell.icon },
        start = start,
        duration = duration,
        enabled = enabled,
        modRate = modRate,
    }
    return cd
end
---Example:
--- @param optionalUnit string
--- @see GlobalConstants#UnitId
--- @see Blizzard_UnitId
--- @return string One of DRUID, ROGUE, PRIEST, etc...
function S:GetUnitClass(optionalUnit)
    optionalUnit = optionalUnit or UnitId.player
    return select(2, UnitClass(optionalUnit))
end

---Example:
---```
---local playerClass = 'DRUID'
---local isValidClass = IsPlayerClassAnyOf('DRUID','ROGUE', 'PRIEST')
---assertThat(isValidClass).IsTrue()
---```
function S:IsPlayerClassAnyOf(...)
    local unitClass = self:GetUnitClass()
    return IsAnyOf(unitClass, ...)
end

--- @param spellInfo Profile_Spell
function S:IsShapeShiftActive(spellInfo)
    if not spellInfo then return false end
    if self:IsPlayerClassAnyOf(GC.UnitClass.PRIEST, GC.UnitClass.ROGUE) then
        return GetShapeshiftForm() > 0
    end
    return DruidAPI:IsActiveForm(spellInfo.id)
end

--- Generalizes shapeshift and stealth and shapeshift form
--- @param spellInfo Profile_Spell
function S:IsShapeshiftOrStealthSpell(spellInfo)
    return self:IsShapeshiftSpell(spellInfo)
            or self:IsStealthSpell(spellInfo.name)
end

--- Generalizes shapeshift and stealth and shapeshift form
--- @param spellInfo Profile_Spell
function S:IsShapeshiftSpell(spellInfo) return true == spellInfo.isShapeshift end

--- @param spellName string
function S:IsStealthSpell(spellName)
    return IsAnyOf(spellName, WAttr.PROWL, WAttr.STEALTH)
end

--- @param spellInfo Profile_Spell
function S:GetSpellIcon(spellInfo)
    if not spellInfo then return nil end

    if self:IsShapeshiftSpell(spellInfo) then
        local unitClass = self:GetUnitClass(UnitId.player)
        if self:IsShapeShiftActive(spellInfo) then
            if unitClass == GC.UnitClass.DRUID then
                return GC.Textures.DRUID_FORM_ACTIVE_ICON
            elseif unitClass == GC.UnitClass.PRIEST then
                return GC.Textures.PRIEST_SHADOWFORM_ACTIVE_ICON
            end
        end
    elseif self:IsStealthSpell(spellInfo.name) and IsStealthed() then
        return GC.Textures.STEALTHED_ICON
    end
    return spellInfo.icon
end

--- @param spellInfo Profile_Spell
function S:GetStealthIcon(spellInfo)
    if self:IsStealthSpell(spellInfo.name) and IsStealthed() then
        return GC.Textures.STEALTHED_ICON
    end
    return spellInfo.icon
end

--- @param spellInfo Profile_Spell
function S:GetShapeshiftIcon(spellInfo)
    if self:IsShapeShiftActive(spellInfo) then return GC.Textures.DRUID_FORM_ACTIVE_ICON end
    return spellInfo.icon
end

--- @param spellInfo Profile_Spell
function S:GetSpellAttributeValue(spellInfo)
    --[[local spellAttrValue = spellInfo.id
    if self:IsShapeshiftOrStealthSpell(spellInfo) then
        spellAttrValue = spellInfo.name
    end]]
    return spellInfo.name
end

--- @param itemID number
function S:IsToyItem(itemID)
    if not C_ToyBox then return false end
    local _itemID, toyName, icon, isFavorite, hasFanfare, quality = C_ToyBox.GetToyInfo(itemID)
    return not (_itemID == nil or toyName == nil)
end

--- @param macroName string
--- @return ItemInfo
function S:GetMacroItem(macroName)
    local name = GetMacroItem(macroName); if not name then return nil end
    return self:GetItemInfo(name)
end

function S:GetItemID(itemName)
    if String.IsBlank(itemName) then return nil end
    local link = select(2, GetItemInfo(itemName))
    if not link then return nil end
    local itemID = GetItemInfoFromHyperlink(link)
    return itemID
end

--- @param itemIDOrName number|string The itemID or itemName
--- @return number The numeric itemID
function S:ResolveItemID(itemIDOrName)
    if type(itemIDOrName) == 'string' then
        return self:GetItemID(itemIDOrName)
    elseif type(itemIDOrName) == 'number' then
        return itemIDOrName
    end
    return nil
end

--- @param spellName string
function S:IsItemSpell(spellName) return spellName and GetItemInfo(spellName) ~= nil end

--- See: [GetItemInfo](https://wowpedia.fandom.com/wiki/API_GetItemInfo)
--- See: [GetItemInfoInstant](https://wowpedia.fandom.com/wiki/API_GetItemInfoInstant)
--- @param item ItemID_Link_Or_Name
--- @return ItemInfo
function S:GetItemInfo(item)
    local itemID = self:ResolveItemID(item); if not itemID then return nil end

    local itemName, itemLink,
        itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
        itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType,
        expacID, setID, isCraftingReagent = GetItemInfo(itemID)

    --- count includes charges
    local count = GetItemCount(itemID, false, true, true) or 0

    --- @type ItemInfo
    local itemInfo = { id = itemID, name = itemName, link = itemLink, icon = itemTexture,
                       quality = itemQuality, level = itemLevel, minLevel = itemMinLevel,
                       type = itemType, subType = itemSubType, stackCount = itemStackCount,
                       count = count, equipLoc=itemEquipLoc, classID=classID,
                       subclassID=subclassID, bindType=bindType,
                       isCraftingReagent=isCraftingReagent }
    return itemInfo
end

--- @return string, number
function S:GetItemSpellInfo(itemIdNameOrLink)
   local spellName, spellID = GetItemSpell(itemIdNameOrLink)
   return spellName, spellID
end

--- See: [GetItemCooldown](https://wowpedia.fandom.com/wiki/API_GetItemCooldown)
--- @param itemIDOrName number|string The itemID or itemName
--- @return ItemCooldown
function S:GetItemCooldown(itemIDOrName)
    local itemID = self:ResolveItemID(itemIDOrName); if not itemID then return nil end

    if C_Container then GetItemCooldown = C_Container.GetItemCooldown end
    local start, duration, enabled = GetItemCooldown(itemID)
    local item = self:GetItemInfo(itemID)
    if not item then return nil end

    --- @type ItemCooldown
    local cd = {
        item = { id = itemID, name = item.name, icon=item.icon },
        start=start, duration=duration, enabled=enabled,
        details = item
    }

    return cd
end

--- #### Alias for #GetSpellCooldownDetails(spellID)
--- @return SpellCooldownDetails
function S:GSCD(spellID, optionalSpell) return S:GetSpellCooldownDetails(spellID, optionalSpell) end
--- #### Alias for #GetSpellCooldown(spellID)
--- @return SpellCooldown
function S:GSC(spellID) return S:GetSpellCooldown(spellID) end
--- #### Alias for #GetItemCooldown(itemId)
--- @return ItemCooldown
function S:GIC(itemID) return S:GetItemCooldown(itemID) end
