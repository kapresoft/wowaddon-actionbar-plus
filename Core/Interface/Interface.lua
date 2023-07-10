-- Addon Interface Types for EmmyLua
-- This file does not need to be included in _Common.xml
--[[-----------------------------------------------------------------------------
ActionbarPlus_AceDB
-------------------------------------------------------------------------------]]
--- @class ActionbarPlus_AceDB
local _db = {
    --- @type Profile_Global_Config
    global = {},
    --- @type Profile_Config
    profile = {},
}

--[[-----------------------------------------------------------------------------
Namespace
-------------------------------------------------------------------------------]]
--- @class LibPackMixin
local LibPackMixin = {
    --- @type GlobalObjects
    O = {}
}

--- @class Namespace : LibPackMixin
local Namespace = {
    --- @type string
    name = "",

    --- @type GameVersion
    gameVersion = "retail",

    --- @type GlobalObjects
    O = {},
    --- @type ActionbarPlus_AceDB
    db = {},
    --- @type Module
    M = {},

    --- @type Kapresoft_LibUtil
    Kapresoft_LibUtil = {},

    --- @type fun(): Kapresoft_LibUtil
    K = {},

    --- @type LocalLibStub
    LibStub = {},

    --- @type fun(self:Namespace) : boolean
    IsVanilla = false,
    --- @type fun(self:Namespace) : boolean
    IsTBC = false,
    --- @type fun(self:Namespace) : boolean
    IsWOTLK = false,
    --- @type fun(self:Namespace) : boolean
    IsRetail = false,

    --- Used in TooltipFrame and BaseAttributeSetter to coordinate the GameTooltip Anchor
    --- @see TooltipAnchor#SCREEN_* vars
    --- @type string
    GameTooltipAnchor = "",
    --- @type fun(o:any, ...) : void
    pformat = {},
}

--- @class CursorUtil : CursorMixin
local CursorUtil = {}

--[[-----------------------------------------------------------------------------
ActionbarPlus
-------------------------------------------------------------------------------]]
--- @class ActionbarPlusProperties
local ActionbarPlusProperties = { }
ActionbarPlusProperties.db = _db


--[[-----------------------------------------------------------------------------
Profile
-------------------------------------------------------------------------------]]
--- @class Profile_Spell
local Profile_Spell = {
    ["minRange"] = 0,
    ["id"] = 8232,
    ["label"] = "Windfury Weapon |c00747474(Rank 1)|r",
    ["name"] = "Windfury Weapon",
    ["castTime"] = 0,
    ["link"] = "|cff71d5ff|Hspell:8232:0|h[Windfury Weapon]|h|r",
    ["maxRange"] = 0,
    ["icon"] = 136018,
    ["rank"] = "Rank 1"
}
--- @class Profile_Item
local Profile_Item = {
    ["name"] = "Arcane Powder",
    ["link"] = "|cffffffff|Hitem:17020::::::::70:::::::::|h[Arcane Powder]|h|r",
    ["id"] = 17020,
    ["stackCount"] = 20,
    ["icon"] = 133848,
    ["count"] = 40,
}
--- @class Profile_Macro
local Profile_Macro = {
    ["type"] = "macro",
    ["index"] = 41,
    ["name"] = "z#LOL",
    ["icon"] = 132093,
    -- This macro is used by third-party plugins
    ["icon2"] = 132093,
    ["body"] = "/lol\n",
}
--- @class Profile_MacroText
local Profile_MacroText = {
    ["type"] = "macrotext",
    ["name"] = "z#LOL",
    ["icon"] = 132093,
    ["body"] = "/lol\n",
}
--- @class Profile_Mount_Spell
local Profile_Mount_Spell = { id = 1, icon = 123 }
--- @class Profile_Mount
local Profile_Mount = {
    type = 'mount',
    id = -1,
    index = -1,
    name = 'Reawakened Phase Hunter',
    spell = Profile_Mount_Spell,
}
--- @class Profile_Companion_Spell
local Profile_Companion_Spell = { id = 1, icon = 123 }
--- @class Profile_Companion
local Profile_Companion = {
    type = 'companion',
    petType = 'critter',
    mountType = 0x1,
    id = -1,
    index = -1,
    name = 'Black Kingsnake',
    spell = Profile_Companion_Spell,
}
--- @class Profile_BattlePet
local Profile_BattlePet = {
    ['type'] = 'battlepet',
    ['petType'] = -1,
    ['guid'] = 'BattlePet-0-000008C13591',
    ['speciesID'] = speciesID,
    ['creatureID'] = 157969,
    ['name'] = 'Anima Wyrmling',
    ['icon'] = 3038273,
}

