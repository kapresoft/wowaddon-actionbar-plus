--[[-----------------------------------------------------------------------------
Alias Functions
-------------------------------------------------------------------------------]]
--- @alias FrameHandlerFunction fun(frameWidget:FrameWidget) : void
--- @alias ButtonPredicateFunction fun(btnWidget:ButtonUIWidget) : boolean
--- @alias ButtonHandlerFunction fun(btnWidget:ButtonUIWidget) : void
--- @alias ButtonHandlerSpellAuraFunction fun(btnWidget:ButtonUIWidget, auraInfo:AuraInfo) : void

--[[-----------------------------------------------------------------------------
BaseLibraryObject
-------------------------------------------------------------------------------]]
local function BaseLibraryObject_Def()
    --- @class BaseLibraryObject
    local o = {}
    --- @type table
    o.mt = { __tostring = function() end }

    --- @type fun() : Logger
    o.logger = {}

    --- @return string
    function o:GetModuleName() end
    --- @return string, string The major and minor version
    function o:GetVersionUnpacked() end
    --- @type fun(self:BaseLibraryObject) : table<string, string>  With keys "major" and "minor"; major:string, minor:string
    --- @return table<string, string>
    function o:GetVersion() end
    --- @return Logger
    function o:GetLogger() end
end

--[[-----------------------------------------------------------------------------
BaseLibraryObject_WithAceEvent
-------------------------------------------------------------------------------]]
local function BaseLibraryObject_WithAceEvent_Def()
    --- @class BaseLibraryObject_WithAceEvent : AceEvent
    local o = {}
    --- @type table
    o.mt = { __tostring = function() end }

    --- @return string
    function o:GetModuleName() end
    --- @return string, string The major and minor version
    function o:GetVersionUnpacked() end
    --- @type fun(self:BaseLibraryObject) : table<string, string>  With keys "major" and "minor"; major:string, minor:string
    --- @return table<string, string>
    function o:GetVersion() end
    --- @return Logger
    function o:GetLogger() end
end

--[[-----------------------------------------------------------------------------
BaseLibraryObject_Initialized
-------------------------------------------------------------------------------]]
--- @class BaseLibraryObject_Initialized : BaseLibraryObject
local BaseLibraryObject_Initialized = {}
--- @type ActionbarPlus
BaseLibraryObject_Initialized.addon = {}

--[[-----------------------------------------------------------------------------
BaseLibraryObject_Initialized_WithAceEvent
-------------------------------------------------------------------------------]]
--- @class BaseLibraryObject_Initialized_WithAceEvent : BaseLibraryObject_WithAceEvent
local BaseLibraryObject_Initialized_WithAceEvent = {}
--- @type ActionbarPlus
BaseLibraryObject_Initialized_WithAceEvent.addon = {}
