--[[-----------------------------------------------------------------------------
Lua Vars
-------------------------------------------------------------------------------]]
local unpack = unpack
local sformat, loadstring, format = string.format, loadstring, format

--[[-----------------------------------------------------------------------------
Blizzard Vars
-------------------------------------------------------------------------------]]
local ReloadUI, IsShiftKeyDown, UnitOnTaxi = ReloadUI, IsShiftKeyDown, UnitOnTaxi
local UIParent, CreateFrame = UIParent, CreateFrame
local InterfaceOptionsFrame, PlaySound, SOUNDKIT = InterfaceOptionsFrame, PlaySound, SOUNDKIT

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
-- Bump this version for every release tag
--

--- @type Namespace
local _, ns = ...
local O, GC, LibStub = ns.O, ns.O.GlobalConstants, ns.O.LibStub

local AO = O.AceLibFactory:A()
local GCC, M = GC.C, GC.M

local String, Table, LogFactory = O.String, O.Table, O.LogFactory
local IsEmptyTable, parseSpaceSeparatedVar = Table.isEmpty, Table.parseSpaceSeparatedVar
local IsBlank, IsAnyOf = String.IsBlank, String.IsAnyOf
local MX, WMX = O.Mixin, O.WidgetMixin

local AceDB, AceConfigDialog = AO.AceDB, AO.AceConfigDialog
local P = O.Profile
local p = LogFactory()

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]
--- @param frame ActionbarPlus_Frame
local function OnPlayerEnteringWorld(frame, event, ...)
    local isLogin, isReload = ...
    if event ~= GC.E.PLAYER_ENTERING_WORLD then return end

    if UnitOnTaxi(GC.UnitId.player) == true then
        local isShown = WMX:IsHideWhenTaxi() ~= true
        WMX:ShowActionbarsDelayed(isShown, 3)
    end
    frame.ctx.addon:SendMessage(M.OnAddOnReady)

    --@debug@
    isLogin = true
    --@end-debug@

    if not isLogin then return end
    local versionText = GC:GetAddonInfo()
    local C = GC:GetAceLocale()
    p:log(sformat(C['Addon Initialized Text Format'], versionText, GCC.ABP_COMMAND))
end

