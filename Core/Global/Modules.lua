--[[-----------------------------------------------------------------------------
Modules
-------------------------------------------------------------------------------]]
local addon, ns = ...

--- @class Modules
local L = {
    mt = {
        __tostring = function() return 'Modules' end
    }
}
setmetatable(L, L.mt)

--- @class Module
local M = {
    LibStub = 'LibStub',

    -- Libraries
    ActionbarPlusAPI = 'ActionbarPlusAPI',
    BaseAPI = 'BaseAPI',
    API = 'API',
    Logger = 'Logger',
    LogFactory = 'LogFactory',
    PrettyPrint = 'PrettyPrint',
    Table = 'Table',
    String = 'String',
    Safecall = 'Safecall',
    LuaEvaluator = 'LuaEvaluator',
    ActionbarPlusEventMixin = 'ActionbarPlusEventMixin',
    ActionType = 'ActionType',
    Assert = 'Assert',
    --- @deprecated Use AceLibrary
    AceLibFactory = 'AceLibFactory',
    AceLibrary = 'AceLibrary',
    -- Mixins
    Mixin = 'Mixin',
    ButtonMixin = 'ButtonMixin',
    ButtonProfileMixin = 'ButtonProfileMixin',
    CursorMixin = 'CursorMixin',
    -- Addons
    BaseAttributeSetter = 'BaseAttributeSetter',
    BattlePetDragEventHandler = 'BattlePetDragEventHandler',
    BattlePetAttributeSetter = 'BattlePetAttributeSetter',
    ButtonFactory = 'ButtonFactory',
    ButtonFrameFactory = 'ButtonFrameFactory',
    ButtonUI = 'ButtonUI',
    ButtonUIWidgetBuilder = 'ButtonUIWidgetBuilder',
    CompanionDragEventHandler = 'CompanionDragEventHandler',
    CompanionAttributeSetter = 'CompanionAttributeSetter',
    Config = 'Config',
    ConfigEventHandlerMixin = 'ConfigEventHandlerMixin',
    DruidAPI = 'DruidAPI',
    EquipmentSetDragEventHandler = 'EquipmentSetDragEventHandler',
    EquipmentSetAttributeSetter = 'EquipmentSetAttributeSetter',
    FrameHandleMixin = 'FrameHandleMixin',
    GlobalConstants = 'GlobalConstants',
    ItemAttributeSetter = 'ItemAttributeSetter',
    ItemDragEventHandler = 'ItemDragEventHandler',
    LocalizationUtil = 'LocalizationUtil',
    MacroAttributeSetter = 'MacroAttributeSetter',
    MacroDragEventHandler = 'MacroDragEventHandler',
    MacroEventsHandler = 'MacroEventsHandler',
    MacrotextAttributeSetter = 'MacrotextAttributeSetter',
    Modules = 'Modules',
    MountDragEventHandler = 'MountDragEventHandler',
    MountAttributeSetter = 'MountAttributeSetter',
    PickupHandler = 'PickupHandler',
    PlayerAuraUtil = 'PlayerAuraUtil',
    PlayerAuraMapping = 'PlayerAuraMapping',
    Profile = 'Profile',
    ProfileInitializer = 'ProfileInitializer',
    ReceiveDragEventHandler = 'ReceiveDragEventHandler',
    SpellAttributeSetter = 'SpellAttributeSetter',
    SpellDragEventHandler = 'SpellDragEventHandler',
    WidgetMixin = 'WidgetMixin',
    -- Support Classes
    M6Support = 'M6Support'
}

