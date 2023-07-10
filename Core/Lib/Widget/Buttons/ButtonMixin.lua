--[[-----------------------------------------------------------------------------
Lua Vars
-------------------------------------------------------------------------------]]
local tostring, format, strlower, tinsert = tostring, string.format, string.lower, table.insert

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, GC, M, LibStub, API = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub, ns.O.API
local pformat = ns.pformat
local P, BaseAPI = O.Profile, O.BaseAPI
local String, WMX = O.String, O.WidgetMixin
local AceEvent = O.AceLibrary.AceEvent
local IsBlank, IsNotBlank, ParseBindingDetails = String.IsBlank, String.IsNotBlank, String.ParseBindingDetails

local WAttr = O.GlobalConstants.WidgetAttributes
local SPELL, ITEM, MACRO, MOUNT = WAttr.SPELL, WAttr.ITEM, WAttr.MACRO, WAttr.MOUNT

local C, T = GC.C, GC.Textures
local UNIT = GC.UnitIDAttributes

local emptyTexture = GC.Textures.TEXTURE_EMPTY
local emptyGridTexture = GC.Textures.TEXTURE_EMPTY_GRID
local highlightTexture = GC.Textures.TEXTURE_EMPTY_GRID
local pushedTextureMask = GC.Textures.TEXTURE_EMPTY_GRID

local highlightTextureAlpha = 0.5
local highlightTextureInUseAlpha = 0.5
local pushedTextureInUseAlpha = 0.5
local nonEmptySlotAlpha = 1.0
local showEmptyGridAlpha = 0.6
local MIN_BUTTON_SIZE = GC.C.MIN_BUTTON_SIZE_FOR_HIDING_TEXTS

--[[-----------------------------------------------------------------------------
New Instance
self: widget
button: widget.button
-------------------------------------------------------------------------------]]
--- @class ButtonMixin : ButtonProfileMixin @ButtonMixin extends ButtonProfileMixin
--- @see ButtonUIWidget
local L = LibStub:NewLibrary(M.ButtonMixin); if not L then return end; AceEvent:Embed(L)
local p = L:GetLogger()

--[[-----------------------------------------------------------------------------
Instance Methods
-------------------------------------------------------------------------------]]

