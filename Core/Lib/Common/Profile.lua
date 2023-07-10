--[[-----------------------------------------------------------------------------
Lua Vars
-------------------------------------------------------------------------------]]
local type, pairs, tostring = type, pairs, tostring

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, LibStub = ns:LibPack()

local GC, Ace, PI = O.GlobalConstants, O.AceLibrary, O.ProfileInitializer
local Table, Assert, String = O.Table, O.Assert, O.String
local AceEvent, W = Ace.AceEvent, GC.WidgetAttributes
local IsEmptyTable, isNotTable, tsize, tinsert, tsort
    = Table.IsEmpty, Table.isNotTable, Table.size, table.insert, table.sort
local IsBlankStr = String.IsBlank
local AssertThatMethodArgIsNotNil = Assert.AssertThatMethodArgIsNotNil

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @class Profile : BaseLibraryObject_WithAceEvent
local P = LibStub:NewLibrary(ns.M.Profile); if not P then return end
AceEvent:Embed(P)
local p = P:GetLogger()

local ConfigNames = GC.Profile_Config_Names
local C = GC:GetAceLocale()

--[[-----------------------------------------------------------------------------
Interface Definition
-------------------------------------------------------------------------------]]
--- @class TooltipKeyName
local TooltipKeyName = {
    ['SHOW'] = '',
    ['ALT'] = 'alt',
    ['CTRL'] = 'ctrl',
    ['SHIFT'] = 'shift',
    ['HIDE'] = 'hide',
}

--- @class TooltipKey
local TooltipKey = {
    names = TooltipKeyName,
    sorting = {
        TooltipKeyName.SHOW, TooltipKeyName.ALT, TooltipKeyName.CTRL,
        TooltipKeyName.SHIFT, TooltipKeyName.HIDE },
    kvPairs = {
        [TooltipKeyName.SHOW]  = C['Show'],
        [TooltipKeyName.ALT]   = C['ALT'],
        [TooltipKeyName.CTRL]  = C['CTRL'],
        [TooltipKeyName.SHIFT] = C['SHIFT'],
        [TooltipKeyName.HIDE]  = C['Hide'],
    }
}

--- @class TooltipAnchorTypeKey
--- @see Config
local TooltipAnchorTypeKey = {
    names = GC.TooltipAnchor,
    sorting = {
        GC.TooltipAnchor.CURSOR_TOPLEFT, GC.TooltipAnchor.CURSOR_TOPRIGHT,
        GC.TooltipAnchor.CURSOR_BOTTOMLEFT, GC.TooltipAnchor.CURSOR_BOTTOMRIGHT,
        GC.TooltipAnchor.SCREEN_TOPLEFT, GC.TooltipAnchor.SCREEN_TOPRIGHT,
        GC.TooltipAnchor.SCREEN_BOTTOMLEFT, GC.TooltipAnchor.SCREEN_BOTTOMRIGHT,
    },
    kvPairs = {
        [GC.TooltipAnchor.CURSOR_TOPLEFT]  = 'Cursor Top Left',
        [GC.TooltipAnchor.CURSOR_TOPRIGHT]  = 'Cursor Top Right',
        [GC.TooltipAnchor.CURSOR_BOTTOMLEFT]  = 'Cursor Bottom Left',
        [GC.TooltipAnchor.CURSOR_BOTTOMRIGHT]  = 'Cursor Bottom Right',
        [GC.TooltipAnchor.SCREEN_TOPLEFT]  = 'Screen Top Left',
        [GC.TooltipAnchor.SCREEN_TOPRIGHT]  = 'Screen Top Right',
        [GC.TooltipAnchor.SCREEN_BOTTOMLEFT]  = 'Screen Bottom Left',
        [GC.TooltipAnchor.SCREEN_BOTTOMRIGHT]  = 'Screen Bottom Right',
    }
}

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]

