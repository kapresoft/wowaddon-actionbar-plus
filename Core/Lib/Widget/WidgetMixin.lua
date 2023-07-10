--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
local GameTooltip, IsUsableSpell, C_Timer = GameTooltip, IsUsableSpell, C_Timer
local GetNumBindings, GetBinding, GameTooltip_AddBlankLinesToTooltip = GetNumBindings, GetBinding, GameTooltip_AddBlankLinesToTooltip
local GetModifiedClick, IsShiftKeyDown, IsAltKeyDown, IsControlKeyDown = GetModifiedClick, IsShiftKeyDown, IsAltKeyDown, IsControlKeyDown
local UISpecialFrames, StaticPopup_Visible, StaticPopup_Show = UISpecialFrames, StaticPopup_Visible, StaticPopup_Show
local StaticPopupDialogs, ReloadUI = StaticPopupDialogs, ReloadUI
--[[-----------------------------------------------------------------------------
Lua Vars
-------------------------------------------------------------------------------]]
local setglobal = setglobal

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, LibStub = ns:LibPack()

local MX, String, P = O.Mixin, O.String, O.Profile
local GC = O.GlobalConstants
local IsBlank, IsNotBlank, ParseBindingDetails = String.IsBlank, String.IsNotBlank, String.ParseBindingDetails
local sreplace = String.replace

local MAX_NAME_CHARACTER_COUNT = 3

StaticPopupDialogs[GC.C.CONFIRM_RELOAD_UI] = {
    text = "Reload UI?", button1 = "Yes", button2 = "No",
    timeout = 0, whileDead = true, hideOnEscape = true,
    OnAccept = function() ReloadUI() end,
    preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
-- todo next: rename to WidgetUtil?
--- @class WidgetMixin : BaseLibraryObject
local _L = LibStub:NewLibrary(ns.M.WidgetMixin)
local p = _L:GetLogger()

--- @class FontStringWidget
local FontStringWidget = {
    --- @type FontStringTemplate
    fontString = {}
}
---type Font (see _Buttons.xml)
function FontStringWidget:GetNormalFont() return ABP_NumberFontNormalShadow end
---NumberFontNormalRightRed is Blizz. Font
function FontStringWidget:GetRedFont() return NumberFontNormalRightRed end
function FontStringWidget:SetVertexColorNormal()
    self.fontString:SetVertexColor(self:GetNormalFont():GetTextColor())
end
function FontStringWidget:SetVertexColorOutOfRange()
    self.fontString:SetVertexColor(self:GetRedFont():GetTextColor())
end
function FontStringWidget:SetTextWithRangeIndicator()
    self.fontString:SetText(RANGE_INDICATOR)
end
function FontStringWidget:ClearText() self.fontString:SetText('') end
function FontStringWidget:Show() self.fontString:Show() end
function FontStringWidget:Hide() self.fontString:Hide() end

function FontStringWidget:ScaleWithButtonSize(buttonSize)
    local fs = self.fontString
    local adjustX = buttonSize * 0.1
    local adjustY = buttonSize * 0.05
    fs:SetPoint("TOPRIGHT", -adjustX, -adjustY)
    local defaultFontHeight = 9
    local fontName, fontHeight = fs:GetFont()
    fontHeight = defaultFontHeight
    if buttonSize > 30 then
        local increase = math.ceil((buttonSize - 20) / 5)
        fontHeight = fontHeight + increase
    else
        fontHeight = defaultFontHeight
    end
    fs:SetFont(fontName, fontHeight, "OVERLAY")
end

--- @class FontStringTemplate
local FontStringTemplate = {
    --- @type FontStringWidget
    widget = nil
}

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]

--- @param button ButtonUI
--- @return _FontString
function _L:CreateFontString(button)
    local fs = button:CreateFontString(nil, nil, "NumberFontNormal")
    fs:SetPoint("BOTTOMRIGHT", -3, 2)
    local _, fontHeight = fs:GetFont()
    fs.textDefaultFontHeight = fontHeight
    return fs
end

