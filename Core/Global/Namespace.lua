--[[-----------------------------------------------------------------------------
Namespace Initialization
-------------------------------------------------------------------------------]]
local _addon, _ns = ...
local LibStub = LibStub

---This absolutely does NOTHING but make EmmyLua work better in IDEs for code
---completions.
--- @param o Namespace
local function Define_InterfaceMethods(o)

    --- @see CursorMixin.lua
    --- @return CursorUtil
    --function o:CreateCursorUtil() end

    --- @see UtilWrapper.lua
    --- @param start number
    --- @param increment number
    --- @return Kapresoft_Incrementer
    function o:CreateIncrementer(start, increment) end

end

Define_InterfaceMethods(_ns)

--- @type LibPackMixin
local LibPackMixin = {}
--- @return GlobalObjects, LocalLibStub
function LibPackMixin:LibPack() return self.O, self.O.LibStub end
--- @return GlobalObjects, GlobalConstants
function LibPackMixin:LibPack2() return self.O, self.O.GlobalConstants end
--- @generic A : AceEvent
--- @return A
function LibPackMixin:AceEvent() return self.O.AceLibrary.AceEvent:Embed({}) end
--- @return AceBucket
function LibPackMixin:AceBucket() return self.LibStubAce('AceBucket-3.0'):Embed({}) end

--- @return AceBucket
--- @param obj table
function LibPackMixin:AceBucketEmbed(obj)
    local AceBucket = self.LibStubAce('AceBucket-3.0'); if obj then AceBucket:Embed(obj) end
    return AceBucket
end

--- @return Namespace
local function CreateNamespace(...)
    --- @type string
    local addon
    --- @type Namespace
    local ns

    addon, ns = ...

    function ns:K() return ns.Kapresoft_LibUtil end

    --- this is in case we are testing outside of World of Warcraft
    addon = addon or ABP_GlobalConstants.C.ADDON_NAME

    --- @type GlobalObjects
    ns.O = ns.O or {}
    --- The AddOn Name, i.e. "ActionbarPlus"
    --- @type string
    ns.name = addon
    --- @type ActionbarPlus_AceDB
    ns.db = ns.db or {}

    --- @type Module
    ns.M = ns.M or {}

    ns.pformat = ns:K().pformat:B()

    ns:K():Mixin(ns, LibPackMixin)

    --- @param o Namespace
    local function Methods(o)

        --- @return Profile_Config
        function o.p() return ns.db.profile end

        --- @return BooleanOptional
        function o:IsLoggingEnabled() return true == ns.O.GlobalConstants.F.ENABLE_LOGGING end
        --- @return BooleanOptional
        function o:IsLoggingDisabled() return true ~= ns.O.GlobalConstants.F.ENABLE_LOGGING end

        --- @return GameVersion
        function o:IsVanilla() return self.gameVersion == 'classic' end
        --- @return GameVersion
        function o:IsTBC() return self.gameVersion == 'tbc_classic' end
        --- @return GameVersion
        function o:IsWOTLK() return self.gameVersion == 'wotlk_classic' end
        --- @return GameVersion
        function o:IsRetail() return self.gameVersion == 'retail' end

        --- @return CursorUtil
        ---@param cursorInfo CursorInfo Optional cursorInfo instance
        function o:CreateCursorUtil(cursorInfo)
            local _cursorInfo = cursorInfo or o.O.API:GetCursorInfo()
            return self:K():CreateAndInitFromMixin(o.O.CursorMixin, _cursorInfo)
        end

        --- @param start number
        --- @param increment number
        --- @return Kapresoft_Incrementer
        function o:CreateIncrementer(start, increment) return self:K():CreateIncrementer(start, increment) end

        --- @param moduleName string The module name, i.e. Logger
        --- @return string The complete module name, i.e. 'ActionbarPlus-Logger-1.0'
        function o:LibName(moduleName) return self.name .. '-' .. moduleName .. '-1.0' end

        --- @param name string The module name
        --- @param o any The object to register
        function o:Register(name, o)
            if not (name or o) then return end
            ns.O[name] = o
        end
    end

    Methods(ns)

    --- @class LocalLibStub : Kapresoft_LibUtil_LibStubMixin
    local LocalLibStub = ns:K().Objects.LibStubMixin:New(ns.name, 1.0,
            function(name, newLibInstance)
                --- @type Logger
                local loggerLib = LibStub(ns:LibName(ns.M.Logger))
                if loggerLib then
                    newLibInstance.logger = function() return loggerLib:NewLogger(name) end
                    newLibInstance.logger():log(30, 'New Lib: %s', newLibInstance.major)
                    function newLibInstance:GetLogger() return self.logger() end
                end
                ns:Register(name, newLibInstance)
            end)
    ns.LibStub = LocalLibStub
    ns.LibStubAce = LibStub
    ns.O.LibStub = LocalLibStub

    ns.mt = { __tostring = function() return addon .. '::Namespace'  end }
    setmetatable(ns, ns.mt)

    return ns
end

if _ns.name then return end

CreateNamespace(...)