--- @param source _RegionAnchor
--- @param dest _RegionAnchor
local function CopyAnchor(source, dest)
    dest.point = source.point
    dest.relativeTo = source.relativeTo
    dest.relativePoint = source.relativePoint
    dest.x = source.x
    dest.y = source.y
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- @param obj any
function P:Mixin(obj)
    return ns:K():Mixin(obj, self)
end

--local function removeElement(tbl, value)
--    for i, v in ipairs(tbl) do if v == value then tbl[i] = nil end end
--end

--- Removes a particular actionType data from Profile_Button
--- @param bw ButtonUIWidget
function P:CleanupActionTypeData(bw)
    local btnConf = P:GetButtonConfigForScrubbing(bw.frameIndex, bw:GetName())
    if not btnConf then return end

    if IsEmptyTable(btnConf) or IsBlankStr(btnConf.type) then
        self:ResetButtonConfig(bw)
        return
    end

    local actionTypes = O.ActionType:GetOtherNamesExcept(btnConf.type)
    for _, v in ipairs(actionTypes) do if v ~= nil then btnConf[v] = nil end end
end

--- @type table<number, Profile_Bar>
local barProfiles = {}

--- @type table<string, Profile_Button>
local buttonProfiles = {}

--- @param frameIndex Index
--- @param buttonName string
--- @return Profile_Button
function P:GetButtonConfig(frameIndex, buttonName)
    local bar = self:GetBar(frameIndex)
    local buttons = bar.buttons or {}
    bar.buttons = buttons
    if not buttons[buttonName] then
        local btn = O.ProfileInitializer:CreateSingleButtonTemplate()
        buttons[buttonName] = btn
    end
    return buttons[buttonName]
end

--- @param frameIndex Index
--- @param buttonName string
--- @return Profile_Button
function P:GetButtonConfigForScrubbing(frameIndex, buttonName)
    local bar = self:GetBar(frameIndex)
    local buttons = bar.buttons or {}
    bar.buttons = buttons
    if not buttons then return nil end
    return self:GetBar(frameIndex).buttons[buttonName]
end

--- @deprecated To be deleted
--- @param frameIndex Index
--- @param buttonName string
function P:RetrieveButtonConfig(frameIndex, buttonName)
    local profileButton = self:GetButtonData(frameIndex, buttonName)
    buttonProfiles[buttonName] = profileButton
    return profileButton
end

