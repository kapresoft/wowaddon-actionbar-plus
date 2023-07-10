--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
local IsShiftKeyDown, IsAltKeyDown, IsControlKeyDown = IsShiftKeyDown, IsAltKeyDown, IsControlKeyDown
local GetMacroSpell, IsPassiveSpell = GetMacroSpell, IsPassiveSpell

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local P, API, BaseAPI = O.Profile, O.API, O.BaseAPI
local CN = GC.Profile_Config_Names
local String, Table, W = O.String, O.Table, GC.WidgetAttributes
local IsEmptyTable, IsNil = Table.IsEmpty, O.Assert.IsNil
local IsEmptyStr, IsBlankStr = String.IsEmpty, String.IsBlank
local p = O.LogFactory(M.ButtonProfileMixin)

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]

--- @class ButtonProfileMixin : BaseLibraryObject
local L = LibStub:NewLibrary(M.ButtonProfileMixin)

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
local function PR() return O.Profile end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
---@param o ButtonProfileMixin | ButtonMixin | ButtonUIWidget
local function PropsAndMethods(o)

    --- @param widget ButtonUIWidget
    function o:New(widget)
        return ns:K():CreateAndInitFromMixin(o, widget)
    end

    --- @param widget ButtonUIWidget
    function o:Init(widget)
        self.w = widget
    end

    --- @return Profile_Button
    function o:conf() return self:GetConfig() end

    function o:SetButtonAttributes()
        local conf = self:conf()
        if not conf then return end
        if IsBlankStr(conf.type) then
            conf.type = self:GuessButtonType(conf)
            if IsBlankStr(conf.type) then return end
        end
        local setter = self:GetAttributesSetter()
        if not setter then return end
        setter:SetAttributes(self.button())
    end

    --- @return table<string, AttributeSetter>
    function o:GetAllAttributesSetters()
        --- @type table<string, AttributeSetter>
        local AttributeSetters = {
            [W.SPELL]       = O.SpellAttributeSetter,
            [W.ITEM]        = O.ItemAttributeSetter,
            [W.MACRO]       = O.MacroAttributeSetter,
            [W.MOUNT]       = O.MountAttributeSetter,
            [W.COMPANION]   = O.CompanionAttributeSetter,
            [W.BATTLE_PET]   = O.BattlePetAttributeSetter,
            [W.EQUIPMENT_SET] = O.EquipmentSetAttributeSetter,
        }
        return AttributeSetters
    end

    --- @return AttributeSetter
    function o:GetAttributesSetter(actionType)
        local type = actionType or self:conf().type
        --p:log('type: %s', tostring(type))
        return self:GetAllAttributesSetters()[type]
    end

    --- Autocorrect bad data if we have button data with
    --- btnData[type] but no btnData.type field
    ---@param btnData Profile_Button
    function o:GuessButtonType(btnData)
        for buttonType in pairs(self:GetAllAttributesSetters()) do
            -- return the first data found
            if not IsEmptyTable(btnData[buttonType]) then
                p:log(1, 'btnData[%s] did not have a type and was corrected: %s', self.w:GetName(), btnData.type)
                return buttonType
            end
        end
        return nil
    end

    function o:IsEmpty()
        if IsEmptyTable(self:conf()) then return true end
        local type = self:conf().type
        if IsBlankStr(type) then return true end
        if IsEmptyTable(self:conf()[type]) then return true end
        return false
    end

    --- @return Profile_Bar
    function o:GetBarConfig() return self.dragFrame():GetConfig() end

    ---#### Get Profile Button Config Data
    --- @return Profile_Button
    function o:GetConfig() return PR():GetButtonConfig(self.w.frameIndex, self.w.buttonName) end

    --- @return Profile_Config
    function o:GetProfileConfig() return PR():P() end

    --- @param type ActionTypeName One of: spell, item, or macro
    function o:GetButtonTypeData(type) return self:conf()[type] end

    --- @return Profile_Spell
    function o:GetSpellData() return self:GetButtonTypeData(W.SPELL) end
    function o:GetSpellName() local sp = self:GetSpellData(); return sp and sp.name end
    --- @return Profile_Item
    function o:GetItemData() return self:GetButtonTypeData(W.ITEM) end
    function o:GetItemName() local i = self:GetItemData(); return i and i.name end
    --- @return Profile_Macro
    function o:GetMacroData() return self:GetButtonTypeData(W.MACRO) end

    --- @return MacroName The macro name
    function o:GetMacroName() return self:GetMacroInfo() end
    --- @return Index
    function o:GetMacroIndex() return select(2, self:GetMacroInfo()) end

    --- @return MacroName, Index
    function o:GetMacroInfo()
        local md = self:GetMacroData(); if not md then return nil end
        return md and md.name, md.index
    end
    --- @return boolean
    ---@param name string The macro name to check
    function o:HasMacroName(name)
        if IsBlankStr(name) or not self:IsMacro() then return false end
        return name == self:GetMacroData().name
    end
    --- @return Profile_MacroText
    function o:GetMacroTextData() return self:GetButtonTypeData(W.MACRO_TEXT) end

    --- @return Profile_Mount
    function o:GetMountData() return self:GetButtonTypeData(W.MOUNT) end
    --- @return Profile_Companion
    function o:GetCompanionData() return self:GetButtonTypeData(W.COMPANION) end
    --- @return Profile_BattlePet
    function o:GetBattlePetData() return self:GetButtonTypeData(W.BATTLE_PET) end
    --- @return Profile_EquipmentSet
    function o:GetEquipmentSetData() return self:GetButtonTypeData(W.EQUIPMENT_SET) end

    --- @return boolean
    function o:ContainsValidAction() return self:GetEffectiveSpellName() ~= nil end

    function o:ConfigContainsValidActionType()
        if not type then return false end
        local btnConf = self:conf()
        if not btnConf then return false end
        if IsBlankStr(btnConf.type) and IsEmptyTable(btnConf[btnConf.type]) then
            return false
        end
        return true
    end

    function o:GetTooltipVisibilityKey()
        return self:GetProfileConfig()[CN.tooltip_visibility_key]
    end

    function o:GetTooltipVisibilityCombatOverrideKeyOption()
        return self:GetProfileConfig()[CN.tooltip_visibility_combat_override_key]
    end

    --- @return SpellName|nil
    function o:GetEffectiveSpellName()
        self:IsActionType()
        local conf = self:conf()
        local actionType = conf and conf.type
        if IsBlankStr(actionType) then return nil end

        local spellName
        if actionType == 'spell' and not IsBlankStr(conf.spell.name) then
            spellName = conf.spell.name
        elseif actionType == 'macro' then
            spellName = API:GetMacroSpell(self:GetMacroIndex())
        elseif actionType == 'item' then
            spellName = API:GetItemSpellInfo(conf.item.name)
        elseif actionType == 'mount' then
            spellName = conf.mount.name
        end

        return spellName
    end

    --- @return SpellID|nil
    function o:GetEffectiveSpellID()
        local conf = self:conf()
        local actionType = conf and conf.type
        if IsBlankStr(actionType) then return nil end

        local spellID
        if actionType == 'spell' and not IsBlankStr(conf.spell.name) then
            spellID = conf.spell.id
        elseif actionType == 'macro' then
            _, spellID = API:GetMacroSpell(self:GetMacroIndex())
        elseif actionType == 'item' then
            _, spellID = API:GetItemSpellInfo(conf.item.name)
        --elseif actionType == 'mount' then
            --spellID = conf.mount.name
        end

        return spellID
    end

    function o:IsInvalidButtonData(o, key)
        if type(o) ~= 'table' then return true end
        return type(o[key]) == 'table'
    end

    --- @return boolean
    function o:IsMacro() return self:IsActionType(W.MACRO) end
    --- @return boolean
    function o:IsMacroText() return self:IsActionType(W.MACRO_TEXT) end
    --- @return boolean
    function o:IsSpell() return self:IsActionType(W.SPELL)
            and self:IsValidSpellProfile(self:conf()) end
    --- @return boolean
    function o:IsItem() return self:IsActionType(W.ITEM) end
    --- @return boolean
    function o:IsMount() return self:IsActionType(W.MOUNT) end
    --- @see Interface/FrameXML/SecureHandlers.lua
    --- @return boolean
    function o:IsCompanion() return self:IsActionType(W.COMPANION) end
    --- @return boolean
    function o:IsBattlePet() return self:IsActionType(W.BATTLE_PET) end
    --- @return boolean
    function o:IsEquipmentSet() return self:IsActionType(W.EQUIPMENT_SET) end

    function o:IsStealthSpell()
        local spellInfo = self:GetSpellData()
        if not (spellInfo and spellInfo.name) then return false end
        return API:IsStealthSpell(spellInfo.name)
    end
    function o:IsShapeshiftSpell()
        local spellInfo = self:GetSpellData()
        if not (spellInfo and spellInfo.name) then return false end
        return API:IsShapeshiftSpell(spellInfo)
    end

    --- @param optionalSpellNameOrId number|string
    function o:IsPassiveSpell(optionalSpellNameOrId)
        local spellNameOrId = optionalSpellNameOrId
        if not spellNameOrId then
            local spellInfo = self:GetSpellData()
            if spellInfo then spellNameOrId = spellInfo.name end
        end
        -- assume passive by default if we can't find any spell info
        if not spellNameOrId then return true end
        return IsPassiveSpell(spellNameOrId)
    end

    --- @deprecated Use #IsActionType(type, optionalConfig)
    --- @param config Profile_Button
    --- @param type string spell, item, macro, mount, etc
    function o:IsConfigOfType(config, type)
        if IsEmptyTable(config) then return false end
        return config.type and type == config.type
    end
    --- @param type ActionTypeName
    --- @param optionalConfig Profile_Button|nil
    function o:IsActionType(type, optionalConfig)
        local config = optionalConfig or self:conf()
        return config.type and type == config.type
    end

    --- @return boolean true if the key override is pressed
    function o:IsTooltipModifierKeyDown()
        local tooltipKey = self:GetTooltipVisibilityKey();
        return self:IsOverrideKeyDown(tooltipKey)
    end

    --- @return boolean true if the key override is pressed
    function o:IsTooltipCombatModifierKeyDown()
        local combatOverride = self:GetTooltipVisibilityCombatOverrideKeyOption();
        return self:IsOverrideKeyDown(combatOverride)
    end

    --- @see TooltipKeyName
    --- @param value string One of TooltipKeyName value
    --- @return boolean true if the key override is pressed
    function o:IsOverrideKeyDown(value)
        local tooltipKey = P:GetTooltipKey().names
        if tooltipKey.SHOW == value then return true end
        if tooltipKey.HIDE == value then return false end

        if tooltipKey.ALT == value then
            return IsAltKeyDown()
        elseif tooltipKey.CTRL == value then
            return IsControlKeyDown()
        elseif tooltipKey.SHIFT == value then
            return IsShiftKeyDown()
        end
        return false
    end

    --- @return boolean
    function o:IsHideWhenTaxi() return PR():IsHideWhenTaxi() end
    ---@param s Profile_Spell
    function o:IsInvalidSpell(s) return IsNil(s) or (IsNil(s.name) and IsNil(s.id) and IsNil(s.icon)) end
    ---@param m Profile_Macro
    function o:IsInvalidMacro(m) return IsNil(m) or (IsNil(m.name) and IsNil(m.index) and IsNil(m.icon)) end

    ---@param i Profile_Item
    function o:IsInvalidItem(i) return IsNil(i) or (IsNil(i.name)  and IsNil(i.id) and IsNil(i.icon)) end
    --- @param m Profile_Mount
    function o:IsInvalidMount(m)
        return IsNil(m) or (IsNil(m.name) and IsNil(m.spell) and IsNil(m.spell.id))
    end
    --- @param c Profile_Companion
    function o:IsInvalidCompanion(c)
        return IsNil(c) or (IsNil(c.name) and IsNil(c.spell) and IsNil(c.spell.id))
    end
    --- @param e Profile_EquipmentSet
    function o:IsInvalidEquipmentSet(e)
        e = e or self:GetEquipmentSetData()
        if not e then return true end
        return IsNil(e) or (IsNil(e.name) and IsNil(e.index)) end

    --- @param pet Profile_BattlePet
    function o:IsInvalidBattlePet(pet) return IsNil(pet) or (IsNil(pet.guid) and IsNil(pet.name)) end
    function o:IsShowIndex() return P:IsShowIndex(self.w.frameIndex) end
    function o:IsShowEmptyButtons() return P:IsShowEmptyButtons(self.w.frameIndex) end
    function o:IsShowKeybindText() return P:IsShowKeybindText(self.w.frameIndex) end

    --- @return EquipmentSetInfo
    function o:FindEquipmentSet()
        local btnData = self:GetEquipmentSetData()
        if not btnData then return nil end

        local id, name = btnData.id, btnData.name
        local index = BaseAPI:GetEquipmentSetIndex(id)
        if not index then return nil end

        local equipmentSet = BaseAPI:GetEquipmentSetInfoByName(name)
        if not equipmentSet then
            equipmentSet = BaseAPI:GetEquipmentSetInfoBySetID(id)
        end
        return equipmentSet
    end

    function o:IsMissingEquipmentSet()
        if self:IsInvalidEquipmentSet() then return true end
        local equipmentSet = self:FindEquipmentSet()
        if not equipmentSet then return true end

        local index = BaseAPI:GetEquipmentSetIndex(equipmentSet.id)
        if not index then return true end

        return equipmentSet.id ~= self:GetEquipmentSetData().id
    end

    function o:ResetButtonData()
        local conf = self:conf()
        for _, a in ipairs(O.ActionType:GetNames()) do conf[a] = nil end
        conf[W.TYPE] = ''
    end

    function o:CleanupActionTypeData() PR():CleanupActionTypeData(self.w) end

end

PropsAndMethods(L)

