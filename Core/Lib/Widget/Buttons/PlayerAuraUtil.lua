--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, LibStub = ns:LibPack()
local PAM, KC = O.PlayerAuraMapping, ns:K().Objects.Constants

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @class PlayerAuraUtil : BaseLibraryObject
local L = LibStub:NewLibrary(ns.M.PlayerAuraUtil)
local p = L.logger()
local pformat = ns.pformat

--[[-----------------------------------------------------------------------------
Properties
-------------------------------------------------------------------------------]]
--- @type PlayerAuraMap
L.addedAuras = {}

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- @param fw FrameWidget
--- @param msg string
local function OnPlayerAuraClassic(fw, msg)
    p:log(10, 'UNIT_AURA <CLASSIC>')
end

--- @param fw FrameWidget
--- @param playerAura AuraInfo
local function OnPlayerAuraRemoved(fw, playerAura)
    fw:ApplyForEachSpellOrMacroButtons(playerAura.spell.id, function(bw)
        L:ApplyIfAuraSpellMatches(bw, playerAura, function(bw, auraInfo) bw:HideOverlayGlow() end)
    end)
end

--- @param fw FrameWidget
--- @param playerAuras PlayerAuraMap The player auras table will never be empty.
local function OnPlayerAurasAdded(fw, playerAuras)
    L:ApplyToMatchingButtons(fw, playerAuras, function(bw, auraInfo)
        if L:IsActiveAura(auraInfo.aura.instanceID) then bw:ShowOverlayGlow() end
    end)
end

--- @param mappedAura AuraInfo
--- @param auraData AuraData
--- @return AuraInfo The new AuraInfo based on the mapped AuraInfo
local function CreateAuraInfo(mappedAura, auraData)
    if not mappedAura then return nil end

    --- @type AuraInfo
    local newAuraInfo = KC:CreateFromMixins(mappedAura)
    local aid = auraData.auraInstanceID
    newAuraInfo.aura.instanceID = aid
    newAuraInfo.aura.data = auraData

    return newAuraInfo
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- @param o PlayerAuraUtil
local function PropsAndMethods(o)

    o.OnPlayerAurasAdded = OnPlayerAurasAdded
    o.OnPlayerAuraRemoved = OnPlayerAuraRemoved

    --- @type PlayerAuraMap
    function o:GetActiveAuras() return self.addedAuras end

    --- if AuraData exists, then the aura is active
    --- @param instanceID AuraInstanceID
    function o:IsActiveAura(instanceID)
        if not C_UnitAuras then return false end
        return C_UnitAuras.GetAuraDataByAuraInstanceID('player', instanceID) ~= nil
    end

    --- @param playerAuraUpdateInfo UnitAuraUpdateInfo
    --- @return PlayerAuraMap
    function o:GetPlayerSpellsFromAura(playerAuraUpdateInfo)
        --- @type PlayerAuraMap
        local playerAuras = {}

        local addedAuras = playerAuraUpdateInfo and playerAuraUpdateInfo.addedAuras or {}
        if #addedAuras <= 0 then return playerAuras end

        for _, auraData in ipairs(addedAuras) do
            local mappedAura = PAM:GetAuraByAuraSpellID(auraData.spellId)
            local newAuraInfo = CreateAuraInfo(mappedAura, auraData)
            if newAuraInfo then
                local aid = auraData.auraInstanceID
                playerAuras[aid] = newAuraInfo
                self.addedAuras[aid] = newAuraInfo
            end
        end

        return playerAuras
    end

    --- @param playerAuraUpdateInfo UnitAuraUpdateInfo
    --- @return PlayerAuraMap
    function o:GetRemovedAuras(playerAuraUpdateInfo)
        --- @type PlayerAuraMap
        local playerAuras = {}

        local removedInstanceIDs = playerAuraUpdateInfo and playerAuraUpdateInfo.removedAuraInstanceIDs or {}
        if #removedInstanceIDs > 0 then
            for _, rID in ipairs(removedInstanceIDs) do
                local auraInfo = self.addedAuras[rID]
                if auraInfo then playerAuras[rID] = auraInfo end
            end
        end

        return playerAuras
    end

    --- @param aura AuraInfo
    function o:RemoveAura(aura)
        local auraInstanceID = aura.aura.instanceID
        C_Timer.After(1, function()
            self.addedAuras[auraInstanceID] = nil
            p:log(10, 'Removed[%s=>%s]: aid=%s expiry=%s',
                    aura.aura.spell.name, aura.spell.name, auraInstanceID, aura.aura.data.expirationTime)
        end)
    end

    --- @param fw FrameWidget
    --- @param applyFunction ButtonHandlerSpellAuraFunction | "function(bw, auraInfo) print(bw:GetName()) end"
    --- @param activePlayerAuras PlayerAuraMap
    function o:ApplyToMatchingButtons(fw, activePlayerAuras, applyFunction)
        for auraInstanceID, playerAura in pairs(activePlayerAuras) do
            fw:ApplyForEachSpellOrMacroButtons(playerAura.spell.id, function(bw)
                self:ApplyIfAuraSpellMatches(bw, playerAura, applyFunction)
            end)
        end
    end

    --- @param bw ButtonUIWidget
    --- @param applyFunction ButtonHandlerSpellAuraFunction | "function(bw, auraInfo) print(bw:GetName()) end"
    --- @param playerAura AuraInfo
    function o:ApplyIfAuraSpellMatches(bw, playerAura, applyFunction)
        local spellId
        local playerSpell = playerAura.spell
        if bw:IsSpell() then
            spellId = bw:GetSpellData().id
        elseif bw:IsMacro() then
            spellId = bw:GetMacroSpellId()
        end
        if spellId and playerSpell.id == spellId then
            applyFunction(bw, playerAura)
        end
    end

    ---@param w ButtonUIWidget
    function o:OnAfterButtonAttributesSet(w)
        local activeAuras = self:GetActiveAuras()
        if O.Table.IsEmpty(activeAuras) then return end
        for aID, aInfo in pairs(activeAuras) do
            if self:IsActiveAura(aID) and w:SpellNameEquals(aInfo.spell.name) then
                w:ShowOverlayGlow()
                return
            end
        end
    end
end

PropsAndMethods(L)




