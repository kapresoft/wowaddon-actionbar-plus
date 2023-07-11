--[[-----------------------------------------------------------------------------
ActionButtonMixin: Similar to ButtonMixin.lua
-------------------------------------------------------------------------------]]

--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub
local p, pformat = O.Logger:NewLogger('ActionButtonWidgetMixin'), ns.pformat
local String, Table, W = O.String, O.Table, GC.WidgetAttributes
local IsEmptyTable = Table.IsEmpty
local IsEmptyStr, IsBlankStr, IsNotBlankStr = String.IsEmpty, String.IsBlank, String.IsNotBlank

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @alias ActionButtonWidget ActionButtonWidgetMixin
--- @class ActionButtonWidgetMixin
local L = {
    --- @type number
    index = -1,
    --- @type number
    frameIndex = -1,
    --- @type fun() : ActionButton
    button = nil,
    --- @type ActionBarFrame
    parentFrame = nil,
    --- See: Interface/FrameXML/ActionButtonTemplate.xml
    --- @type fun() : CooldownFrame
    cooldown = nil,

    --- @type fun() : Profile_Button
    config = nil,

    placement = { rowNum = -1, colNum = -1 },
    --- @type number
    buttonPadding = 1,

    --- @type boolean
    eventRegistered = false,
}
ns.O.ActionButtonWidgetMixin = L

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- Removes a particular actionType data from Profile_Button
--- @param btnData Profile_Button
local function CleanupActionTypeData(btnData)
    local function removeElement(tbl, value)
        for i, v in ipairs(tbl) do if v == value then tbl[i] = nil end end
    end
    if btnData == nil or btnData.type == nil then return end
    local actionTypes = O.ActionType:GetOtherNamesExcept(btnData.type)
    for _, v in ipairs(actionTypes) do if v ~= nil then btnData[v] = {} end end
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- @see ActionBarButtonTemplateMixin.lua
--- @param o ActionButtonWidgetMixin
local function PropsAndMethods(o)

    ---@param actionButton ActionButton
    function o:Init(actionButton)
        self.button = function() return actionButton end
        self.button().widget = function() return self end
        self.cooldown = function() return actionButton.cooldown end
        self.parentFrame = self.button():GetParent()
        self.frameIndex = self.parentFrame.widget().index
        --p:log('findex[%s]: %s', actionButton:GetName(),  tostring(self.frameIndex))
    end

    --- ### See: [UIHANDLER_OnReceiveDrag](https://wowpedia.fandom.com/wiki/UIHANDLER_OnReceiveDrag)
    function o:OnReceiveDragHandler()
        p:log(0, 'OnReceiveDragHandler[%s]: cursor=%s',
                self.button():GetName(), pformat(O.API:GetCursorInfo()))
        local cursor = ns:CreateCursorUtil()
        if not cursor:IsValid() then
            p:log(20, 'OnReceiveDrag| CursorInfo: %s isValid: false', pformat:B()(cursor:GetCursor()))
            return false else
        end

        p:log(0, 'OnReceiveDrag| CursorInfo: %s', pformat:B()(cursor:GetCursor()))
        --cursorUtil:ClearCursor()

        self:HandleCursor(cursor)

        --local hTexture = btnUI:GetHighlightTexture()
        --if hTexture and not hTexture.mask then
        --    print('creating mask')
        --    hTexture.mask = CreateMask(btnUI, hTexture, GC.Textures.TEXTURE_EMPTY_GRID)
        --end
        --self.widget:Fire('OnReceiveDrag')
    end

    ---@param cursor CursorUtil
    function o:HandleCursor(cursor)
        --- @type ReceiveDragEventHandler
        local handled = O.ReceiveDragEventHandler:HandleV2(self, cursor)
        if handled then cursor:ClearCursor() end
    end

    --- @return Profile_Button
    function o:config()
        --if not self.index then return end
        --p:log('findex: %s index: %s', tostring(self.frameIndex), tostring(self.index))
        local p = O.Profile:GetButtonData(self.frameIndex, self.button():GetName())
        CleanupActionTypeData(p)
        return p
    end

    --- @param type ActionTypeName One of: spell, item, or macro
    function o:GetButtonTypeData(type) return self:config()[type] end
    --- @return Profile_Spell
    function o:GetSpellData() return self:GetButtonTypeData('spell') end

    --- @return ButtonAttributes
    function o:GetButtonAttributes() return GC.ButtonAttributes end
    function o:ResetWidgetAttributes()
        if InCombatLockdown() then return end
        local button = self.button()
        for _, v in pairs(self:GetButtonAttributes()) do
            if not InCombatLockdown() then button:SetAttribute(v, nil) end
        end
    end

    --- @param icon string Blizzard Icon
    function o:SetIcon(icon)
        if not icon then return end
        local btn = self.button()
        btn:SetNormalTexture(icon)
        btn:SetPushedTexture(icon)
        btn:GetNormalTexture():SetAllPoints(btn)
    end

    --- Sets an attribute on the frame.
    --- @param name string
    --- @param value any
    function o:SetAttribute(name, value) self.button():SetAttribute(name, value) end

    function o:SetButtonAttributes()
        local conf = self:config(); if not conf then return end

        if IsBlankStr(conf.type) then
            conf.type = self:GuessButtonType(conf)
            if IsBlankStr(conf.type) then return end
        end
        local setter = self:GetAttributesSetter(conf.type)
        if not setter then return end
        if setter.SetAttributesV2 then setter:SetAttributesV2(self) end
    end

    --- @see Interface/FrameXML/ActionButtonTemplate.xml
    function o:SetButtonUIAttributes()
        local barConf = self.parentFrame.widget():conf()
        local btnSize = barConf.widget.buttonSize
        p:log(10, 'size[%s]: %s', self.button():GetName(), btnSize)
        local btn = self.button()

        btn:GetHighlightTexture():SetAlpha(1.0)
        btn:GetPushedTexture():SetAlpha(0.7)
        btn:GetNormalTexture():SetAlpha(0.4)
        btn:GetCheckedTexture():SetAlpha(1.0)

        local scale = btnSize/36
        p:log('scale: %s', scale)
        btn:SetScale(scale)
        if not self:IsEmpty() then
            btn:GetPushedTexture():SetAllPoints(btn)
            btn:GetNormalTexture():SetAlpha(1.0)
        else
        end
    end

    --- Autocorrect bad data if we have button data with
    --- btnData[type] but no btnData.type field
    ---@param btnData Profile_Button
    function o:GuessButtonType(btnData)
        for buttonType in pairs(self:GetAllAttributesSetters()) do
            -- return the first data found
            if not IsEmptyTable(btnData[buttonType]) then
                p:log(1, 'btnData[%s] did not have a type and was corrected: %s', self.w:GetName(), btnData.type)
                return buttonType
            end
        end
        return nil
    end

    --- @return AttributeSetter
    function o:GetAttributesSetter(actionType)
        local type = actionType or self:config().type
        return type and self:GetAllAttributesSetters()[type]
    end


    --- @return table<string, AttributeSetter>
    function o:GetAllAttributesSetters()
        --- @type table<string, AttributeSetter>
        local AttributeSetters = {
            [W.SPELL]       = O.SpellAttributeSetter,
            [W.ITEM]        = O.ItemAttributeSetter,
            [W.MACRO]       = O.MacroAttributeSetter,
            [W.MOUNT]       = O.MountAttributeSetter,
            [W.COMPANION]   = O.CompanionAttributeSetter,
            [W.BATTLE_PET]   = O.BattlePetAttributeSetter,
            [W.EQUIPMENT_SET] = O.EquipmentSetAttributeSetter,
        }
        return AttributeSetters
    end

    function o:IsEmpty()
        local config = self:config(); if not config then return end
        if IsEmptyTable(config) then return true end
        local type = config.type
        if IsBlankStr(type) then return true end
        if IsEmptyTable(config[type]) then return true end
        return false
    end
    function o:HasAction() return false == self:IsEmpty() end


end; PropsAndMethods(L)
