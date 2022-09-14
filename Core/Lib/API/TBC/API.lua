--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
local GetSpellSubtext, GetSpellInfo, GetSpellLink = GetSpellSubtext, GetSpellInfo, GetSpellLink
local GetSpellCooldown = GetSpellCooldown
local GetItemInfo, GetItemCooldown, GetItemCount = GetItemInfo, GetItemCooldown, GetItemCount

--[[-----------------------------------------------------------------------------
Lua Vars
-------------------------------------------------------------------------------]]
local format = string.format

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
local _, _, String = ABP_LibGlobals:LibPackUtils()
local IsNotBlank = String.IsNotBlank

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
---@class API
local S = {}
---@type API
_API = S

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]


--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]

---Note: should call ButtonData:ContainsValidAction() before calling this
---@return boolean true, false or nil if not applicable
---@param btnConfig ProfileButton
---@param targetUnit string one of "target", "focus", "mouseover", etc.. See Blizz APIs
function S:IsActionInRange(btnConfig, targetUnit)
    local SPELL, ITEM, MACRO = ABP_LibGlobals:SpellItemMacroAttributes()

    if btnConfig.type == SPELL then
        local val = IsSpellInRange(btnConfig.spell.name, targetUnit)
        if val == nil then return nil end
        return val == true or val == 1
    end
    if btnConfig.type == ITEM then
        local val = IsSpellInRange(btnConfig.item.name, targetUnit)
        if val == nil then return nil end
        return  val == true or val == 1
    end
    if btnConfig.type == MACRO then
        return false
    end
end

--- See:
---  * https://wowpedia.fandom.com/wiki/API_GetSpellInfo
---### SpellInfo
---```
--- {
---    id = 1456,
---    name = 'Life Tap',
---    label = 'Life Tap (Rank 3)',
---    rank = 'Rank 3'
---    castTime = 0,
---    icon = 136126,
---    link = '[Life Tap]',
---    maxRange = 0,
---    minRange = 0,
--- }
---```
---@param spellNameOrId string Spell ID or Name
---@return SpellInfo
function S:GetSpellInfo(spellNameOrId)
    local name, _, icon, castTime, minRange, maxRange, id = GetSpellInfo(spellNameOrId)
    if name then
        local subTextOrRank = GetSpellSubtext(spellNameOrId)
        local spellLink = GetSpellLink(spellNameOrId)
        ---@class SpellInfo
        local spellInfo = { id = id, name = name, icon = icon,
                            link=spellLink, castTime = castTime,
                            minRange = minRange, maxRange = maxRange, rank = subTextOrRank }
        spellInfo.label = spellInfo.name
        if IsNotBlank(spellInfo.rank) then
            -- color codes format: |cAARRGGBB
            local labelFormat = '%s |c00747474(%s)|r'
            spellInfo.label = format(labelFormat, spellInfo.name, spellInfo.rank)
        end
        return spellInfo;
    end
    return nil
end

---@return SpellCooldownDetails
function S:GetSpellCooldownDetails(spellID, optionalSpell)
    local spell = optionalSpell or self:GetSpellInfo(spellID)
    if spell == nil then error("Spell not found: " .. spellID) end
    local start, duration, enabled, modRate = GetSpellCooldown(spellID);
    local cooldown = { start = start, duration = duration, enabled = enabled, modRate = modRate }
    ---@class SpellCooldownDetails
    local details = { spell = spell, cooldown = cooldown }
    return details
end

--- See: [GetSpellCooldown](https://wowpedia.fandom.com/wiki/API_GetSpellCooldown)
---@return SpellCooldown
function S:GetSpellCooldown(spellID, optionalSpell)
    --print(string.format('optionalSpell: %s', pformat(optionalSpell)))
    local start, duration, enabled, modRate = GetSpellCooldown(spellID);
    local name, _, icon, _, _, _, _ = GetSpellInfo(spellID)
    ---@class SpellCooldown
    local cd = {
        spell = { name = name, id = spellID, icon = icon },
        start = start, duration = duration, enabled = enabled, modRate = modRate }
    if optionalSpell then
        cd.spell.details = optionalSpell
    end
    return cd
end

--- See: [GetItemInfo](https://wowpedia.fandom.com/wiki/API_GetItemInfo)
--- See: [GetItemInfoInstant](https://wowpedia.fandom.com/wiki/API_GetItemInfoInstant)
---@return ItemInfo
function S:GetItemInfo(itemID)
    local itemName, itemLink,
        itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
        itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType,
        expacID, setID, isCraftingReagent = GetItemInfo(itemID)

    local count = GetItemCount(itemID, false, true, true) or 0

    ---@class ItemInfo
    local itemInfo = { id = itemID, name = itemName, link = itemLink, icon = itemTexture,
                       quality = itemQuality, level = itemLevel, minLevel = itemMinLevel,
                       type = itemType, subType = itemSubType, stackCount = itemStackCount,
                       count = count, equipLoc=itemEquipLoc, classID=classID,
                       subclassID=subclassID, bindType=bindType,
                       isCraftingReagent=isCraftingReagent }
    return itemInfo
end

---@return string, number
function S:GetItemSpellInfo(itemIdNameOrLink)
   local spellName, spellID = GetItemSpell(itemIdNameOrLink)
   return spellName, spellID
end

--- See: [GetItemCooldown](https://wowpedia.fandom.com/wiki/API_GetItemCooldown)
---@return ItemCooldown
function S:GetItemCooldown(itemId, optionalItem)
    if not itemId then return nil end;
    local start, duration, enabled = GetItemCooldown(itemId)
    ---@class ItemCooldown
    local cd = {
        item = { id = itemId },
        start=start, duration=duration, enabled=enabled
    }
    if optionalItem then
        cd.item.details = optionalItem
        cd.item.name = optionalItem.name
    end
    return cd
end

---@return SpellCooldownDetails
function S:GSCD(spellID, optionalSpell) return S:GetSpellCooldownDetails(spellID, optionalSpell) end
---@return SpellCooldown
function S:GSC(spellID, optionalSpellName) return S:GetSpellCooldown(spellID, optionalSpellName) end
---@return ItemCooldown
function S:GIC(itemId, optionalItem) return S:GetItemCooldown(itemId, optionalItem) end