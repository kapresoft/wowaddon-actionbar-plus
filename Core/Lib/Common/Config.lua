--[[-----------------------------------------------------------------------------
Lua Vars
-------------------------------------------------------------------------------]]
local format = string.format

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local O, LibStub = ns:LibPack()

local GC, Ace, BaseAPI = O.GlobalConstants, O.AceLibrary, O.BaseAPI
local E, M = GC.E, GC.M
local AceEvent, AceConfig, AceConfigDialog, AceDBOptions = Ace.AceEvent, Ace.AceConfig, Ace.AceConfigDialog, Ace.AceDBOptions

local p = O.LogFactory(ns.M.Config)

---These are loaded in #fetchLibs()
--- @type Profile
local P
--- @type Profile_Config_Names
local PC
--- @type Profile_Config_Widget_Names
local WC
--- @type TooltipKey
local TTK
--- @type TooltipAnchorTypeKey
local TTAK
--- @type ButtonFactory
local BF
--- @type ButtonFrameFactory
local FF
--- @type table<string, string|number>
local L

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]
local function ConfirmAndReload() return O.WidgetMixin:ConfirmAndReload() end
--- @return FrameWidget
local function GetFrameWidget(frameIndex) return FF:GetFrameByIndex(frameIndex).widget end
--- @return Profile_Bar
local function GetBarConfig(frameIndex) return P:GetBar(frameIndex) end

--- @param applyFunction function Format: applyFuntion(ButtonUIWidget)
local function ApplyForEachButton(applyFunction, configVal)
    BF:ApplyForEachFrames(function(frameWidget)
        --- @param widget ButtonUIWidget
        frameWidget:ApplyForEachButtons(function(widget) applyFunction(widget, configVal) end)
    end)
end

local function PSetWithEvent(config, key, fallbackVal, eventName)
    return function(_, v)
        assert(type(key) == 'string', 'Profile key should be a string')
        config.profile[key] = v or fallbackVal
        if eventName then BF:Fire(eventName) end
    end
end

local function SetAndApplyGeneric(config, key, fallbackVal, postFunction)
    return function(_, v)
        assert(type(key) == 'string', 'Profile key should be a string')
        config.profile[key] = v or fallbackVal
        if 'function' == type(postFunction) then postFunction(config.profile[key]) end
    end
end

--- @param fallback any The fallback value
--- @param key string The key value
--- @param config Config The config instance
local function SetAndApply(config, key, fallback, foreachButtonFunction)
    return function(_, v)
        assert(type(key) == 'string', 'Profile key should be a string')
        config.profile[key] = v or fallback
        if 'function' == type(foreachButtonFunction) then
            ApplyForEachButton(foreachButtonFunction, config.profile[key])
        end
    end
end

--- @param frameIndex number
--- @param key string The key value
--- @param fallback any The fallback value
--- @param eventNameOrFunction string | function | nil
local function PSetWidget(frameIndex, key, fallback, eventNameOrFunction)
    return function(_, v)
        assert(type(key) == 'string', 'Widget attribute key should be a string, but was ' .. type(key))
        GetBarConfig(frameIndex).widget[key] = v or fallback
        if 'string' == type(eventNameOrFunction) then BF:Fire(eventNameOrFunction, frameIndex)
        elseif 'function' == type(eventNameOrFunction) then eventNameOrFunction(frameIndex, v or fallback) end
    end
end

--- @param frameIndex number
--- @param key string The key value
--- @param fallback any The fallback value
--- @param eventNameOrFunction string | function | nil
local function PSetSpecificWidget(frameIndex, key, fallback, eventNameOrFunction)
    return function(_, v)
        assert(type(key) == 'string', 'Widget attribute key should be a string, but was ' .. type(key))
        GetBarConfig(frameIndex).widget[key] = v or fallback
        if 'string' == type(eventNameOrFunction) then BF:FireOnFrame(frameIndex, eventNameOrFunction)
        elseif 'function' == type(eventNameOrFunction) then eventNameOrFunction(frameIndex, v or fallback) end
    end
end

