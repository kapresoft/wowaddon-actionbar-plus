--[[-----------------------------------------------------------------------------
README: ButtonData is no longer being used
-------------------------------------------------------------------------------]]

--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
local GetMacroSpell, IsPassiveSpell = GetMacroSpell, IsPassiveSpell

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, LibStub = ns:LibPack()

local String, Assert = O.String, O.Assert
local W = O.GlobalConstants.WidgetAttributes
local SPELL, ITEM, MACRO, MOUNT, COMPANION, BATTLE_PET, EQUIPMENT_SET =
    W.SPELL, W.ITEM, W.MACRO, W.MOUNT,
    W.COMPANION, W.BATTLE_PET, W.EQUIPMENT_SET
local P, API = O.Profile, O.API

local IsBlank, IsNil = String.IsBlank, Assert.IsNil
local IsEmptyTable = O.Table.IsEmpty

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @class ButtonData : BaseLibraryObject
local L = LibStub:NewLibrary(ns.M.ButtonData)
local p = L.logger()

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
local function removeElement(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then tbl[i] = nil end
    end
end

--- @deprecated See ButtonProfileMixin#CleanupTypeData
--- @param profileButton Profile_Button
local function CleanupTypeData(profileButton)
    if profileButton == nil or profileButton.type == nil then return end
    local btnTypes = { SPELL, MACRO, ITEM, MOUNT, COMPANION, BATTLE_PET, EQUIPMENT_SET }
    removeElement(btnTypes, profileButton.type)
    for _, v in ipairs(btnTypes) do
        if v ~= nil then profileButton[v] = {} end
    end
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- @param o ButtonData
local function PropsAndMethods(o)

    --- @param widget ButtonUIWidget
    --- @return ButtonData
    function o:New(widget)
        local newObj = ns:K():CreateAndInitFromMixin(self, widget)
        newObj.mt = { __tostring = function() return 'ButtonData::' .. widget:GetName()  end}
        setmetatable(newObj, newObj.mt)
        return newObj
    end

    --- @param widget ButtonUIWidget
    function o:Init(widget)
        assert(widget, "ButtonUIWidget is required")
        self.config = P:GetButtonConfig(widget.frameIndex, widget.index)
        self.widget = widget
    end

    function o:GetBarConfig() return self.widget.dragFrame():GetConfig() end

    function o:invalidButtonData(obj, key)
        if type(obj) ~= 'table' then return true end
        if type(obj[key]) ~= 'nil' then
            local d = obj[key]
            if type(d) == 'table' then return (IsBlank(d['id']) and IsBlank(d['index'])) end
        end
        return true
    end

    --- @return Profile_Button
    function o:GetConfig()
        local w = self.widget
        local profileButton = P:GetButtonData(w.frameIndex, w.buttonName)
        -- self cleanup
        CleanupTypeData(profileButton)
        return profileButton
    end

    --- @return Profile_Config
    function o:GetProfileConfig() return P:P() end
    --- @return boolean
    function o:IsHideWhenTaxi() return P:IsHideWhenTaxi() end
    --- @return boolean
    function o:ContainsValidAction() return self:GetActionName() ~= nil end
    --- @return string
    function o:GetActionName()
        local conf = self:GetConfig()
        if not self:invalidButtonData(conf, SPELL) then return conf.spell.name end
        if not self:invalidButtonData(conf, ITEM) then return conf.item.name end
        if not self:invalidButtonData(conf, MACRO) then return conf.macro.name end
        return nil
    end

    --- @return Profile_Spell
    function o:GetSpellInfo()
        local w = self.widget
        --- @type Profile_Spell
        local spellInfo
        local conf = w:GetConfig()
        if not conf and (conf.spell or conf.macro) then return false end
        if w:IsConfigOfType(conf, SPELL) then
            spellInfo = conf[SPELL]
            API:ApplySpellInfoAttributes(spellInfo)
        elseif w:IsConfigOfType(conf, MACRO) and conf.macro.index then
            local macroSpellId =  GetMacroSpell(conf.macro.index)
            spellInfo = API:GetSpellInfo(macroSpellId)
        end
        if not (spellInfo and spellInfo.name) then return nil end
        return spellInfo
    end

    function o:IsShapeshiftOrStealthSpell() return API:IsShapeshiftOrStealthSpell(self:GetSpellInfo()) end

    function o:IsStealthSpell()
        local spellInfo = self:GetSpellInfo()
        if not (spellInfo and spellInfo.name) then return false end
        return API:IsStealthSpell(spellInfo.name)
    end
    function o:IsShapeshiftSpell()
        local spellInfo = self:GetSpellInfo()
        if not (spellInfo and spellInfo.name) then return false end
        return API:IsShapeshiftSpell(spellInfo)
    end
    --- @param optionalSpellNameOrId number|string
    function o:IsPassiveSpell(optionalSpellNameOrId)
        local spellNameOrId = optionalSpellNameOrId
        if not spellNameOrId then
            local spellInfo = self:GetSpellInfo()
            if spellInfo then spellNameOrId = spellInfo.name end
        end
        -- assume passive by default if we can't find any spell info
        if not spellNameOrId then return true end
        return IsPassiveSpell(spellNameOrId)
    end

    --- @return Profile_Item
    function o:GetItemInfo() return self:GetConfig()[ITEM] end
    --- @return Profile_Macro
    function o:GetMacroInfo() return self:GetConfig()[MACRO] end
    --- @return Profile_Mount
    function o:GetMountInfo() return self:GetConfig()[MOUNT] end
    --- @return Profile_Companion
    function o:GetCompanionInfo() return self:GetConfig()[COMPANION] end
    --- @return Profile_BattlePet
    function o:GetBattlePetInfo() return self:GetConfig()[BATTLE_PET] end
    --- @return Profile_EquipmentSet
    function o:GetEquipmentSetInfo() return self:GetConfig()[EQUIPMENT_SET] end

    function o:ConfigContainsValidActionType()
        if not type then return false end
        local btnConf = self:GetConfig()
        if not btnConf then return false end
        if IsBlank(btnConf.type) and IsEmptyTable(btnConf[btnConf.type]) then
            return false
        end
        return true
    end

    --- @param m Profile_Mount
    function o:IsInvalidMount(m)
        return IsNil(m) and IsNil(m.name) and IsNil(m.spell) and IsNil(m.spell.id)
    end

    --- @param c Profile_Companion
    function o:IsInvalidCompanion(c)
        return IsNil(c) and IsNil(c.name) and IsNil(c.spell) and IsNil(c.spell.id)
    end

    --- @param pet Profile_BattlePet
    function o:IsInvalidBattlePet(pet) return IsNil(pet) and IsNil(pet.guid) and IsNil(pet.name) end

    function o:IsShowIndex() return P:IsShowIndex(self.widget.frameIndex) end
    function o:IsShowEmptyButtons() return P:IsShowEmptyButtons(self.widget.frameIndex) end
    function o:IsShowKeybindText() return P:IsShowKeybindText(self.widget.frameIndex) end

end

PropsAndMethods(L)

