--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub, pformat = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub, ns.pformat

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @class PlayerAuraMapping : BaseLibraryObject
local L = LibStub:NewLibrary(M.PlayerAuraMapping); if not L then return end
local p = L.logger()

local Mapping = {
    --- @type PlayerAuraUnitMap
    ['retail'] = {
        --- @type PlayerAuraSpecializationMap
        ['MAGE'] = {
            --- @type PlayerAuraMap
            [1] = {},
            --- @type PlayerAuraMap
            [2] = {},
            --- @type PlayerAuraMap
            [3] = {
                --- @type AuraInfo
                [190446] = {
                    aura = { spell = { id = 190446, name = 'Brain Freeze' } },
                    spell = { id = 44614, name='Flurry' }
                },
                --- @type AuraInfo
                [44544] = {
                    aura = { spell = { id = 44544, name = 'Fingers of Frost' } },
                    spell = { id = 30455, name='Ice Lance' }
                }
            }
        },
        ['WARLOCK'] = {
            [2] = {
                [264173] = {
                    aura = { spell = { id = 264173, name ='Demonic Core'} },
                    spell = { id = 264178, name = 'Demonbolt'},
                },
                [205146] = {
                    aura = { spell = { id = 205146, name ='Demonic Calling'} },
                    spell = { id = 104316, name ='Call Dreadstalkers'},
                }
            }
        }
    },
    --- @type PlayerAuraUnitMap
    ['wotlk_classic'] = {
        --- @type PlayerAuraSpecializationMap
        ['MAGE'] = {
            --- @type PlayerAuraMap
            [1] = {
                --- @type AuraInfo
                [12345] = { }
            },
            --- @type PlayerAuraMap
            [2] = {
                --- @type AuraInfo
                [12346] = { }
            }
        }
    },
    ['classic'] = {

    }
}

--[[-----------------------------------------------------------------------------
Methods & Properties
-------------------------------------------------------------------------------]]
---@param o PlayerAuraMapping
local function MethodsAndProperties(o)

    --- @type PlayerAuraSpecializationMap
    o.playerClassMapping = nil

    --- @return PlayerAuraSpecializationMap
    function o:GetPlayerClassMapping()
        if self.playerClassMapping then return self.playerClassMapping end

        local gameMapping = Mapping[ns.gameVersion]; if not gameMapping then return nil end
        self.playerClassMapping = gameMapping[GC:GetPlayerClass()]
    end

    --- @param auraSpellID number The aura SpellID
    --- @return AuraInfo
    function o:GetAuraByAuraSpellID(auraSpellID)
        local pcm = self:GetPlayerClassMapping(); if not pcm then return nil end
        --- @type table<AuraInstanceID, AuraInfo>
        local playerMapping = pcm[GC:GetSpecializationIndex()]; if not playerMapping then return nil end
        return playerMapping[auraSpellID]
    end

end

MethodsAndProperties(L)