--- ### See: "Interface/FrameXML/ActionButtonTemplate.xml"
--- ### See: [https://wowpedia.fandom.com/wiki/API_FontInstance_SetFont](https://wowpedia.fandom.com/wiki/API_FontInstance_SetFont)
--- @param b ButtonUI The button UI
--- @return _FontString
function _L:CreateNameTextFontString(b)
    --- @type _FontString
    local fs = b:CreateFontString("$parentName", "OVERLAY", 'NumberFontNormalSmallGray')
    local fontName, fontHeight = fs:GetFont()
    fs:SetFont(fontName, fontHeight - 1, "OUTLINE")
    fs:SetPoint("BOTTOM", b,"BOTTOM", 3, 5)
    function fs:SetEllipsesText(text)
        if IsBlank(text) then self:SetText('') return end
        if #text > MAX_NAME_CHARACTER_COUNT then
            text = string.sub(text, 1, MAX_NAME_CHARACTER_COUNT) .. "..."
        end
        self:SetText(text)
    end
    return fs
end

---Font Flags: OUTLINE, THICKOUTLINE, MONOCHROME
--- @see "https://wowpedia.fandom.com/wiki/API_FontInstance_SetFont"
--- @param b ButtonUI The button UI
function _L:CreateIndexTextFontString(b)
    --- @type FontStringTemplate
    local fs = b:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
    local fontName, fontHeight = fs:GetFont()
    fs:SetFont(fontName, fontHeight - 1, "OUTLINE")
    --fs:SetTextColor(100/255, 100/255, 100/255)
    fs:SetVertexColor(FontStringWidget:GetNormalFont():GetTextColor())
    fs:SetPoint("BOTTOMLEFT", 4, 4)

    return fs
end

---Font Flags: OUTLINE, THICKOUTLINE, MONOCHROME
--- @see "https://wowpedia.fandom.com/wiki/API_FontInstance_SetFont"
--- @param b ButtonUI The button UI
--- @return FontStringTemplate
function _L:CreateKeybindTextFontString(b)
    --- @type FontStringTemplate
    local fs = b:CreateFontString(nil, "OVERLAY", 'ABP_NumberFontNormalShadow')
    fs:SetJustifyH("RIGHT")
    fs:SetJustifyV("TOP")
    --- @type FontStringWidget
    local widget = MX:Mixin({ }, FontStringWidget)
    widget.fontString = fs
    fs.widget = widget;

    return fs
end

function _L:ShowActionbarsDelayed(isShown, delayInSec)
    local actualDelayInSec = delayInSec
    local showActionBars = isShown == true
    if type(actualDelayInSec) ~= 'number' then actualDelayInSec = delayInSec end
    if actualDelayInSec <= 0 then actualDelayInSec = 1 end
    -- Hide immediately and then try again after delayInSec
    self:ShowActionbars(isShown)
    C_Timer.After(actualDelayInSec, function() self:ShowActionbars(showActionBars) end)
end

--- @param isShown boolean Set to true to show action bar
function _L:ShowActionbars(isShown)
    O.ButtonFactory:ApplyForEachVisibleFrames(function(frameWidget)
        if frameWidget:IsShownInConfig() then
            frameWidget:SetGroupState(isShown)
        end
    end)
end

function _L:IsHideWhenTaxi() return P:IsHideWhenTaxi() end

function _L:HideTooltipDelayed(delayInSec)
    local actualDelayInSec = delayInSec
    if not actualDelayInSec or actualDelayInSec < 0 then
        GameTooltip:Hide()
        return
    end
    C_Timer.After(actualDelayInSec, function() GameTooltip:Hide() end)
end

--- @class BindingInfo
local BindingInfo = {
    name = 'command',
    btnName = '', category = '',
    key1 = '', key1Short = '', key2 = 'key2',
    --- @type BindingDetails
    details = { action = '', buttonPressed = '' }
}

