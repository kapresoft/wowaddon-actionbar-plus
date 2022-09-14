--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
local GetMacroSpell, GetMacroItem, GetItemInfoInstant =
    GetMacroSpell, GetMacroItem, GetItemInfoInstant
local C_Timer = C_Timer

--[[-----------------------------------------------------------------------------
Lua Vars
-------------------------------------------------------------------------------]]
local tostring, format, strlower, tinsert = tostring, string.format, string.lower, table.insert
local LSM = ABP_WidgetConstants:LibPack_AceLibFactory():GetAceSharedMedia()
local noIconTexture = LSM:Fetch(LSM.MediaType.BACKGROUND, "Blizzard Dialog Background")
local TOPLEFT, BOTTOMLEFT, ANCHOR_TOPLEFT = TOPLEFT, BOTTOMLEFT, ANCHOR_TOPLEFT

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
local LibStub, M, G = ABP_LibGlobals:LibPack()
local WU = ABP_LibGlobals:LibPack_WidgetUtil()
local _, Table, String, LogFactory = G:LibPackUtils()
local p = LogFactory:NewLogger('ButtonMixin')
local SPELL, ITEM, MACRO = G:SpellItemMacroAttributes()
local UNIT = G:UnitIdAttributes()

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
---@param widget ButtonUIWidget
---@param rowNum number The row number
---@param colNum number The column number
local function SetButtonLayout(widget, rowNum, colNum)
    ---@type FrameWidget
    local dragFrame = widget.dragFrame
    local barConfig = dragFrame:GetConfig()
    local buttonSize = barConfig.widget.buttonSize
    local buttonPadding = widget.buttonPadding
    local frameStrata = widget.frameStrata
    local button = widget.button
    local dragFrameWidget = widget.dragFrame

    local widthPaddingAdj = dragFrameWidget.padding
    local heightPaddingAdj = dragFrameWidget.padding + dragFrameWidget.dragHandleHeight
    local widthAdj = ((colNum - 1) * buttonSize) + widthPaddingAdj
    local heightAdj = ((rowNum - 1) * buttonSize) + heightPaddingAdj

    button:SetFrameStrata(frameStrata)
    button:SetSize(buttonSize - buttonPadding, buttonSize - buttonPadding)
    button:SetPoint(TOPLEFT, dragFrameWidget.frame, TOPLEFT, widthAdj, -heightAdj)

    button.keybindText.widget:ScaleWithButtonSize(buttonSize)
end

--[[-----------------------------------------------------------------------------
New Instance
self: widget
button: widget.button
-------------------------------------------------------------------------------]]
---@class ButtonMixin : ButtonProfileMixin @ButtonMixin extends ButtonProfileMixin
---@see ButtonUIWidget
local _L = LibStub:NewLibrary(M.ButtonMixin)
G:Mixin(_L, G:LibPack_ButtonProfileMixin())

function _L:Init()
    SetButtonLayout(self, self.placement.rowNum, self.placement.colNum)
    WU:InitTextures(self, noIconTexture)
end

---@return ButtonUI
function _L:_Button() return self.button end
---@return ButtonUIWidget
function _L:_Widget() return self end

function _L:GetName() return self:_Button():GetName() end
function _L:GetIndex() return self.index end
function _L:GetFrameIndex() return self.dragFrameWidget:GetIndex() end
function _L:IsParentFrameShown() return self.dragFrame:IsShown() end

function _L:ResetConfig()
    self:_Widget().profile:ResetButtonData(self)
    self:ResetWidgetAttributes()
end

function _L:SetButtonAsEmpty()
    self:ResetConfig()
    self:SetTextureAsEmpty()
end

function _L:Reset()
    self:ResetCooldown()
    self:ClearAllText()
end

function _L:ResetCooldown() self:SetCooldown(0, 0) end
function _L:SetCooldown(start, duration) self.cooldown:SetCooldown(start, duration) end


---@type BindingInfo
function _L:GetBindings()
    return (self.addon.barBindings and self.addon.barBindings[self.buttonName]) or nil
end

---@param text string
function _L:SetText(text)
    if String.IsBlank(text) then text = '' end
    self:_Button().text:SetText(text)
end
---@param state boolean true will show the button index number
function _L:ShowIndex(state)
    local text = ''
    if true == state then text = self:_Widget().index end
    self:_Button().indexText:SetText(text)
end

---@param state boolean true will show the button index number
function _L:ShowKeybindText(state)
    local text = ''
    local button = self:_Button()
    if not self:HasKeybindings() then
        button.keybindText:SetText(text)
        return
    end

    if true == state then
        local bindings = self:GetBindings()
        if bindings and bindings.key1Short then
            text = bindings.key1Short
        end
    end
    button.keybindText:SetText(text)
end