--- @param o ButtonMixin|ButtonUIWidget
local function PropsAndMethods(o)

    --- Create a new ButtonMixin instance and
    --- @param widget ButtonUIWidget
    function o:Mixin(widget) ns:K():Mixin(widget, self:New(widget)) end

    --- @param widget ButtonUIWidget
    --- @return ButtonMixin
    function o:New(widget)
        local newObj = ns:K():CreateAndInitFromMixin(o, widget)
        ns:K():Mixin(newObj, O.ButtonProfileMixin:New(widget))
        return newObj
    end

    --- @param widget ButtonUIWidget
    function o:Init(widget)
        self.w = widget
    end

    function o:GetName() return self.button():GetName() end

    --- Only used for prefixing logs
    --- @return string F1-B1 for Frame 1 and Button 1
    function o:GN() return format(GC.C.BUTTON_NAME_SHORT_FORMAT, tostring(self.frameIndex), tostring(self.index)) end

    function o:InitWidget()
        self:SetButtonProperties()
        self:InitTextures(emptyTexture)
        if self:IsEmpty() then self:SetTextureAsEmpty() end
    end

    function o:SetButtonProperties()
        --- @type FrameWidget
        local dragFrame = self.dragFrame()
        local barConfig = dragFrame:GetConfig()
        local buttonSize = barConfig.widget.buttonSize
        local buttonPadding = dragFrame.horizontalButtonPadding
        local frameStrata = self.frameStrata
        local frameLevel = self.frameLevel
        local button = self.button()

        button:SetFrameStrata(frameStrata)
        button:SetFrameLevel(frameLevel)
        button:SetSize(buttonSize - buttonPadding, buttonSize - buttonPadding)

        self:Scale(buttonSize)
    end

    --- @param buttonSize number
    function o:Scale(buttonSize)
        local button = self.button()
        button.keybindText.widget:ScaleWithButtonSize(buttonSize)
        --todo next: move to a ButtonScaleMixin?
        self:ScaleButtonTextsWithButtonSize(buttonSize)
        self:ScaleItemCountOffset(buttonSize)
    end

    --- @param buttonSize number
    function o:ScaleItemCountOffset(buttonSize)
        local offsetX = -2
        local offsetY = 7
        local scaleFactorX = 50
        local scaleFactorY = 100
        offsetX = (buttonSize/100) - (offsetX + buttonSize/15)
        local scaleXOffset = buttonSize/scaleFactorX * offsetX
        local scaleYOffset = buttonSize/scaleFactorY * offsetY
        self.button().text:SetPoint("BOTTOMRIGHT", scaleXOffset, scaleYOffset)
    end

    --- @see "BlizzardInterfaceCode/Interface/SharedXML/SharedFontStyles.xml" for font styles
    --- @param buttonSize number
    function o:ScaleButtonTextsWithButtonSize(buttonSize)
        local hideItemCountText = false
        local hideCountdownNumbers = false
        local hideIndexText = false
        local hideKeybindText = false
        local countdownFont
        local itemCountFont
        local profile = self.w:GetProfileConfig()
        local textUI = self.button().text
        local itemCountFontHeight = textUI.textDefaultFontHeight

        if true == profile.hide_countdown_numbers then hideCountdownNumbers = true end

        if buttonSize > 80 then
            itemCountFont = "GameFontNormalOutline"
            countdownFont = "GameFontNormalHuge4Outline"
            itemCountFontHeight = textUI.textDefaultFontHeight
        elseif buttonSize >= 70 and buttonSize <= 80 then
            itemCountFontHeight = 12
            countdownFont = "GameFontNormalHuge3Outline"
        elseif buttonSize >= 40 and buttonSize < 70 then
            itemCountFontHeight = 11
            countdownFont = "GameFontNormalLargeOutline"
        elseif buttonSize >= MIN_BUTTON_SIZE and buttonSize < 40 then
            itemCountFontHeight = 10
            countdownFont = "GameFontNormalMed3Outline"
        else
            countdownFont = "GameFontNormalOutline"
            itemCountFontHeight = 9

            if true == profile.hide_text_on_small_buttons then
                hideItemCountText = true
                hideIndexText = true
                hideCountdownNumbers = true
                hideKeybindText = true
            end

        end
        local fontName, _, fontAttr = textUI:GetFont()
        textUI:SetFont(fontName, itemCountFontHeight, fontAttr)

        self.cooldown():SetCountdownFont(countdownFont)
        self:HideCountdownNumbers(hideCountdownNumbers)
        self:SetHideItemCountText(hideItemCountText)
        self:SetHideIndexText(hideIndexText)
        self:SetHideKeybindText(hideKeybindText)

    end

    function o:RefreshTexts()
        local profile = self.w:GetProfileConfig()
        self:HideCountdownNumbers(true == profile.hide_countdown_numbers)
        local hideTexts = true == profile.hide_text_on_small_buttons
        if not hideTexts then
            local fw = self.dragFrame()
            local barConf = fw:GetConfig()
            if true == barConf.show_button_index then
                self:SetHideIndexText(false)
            end
            return
        end

        local barConfig = self.dragFrame():GetConfig()
        local buttonSize = barConfig.widget.buttonSize
        if buttonSize > MIN_BUTTON_SIZE then return end

        self:SetHideKeybindText(hideTexts)
        self:SetHideIndexText(hideTexts)
        if not profile.hide_countdown_numbers then self:HideCountdownNumbers(hideTexts) end
    end

    --- @param state boolean
    function o:HideCountdownNumbers(state)
        self.cooldown():SetHideCountdownNumbers(state)
    end

    ---This is the item count text
    --- @param state boolean
    function o:SetHideItemCountText(state)
        local btn = self.button()
        if true == state then
            btn.text:Hide()
            return
        end

        btn.text:Show()
    end

    --- @param state boolean
    function o:SetHideKeybindText(state)
        local btn = self.button()
        if true == state then
            btn.keybindText:Hide()
            return
        end

        btn.keybindText:Show()
    end
    --- @param state boolean
    function o:SetHideIndexText(state)
        local btn = self.button()
        if true == state then
            btn.indexText:Hide()
            return
        end

        btn.indexText:Show()
    end

    --- @param btn _Button
    --- @param texture _Texture
    --- @param texturePath string
    local function CreateMask(btn, texture, texturePath)
        local mask = btn:CreateMaskTexture()
        local topx, topy = 1, -1
        local botx, boty = -1, 1
        mask:SetPoint(C.TOPLEFT, texture, C.TOPLEFT, topx, topy)
        mask:SetPoint(C.BOTTOMRIGHT, texture, C.BOTTOMRIGHT, botx, boty)
        mask:SetTexture(texturePath, C.CLAMPTOBLACKADDITIVE, C.CLAMPTOBLACKADDITIVE)
        texture.mask = mask
        texture:AddMaskTexture(mask)
        return mask
    end

    --- - Call this function once only; otherwise *CRASH* if called N times
    --- - [UIOBJECT MaskTexture](https://wowpedia.fandom.com/wiki/UIOBJECT_MaskTexture)
    --- - [Texture:SetTexture()](https://wowpedia.fandom.com/wiki/API_Texture_SetTexture)
    --- - [alphamask](https://wow.tools/files/#search=alphamask&page=5&sort=1&desc=asc)
    --- @param icon string The icon texture path
    function o:InitTextures(icon)
        local btnUI = self.button()

        -- DrawLayer is 'ARTWORK' by default for icons
        btnUI:SetNormalTexture(icon)
        --Blend mode "Blend" gets rid of the dark edges in buttons
        btnUI:GetNormalTexture():SetBlendMode(GC.BlendMode.BLEND)

        self:SetHighlightDefault(btnUI)
        btnUI:SetPushedTexture(icon)

        local tex = btnUI:GetPushedTexture()
        CreateMask(btnUI, tex, pushedTextureMask)
        tex:SetAlpha(pushedTextureInUseAlpha)

        local hTexture = btnUI:GetHighlightTexture()
        if hTexture and not hTexture.mask then
            CreateMask(btnUI, hTexture, highlightTexture)
        end
    end

    --- @return Index
    function o:GetIndex() return self.w.index end
    --- @return Index
    function o:GetFrameIndex() return self.w.frameIndex end

    --- @return boolean
    function o:IsParentFrameShown() return self.dragFrame():IsShown() end
    --- @return boolean
    function o:IsShown() return self:IsParentFrameShown() end
    --- @return boolean
    function o:IsHidden() return self:IsParentFrameShown() ~= true end
    --- @return boolean
    function o:IsUpdatable() return self:IsSpellUpdatable(self:GetEffectiveSpellName()) end
    --- @return boolean
    function o:IsNotUpdatable() return self:IsSpellNotUpdatable(self:GetEffectiveSpellName()) end
    --- @param spellName SpellName
    --- @return boolean
    function o:IsSpellNotUpdatable(spellName) return self:IsHidden() or IsBlank(spellName) end
    --- @param spellName SpellName
    --- @return boolean
    function o:IsSpellUpdatable(spellName) return not self:IsSpellNotUpdatable(spellName) end

    function o:ResetConfig()
        self.w:ResetButtonData()
        self:ResetWidgetAttributes()
    end

    function o:SetButtonAsEmpty()
        self:ResetConfig()
        self:SetTextureAsEmpty()
    end

    function o:Reset()
        self:ResetCooldown()
        self:HideOverlayGlow()
        self:ClearAllText()
    end

    function o:ResetCooldown() self:SetCooldown(0, 0) end

    function o:SetCooldown(start, duration)
        if not (start or duration) then return end
        self.cooldown():SetCooldown(start, duration)
    end

    --- @type BindingInfo
    function o:GetBindings()
        local barBindings = self.addon().barBindings
        return (barBindings and barBindings[self.buttonName]) or nil
    end

    --- @param text string
    function o:SetText(text)
        if String.IsBlank(text) then text = '' end
        self.button().text:SetText(text)
    end

    --- Sets the name of the button (Used by Macros)
    --- @param text string
    function o:SetNameText(text) self.button().nameText:SetEllipsesText(text) end

    function o:SetTextDelayed(text, optionalDelay)
        C_Timer.After(optionalDelay or 0.1, function() self:SetText(text) end)
    end

    --- @param state boolean true will show the button index number
    function o:ShowIndex(state)
        local text = ''
        if true == state then text = self.w.index end
        self.button().indexText:SetText(text)
        self:RefreshTexts()
    end

    --- @param state boolean true will show the button index number
    function o:ShowKeybindText(state)
        local text = ''
        local button = self.button()
        if not self:HasKeybindings() then
            button.keybindText:SetText(text)
            self:RefreshTexts()
            return
        end

        local bindings = self:GetBindings()
        if not self:HasValidKeybindings(bindings) then
            button.keybindText:SetText(text)
            self:RefreshTexts()
            return
        end

        if bindings and bindings.key1Short then
            text = bindings.key1Short
        end

        button.keybindText:SetText(text)
        self:RefreshTexts()
    end

    function o:HasKeybindings() return self:HasValidKeybindings(self:GetBindings()) end

    --- @param bindingDetails BindingDetails
    function o:HasValidKeybindings(bindingDetails)
        if not bindingDetails then return false end
        return bindingDetails and String.IsNotBlank(bindingDetails.key1)
    end


    function o:ClearAllText()
        self:SetText('')
        self.button().keybindText:SetText('')
        self.button().nameText:SetText('')
    end

    --- @return CooldownInfo
    function o:GetCooldownInfo()
        local btnData = self.w:conf()
        if btnData == nil or String.IsBlank(btnData.type) then return nil end
        local type = btnData.type

        --- @type CooldownInfo
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

    --- @param cd CooldownInfo The cooldown info
    --- @return SpellCooldown
    function o:GetSpellCooldown(cd)
        local spell = self:GetSpellData()
        if self:IsInvalidSpell(spell) then return nil end

        local spellCD = API:GetSpellCooldown(spell.id)
        if not spellCD then return nil end

        cd.details = spellCD
        cd.start = spellCD.start
        cd.duration = spellCD.duration
        cd.enabled = spellCD.enabled

        return cd
    end

    --- @param cd CooldownInfo The cooldown info
    --- @return ItemCooldown
    function o:GetItemCooldown(cd)
        local item = self:GetItemData()
        if self:IsInvalidItem(item) then return nil end
        local itemCD = API:GIC(item.id)
        if itemCD ~= nil then
            cd.details = itemCD
            cd.start = itemCD.start
            cd.duration = itemCD.duration
            cd.enabled = itemCD.enabled
            return cd
        end
        return nil
    end

    --- @param itemName string The cooldown info
    --- @return CooldownInfo
    function o:GetItemCooldownInfo(itemName)
        if not itemName then return nil end
        local itemCD = API:GIC(itemName)

        --- @type CooldownInfo
        local cd = {
            type=type,
            start=nil,
            duration=nil,
            enabled=0,
            details = {}
        }
        if itemCD ~= nil then
            cd.details = itemCD
            cd.start = itemCD.start
            cd.duration = itemCD.duration
            cd.enabled = itemCD.enabled
            return cd
        end
        return nil
    end

    --- @param cd CooldownInfo The cooldown info
    function o:GetMacroCooldown(cd)
        local spellCD = self:GetMacroSpellCooldown();
        if spellCD and spellCD.spell then
            cd.details = spellCD
            cd.start = spellCD.start
            cd.duration = spellCD.duration
            cd.enabled = spellCD.enabled
            cd.icon = spellCD.spell.icon
            return cd
        end

        local itemCD = self:GetMacroItemCooldown()
        if itemCD then
            cd.details = itemCD
            cd.start = itemCD.start
            cd.duration = itemCD.duration
            cd.enabled = itemCD.enabled
            return cd
        end

        return nil;
    end

    --- @return SpellCooldown
    function o:GetMacroSpellCooldown()
        local macro = self:GetMacroData();
        if not macro then return nil end

        -- GetMacroInfo() must be called before GetMacroSpell() to get the updated spell info
        -- This fixes the macro sequence icon issue
        local i = macro.index
        local _, icon = GetMacroInfo(i)
        local spellID = GetMacroSpell(i); if not spellID then return nil end
        local spellCD = API:GetSpellCooldown(spellID); if not spellCD then return nil end

        spellCD.spell.icon = icon
        return spellCD
    end

    --- @return ItemCooldown
    function o:GetMacroItemCooldown()
        local macro = self:GetMacroData();
        if not macro then return nil end

        local itemName = GetMacroItem(macro.index)
        if not itemName then return nil end

        local itemCD = API:GetItemCooldown(itemName); if not itemCD then return nil end
        -- GetMacroInfo has the updated icon
        local _, icon = GetMacroInfo(macro.index)
        itemCD.item = {
            id = itemCD.item.id,
            name = itemName,
            icon = icon
        }
        return itemCD
    end

    function o:ResetWidgetAttributes()
        if InCombatLockdown() then return end
        local button = self.button()
        for _, v in pairs(GC.ButtonAttributes) do
            if not InCombatLockdown() then
                button:SetAttribute(v, nil)
            end
        end
    end

    --- @return boolean true if btn type is item or macro
    function o:IsItemOrMacro()
        return not self:IsEmpty() and (self:IsItem() or self:IsMacro())
    end

    function o:UpdateItemOrMacroState()
        if self:IsItem() then
            self:UpdateItemState()
            return
        end
        if self:IsMacro() then self:UpdateMacroState() end
    end

    function o:UpdateSpellState()
        if not self:IsSpell() then return end
        self:UpdateSpellCharges(self:GetSpellName())
    end

    ---@param spellName SpellName
    function o:UpdateSpellCharges(spellName)
        local currentCharge, maxCharge = GetSpellCharges(spellName)
        if not maxCharge or (maxCharge <= 1) then return end
        self:SetText(currentCharge)
    end

    function o:UpdateItemState()
        self:ClearAllText()
        local item = self.w:GetItemData()
        if self:IsInvalidItem(item) then return end
        local itemID = item.id
        local itemInfo = API:GetItemInfo(itemID)
        self:UpdateItemStateByItemInfo(itemInfo)
        self:SetActionUsable(self:IsUsableItem(itemID))
        return
    end

    --- @param itemIDOrName number|string The itemID or itemName
    function o:UpdateItemStateByItem(itemIDOrName)
        self:UpdateItemStateByItemInfo(API:GetItemInfo(itemIDOrName))
    end

    ---@param itemInfo ItemInfo
    function o:UpdateItemStateByItemInfo(itemInfo)
        self:SetText('')
        if not itemInfo then return nil end

        local itemID = itemInfo.id
        if itemInfo == nil then return end
        if API:IsToyItem(itemID) then self:SetActionUsable(true); return end

        local stackCount = itemInfo.stackCount or 1
        local count = itemInfo.count
        -- health stones, mana gems/emeralds
        local chargeCount = GetItemCount(itemInfo.name, false, true, false)
        if chargeCount > 1 then
            stackCount = chargeCount
            count = chargeCount
        end
        if stackCount > 1 and count > 0 then self:SetText(count) end
        if count <= 0 then
            self:SetText('')
            self:SetActionUsable(false)
        end
    end

    function o:UpdateUsable()
        local cd = self:GetCooldownInfo()
        if (cd == nil or cd.details == nil) then
            if self:IsCompanion() then self:SetActionUsable(true)
            elseif self:IsEquipmentSet() then self:SetActionUsable(not InCombatLockdown()) end
            return
        end
        local c = self.w:conf()
        local isUsable = true
        if c.type == SPELL then
            isUsable = self:IsUsableSpell(cd)
        elseif c.type == MACRO then
            isUsable = self:IsUsableMacro(cd)
        elseif c.type == ITEM then
            isUsable = self:IsUsableItem(cd)
        end
        self:SetActionUsable(isUsable)
    end


    function o:UpdateState()
        self:UpdateCooldown()
        self:UpdateItemOrMacroState()
        self:UpdateSpellState()
        self:UpdateUsable()
        self:SetHighlightDefault()
        self:SetNormalIconAlphaDefault()

        self:UpdateKeybindTextState()
        self:UpdateRangeIndicator()
    end

    --Dynamic toggling of keybind text for
    --the actionbar grid event
    function o:UpdateKeybindTextState()
        local button = self.button()
        if not self:IsShowKeybindText() then
            button.keybindText:Hide()
            return
        end

        if self:IsEmpty() then
            if self:IsShowEmptyButtons() then
                button.keybindText:Show()
            else
                button.keybindText:Hide()
            end
            return
        end

        if not self:IsEmpty() then button.keybindText:Show() end
    end

    function o:UpdateStateDelayed(inSeconds) C_Timer.After(inSeconds or 1, function() self:UpdateState() end) end
    ---@param optionalCooldownInfo CooldownInfo
    function o:UpdateCooldown(optionalCooldownInfo)
        local cd = optionalCooldownInfo or self:GetCooldownInfo()
        if not cd or cd.enabled == 0 then return end
        -- Instant cast spells have zero duration, skip
        if (not cd.duration) or cd.duration <= 0 then
            self:ResetCooldown()
            return
        end
        self:SetCooldown(cd.start, cd.duration)
    end
    function o:UpdateCooldownDelayed(inSeconds) C_Timer.After(inSeconds, function() self:UpdateCooldown() end) end

    --- Note: Equipment Set Name cannot be updated.
    --- The Equipment Manager always creates a new unique name.
    function o:UpdateEquipmentSet()
        -- if index changed (similar to how macros are updated)
        -- if equipment set was deleted
        -- icon update
        if self:IsMissingEquipmentSet() then self:SetButtonAsEmpty(); return end

        local equipmentSet = self.w:FindEquipmentSet()
        if not equipmentSet then self:SetButtonAsEmpty(); return end

        local btnData = self.w:GetEquipmentSetData()
        btnData.name = equipmentSet.name
        btnData.icon = equipmentSet.icon
        self:SetIcon(btnData.icon)
    end

    --- IsSpellOverlayed() is available in Retail Version
    function o:UpdateGlow()
        if not IsSpellOverlayed then return end
        local spell = self:GetEffectiveSpellName(); if not spell then return end
        local spellID = select(7, GetSpellInfo(spell)); if not spellID then return end
        local isGlowing = IsSpellOverlayed(spellID)
        if isGlowing then self:ShowOverlayGlow(); return else end
        self:HideOverlayGlow()
    end

    --- @return ActionBarInfo
    function o:GetActionbarInfo()
        local index = self.index
        local dragFrame = self.dragFrame();
        local frameName = dragFrame:GetName()
        local btnName = format('%sButton%s', frameName, tostring(index))

        --- @class ActionBarInfo
        local info = {
            name = frameName, index = dragFrame:GetFrameIndex(),
            button = { name = btnName, index = index },
        }
        return info
    end

    function o:ClearHighlight() self.button():SetHighlightTexture(nil) end
    function o:ResetHighlight() self:SetHighlightDefault() end

    --- @param texture string
    function o:SetNormalTexture(texture) self.button():SetNormalTexture(texture) end
    --- @param texture string
    function o:SetPushedTexture(texture)
        if texture then
            self.button():SetPushedTexture(texture)
            self:SetPushedTextureAlpha(pushedTextureInUseAlpha)
            return
        end
        self.button():SetPushedTexture(emptyTexture)
        if not self:IsShowEmptyButtons() then
            self:SetPushedTextureAlpha(0)
        end
    end

    --- @param texture string
    function o:SetHighlightTexture(texture)
        if texture then
            self.button():SetHighlightTexture(texture)
            self:SetHighlightTextureAlpha(highlightTextureAlpha)
            return
        end
        self.button():SetHighlightTexture(emptyTexture)
        self:SetHighlightTextureAlpha(0)
    end

    --- @param alpha number 1 (opaque) to zero (transparent)
    function o:SetPushedTextureAlpha(alpha) self.button():GetPushedTexture():SetAlpha(alpha or 1) end
    --- @param alpha number 1 (opaque) to zero (transparent)
    function o:SetHighlightTextureAlpha(alpha) self.button():GetHighlightTexture():SetAlpha(alpha or 1) end

    function o:SetTextureAsEmpty()
        self:SetNormalTexture(emptyTexture)
        self:SetPushedTexture(nil)
        self:SetHighlightTexture(nil)
        self:SetNormalIconAlphaAsEmpty()
        self:SetVertexColorNormal()
    end

    function o:SetNormalIconAlphaAsEmpty()
        local alpha = showEmptyGridAlpha
        if true ~= self.w:IsShowEmptyButtons() then alpha = 0 end
        self:SetNormalIconAlpha(alpha)
    end

    --- @param alpha number 0.0 to 1.0
    function o:SetNormalIconAlpha(alpha) self.button():GetNormalTexture():SetAlpha(alpha or 1.0) end
    function o:SetVertexColorNormal() self.button():GetNormalTexture():SetVertexColor(1.0, 1.0, 1.0) end

    function o:SetNormalIconAlphaDefault()
        if self:IsEmpty() then
            self:SetNormalIconAlphaAsEmpty()
            return
        end
        self:SetNormalIconAlpha(nonEmptySlotAlpha)
    end

    function o:SetPushedTextureDisabled() self.button():SetPushedTexture(nil) end

    ---This is used when an action button starts dragging to highlight other drag targets (empty slots).
    function o:ShowEmptyGrid()
        if not self:IsEmpty() then return end
        self:SetNormalTexture(emptyTexture)
        self:SetHighlightEmptyButtonEnabled(false)
    end

    function o:ShowEmptyGridEvent()
        if not self:IsEmpty() then return end
        self:SetButtonAsEmpty()
        self:ShowEmptyGrid()
        self:ShowKeybindText(true)

        if not self:IsShowKeybindText() then
            self.button().keybindText:Hide()
        elseif self:IsEmpty() then
            self.button().keybindText:Show()
        end
    end

    function o:HideEmptyGridEvent()
        if not self:IsEmpty() then return end
        self:SetTextureAsEmpty()
        self:SetHighlightEmptyButtonEnabled(true)
        self:SetNormalTexture(emptyTexture)
        self:SetNormalIconAlphaAsEmpty()
        if self:IsEmpty() and not self:IsShowEmptyButtons() then
            self.button().keybindText:Hide()
        end
    end

    function o:SetCooldownTextures(icon)
        local btnUI = self.button()
        btnUI:SetNormalTexture(icon)
        btnUI:SetPushedTexture(icon)
    end

    function o:SetButtonStateNormal() self.button():SetButtonState('NORMAL') end
    function o:SetButtonStatePushed() self.button():SetButtonState('PUSHED') end

    ---Typically used when casting spells that take longer than GCD
    function o:SetHighlightInUse()
        local btn = self.button()
        self:SetNormalIconAlpha(highlightTextureInUseAlpha)
        local hltTexture = btn:GetHighlightTexture()
        --highlight texture could be nil if action_button_mouseover_glow is disabled
        if not hltTexture then return end
        hltTexture:SetDrawLayer(C.ARTWORK_DRAW_LAYER)
        hltTexture:SetAlpha(highlightTextureInUseAlpha)
        if hltTexture and not hltTexture.mask then CreateMask(btn, hltTexture, highlightTexture) end
    end
    function o:SetHighlightDefault()
        if self:IsEmpty() then return end
        self:SetHighlightEnabled(P:IsActionButtonMouseoverGlowEnabled())
        self:SetNormalIconAlpha(1.0)
    end

    function o:RefreshHighlightEnabled()
        local profile = self.w:GetProfileConfig()
        self:SetHighlightEnabled(true == profile.action_button_mouseover_glow)
    end

    --- @param state boolean true, to enable highlight
    function o:SetHighlightEnabled(state)
        local btnUI = self.button()
        if state == true then
            btnUI:SetHighlightTexture(highlightTexture)
            btnUI:GetHighlightTexture():SetBlendMode(GC.BlendMode.ADD)
            btnUI:GetHighlightTexture():SetDrawLayer(GC.DrawLayer.HIGHLIGHT)
            btnUI:GetHighlightTexture():SetAlpha(highlightTextureAlpha)
            return
        end
        self:SetHighlightTexture(nil)
    end

    ---This is used for mouseover when dragging a cursor
    ---to highlight an empty slot
    function o:SetHighlightEmptyButtonEnabled(state)
        if not self:IsEmpty() then return end
        if true == state then
            self:SetNormalTexture(emptyGridTexture)
            self:SetNormalIconAlpha(showEmptyGridAlpha)
            return
        end
        self:SetNormalTexture(emptyTexture)
        self:SetNormalIconAlpha(showEmptyGridAlpha)
    end

    --- @param spellID string The spellID to match
    --- @param optionalBtnConf Profile_Button
    --- @return boolean
    function o:IsMatchingItemSpellID(spellID, optionalBtnConf)
        if not self:IsValidItemProfile(optionalBtnConf) then return end
        local _, btnItemSpellId = API:GetItemSpellInfo(optionalBtnConf.item.id)
        if spellID == btnItemSpellId then return true end
        return false
    end

    --- @param spellID string The spellID to match
    --- @param optionalBtnConf Profile_Button
    --- @return boolean
    function o:IsMatchingSpellID(spellID, optionalBtnConf)
        local buttonData = optionalBtnConf or self:conf()
        local w = self.w
        if w:IsSpell() then
            return spellID == buttonData.spell.id
        elseif w:IsItem() then
            return w:IsMatchingItemSpellID(spellID, buttonData)
        elseif w:IsMount() then
            return spellID == buttonData.mount.spell.id
        end
        return false
    end

    --- @param spellName SpellName
    --- @param buttonData Profile_Button
    function o:IsMatchingSpellName(spellName, buttonData)
        local s = buttonData or self:conf()
        if not (s.spell and s.spell.name) then return false end
        if not (s and spellName == s.spell.name) then return false end
        return true
    end

    --- @param spellID string
    --- @param optionalProfileButton Profile_Button
    function o:IsMatchingMacroSpellID(spellID, optionalProfileButton)
        optionalProfileButton = optionalProfileButton or self:conf()
        if not self:IsValidMacroProfile(optionalProfileButton) then return end
        local macroSpellId =  GetMacroSpell(optionalProfileButton.macro.index)
        if not macroSpellId then return false end
        if spellID == macroSpellId then return true end
        return false
    end

    --- @param spellID string The spellID to match
    --- @return boolean
    function o:IsMatchingMacroOrSpell(spellID)
        --- @type Profile_Button
        local conf = self:conf()
        if not conf and (conf.spell or conf.macro) then return false end
        if self:IsConfigOfType(conf, SPELL) then
            return spellID == conf.spell.id
        elseif self:IsConfigOfType(conf, MACRO) and conf.macro.index then
            local macroSpellId =  GetMacroSpell(conf.macro.index)
            return spellID == macroSpellId
        end

        return false;
    end


    --- @param optionalSpell SpellName|nil
    --- @return SpellName, Boolean  returns true if spell is a ranged and updatable spell
    function o:GetEffectiveRangedSpellName(optionalSpell)
        local spell = optionalSpell or self:GetEffectiveSpellName()
        if not spell then return nil, false end
        if self:IsSpellNotUpdatable(spell) then return spell, false end
        if not self:SpellRequiresTarget(spell) then return spell, false end
        return spell, true
    end

    function o:UpdateRangeIndicator()
        if self:IsHidden() then return end

        local spell, ranged = self:GetEffectiveRangedSpellName()
        if ranged == false then return end

        self:UpdateRangeIndicatorBySpell(spell)
    end

    ---@param spell SpellName
    function o:UpdateRangeIndicatorBySpell(spell)
        if self:IsHidden() then return end
        if not spell then return nil end

        local configIsShowKeybindText = self.dragFrame():IsShowKeybindText()
        self:ShowKeybindText(configIsShowKeybindText)

        local hasTarget = API:IsValidActionTarget()
        if configIsShowKeybindText == true then
            return self:UpdateRangeIndicatorWithShowKeybindOn(spell, hasTarget)
        end
        self:UpdateRangeIndicatorWithShowKeybindOff(spell, hasTarget)
    end

    --- @param spell SpellName Effective spell name for spell, item, macro
    --- @param hasTarget boolean Player has a target
    function o:UpdateRangeIndicatorWithShowKeybindOn(spell, hasTarget)
        local kb = self:GetKeybindText()
        if not hasTarget then kb:SetVertexColorNormal(); return end
        if not self:HasKeybindings() then kb:SetTextWithRangeIndicator() end

        -- else if in range, color is "white"
        local inRange = API:IsSpellInRange(spell, UNIT.TARGET)
        kb:SetVertexColorNormal()
        if inRange == false then
            kb:SetVertexColorOutOfRange()
        elseif inRange == nil then
            if not self.w:HasKeybindings() then kb:ClearText() end
        end
    end

    --- @param spell SpellName Effective spell name for spell, item, macro
    --- @param hasTarget boolean Player has a target
    function o:UpdateRangeIndicatorWithShowKeybindOff(spell, hasTarget)
        local kb = self:GetKeybindText()
        if not hasTarget then
            kb:ClearText()
            kb:SetVertexColorNormal()
            return
        end

        -- inRange can return nil if item/spell is invalid or target is invalid
        local inRange = API:IsSpellInRange(spell, UNIT.TARGET)
        kb:SetTextWithRangeIndicator()
        kb:SetVertexColorNormal()
        kb:Show()

        if inRange == false then
            kb:SetVertexColorOutOfRange()
        elseif inRange == nil then
            kb:ClearText()
        end
    end

    --- @param isUsable boolean
    function o:SetActionUsable(isUsable)
        local normalTexture = self.button():GetNormalTexture()
        if not normalTexture then return end
        -- energy based spells do not use 'notEnoughMana'
        if IsStealthed() or API:IsShapeShiftActive(self:GetSpellData()) then
            normalTexture:SetVertexColor(1.0, 1.0, 1.0)
        elseif not isUsable then
            normalTexture:SetVertexColor(0.3, 0.3, 0.3)
        else
            normalTexture:SetVertexColor(1.0, 1.0, 1.0)
        end
    end

    --- @param cd CooldownInfo
    function o:IsUsableSpell(cd)
        local spellID = cd.details.spell.id
        -- why true by default?
        if IsBlank(spellID) then return true end
        return IsUsableSpell(spellID)
    end

    function o:IsUsableToy(itemID)
        local _, spellID = API:GetItemSpellInfo(itemID)
        if not spellID then return false end
        return IsUsableSpell(spellID)
    end

    --- @param itemID ItemID
    function o:IsUsableItemID(itemID)
        if API:IsToyItem(itemID) then return self:IsUsableToy(itemID) end
        return IsUsableItem(itemID)
    end

    --- @param cdOrItemID CooldownInfo|number
    function o:IsUsableItem(cdOrItemID)
        if 'number' == type(cdOrItemID) then return self:IsUsableItemID(cdOrItemID) end
        local itemID = cdOrItemID.details.item.id
        if IsBlank(itemID) then return true end
        if API:IsToyItem(itemID) then return self:IsUsableToy(itemID) end
        return IsUsableItem(itemID)
    end

    --- @param cd CooldownInfo
    function o:IsUsableMacro(cd)
        if not (cd or cd.details) then return false end
        if cd.details.spell then
            local spellID = cd.details.spell.id
            if IsBlank(spellID) then return true end
            return IsUsableSpell(spellID)
        elseif cd.details.item then
            return IsUsableItem(cd.details.item.id)
        end
        return false
    end

    --- @param icon string Blizzard Icon
    function o:SetIcon(icon)
        local btn = self.button()
        self:SetNormalTexture(icon)
        self:SetPushedTexture(icon)
        local nTexture = btn:GetNormalTexture()
        if not nTexture.mask then CreateMask(btn, nTexture, emptyTexture) end
    end

    --- @param buttonData Profile_Button
    function o:IsValidItemProfile(buttonData)
        return not (buttonData == nil or buttonData.item == nil
                or IsBlank(buttonData.item.id))
    end

    --- @param buttonData Profile_Button
    function o:IsValidSpellProfile(buttonData)
        return not (buttonData == nil or buttonData.spell == nil
                or IsBlank(buttonData.spell.id))
    end

    --- @param buttonData Profile_Button
    function o:IsValidMacroProfile(buttonData)
        return not (buttonData == nil or buttonData.macro == nil
                or IsBlank(buttonData.macro.index)
                or IsBlank(buttonData.macro.name))
    end

    function o:CanChangeEquipmentSet()
        if not (C_EquipmentSet and C_EquipmentSet.CanUseEquipmentSets()) then return false end
        return self:IsEquipmentSet()
    end

    function o:UpdateMacroState()
        --- @type SpellCooldown
        local scd = self:GetMacroSpellCooldown()
        if scd and scd.spell then
            -- clear the text since item counts doesn't apply for spells
            self:SetText('')
            local icon
            icon = scd.spell.icon
            self:UpdateSpellCharges(scd.spell.name)

            if self:IsStealthSpell() then
                local spellInfo = self:GetSpellData()
                icon = API:GetSpellIcon(spellInfo)
            elseif self:IsShapeshiftSpell() then
                local spellInfo = self:GetSpellData()
                icon = API:GetSpellIcon(spellInfo)
            end
            if icon then self:SetIcon(icon) end
            self:UpdateCooldown(scd)
            return
        end

        local icd = self:GetMacroItemCooldown()
        if icd and icd.item then
            local item = icd.item
            local icon = item.icon
            self:SetNameText(self:GetMacroName())
            self:UpdateItemStateByItem(item.name)
            if icon then self:SetIcon(icon) end
            self:UpdateCooldown(icd)
            return
        end

        -- todo next: UpdateCooldown() is being called twice when called via self:UpdateState()
    end

    ---@param state boolean Set to true to enable mouse
    function o:EnableMouse(state) if InCombatLockdown() then return end; self.button():EnableMouse(state) end
    function o:Hide() if InCombatLockdown() then return end; self.button():Hide() end
    function o:Show() if InCombatLockdown() then return end; self.button():Show() end

    --- @return FontStringWidget
    function o:GetKeybindText() return self.button().keybindText.widget end

    ---@param spell SpellName|SpellID
    function o:SpellRequiresTarget(spell)
        if not spell then return false end

        if 'string' == type(spell) then
            return SpellHasRange(spell) == true
        elseif 'number' == type(spell) then
            return SpellHasRange(GetSpellInfo(spell)) == true
        end
        return false
    end

    function o:GetIcon()
        local texture = self.button():GetNormalTexture()
        if texture then return texture:GetTexture() end
        return nil
    end

    ---@param optionalMacroName string Optional. Will pull from btn data if not supplied
    function o:IsM6Macro(optionalMacroName)
        if not self.w:IsMacro() then return false end
        if type(optionalMacroName) == 'string' then return GC:IsM6Macro(optionalMacroName) end
        return GC:IsM6Macro(self.w:GetMacroData().name)
    end
    function o:ShowOverlayGlow() ActionButton_ShowOverlayGlow(self.button()) end
    function o:HideOverlayGlow() ActionButton_HideOverlayGlow(self.button()) end


    function o:LogSpellName() p:log('SpellName: %s', tostring(self:GetEffectiveSpellName())) end

    --- @param label string
    function o:LogSpellNameWithDetails(label) p:log('[%s::%s]: %s [%s]', label or 'SpellDetails',
            self:GN(), tostring(self:GetEffectiveSpellName()), tostring(self:GetConfig().type)) end
end

PropsAndMethods(L)