--- @class Profile_EquipmentSet
local Profile_EquipmentSet = {
    ['type'] ='equipmentset',
    ['name'] = '<name of equipment>',
    --- The Equipment setID
    ['id'] = 1,
    ['icon'] = 3038273,
}

--- @class Profile_Button
local Profile_Button = {
    ['type'] = 'spell',
    ["spell"] = Profile_Spell,
    ["item"] = Profile_Item,
    ["macro"] = Profile_Macro,
    ["mount"] = Profile_Mount,
    ["companion"] = Profile_Companion,
    ["equipmentset"] = Profile_EquipmentSet,
}

--- @class Profile_Bar_Widget
local Profile_Bar_Widget = {
    ["rowSize"] = 1,
    ["colSize"] = 1,
    ["buttonSize"] = 11,
    ["buttonAlpha"] = 0.1,
    ["frame_handle_mouseover"] = false,
    ["frame_handle_alpha"] = 1.0,
    ["show_empty_buttons"] = true
}


--- @class Profile_Bar
local Profile_Bar = {
    -- show/hide the actionbar frame
    ["enabled"] = false,
    -- allowed values: {"", "always", "in-combat"}
    ["locked"] = "",
    -- shows the button index
    ["show_button_index"] = true,
    -- shows the keybind text TOP
    --TODO next: show_keybind_text should be in Profile_Bar_Widget properties
    ["show_keybind_text"] = true,
    ["widget"] = Profile_Bar_Widget,
    --- @see _RegionAnchor
    ["anchor"] = { point="CENTER", relativeTo=nil, relativePoint='CENTER', x=0.0, y=0.0 },
    --- @type table<number, Profile_Button>
    ["buttons"] = {
        ['ActionbarPlusF1Button1'] = Profile_Button
    }
}

--- @class Global_Profile_Bar
local Global_Profile_Bar = {
    --- @type _RegionAnchor
    ["anchor"] = { point="CENTER", relativeTo=nil, relativePoint='CENTER', x=0.0, y=0.0 },
}

--- @class Profile_Global_Config
local Profile_Global_Config = {
    ["bars"] = {
        ["ActionbarPlusF1"] = Global_Profile_Bar,
        ["ActionbarPlusF2"] = Global_Profile_Bar,
        ["ActionbarPlusF3"] = Global_Profile_Bar,
        ["ActionbarPlusF4"] = Global_Profile_Bar,
        ["ActionbarPlusF5"] = Global_Profile_Bar,
        ["ActionbarPlusF6"] = Global_Profile_Bar,
        ["ActionbarPlusF7"] = Global_Profile_Bar,
        ["ActionbarPlusF8"] = Global_Profile_Bar,
    }
}

--- @class Profile_Config
local Profile_Config = {
    ["hide_when_taxi"] = true,
    --- Toggle action button mouseover glow
    ["action_button_mouseover_glow"] = true,
    --- Hide keybindText and indexText for smaller buttons
    ["hide_text_on_small_buttons"] = true,
    --- Hide cooldown countdown numbers
    ["hide_countdown_numbers"] = true,
    ["tooltip_visibility_key"] = '',
    ["tooltip_visibility_combat_override_key"] = '',
    --- @see TooltipAnchor
    ["tooltip_anchor_type"] = '',
    ["equipmentset_open_character_frame"] = true,
    ["equipmentset_open_equipment_manager"] = true,
    ["equipmentset_show_glow_when_active"] = true,
    --- @type table<string, Profile_Bar>
    ["bars"] = {
        ["ActionbarPlusF1"] = Profile_Bar,
        ["ActionbarPlusF2"] = Profile_Bar,
        ["ActionbarPlusF3"] = Profile_Bar,
        ["ActionbarPlusF4"] = Profile_Bar,
        ["ActionbarPlusF5"] = Profile_Bar,
        ["ActionbarPlusF6"] = Profile_Bar,
        ["ActionbarPlusF7"] = Profile_Bar,
        ["ActionbarPlusF8"] = Profile_Bar,
    }
}