function _L:HasKeybindings()
    local b = self:GetBindings()
    if not b then return false end
    return b and String.IsNotBlank(b.key1)
end
function _L:ClearAllText()
    self:SetText('')
    self.button.keybindText:SetText('')
end

---@return CooldownInfo
function _L:GetCooldownInfo()
    local btnData = self:GetConfig()
    if btnData == nil or String.IsBlank(btnData.type) then return nil end
    local type = btnData.type

    ---@class CooldownInfo
    local cd = {
        type=type,
        start=nil,
        duration=nil,
        enabled=0,
        details = {}
    }
    if type == SPELL then return self:GetSpellCooldown(cd)
    elseif type == MACRO then return self:GetMacroCooldown(cd)
    elseif type == ITEM then return self:GetItemCooldown(cd)
    end
    return nil
end

---@param cd CooldownInfo The cooldown info
---@return SpellCooldown
function _L:GetSpellCooldown(cd)
    local spell = self:GetSpellData()
    if not spell then return nil end
    local spellCD = _API:GetSpellCooldown(spell.id, spell)
    if spellCD ~= nil then
        cd.details = spellCD
        cd.start = spellCD.start
        cd.duration = spellCD.duration
        cd.enabled = spellCD.enabled
        return cd
    end
    return nil
end

---@param cd CooldownInfo The cooldown info
---@return ItemCooldown
function _L:GetItemCooldown(cd)
    local item = self:GetItemData()
    if not (item and item.id) then return nil end
    local itemCD = _API:GetItemCooldown(item.id, item)
    if itemCD ~= nil then
        cd.details = itemCD
        cd.start = itemCD.start
        cd.duration = itemCD.duration
        cd.enabled = itemCD.enabled
        return cd
    end
    return nil
end

---@param cd CooldownInfo The cooldown info
function _L:GetMacroCooldown(cd)
    local spellCD = self:GetMacroSpellCooldown();

    if spellCD ~= nil then
        cd.details = spellCD
        cd.start = spellCD.start
        cd.duration = spellCD.duration
        cd.enabled = spellCD.enabled
        cd.icon = spellCD.spell.icon
        return cd
    else
        local itemCD = self:GetMacroItemCooldown()
        if itemCD ~= nil then
            cd.details = itemCD
            cd.start = itemCD.start
            cd.duration = itemCD.duration
            cd.enabled = itemCD.enabled
            return cd
        end
    end

    return nil;
end

---@return SpellCooldown
function _L:GetMacroSpellCooldown()
    local macro = self:GetMacroData();
    if not macro then return nil end
    local spellId = GetMacroSpell(macro.index)
    if not spellId then return nil end
    return _API:GetSpellCooldown(spellId)
end

---@return number The spellID for macro
function _L:GetMacroSpellId()
    local macro = self:GetMacroData();
    if not macro then return nil end
    return GetMacroSpell(macro.index)
end

---@return ItemCooldown
function _L:GetMacroItemCooldown()
    local macro = self:GetMacroData();
    if not macro then return nil end

    local itemName = GetMacroItem(macro.index)
    if not itemName then return nil end

    local itemID = GetItemInfoInstant(itemName)
    return _API:GetItemCooldown(itemID)
end

function _L:ContainsValidAction() return self:_Widget().buttonData:ContainsValidAction() end

function _L:ResetWidgetAttributes()
    local button = self:_Button()
    for _, v in pairs(self.buttonAttributes) do
        button:SetAttribute(v, nil)
    end
end

function _L:UpdateItemState()
    self:ClearAllText()
    local btnData = self:GetConfig()
    if self:invalidButtonData(btnData, ITEM) then return end
    local itemID = btnData.item.id
    local itemInfo = _API:GetItemInfo(itemID)
    if itemInfo == nil then return end
    local stackCount = itemInfo.stackCount or 1
    btnData.item.count = itemInfo.count
    btnData.item.stackCount = stackCount
    if stackCount > 1 then self:SetText(btnData.item.count) end
end

function _L:UpdateUsable() WU:UpdateUsable(self) end

function _L:UpdateState()
    self:UpdateCooldown()
    self:UpdateItemState()
    self:UpdateUsable()
    self:UpdateRangeIndicator()
end
function _L:UpdateStateDelayed(inSeconds) C_Timer.After(inSeconds, function() self:UpdateState() end) end
function _L:UpdateCooldown()
    local cd = self:GetCooldownInfo()
    if not cd or cd.enabled == 0 then return end
    -- Instant cast spells have zero duration, skip
    if cd.duration <= 0 then
        self:ResetCooldown()
        return
    end
    self:SetCooldown(cd.start, cd.duration)
end
function _L:UpdateCooldownDelayed(inSeconds) C_Timer.After(inSeconds, function() self:UpdateCooldown() end) end


