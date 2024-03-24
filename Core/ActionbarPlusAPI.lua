--[[-----------------------------------------------------------------------------
Lua Vars
-------------------------------------------------------------------------------]]
local tinsert = table.insert

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local ns = select(2, ...)
local O, GC, M, LibStub = ns.O, ns.GC, ns.M, ns.LibStub
local TimeUtil = ns:K().Objects.TimeUtil
local API, String = O.API, O.String
local IsBlank = String.IsBlank

--- @alias ActionbarPlusAPI __ActionbarPlusAPI | __BaseActionBarController
--- @class __ActionbarPlusAPI : BaseLibraryObject
local L = LibStub:NewLibrary(M.ActionbarPlusAPI); if not L then return end
O.ActionBarHandlerMixin:Embed(L)
local p = ns:LC().API:NewLogger(M.ActionbarPlusAPI)

--- @param o __ActionbarPlusAPI | ActionbarPlusAPI
local function PropertiesAndMethods(o)

    -- These fields are used for dependent addons like ActionbarPlus-M6
    --
    --- @see GlobalConstants#GetVersion()
    --- @return string
    function o:GetVersion() return GC:GetVersion() end
    --- @see GlobalConstants#GetLastUpdate()
    --- @return string
    function o:GetLastUpdate() return GC:GetLastUpdate() end
    --- @see GlobalConstants#GetActionbarPlusM6CompatibleVersionDate()
    --- @return string
    function o:GetActionbarPlusM6CompatibleVersionDate() return GC:GetActionbarPlusM6CompatibleVersionDate() end

    --- @return boolean, string OutOfDate result and the ActionbarPlus version text
    function o:IsActionbarPlusM6OutOfDate()
        local outOfDate = TimeUtil:IsOutOfDate(self:GetLastUpdate(), self:GetActionbarPlusM6CompatibleVersionDate())
        return outOfDate, self:GetVersion()
    end

    --- @param itemIDOrName number|string The itemID or itemName
    --- @return ItemInfo
    function o:GetItemInfo(itemIDOrName) return API:GetItemInfo(itemIDOrName) end

    --- @param itemIDOrName number|string The itemID or itemName
    --- @return ItemCooldown
    function o:GetItemCooldown(itemIDOrName) return API:GetItemCooldown(itemIDOrName) end

    --- @param spellNameOrID SpellID|SpellName Spell ID or Name. When passing a name requires the spell to be in your Spellbook.
    --- @return SpellCooldown
    function o:GetSpellCooldown(spellNameOrID) return API:GetSpellCooldown(spellNameOrID) end

    --- @param spellNameOrID SpellID|SpellName
    --- @return SpellName, SpellID
    function o:GetSpell(spellNameOrID)
        local name, id = API:GetSpellName(spellNameOrID); return name, id
    end

    --- @param spellNameOrID SpellID|SpellName
    --- @return boolean, SpellID, SpellName
    function o:IsStealthSpell(spellNameOrID)
        local name, id = API:GetSpellName(spellNameOrID)
        return API:IsStealthSpell(id), name, id
    end

    --- @param id SpellID
    --- @return boolean
    function o:IsStealthSpellByID(id) return API:IsStealthSpell(id) end

    --- @param macroName string
    --- @return boolean
    function o:IsM6Macro(macroName) return GC:IsM6Macro(macroName) end
    
    --- @param btnHandlerFn ButtonHandlerFunction
    function o:UpdateMacros(btnHandlerFn)
        O.ButtonFactory:ApplyForEachVisibleFrames(function(fw)
            fw:ApplyForEachMacro(btnHandlerFn)
        end)
    end
    --- @param btnHandlerFn ButtonHandlerFunction
    function o:UpdateM6Macros(btnHandlerFn)
        O.ButtonFactory:ApplyForEachVisibleFrames(function(fw)
            fw:ApplyForEachMacro(function(bw)
                if not bw:IsM6Macro() then return end
                btnHandlerFn(bw)
            end)
        end)
    end

    --- @param btnHandlerFn ButtonHandlerFunction
    --- @param macroName string
    function o:UpdateMacrosByName(macroName, btnHandlerFn)
        if IsBlank(macroName) then return end
        O.ButtonFactory:ApplyForEachVisibleFrames(function(fw)
            fw:ApplyForEachMacro(function(bw)
                if bw:HasMacroName(macroName) then btnHandlerFn(bw) end
            end)
        end)
    end

    --- @param predicateFn ButtonPredicateFunction
    --- @return table<number, ButtonUIWidget>
    function o:FindMacros(predicateFn)
        local ret = {}
        O.ButtonFactory:ApplyForEachVisibleFrames(function(fw)
            fw:ApplyForEachMacro(function(bw)
                if predicateFn(bw) then tinsert(ret, bw) end
            end)
        end)
    end

end
PropertiesAndMethods(L)

ABP_API = L