--- @class Spellcast_Event_Data
local SpellcastSent_Data = {
    unit='unit', target='target', castGUID='castGUID', spellID=12345
}

--[[-----------------------------------------------------------------------------
Config
-------------------------------------------------------------------------------]]
--- @class Config : BaseLibraryObject_Initialized_WithAceEvent
local Config = {
    --- @type ActionbarPlus
    addon = {},
    --- @type Profile
    profile = {},
    --- @type ConfigEventHandlerMixin
    eventHandler = {},
    maxRows = 20,
    maxCols = 40,
}

--- @class ActionbarInitialSettings
local ActionbarInitialSettings = {
    ['rowSize'] = 1,
    ['colSize'] = 1,
    ['enable'] = false,
    ['frame_handle_mouseover'] = true
}

--- @class LayoutStrategyContext
local LayoutStrategyContext = {
    --- @type Kapresoft_Incrementer
    xIncr = {},
    --- @type Kapresoft_Incrementer
    yIncr = {},
}

--- @class EquipmentSetInfo
local EquipmentSetInfo = {
    name = 'name',
    id = 1,
    --- The button index order
    index = 1,
    setID = 1,
    icon = 12345,
    isEquipped = true,
    numItems = 1,
    numEquipped = 1,
    numInInventory = 1,
    numLost = 0,
    numIgnored = 0,
}

--- @class CooldownInfo
local CooldownInfo = {
    type='spell',
    start=nil,
    duration=nil,
    enabled=0,
    --- @type SpellCooldown | ItemCooldown
    details = {}
}

--- @class SpellCooldown_Spell
local SpellCooldown_Spell = {
    name = 'spell-name',
    id = 1,
    icon = 1234567
}

--- @class SpellCooldown : Cooldown
local SpellCooldown = {
    --- @type SpellCooldown_Spell
    spell = {
        name = 'spell-name',
        id = 1,
        --- @type number
        icon = 1234567
    }
}

--- @class ItemCooldown : Cooldown
local ItemCooldown = {
    item = {
        id = 1,
        name='Water',
        icon=1234567
    },
    --- @type ItemInfo
    details = {}
}

--- @class AuraInfo
local AuraInfo = {
    aura = {
        --- @type SpellInfo
        spell = { id = 123, name = 'Aura Spell Name' },
        instanceID = 123,
        --- @type AuraData
        data = {},
    },
    --- @type SpellInfo
    spell = {
        id = 123,
        name = 'Spell name'
    }
}

--- @alias AuraInstanceID number
--- @alias PlayerAuraMap table<AuraInstanceID, AuraInfo>
--- @alias PlayerAuraSpecializationMap table<SpecializationIndex, PlayerAuraMap>
--- @alias PlayerAuraUnitMap table<UnitClass, PlayerAuraSpecializationMap>

--- @class AuraMap : table<GameVersion, PlayerClassMap>
local AuraMap = {
    ['classic'] = {
        --- @type PlayerAuraMap
        ['MAGE'] = {
            {
                [190446] = AuraInfo
            },
            {
                [44544] = AuraInfo
            },
        }
    },
    --[[--- @type PlayerClassMap
    ['tbc_classic'] = { },
    --- @type PlayerClassMap
    ['wotlk_classic'] = { },
    --- @type PlayerClassMap
    ['retail'] = { },]]
}
local c = AuraMap.classic


--[[-----------------------------------------------------------------------------
Supported Extensions
-------------------------------------------------------------------------------]]
--- @class M6SupportDBProfile
local M6Support_DB_Profile = {
    ["slots"] = {
        ["s01"] = 1,
        ["s02"] = 2,
    }
}

--- @class M6Support_DB
local M6SupportDB = {
    --- @type M6SupportDBProfile
    profiles = {},
    --- @type table<number, table>
    actions = {},
}
--- @class M6Support_MacroHint
local M6Support_MacroHint = {
    name = 'm6-name',
    isActive = true,
    icon = 123456,
    spell = 'spell-or-item',
    itemCount = 1,
    unknown1 = 0,
    unknown2 = 0,
    fn = function()  end,
    unknown3 = 0,
}

--[[-----------------------------------------------------------------------------
Aliases
-------------------------------------------------------------------------------]]
--- @alias LayoutStrategyFn fun(index:number, barConf:Profile_Bar, context:LayoutStrategyContext)