--- @class GlobalObjects
local GlobalObjectsTemplate = {
    --- @type LocalLibStub
    LibStub = {},

    --- @type ActionbarPlusAPI
    ActionbarPlusAPI = {},
    --- @type BaseAPI
    BaseAPI = {},
    --- @type API
    API = {},
    --- @deprecated Use #AceLibrary : Kapresoft_LibUtil_AceLibrary
    --- @type AceLibFactory
    AceLibFactory = {},
    --- @type Kapresoft_LibUtil_AceLibraryObjects
    AceLibrary = {},
    --- @type ActionbarPlusEventMixin
    ActionbarPlusEventMixin = {},
    --- @type ActionType
    ActionType = {},
    --- @type Kapresoft_LibUtil_Assert
    Assert = {},
    --- @type BaseAttributeSetter
    BaseAttributeSetter = {},
    --- @type ButtonFactory
    ButtonFactory = {},
    --- @type ButtonFrameFactory
    ButtonFrameFactory = {},
    --- @type ButtonMixin
    ButtonMixin = {},
    --- @type ButtonProfileMixin
    ButtonProfileMixin = {},
    --- @type ButtonUI
    ButtonUI = {},
    --- @type ButtonUIWidgetBuilder
    ButtonUIWidgetBuilder = {},
    --- @type Config
    Config = {},
    --- @type ConfigEventHandlerMixin
    ConfigEventHandlerMixin = {},
    --- @type EquipmentSetDragEventHandler
    EquipmentSetDragEventHandler = {},
    --- @type EquipmentSetAttributeSetter
    EquipmentSetAttributeSetter = {},
    --- @type FrameHandleMixin
    FrameHandleMixin = {},
    --- @type GlobalConstants
    GlobalConstants = {},
    --- @type ItemAttributeSetter
    ItemAttributeSetter = {},
    --- @type ItemDragEventHandler
    ItemDragEventHandler = {},
    --- @type LocalizationUtil
    LocalizationUtil = {},
    --- @type LogFactory
    LogFactory = {},
    --- @type Logger
    Logger = {},
    --- @type Kapresoft_LibUtil_LuaEvaluator,
    LuaEvaluator = {},
    --- @type MacroAttributeSetter
    MacroAttributeSetter = {},
    --- @type MacroDragEventHandler
    MacroDragEventHandler = {},
    --- @type MacroEventsHandler
    MacroEventsHandler = {},
    --- @type MacrotextAttributeSetter
    MacrotextAttributeSetter = {},
    --- @type Modules
    Modules = {},
    --- @type MountDragEventHandler
    MountDragEventHandler = {},
    --- @type BattlePetDragEventHandler
    BattlePetDragEventHandler = {},
    --- @type BattlePetAttributeSetter
    BattlePetAttributeSetter = {},
    --- @type CompanionDragEventHandler
    CompanionDragEventHandler = {},
    --- @type CompanionAttributeSetter
    CompanionAttributeSetter = {},
    ----- @type DruidAPI
    DruidAPI = {},
    --- @type MountAttributeSetter
    MountAttributeSetter = {},
    --- @type Kapresoft_LibUtil_Mixin
    Mixin = {},
    --- @type PickupHandler
    PickupHandler = {},
    --- @type PlayerAuraUtil
    PlayerAuraUtil = {},
    --- @type PlayerAuraMapping
    PlayerAuraMapping = {},
    --- @type Profile
    Profile = {},
    --- @type ProfileInitializer
    ProfileInitializer = {},
    --- @type ReceiveDragEventHandler
    ReceiveDragEventHandler = {},
    --- @type Kapresoft_LibUtil_Safecall
    Safecall = {},
    --- @type SpellAttributeSetter
    SpellAttributeSetter = {},
    --- @type SpellDragEventHandler
    SpellDragEventHandler = {},
    --- @type Kapresoft_LibUtil_String
    String = {},
    --- @type Kapresoft_LibUtil_Table
    Table = {},
    --- @type WidgetMixin
    WidgetMixin = {},

    --- @type ActionBarController
    ActionBarController = {},
    --- @type ActionBarBuilder
    ActionBarBuilder = {},
    --- @type ActionbarWidgetMixin
    ActionbarWidgetMixin = {},
    --- @type ActionButtonWidgetMixin
    ActionButtonWidgetMixin = {},
    --- @type ActionBarActionEventsFrame
    ActionBarActionEventsFrame = {},
}
L.M = M
ns.M = M

--- @type Modules
ABP_Modules = L
ns.O = ns.O or {}
ns.O.Modules = L