--- TODO: Delete GetBarBindingsMap() Unused
--- @return table The binding map with button names as the key
function _L:GetBarBindingsMap()
    local barBindingsMap = {}
    local bindCount = GetNumBindings()
    if bindCount <=0 then return nil end
    for i = 1, bindCount do
        local command,cat,key1,key2 = GetBinding(i)
        local bindingDetails = ParseBindingDetails(command)
        if  bindingDetails then
            local key1Short = key1
            if IsNotBlank(key1Short) then
                key1Short = sreplace(key1Short, 'ALT', 'a')
                key1Short = sreplace(key1Short, 'CTRL', 'c')
                key1Short = sreplace(key1Short, 'SHIFT', 's')
                key1Short = sreplace(key1Short, 'META', 'm')
                key1Short = String.ReplaceAllCharButLast(key1Short, '-')
            end
            barBindingsMap[bindingDetails.buttonName] = self:GetBarBindings(bindingDetails.buttonName)
        end
    end
    return barBindingsMap
end

--- @return BindingInfo
--- @param btnName string The button name
function _L:GetBarBindings(btnName)
    if IsBlank(btnName) then return nil end
    local bindCount = GetNumBindings()
    if bindCount <=0 then return nil end
    for i = 1, bindCount do
        local command,cat,key1,key2 = GetBinding(i)
        local bindingDetails = ParseBindingDetails(command)
        if  bindingDetails and btnName == bindingDetails.buttonName then
            local key1Short = key1
            if IsNotBlank(key1Short) then
                key1Short = sreplace(key1Short, 'ALT', 'a')
                key1Short = sreplace(key1Short, 'CTRL', 'c')
                key1Short = sreplace(key1Short, 'SHIFT', 's')
                key1Short = sreplace(key1Short, 'META', 'm')
                key1Short = String.ReplaceAllCharButLast(key1Short, '-')
            end
            --- @type BindingInfo
            local b = {
                name = command, btnName = btnName, category = cat,
                key1 = key1, key1Short = key1Short, key2 = key2,
                details = bindingDetails
            }
            return b
        end
    end
    return nil
end
--- @param frame ButtonUI In retail owner can be any frame; should be treated as a generic frame
function _L:IsTypeMacro(frame)
    if not (frame and frame.widget and frame.widget.buttonName) then return false end
    --- @see ButtonProfileMixin#IsMacro
    return frame.widget:IsMacro()
end

function _L:SetupTooltipKeybindingInfo(tooltip)
    local button = tooltip:GetOwner()
    if not button then return end
    local btnWidget = button.widget
    if btnWidget then
        self:AddKeybindingInfo(btnWidget)
    end
    tooltip:Show()
end

--- @param btnWidget ButtonUIWidget
function _L:AddKeybindingInfo(btnWidget)
    if not btnWidget:HasKeybindings() then return end
    GameTooltip_AddBlankLinesToTooltip(GameTooltip, 1)
    local bindings = btnWidget:GetBindings()
    if not bindings.key1 then return end
    GameTooltip:AddDoubleLine('Keybind ::', bindings.key1, 1, 0.5, 0, 0 , 0.5, 1);
end

function _L:AddItemKeybindingInfo(btnWidget)
    if not btnWidget:HasKeybindings() then return end
    local bindings = btnWidget:GetBindings()
    GameTooltip:AppendText(String.format(GC.C.ABP_KEYBIND_FORMAT, bindings.key1))
end

function _L:IsDragKeyDown()
    -- 'NONE' if not specified
    local pickupAction = GetModifiedClick(GC.C.PICKUPACTION)
    pickupAction = pickupAction == GC.C.CTRL and GC.C.SHIFT or pickupAction
    local isDragKeyDown = pickupAction == GC.C.SHIFT and IsShiftKeyDown()
            or pickupAction == GC.C.ALT and IsAltKeyDown()
            or pickupAction == GC.C.CTRL and IsControlKeyDown()
    return isDragKeyDown
end

function _L:ConfigureFrameToCloseOnEscapeKey(frameName, frameInstance)
    local frame = frameInstance
    if frameInstance.frame then frame = frameInstance.frame end
    setglobal(frameName, frame)
    table.insert(UISpecialFrames, frameName)
end

function _L:ShowReloadUIConfirmation() StaticPopup_Show(GC.C.CONFIRM_RELOAD_UI) end

function _L:ConfirmAndReload()
    local reloadUI = GC.C.CONFIRM_RELOAD_UI
    if StaticPopup_Visible(reloadUI) == nil then return StaticPopup_Show(reloadUI) end
    return false
end