--- @return ActionbarPlus_Frame
--- @param addon ActionbarPlus|ActionbarPlusEventMixin
local function RegisterEvents(addon)

    --- @class ActionbarPlus_Frame : _Frame
    local frame = CreateFrame("Frame", nil, UIParent)
    frame.ctx = { addon = addon }

    local E = GC.E
    frame:SetScript(E.OnEvent, OnPlayerEnteringWorld)
    frame:RegisterEvent(E.PLAYER_ENTERING_WORLD)

    --- @class ActionbarPlusEvent : ActionbarPlusEventMixin
    local addonEvents = ns:K():CreateAndInitFromMixin(O.ActionbarPlusEventMixin, addon)
    addon.addonEvents = function() return addonEvents end

    return frame
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- @class ActionbarPlus_Methods : ActionbarPlusProperties
--- @type string
local methods = {
    --- @param self ActionbarPlus
    ['GetLogger'] = function(self) return p end,
    --- @param self ActionbarPlus
    --- @param isShown boolean
    ['ShowActionbars'] = function(self, isShown)
        WMX:ShowActionbarsDelayed(isShown, 1)
    end,
    --- @param self ActionbarPlus
    ['RegisterSlashCommands'] = function(self)
        self:RegisterChatCommand("abp", "SlashCommands")
    end,
    --- @param self ActionbarPlus
    ['RegisterHooks'] = function(self)
        local f = SettingsPanel or InterfaceOptionsFrame
        if f then self:HookScript(f, 'OnHide', 'OnHide_Config_WithoutSound') end
    end,
    --- @param self ActionbarPlus
    --- @param spaceSeparatedArgs string
    ['SlashCommands'] = function(self, spaceSeparatedArgs)
        local args = parseSpaceSeparatedVar(spaceSeparatedArgs)
        if IsEmptyTable(args) then self:SlashCommand_Help_Handler(); return end
        if IsAnyOf('config', unpack(args))
                or IsAnyOf('conf', unpack(args)) then
            self:OpenConfig();
            return
        end
        if IsAnyOf('info', unpack(args)) then self:SlashCommand_Info_Handler(spaceSeparatedArgs); return end
        self:SlashCommand_Help_Handler()
    end,
    --- @param self ActionbarPlus
    ['SlashCommand_Help_Handler'] = function(self)
        local C = GC:GetAceLocale()
        p:log('')
        p:log(GCC.ABP_CONSOLE_HEADER_FORMAT, C['Available console commands'])
        p:log('%s:  /abp [%s]', C['usage'], C['options'])
        p:log('%s:', C['options'])
        p:log(GCC.ABP_CONSOLE_OPTIONS_FORMAT, 'config', C['Shows the config UI (default)'])
        p:log(GCC.ABP_CONSOLE_OPTIONS_FORMAT, 'info', C['Info Console Command Text'])
        --p:log(GCC.ABP_CONSOLE_OPTIONS_FORMAT, 'macros', 'Enable macro edit mode')
        p:log(GCC.ABP_CONSOLE_OPTIONS_FORMAT, 'help', C['Shows this help'])
    end,
    --- @param self ActionbarPlus
    --- @param spaceSeparatedArgs string
    ['SlashCommand_Info_Handler'] = function(self, spaceSeparatedArgs)
        p:log(GC:GetAddonInfoFormatted())
    end,
    --- @param self ActionbarPlus
    ['ConfirmReloadUI'] = function(self)
        if IsShiftKeyDown() then
            ReloadUI()
            return
        end
        WMX:ShowReloadUIConfirmation()
    end,
    --- @param self ActionbarPlus
    ['OpenConfig'] = function(self, sourceFrameWidget)
        --select the frame config tab if possible
        local optionsConfigPath
        if sourceFrameWidget and sourceFrameWidget.GetFrameIndex  then
            optionsConfigPath = 'bar' .. sourceFrameWidget:GetFrameIndex()
        end
        if optionsConfigPath ~= nil then
            AceConfigDialog:SelectGroup(ns.name, optionsConfigPath)
        end
        AceConfigDialog:Open(ns.name, self.configFrame)
        self.onHideHooked = self.onHideHooked or false
        self.configDialogWidget = AceConfigDialog.OpenFrames[ns.name]

        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
        if not self.onHideHooked then
            self:HookScript(self.configDialogWidget.frame, 'OnHide', 'OnHide_Config_WithSound')
            self.onHideHooked = true
        end
    end,
    --- @param self ActionbarPlus
    ['OnHide_Config_WithSound'] = function(self) self:OnHide_Config(true) end,
    --- @param self ActionbarPlus
    ['OnHide_Config_WithoutSound'] = function(self) self:OnHide_Config() end,
    --- @param self ActionbarPlus
    ['OnHide_Config'] = function(self, enableSound)
        enableSound = enableSound or false
        p:log(10, 'OnHide_Config called with enableSound=%s', tostring(enableSound))
        if true == enableSound then PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE) end
    end,
    --- @param self ActionbarPlus
    ['OnUpdate'] = function(self) p:log('OnUpdate called...') end,
    --- @param self ActionbarPlus
    ['OnProfileChanged'] = function(self) self:ConfirmReloadUI() end,
    --- @param self ActionbarPlus
    ['InitializeDb'] = function(self)
        -- Set up our database
        --- @type ActionbarPlus_AceDB
        self.db = AceDB:New(GC.C.DB_NAME)
        ns.db = self.db
        self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
        self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
        self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
        self:InitDbDefaults()
        self:SendMessage(M.OnDBInitialized, self)
    end,

    --- @param self ActionbarPlus
    ['InitDefaultProfile'] = function(self)
        local defaultProfile = P:CreateDefaultProfile()
        self.defaultDB = { profile =  defaultProfile }
        self.db:RegisterDefaults(self.defaultDB)
    end,

    --- @param self ActionbarPlus
    ['InitDbDefaults'] = function(self)
        self:InitDefaultProfile()
        -- TODO next: remove self.profile in favor of ns.p()
        self.profile = self.db.profile
    end,
    --- This is called automatically by Ace
    --- @param self ActionbarPlus
    ['OnInitialize'] = function(self)
        self:InitializeDb()
        self:RegisterSlashCommands()
        self:RegisterHooks()

        self:SendMessage(M.OnAddOnInitialized, self)
    end
}

--[[-----------------------------------------------------------------------------
New Addon Instance
-------------------------------------------------------------------------------]]
--- @return ActionbarPlus
local function NewInstance()
    --- @class ActionbarPlus : ActionbarPlus_Methods
    local A = LibStub:NewAddon(ns.name)
    MX:Mixin(A, methods)
    A.ActionbarEmptyGridShowing = false

    RegisterEvents(A)

    return A
end

ABP = NewInstance()