--- @param frameIndex number
--- @param key string The key value
--- @param fallback any The fallback value
local function PGetWidget(frameIndex, key, fallback)
    return function(_)
        assert(type(key) == 'string', 'Widget attribute key should be a string, but was ' .. type(key))
        return GetBarConfig(frameIndex).widget[key] or fallback
    end
end

--- @param frameIndex number
local function OnResetAnchor(frameIndex) return function() GetFrameWidget(frameIndex):ResetAnchor() end end

local function GetFrameStateSetterHandler(frameIndex)
    return function(_, v) GetFrameWidget(frameIndex):SetFrameState(v) end
end
local function GetFrameStateGetterHandler(frameIndex)
    return function(_) return P:IsShownInConfig(frameIndex) end
end
local function GetShowButtonIndexStateGetterHandler(frameIndex)
    return function(_) return P:IsShowIndex(frameIndex) end
end
local function GetShowButtonIndexStateSetterHandler(frameIndex)
    --TODO: NEXT: Use events instead
    return function(_, v) GetFrameWidget(frameIndex):ShowButtonIndices(v) end
end
local function GetShowKeybindTextStateGetterHandler(frameIndex)
    return function(_) return P:IsShowKeybindText(frameIndex) end
end
local function GetShowKeybindTextStateSetterHandler(frameIndex)
    --TODO: NEXT: Use events instead
    return function(_, v) GetFrameWidget(frameIndex):ShowKeybindText(v) end
end
local function GetLockStateSetterHandler(frameIndex)
    return function(_, v)
        P:SetBarLockValue(frameIndex, v)
        GetFrameWidget(frameIndex):SetLockedState()
    end
end
local function GetLockStateGetterHandler(frameIndex)
    return function(_) return P:GetBarLockValue(frameIndex) end
end

local function GetRowSizeGetterHandler(frameIndex)
    return function(_) return P:GetRowSize(frameIndex) end
end
local function GetRowSizeSetterHandler(frameIndex)
    return function(_, v)
        GetBarConfig(frameIndex).widget.rowSize = v
        BF:Fire(E.OnButtonCountChanged, frameIndex)
    end
end
local function GetColSizeGetterHandler(frameIndex)
    return function(_) return P:GetColumnSize(frameIndex) end
end
local function GetColSizeSetterHandler(frameIndex)
    return function(_, v)
        GetBarConfig(frameIndex).widget.colSize = v
        BF:Fire(E.OnButtonCountChanged, frameIndex)
    end
end

--- @param config Config The config instance
--- @param key string The key value
--- @param fallback any The fallback value
local function PSet(config, key, fallback)
    return function(_, v)
        assert(type(key) == 'string', 'Profile key should be a string')
        config.profile[key] = v or fallback
    end
end

--- @param config Config The config instance
--- @param fallback any The fallback value
--- @param key string The key value
local function PGet(config, key, fallback)
    return function(_)
        assert(type(key) == 'string', 'Profile key should be a string')
        return config.profile[key] or fallback
    end
end

local function lazyInitLibs()
    P, BF, FF = O.Profile, O.ButtonFactory, O.ButtonFrameFactory
    PC = GC.Profile_Config_Names
    WC = GC.Profile_Config_Widget_Names
    TTK = P:GetTooltipKey()
    TTAK = P:GetTooltipAnchorTypeKey()
    L = GC:GetAceLocale()
end

--[[-----------------------------------------------------------------------------
Sequence
-------------------------------------------------------------------------------]]
local sp = '                                                                   '

--- @class SequenceMixin
local SequenceMixin = {

    --- @param self SequenceMixin
    --- @param startingIndex number
    ["Init"] = function(self, startingIndex)
        self.order = startingIndex or 1
    end,
    --- @param self SequenceMixin
    ["get"] = function(self) return self.order  end,
    --- @param self SequenceMixin
    --- @param incr number An optional increment amount
    ["next"] = function(self, incr)
        self.order = self.order + (incr or 1)
        return self.order
    end,
    --- @param self SequenceMixin
    ["reset"] = function(self)
        local lastCount = self.order + 1
        self.order = 1
        return lastCount
    end
}