---@return ActionBarInfo
function _L:GetActionbarInfo()
    local index = self.index
    local dragFrame = self.dragFrame;
    local frameName = dragFrame:GetName()
    local btnName = format('%sButton%s', frameName, tostring(index))

    ---@class ActionBarInfo
    local info = {
        name = frameName, index = dragFrame:GetFrameIndex(),
        button = { name = btnName, index = index },
    }
    return info
end

function _L:ClearHighlight() self.button:SetHighlightTexture(nil) end
function _L:ResetHighlight() WU:ResetHighlight(self) end
function _L:SetTextureAsEmpty() self:SetIcon(noIconTexture) end
function _L:SetIcon(icon) WU:SetIcon(self, icon) end
function _L:SetCooldownTextures(icon) WU:SetCooldownTextures(self, icon) end
function _L:SetHighlightInUse() WU:SetHighlightInUse(self.button) end
function _L:SetHighlightDefault() WU:SetHighlightDefault(self.button) end

---@param spellID string The spellID to match
---@param optionalProfileButton ProfileButton
---@return boolean
function _L:IsMatchingItemSpellID(spellID, optionalProfileButton)
    return WU:IsMatchingItemSpellID(spellID, optionalProfileButton or self:GetConfig())
end
---@param spellID string The spellID to match
---@param optionalProfileButton ProfileButton
---@return boolean
function _L:IsMatchingSpellID(spellID, optionalProfileButton)
    return WU:IsMatchingSpellID(spellID, optionalProfileButton or self:GetConfig())
end
---@param spellID string The spellID to match
---@param optionalProfileButton ProfileButton
---@return boolean
function _L:IsMatchingMacroSpellID(spellID, optionalProfileButton)
    return WU:IsMatchingMacroSpellID(spellID, optionalProfileButton or self:GetConfig())
end
---@param spellID string The spellID to match
---@return boolean
function _L:IsMatchingMacroOrSpell(spellID)
    ---@type ProfileButton
    local conf = self:GetConfig()
    if not conf and (conf.spell or conf.macro) then return false end
    if self:IsSpellConfig(conf) then
        return spellID == conf.spell.id
    elseif self:IsMacroConfig(conf) and conf.macro.index then
        local macroSpellId =  GetMacroSpell(conf.macro.index)
        return spellID == macroSpellId
    end

    return false;
end

---@param rowNum number
---@param colNum number
function _L:Resize(rowNum, colNum) SetButtonLayout(self, rowNum, colNum) end

---@param hasTarget boolean Player has a target
function _L:UpdateRangeIndicatorWithShowKeybindOn(hasTarget)
    -- if no target, do nothing and return
    local widget = self:_Widget()
    local fs = widget.button.keybindText
    if not hasTarget then fs.widget:SetVertexColorNormal(); return end
    if widget:IsMacro() then return end
    if not widget:HasKeybindings() then fs.widget:SetTextWithRangeIndicator() end

    -- else if in range, color is "white"
    local inRange = _API:IsActionInRange(widget:GetConfig(), UNIT.target)
    --self:log('%s in-range: %s', widget:GetName(), tostring(inRange))
    fs.widget:SetVertexColorNormal()
    if inRange == false then
        fs.widget:SetVertexColorOutOfRange()
    elseif inRange == nil then
        -- spells, items, macros where range is not applicable
        if not widget:HasKeybindings() then fs.widget:ClearText() end
    end
end

---@param hasTarget boolean Player has a target
function _L:UpdateRangeIndicatorWithShowKeybindOff(hasTarget)
    -- if no target, clear text and return
    local fs = self:_Button().keybindText
    if not hasTarget then
        fs.widget:ClearText()
        fs.widget:SetVertexColorNormal()
        return
    end

    local widget = self:_Widget()
    if widget:IsMacro() then return end

    -- has target, set text as range indicator
    fs.widget:SetTextWithRangeIndicator()

    local inRange = _API:IsActionInRange(widget:GetConfig(), UNIT.target)
    --self:log('%s in-range: %s', widget:GetName(), tostring(inRange))
    fs.widget:SetVertexColorNormal()
    if inRange == false then
        fs.widget:SetVertexColorOutOfRange()
    elseif inRange == nil then
        fs.widget:ClearText()
    end
end

function _L:UpdateRangeIndicator()
    if not self:ContainsValidAction() then return end
    local widget = self:_Widget()
    local configIsShowKeybindText = widget.dragFrame:IsShowKeybindText()
    local hasTarget = GetUnitName(UNIT.target) ~= null
    widget:ShowKeybindText(configIsShowKeybindText)

    if configIsShowKeybindText == true then
        return self:UpdateRangeIndicatorWithShowKeybindOn(hasTarget)
    end
    self:UpdateRangeIndicatorWithShowKeybindOff(hasTarget)
end