--- @deprecated To be deleted
--- Object buttons[buttonName] is guaranteed to exist by the default profile (see #CreateDefaultProfile())
--- @return Profile_Button
function P:GetButtonData(frameIndex, buttonName)
    local barData = self:GetBar(frameIndex)
    if not barData then return end
    local buttons = barData.buttons
    return buttons[buttonName]
end

function P:CreateDefaultProfile() return PI:InitNewProfile() end

function P:CreateBarsTemplate()
    local bars = {}
    for i=1, self:GetActionbarFrameCount() do
        local frameName = self:GetFrameNameByIndex(i)
        bars[frameName] = {
            enabled = false,
            buttons = {}
        }
    end

    return bars
end

--- @return Profile_Config
function P:P() return ns.db.profile  end
--- @return Profile_Global_Config
function P:G()
    local g = ns.db.global
    if Table.isNotTable(g.bars) then PI:InitGlobalSettings(g) end
    return g
end

-- /run ABP_Table.toString(Profile:GetBar(1))
--- @return Profile_Bar
function P:GetBar(frameIndex) return barProfiles[frameIndex] or self:RetrieveBar(frameIndex) end

---@param bw ButtonUIWidget
function P:ResetButtonConfig(bw) P:GetBar(bw.frameIndex).buttons[bw:GetName()] = nil end

--- @return Profile_Bar
---@param frameIndex number
function P:RetrieveBar(frameIndex)
    assert(frameIndex, "RetrieveBar: frameIndex is required.")
    local frameName = self:GetFrameNameByIndex(frameIndex)
    local profile = ns.p()
    local bar = profile.bars[frameName]
    barProfiles[frameIndex] = bar
    return bar
end


function P:GetBars()
    return ns.db.profile.bars
end

function P:GetBarSize()
    local bars = P:GetBars()
    if isNotTable(bars) then return 0 end
    return tsize(bars)
end

--- @param frameIndex number The frame index number
--- @param isEnabled boolean The enabled state
function P:SetBarEnabledState(frameIndex, isEnabled)
    local bar = self:GetBar(frameIndex)
    bar.enabled = isEnabled
end

--- @param frameIndex number The frame index number
function P:IsBarEnabled(frameIndex)
    local bar = self:GetBar(frameIndex)
    return bar and bar.enabled
end
--- @param frameIndex number The frame index number
function P:IsShownInConfig(frameIndex) return self:IsBarEnabled(frameIndex) end

--- @param frameIndex number The frame index number
function P:GetBarLockValue(frameIndex)
    local bar = self:GetBar(frameIndex)
    return bar.locked or ''
end

--- @param frameIndex number The frame index number
--- @param value string Allowed values are "always", "in-combat", or nil
function P:SetBarLockValue(frameIndex, value)
    local bar = self:GetBar(frameIndex)
    local valueLower = string.lower(value or '')
    if valueLower == 'always' or valueLower == 'in-combat' then
        bar.locked = value
        return bar.locked
    end
    bar.locked = ''
    return bar.locked
end

function P:IsCharacterSpecificAnchor()
    return true == self.profile[ConfigNames.character_specific_anchors]
end

--- @param frameIndex number
--- @return _RegionAnchor
function P:GetAnchor(frameIndex)
    if self:IsCharacterSpecificAnchor() then return self:GetCharacterSpecificAnchor(frameIndex) end
    return self:GetGlobalAnchor(frameIndex)
end

--- @param frameIndex number
--- @return _RegionAnchor
function P:GetGlobalAnchor(frameIndex)
    --- @type Global_Profile_Bar
    local g = self:G()
    local fn = P:GetFrameNameByIndex(frameIndex)
    --- @type Profile_Global_Config
    local buttonConf = g.bars[fn]
    if not buttonConf then buttonConf = PI:InitGlobalButtonConfig(g, fn) end
    if Table.isEmpty(buttonConf.anchor) then
        buttonConf.anchor = PI:InitGlobalButtonConfigAnchor(g, fn)
    end
    return buttonConf.anchor
end

--- @param frameIndex number
--- @return _RegionAnchor
function P:GetCharacterSpecificAnchor(frameIndex) return self:GetBar(frameIndex).anchor end

--- @param frameAnchor _RegionAnchor
--- @param frameIndex number
function P:SaveAnchor(frameAnchor, frameIndex)
    -- always sync the character specific settings
    self:SaveCharacterSpecificAnchor(frameAnchor, frameIndex)

    if not self:IsCharacterSpecificAnchor() then
        self:SaveGlobalAnchor(frameAnchor, frameIndex)
    end
end

--- @param frameIndex number
--- @return Global_Profile_Bar
function P:GetGlobalBar(frameIndex)
    local frameName = self:GetFrameNameByIndex(frameIndex)
    return frameIndex and self:G().bars[frameName]
end

--- Global
--- @param frameAnchor _RegionAnchor
--- @param frameIndex number
function P:SaveGlobalAnchor(frameAnchor, frameIndex)
    local globalBarConf = self:GetGlobalBar(frameIndex)
    CopyAnchor(frameAnchor, globalBarConf.anchor)
end

--- @param frameAnchor _RegionAnchor
--- @param frameIndex number
function P:SaveCharacterSpecificAnchor(frameAnchor, frameIndex)
    local barProfile = self:GetBar(frameIndex)
    CopyAnchor(frameAnchor, barProfile.anchor)
end

function P:IsActionButtonMouseoverGlowEnabled() return self:P().action_button_mouseover_glow == true end
function P:IsBarUnlocked(frameIndex) return self:GetBarLockValue(frameIndex) == '' or self:GetBarLockValue(frameIndex) == nil end
function P:IsBarLockedInCombat(frameIndex) return self:GetBarLockValue(frameIndex) == 'in-combat' end
function P:IsBarLockedAlways(frameIndex) return self:GetBarLockValue(frameIndex) == 'always' end
function P:IsBarIndexEnabled(frameIndex) return self:IsBarNameEnabled(self:GetFrameNameByIndex(frameIndex)) end

function P:IsBarNameEnabled(frameName)
    if not self.profile.bars then return false end
    local bar = self.profile.bars[frameName]
    if isNotTable(bar) then return false end
    return bar.enabled
end

--- @param frameIndex number The frame index number
--- @param isEnabled boolean The enabled state
function P:SetShowIndex(frameIndex, isEnabled)
    self:GetBar(frameIndex).show_button_index = (isEnabled == true)
end

--- @param frameIndex number The frame index number
--- @param isEnabled boolean The enabled state
function P:SetShowKeybindText(frameIndex, isEnabled)
    self:GetBar(frameIndex).show_keybind_text = (isEnabled == true)
end

--- @param frameIndex number The frame index number
--- @return boolean
function P:IsShowIndex(frameIndex) return self:GetBar(frameIndex).show_button_index == true end

--- @param frameIndex number The frame index number
function P:IsShowKeybindText(frameIndex) return self:GetBar(frameIndex).show_keybind_text == true end

--- @param frameIndex number The frame index number
function P:IsShowEmptyButtons(frameIndex) return self:GetBar(frameIndex).widget.show_empty_buttons == true end

function P:GetFrameNameByIndex(frameIndex) return PI:GetFrameNameByIndex(frameIndex) end

--- @return FrameWidget
function P:GetFrameWidgetByIndex(frameIndex) return _G[self:GetFrameNameByIndex(frameIndex)].widget end

function P:GetActionbarFrameCount() return PI.ActionbarCount end

function P:GetAllFrameNames()
    local fnames = {}
    for i=1, self:GetActionbarFrameCount() do
        local fn = self:GetFrameNameByIndex(i)
        tinsert(fnames, fn)
    end
    tsort(fnames)
    return fnames
end

--- Only return the bars that do exist. Some old profile button info
--- may exist even though the size of bar may not include these buttons.
--- The number of buttons do not reflect how many buttons actually exist because
--- the addon doesn't cleanup old data.
-- TODO: Should we cleanup old config?
--- @param btnType string spell, macro, item
function P:FindButtonsByType(btnType)
    local buttons = {}
    for _, bar in pairs(self:GetBars()) do
        if bar.buttons then
            for buttonName, button in pairs(bar.buttons) do
                if btnType == button.type and _G[buttonName] then
                    buttons[buttonName] = button
                end
            end
        end
    end
    return buttons
end

function P:IsHideWhenTaxi() return self.profile[ConfigNames.hide_when_taxi] == true end

--- @param anchorType string
--- @see TooltipAnchor
function P:SetTooltipAnchorType(anchorType) self.profile[ConfigNames.tooltip_anchor_type] = anchorType end
--- @see TooltipAnchor
--- @return string One of TooltipAnchor values
function P:GetTooltipAnchorType() return self.profile[ConfigNames.tooltip_anchor_type] or GC.TooltipAnchor.CURSOR_TOPRIGHT end

--- @return Profile_Config_Names
function P:GetConfigNames() return ConfigNames end

--- @return TooltipKey
function P:GetTooltipKey() return TooltipKey end

--- @return TooltipAnchorTypeKey
function P:GetTooltipAnchorTypeKey() return TooltipAnchorTypeKey end

function P:GetRowSize(frameIndex)
    return self:GetBar(frameIndex).widget.rowSize or 2
end

function P:GetColumnSize(frameIndex)
    return self:GetBar(frameIndex).widget.colSize or 6
end


--[[-----------------------------------------------------------------------------
Listen to Message
-------------------------------------------------------------------------------]]
P:RegisterMessage(GC.M.OnDBInitialized, function(msg)
    P.profile = ns.db.profile
end)
