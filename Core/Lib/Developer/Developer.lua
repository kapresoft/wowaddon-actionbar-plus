------------------------------------------------------------------------
-- test stuff.
------------------------------------------------------------------------
local format = string.format
--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
local SetCVar, GetCVarBool  = SetCVar, GetCVarBool

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, GC = ns.O, ns.O.GlobalConstants

local AceEvent = O.AceLibrary.AceEvent
local BF = O.ButtonFactory
local P = O.Profile

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @class Developer : BaseLibraryObject_WithAceEvent
local L = {}; AceEvent:Embed(L); D = L
local p = O.LogFactory('Developer')

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
function L:SpecIndex() return GC:GetSpecializationIndex() end
function L:PlayerClass() return GC:GetPlayerClass() end

function L:TT()
    self:SendMessage(GC.M.OnTooltipFrameUpdate)
end

--- down or up
function L:KDT()
    local useKeyDown = GetCVarBool("ActionButtonUseKeyDown")
    p:log('ActionButtonUseKeyDown[before]: %s', useKeyDown)
    useKeyDown = not useKeyDown
    SetCVar("ActionButtonUseKeyDown", useKeyDown)
    return useKeyDown
end

function L:ResetBarConfig()

    for i = 1, 8 do
        local f = _G['ActionbarPlusF' .. i]
        --- @type FrameWidget
        local w = f.widget
        local cf = w:GetConfig()
        cf.enabled = nil
        cf.anchor = nil
        cf.widget.buttonSize = nil
    end

end

function L:GetGlobalProfile() return P:G() end


function L:AnchorX(frameIndex, x)
    local fw = self:F(frameIndex).widget
    local a = fw:GetConfig().anchor
    a.x = x
end
function L:AnchorReset(frameIndex)
    local fw = self:F(frameIndex).widget
    local barData = fw:GetConfig()
    --barData.anchor = {}
    local a = barData.anchor
    a.point = nil
    a.relativePoint = nil
    a.x = nil
    a.y = nil
    print('Anchor Reset Done')
end

--- @param frameIndex number
--- @return FrameWidget
function L:F(frameIndex, buttonIndex)
    if not buttonIndex then return _G['ActionbarPlusF' .. tostring(frameIndex)].widget end
    return self:B(frameIndex, buttonIndex)
end

--- @return Profile_Bar
function L:C(frameIndex) return self:F(frameIndex):GetConfig() end

function L:M() return GetMouseFocus() end

function L:B(frameIndex, buttonIndex)
    local bn = string.format('ActionbarPlusF%sButton%s', frameIndex, buttonIndex)
    return _G[bn].widget
end

function L:API() return O.BaseAPI, O.API end
function L:NS() return ns end
function L:O() return ns.O end

function L:SM(msg) self:SendMessage(msg) end

--[[-----------------------------------------------------------------------------
Frame
-------------------------------------------------------------------------------]]
local function OnEvent(frame, event, ...)
    p:log(10, '%s', event)
    --if event == 'PLAYER_LEAVING_WORLD' then
    --end
end

--- @class DeveloperFrame
local frame = CreateFrame("Frame", 'DeveloperFrame', UIParent)
frame:SetScript('OnEvent', OnEvent)
frame:RegisterEvent('PLAYER_ENTERING_WORLD')
frame:RegisterEvent('PLAYER_LEAVING_WORLD')