--- @param startingSequence number Optional
--- @return SequenceMixin
local function CreateSequence(startingSequence)
    --- @type SequenceMixin
    return CreateAndInitFromMixin(SequenceMixin, startingSequence)
end

local mainSeq = CreateSequence()
local barSeq = CreateSequence()

--[[-----------------------------------------------------------------------------
Properties & Methods
-------------------------------------------------------------------------------]]
--- @param o Config
local function PropsAndMethods(o)

    --- Call Order: Config -> Profile -> ButtonFactory
    --- Message triggered by ActionbarPlus#OnInitializeModules
    --- @param msg string The message name
    function o:OnAddOnInitialized(msg)
        lazyInitLibs()
        assert(ns.db.profile, "Profile is not initialized.")
        self.profile = ns.db.profile
        self.eventHandler = ns:K():CreateAndInitFromMixin(O.ConfigEventHandlerMixin)
        self:Initialize()
        self:SendMessage(GC.M.OnConfigInitialized)
    end

    --- Sets up Ace config dialog
    function o:Initialize()
        local options = self:GetOptions()
        -- Get the option table for profiles
        -- options.args.profiles = AceDBOptions:GetOptionsTable(self.db)
        AceConfig:RegisterOptionsTable(ns.name, options, { GC.C.SLASH_COMMAND_OPTIONS })
        AceConfigDialog:AddToBlizOptions(ns.name, ns.name)
        options.args.profiles = AceDBOptions:GetOptionsTable(ns.db)
    end

    function o:GetOptions()
        return {
            name = GC.C.ADDON_NAME, handler = self.addon, type = "group",
            args = self:CreateConfig(),
        }
    end
    function o:CreateConfig()
        local configArgs = {}

        configArgs['general'] = self:CreateGeneralGroup()
        local hiddenGeneralConfigs = {
            'equipmentset_header',
            PC.equipmentset_open_character_frame,
            PC.equipmentset_open_equipment_manager,
            PC.equipmentset_show_glow_when_active,
        }
        if BaseAPI:IsClassicEra() then
            local gen = configArgs['general'].args
            for _, v in ipairs(hiddenGeneralConfigs) do gen[v] = nil end
        end
        configArgs['debugging'] = self:CreateDebuggingGroup()

        local barConfigs = self:CreateActionBarConfigs()
        for bName, bConf in pairs(barConfigs) do
            configArgs[bName] = bConf
        end


        return configArgs
    end

    function o:CreateGeneralGroup()
        local GeneralConfigHeader = ' ' .. L['General Configuration'] .. ' '
        local GeneralTooltipOptionsHeader = ' ' .. L['Tooltip Options'] .. ' '

        return {
            type = "group",
            name = L['General'],
            desc = GeneralConfigHeader,
            order = mainSeq:next(),
            args = {
                desc = { name = GeneralConfigHeader, type = "header", order = 0 },
                character_specific_anchors = {
                    type = 'toggle',
                    width = 'full',
                    confirm = ConfirmAndReload,
                    order = mainSeq:next(),
                    name = L['Character Specific Frame Positions'],
                    desc = L['Character Specific Frame Positions::Description'],
                    get = PGet(self, PC.character_specific_anchors, false),
                    set = PSet(self, PC.character_specific_anchors, false)
                },
                hide_when_taxi = {
                    width = 'normal',
                    type = 'toggle',
                    order = mainSeq:next(),
                    name = L['Hide during taxi'],
                    desc = L['Hide during taxi::Description'],
                    get = PGet(self, PC.hide_when_taxi, false),
                    set = PSet(self, PC.hide_when_taxi, false),
                    set = PSetWithEvent(self, PC.hide_when_taxi, false, E.OnHideWhenTaxiChanged)
                },
                action_button_mouseover_glow = {
                    width = 'normal',
                    type = 'toggle',
                    order = mainSeq:next(),
                    name = L['Mouseover Glow'],
                    desc = L['Mouseover Glow::Description'],
                    get = PGet(self, PC.action_button_mouseover_glow, false),
                    set = PSetWithEvent(self, PC.action_button_mouseover_glow, false, E.OnMouseOverGlowSettingsChanged)
                },
                hide_text_on_small_buttons = {
                    width = 'full',
                    type = 'toggle',
                    order = mainSeq:next(),
                    name = L['Hide text for smaller buttons'],
                    desc = L['Hide text for smaller buttons::Description'],
                    get = PGet(self, PC.hide_text_on_small_buttons, false),
                    set = PSetWithEvent(self, PC.hide_text_on_small_buttons, false, E.OnTextSettingsChanged),
                },
                hide_countdown_numbers = {
                    width = 'full',
                    type = 'toggle',
                    order = mainSeq:next(),
                    name = L['Hide countdown numbers on cooldowns'],
                    desc = L['Hide countdown numbers on cooldowns::Description'],
                    get = PGet(self, PC.hide_countdown_numbers, false),
                    set = PSetWithEvent(self, PC.hide_countdown_numbers, false, E.OnCooldownTextSettingsChanged),
                },

                equipmentset_header = { order = mainSeq:next(), type = "header", name = "Equipment Set Options" },
                equipmentset_open_character_frame = {
                    order = mainSeq:next(),
                    width = 'normal',
                    type = 'toggle',
                    name = 'Open Character Frame',
                    -- todo next: localize strings
                    desc = 'When the player clicks an equipment set button, the character frame should automatically open. This will provide the user with quick access to their character\'s equipped gear, without requiring them to manually open the frame.',
                    get = PGet(self, PC.equipmentset_open_character_frame, false),
                    set = self:CM(PC.equipmentset_open_character_frame, false),
                },
                equipmentset_open_equipment_manager = {
                    order = mainSeq:next(),
                    width = 1.2,
                    type = 'toggle',
                    name = "Open Equipment Manager",
                    desc = 'When the player clicks an equipment set button, the character frame should automatically open, as well as the Equipment Manager. This will allow users to quickly and easily manage their equipment while also viewing their character\'s information. This setting only applies if "Open Character Frame" is enabled.',
                    get = PGet(self, PC.equipmentset_open_equipment_manager, false),
                    set = self:CM(PC.equipmentset_open_equipment_manager, false),
                },
                equipmentset_show_glow_when_active = {
                    order = mainSeq:next(),
                    width = 'normal',
                    type = 'toggle',
                    name = "Glow After Equip",
                    desc = 'When the player equips a set, the button should light up or glow to provide clear visual feedback and confirm that the equipment set has been successfully equipped.',
                    get = PGet(self, PC.equipmentset_show_glow_when_active, false),
                    set = self:CM(PC.equipmentset_show_glow_when_active, false),
                },
                tooltip_header = { order = mainSeq:next(), type = "header", name = GeneralTooltipOptionsHeader },
                tooltip_visibility_key = {
                    width = 'normal',
                    type = 'select', style = 'dropdown',
                    order = mainSeq:next(),
                    values = TTK.kvPairs, sorting = TTK.sorting,
                    name = L['Tooltip Visibility'],
                    desc = L['Tooltip Visibility::Description'],
                    get = PGet(self, PC.tooltip_visibility_key, TTK.names.SHOW),
                    set = PSet(self, PC.tooltip_visibility_key, TTK.names.SHOW)
                },
                tooltip_visibility_combat_override_key = {
                    width = 'normal',
                    type = 'select', style = 'dropdown',
                    order = mainSeq:next(),
                    values = TTK.kvPairs, sorting = TTK.sorting,
                    name = L['Combat Override Key'],
                    desc = L['Combat Override Key::Description'],
                    get = PGet(self, PC.tooltip_visibility_combat_override_key),
                    set = PSet(self, PC.tooltip_visibility_combat_override_key)
                },
                tooltip_anchor_type = {
                    width = 'normal',
                    type = 'select', style = 'dropdown',
                    order = mainSeq:next(),
                    values = TTAK.kvPairs, sorting = TTAK.sorting,
                    name = L['Tooltip Anchor'],
                    desc = L['Tooltip Anchor::Description'],
                    get = PGet(self, PC.tooltip_anchor_type),
                    set = self:CM(PC.tooltip_anchor_type, GC.TooltipAnchor.CURSOR_TOPLEFT, GC.M.OnTooltipFrameUpdate),
                }
            }
        }
    end

    function o:CreateDebuggingGroup()
        return {
            type = "group",
            name = L['Debugging'],
            desc = L['Debugging::Description'],
            -- Place right before Profiles
            order = 90,
            args = {
                desc = { name = format(" %s ", L['Debugging Configuration']), type = "header", order = 0 },
                log_level = {
                    type = 'range',
                    order = 1,
                    step = 5,
                    min = 0,
                    max = 50,
                    width = 1.2,
                    name = L['Log Level'],
                    desc = L['Log Level::Description'],
                    get = function(_) return GC:GetLogLevel() end,
                    set = function(_, v) GC:SetLogLevel(v) end,
                },
            },
        }
    end

    function o:CreateActionBarConfigs()
        local count = P:GetBarSize()
        local bars = {}
        for i=1,count do
            -- barN is the config path name used for OptionDialog#OpenConfig()
            local key = 'bar' .. i
            bars[key] = self:CreateBarConfigDef(i)
        end
        return bars
    end

    --- @param frameIndex number
    function o:CreateBarConfigDef(frameIndex)
        local configName = format('%s #%s', ABP_ACTIONBAR_BASE_NAME, tostring(frameIndex))
        return {
            type = 'group',
            name = configName,
            desc = format("%s %s", configName, L['Settings']),
            order = mainSeq:next(),
            args = {
                desc = { name = format("%s ", configName, L['Settings']),
                         type = "header", order = barSeq:next(), },
                enabled = {
                    width = "full",
                    type = "toggle",
                    name = L['Enable'],
                    desc = format("%s %s", ABP_ACTIONBAR_BASE_NAME, configName),
                    order = barSeq:next(),
                    get = GetFrameStateGetterHandler(frameIndex),
                    set = GetFrameStateSetterHandler(frameIndex)
                },
                show_empty_buttons = {
                    width = "normal",
                    type = "toggle",
                    name = L['Show empty buttons'],
                    desc = L['Show empty buttons::Description'],
                    order = barSeq:next(),
                    get = PGetWidget(frameIndex, WC.show_empty_buttons, false),
                    set = PSetSpecificWidget(frameIndex, WC.show_empty_buttons, false, E.OnActionbarShowEmptyButtonsUpdated),
                },
                showIndex = {
                    width = "normal",
                    type = "toggle",
                    name = L['Show Button Numbers'],
                    desc = format(L['Show Button Numbers::Description'], configName),
                    order = barSeq:next(),
                    get = GetShowButtonIndexStateGetterHandler(frameIndex),
                    set = GetShowButtonIndexStateSetterHandler(frameIndex)
                },
                showKeybindText = {
                    width = "normal",
                    type = "toggle",
                    name = L['Show Keybind Text'],
                    desc = format(L['Show Keybind Text::Description'], configName),
                    order = barSeq:next(),
                    get = GetShowKeybindTextStateGetterHandler(frameIndex),
                    set = GetShowKeybindTextStateSetterHandler(frameIndex)
                },
                spacer1 = { type="description", name = sp, width="full", order = barSeq:next() },
                alpha = {
                    width = "normal",
                    type = 'range',
                    order = barSeq:next(),
                    isPercent = true,
                    step = 0.01,
                    min = 0,
                    max = 1,
                    name = L['Alpha'],
                    desc = L['Alpha::Description'],
                    get = PGetWidget(frameIndex, WC.buttonAlpha, 1.0),
                    set = PSetSpecificWidget(frameIndex, WC.buttonAlpha, 1.0, E.OnActionbarFrameAlphaUpdated),
                },
                button_width = {
                    width = "normal",
                    type = 'range',
                    order = barSeq:next(),
                    step = 1,
                    min = 20,
                    max = 100,
                    name = L['Size (Width & Height)'],
                    desc = L['Size (Width & Height)::Description'],
                    get = PGetWidget(frameIndex, WC.buttonSize, 36),
                    set = PSetWidget(frameIndex, WC.buttonSize, 36, E.OnButtonSizeChanged),
                },
                rows = {
                    width = "normal",
                    type = 'range',
                    order = barSeq:next(),
                    step = 1,
                    min = 1,
                    max = self.maxCols,
                    name = L['Rows'],
                    desc = L['Rows::Description'],
                    --confirm = ConfirmAndReload,
                    get = GetRowSizeGetterHandler(frameIndex),
                    set = GetRowSizeSetterHandler(frameIndex)
                },
                cols = {
                    width = "normal",
                    type = 'range',
                    order = barSeq:next(),
                    step = 1,
                    min = 1,
                    max = self.maxRows,
                    name = L['Columns'],
                    desc = L['Columns::Description'],
                    --confirm = ConfirmAndReload,
                    get = GetColSizeGetterHandler(frameIndex),
                    set = GetColSizeSetterHandler(frameIndex)
                },
                spacer2 = { type="description", name=sp, width="full", order = barSeq:next() },
                lock = {
                    width = "normal",
                    type = "select", style = "dropdown",
                    order = barSeq:next(),
                    values = { [''] = L['No'],
                               ['always'] = L['Always'],
                               ['in-combat'] = L['In-Combat'] },
                    name = L['Lock Actionbar'],
                    desc = L['Lock Actionbar::Description'],
                    get = GetLockStateGetterHandler(frameIndex),
                    set = GetLockStateSetterHandler(frameIndex)
                },
                spacer3 = { type="description", name=sp, width="full", order = barSeq:next() },
                spacer4 = { type="header", name = L['Frame Handle Settings'], width="full", order = barSeq:next() },
                frame_handle_mouseover = {
                    width = "normal",
                    type = "toggle",
                    order = barSeq:next(),
                    name = L['Mouseover'],
                    desc = L['Mouseover::Description'],
                    get = PGetWidget(frameIndex, WC.frame_handle_mouseover, false),
                    set = PSetSpecificWidget(frameIndex, WC.frame_handle_mouseover, false, E.OnFrameHandleMouseOverConfigChanged),
                },
                frame_handle_alpha = {
                    width = "normal",
                    type = 'range',
                    order = barSeq:next(),
                    name = L['Mouseover'],
                    desc = L['Mouseover::Description'],
                    isPercent = true,
                    step = 0.01,
                    min = 0,
                    max = 1,
                    get = PGetWidget(frameIndex, WC.frame_handle_alpha, 1.0),
                    set = PSetSpecificWidget(frameIndex, WC.frame_handle_alpha, 1.0, E.OnFrameHandleAlphaConfigChanged),
                },
                reset_anchor = {
                    width = "normal",
                    type = 'execute',
                    order = barSeq:reset(),
                    name = L['Reset Anchor'],
                    desc = L['Reset Anchor::Description'],
                    func = OnResetAnchor(frameIndex),
                }
            }
        }
    end

    --- TODO NEXT: Migrate event-base to message-base
    --- Creates a callback function that sends a message after
    --- @param key string The profile key to update
    --- @param fallbackVal any The fallback value
    --- @param message string The message to send
    --- @return fun(_, v:any) : void The function parameter "v" is the option value selected by the user
    --- @see ConfigEventHandlerMixin#SetConfigWithMessage
    function o:CM(key, fallbackVal, message) return self.eventHandler:SetConfigWithMessage(key, fallbackVal, message) end

end

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- properties "addon" and "profile" is injected OnAfterInitialize()
--- @return Config
local function NewInstance()
    --- @type Config
    local newConfig = LibStub:NewLibrary(ns.M.Config); if not newConfig then return end
    newConfig.maxRows = 20
    newConfig.maxCols = 40
    newConfig.maxButtons = newConfig.maxRows * newConfig.maxCols

    AceEvent:Embed(newConfig)
    PropsAndMethods(newConfig)
    newConfig:RegisterMessage(M.OnAddOnInitialized, function(evt, ...) newConfig:OnAddOnInitialized(evt, ...) end)
    return newConfig
end

NewInstance()
