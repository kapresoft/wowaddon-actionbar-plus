local PrettyPrint, Table, String = ABP_LibGlobals:LibPackUtils()
local LibStub, M, G = ABP_LibGlobals:LibPack()

---@class WidgetLibFactory
local _L = LibStub:NewLibrary(M.WidgetLibFactory)

---@type Assert
local assertLib = LibStub(M.Assert)

local CC = ABP_CommonConstants
local unitAttributes = CC.UnitAttributes
local buttonAttributes = CC.ButtonAttributes
local widgetAttributes = CC.WidgetAttributes

---@type AceLibFactory
local aceLibFactory = LibStub(M.AceLibFactory)
--_@type LibSharedMedia
local sharedMedia = aceLibFactory:GetAceSharedMedia()

-- ## Functions ------------------------------------------------

function _L:ResetWidgetAttributes(btnUI)
    for _,v in pairs(buttonAttributes) do
        --l:log(50, 'Resetting Attribute: %s', v)
        btnUI:SetAttribute(v, nil)
    end
end

---@return ButtonFactory
function _L:GetButtonFactory() return LibStub(M.ButtonFactory) end
---@return ButtonFrameFactory
function _L:GetButtonFrameFactory() return LibStub(M.ButtonFrameFactory) end
---@return Profile
function _L:GetProfile() return LibStub(M.Profile) end
---@return Config
function _L:GetConfig() return LibStub(M.Config) end
---@return ButtonUI
function _L:GetButtonUI() return LibStub(M.ButtonUI) end
---@return MacroTextureDialog
function _L:GetMacroTextureDialog() return LibStub(M.MacroTextureDialog) end
---@return WidgetMixin
function _L:GetWidgetMixin() return LibStub(M.WidgetMixin) end

---@param target any
---@param mixins table A list of methods/properties to mix in
function _L:Mixin(target, mixins) return self:GetWidgetMixin():Mixin(target, mixins) end

--- Usage: local Config, Profile, ButtonFactory = WidgetLibFactory:LibPack_AddonLibs()
---@return Config, Profile, ButtonFactory
function _L:LibPack_AddonLibs() return self:GetConfig(), self:GetProfile(), self:GetButtonFactory() end

-- Usage: P, SM = unpack(LibFactory:GetButtonFactoryLibs())
--@return Profile, LibSharedMedia
function _L:GetButtonFactoryLibs() return self:GetProfile(), sharedMedia end

---Get the Config Lib Pack
---```
---local Profile, ButtonFactory = WidgetLibFactory:GetConfigLibPack()
---```
---@return Profile, ButtonFactory, ButtonFrameFactory
function _L:LibPack_Config()
    return self:GetProfile(), self:GetButtonFactory(), self:GetButtonFrameFactory() end

---@return Profile, Assert
function _L:LibPackButtonFrameFactory() return self:GetProfile(), assertLib end

---@return ButtonAttributes, WidgetAttributes, UnitAttributes
function _L:LibPack_WidgetAttributes()
    return buttonAttributes, widgetAttributes, unitAttributes
end

---@return ButtonFrameFactory, ReceiveDragEventHandler, SpellAttributeSetter, ItemAttributeSetter, MacroAttributeSetter, MacrotextAttributeSetter
function _L:LibPack_ButtonFactory()
    return G:Get(M.ButtonFrameFactory, M.ReceiveDragEventHandler, M.SpellAttributeSetter,
            M.ItemAttributeSetter, M.MacroAttributeSetter, M.MacrotextAttributeSetter)
end

---@return ItemAttributeSetter
function _L:ItemAttributeSetter() return LibStub(M.ItemAttributeSetter) end
---@return SpellAttributeSetter
function _L:SpellAttributeSetter() return LibStub(M.SpellAttributeSetter) end
---@return MacroAttributeSetter
function _L:MacroAttributeSetter() return LibStub(M.MacroAttributeSetter) end
---@return MacrotextAttributeSetter
function _L:MacrotextAttributeSetter() return LibStub(M.MacrotextAttributeSetter) end

---@return SpellDragEventHandler, ItemDragEventHandler, MacroDragEventHandler
function _L:LibPack_DragEventHandlers()
    return G:Get(M.SpellDragEventHandler, M.ItemDragEventHandler, M.MacroDragEventHandler)
end