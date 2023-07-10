--[[-----------------------------------------------------------------------------
WoW Vars
-------------------------------------------------------------------------------]]
local GetCursorInfo, ClearCursor, CreateFrame, UIParent = GetCursorInfo, ClearCursor, CreateFrame, UIParent
local InCombatLockdown, GameFontHighlightSmallOutline = InCombatLockdown, GameFontHighlightSmallOutline
local C_Timer, C_PetJournal = C_Timer, C_PetJournal

--[[-----------------------------------------------------------------------------
LUA Vars
-------------------------------------------------------------------------------]]
local tostring, format, strlower, tinsert = tostring, string.format, string.lower, table.insert

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Namespace
local _, ns = ...
local pformat = ns.pformat
local O, GC, M, LibStub = ns.O, ns.O.GlobalConstants, ns.M, ns.O.LibStub

local AO = O.AceLibFactory:A()
local AceEvent, AceGUI, AceHook = AO.AceEvent, AO.AceGUI, AO.AceHook

local String = O.String
local A, P, PH = O.Assert, O.Profile, O.PickupHandler

local WMX, ButtonMX = O.WidgetMixin, O.ButtonMixin
local E, WAttr = GC.E, GC.WidgetAttributes

local IsBlank = String.IsBlank
local AssertThatMethodArgIsNotNil = A.AssertThatMethodArgIsNotNil

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @class ButtonUIWidgetBuilder : WidgetMixin
local _B = LibStub:NewLibrary(M.ButtonUIWidgetBuilder)

--- @class ButtonUILib
local _L = LibStub:NewLibrary(M.ButtonUI, 1)
local p = O.LogFactory:NewLogger(M.ButtonUI)

--- @return ButtonUIWidgetBuilder
function _L:WidgetBuilder() return _B end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
--- @param cursorInfo CursorInfo
local function IsValidDragSource(cursorInfo)
    --p:log("IsValidDragSource| CursorInfo=%s", cursorInfo)
    if not cursorInfo or IsBlank(cursorInfo.type) then
        -- This can happen if a chat tab or others is dragged into
        -- the action bar.
        --p:log(20, 'Received drag event with invalid cursor info. Skipping...')w
        return false
    end
    return O.ReceiveDragEventHandler:IsSupportedCursorType(cursorInfo)
end

---TODO: See the following implementation to mimic keydown
--- - https://wowpedia.fandom.com/wiki/CVar_ActionButtonUseKeyDown
--- - https://www.wowinterface.com/forums/showthread.php?t=58768
--- @param widget ButtonUIWidget
--- @param down boolean true if the press is KeyDown
local function RegisterForClicks(widget, event, down)
    local useKeyDown = GetCVarBool("ActionButtonUseKeyDown")
    local btn = widget.button()
    if E.ON_LEAVE == event then
        if useKeyDown then
            btn:RegisterForClicks('AnyDown')
        else
            btn:RegisterForClicks('AnyUp')
        end
    elseif E.ON_ENTER == event then
        if useKeyDown then
            --- Note: Macro will not trigger on first click if Drag Key is used in 'mod:<key>' in macros
            --- Macros should not use mod:<key> on the same drag key
            btn:RegisterForClicks(WMX:IsDragKeyDown() and 'AnyUp' or 'AnyDown')
        else
            btn:RegisterForClicks('AnyUp')
        end
    elseif E.MODIFIER_STATE_CHANGED == event or 'PreClick' == event or 'PostClick' == event then
        if useKeyDown then
            btn:RegisterForClicks(down and WMX:IsDragKeyDown() and 'AnyUp' or 'AnyDown')
        else
            btn:RegisterForClicks('AnyUp')
        end
    end
end

--- @param btn ButtonUI
--- @param key string The key clicked
--- @param down boolean true if the press is KeyDown
local function OnPreClick(btn, key, down)
    local w = btn.widget
    w:SendMessage(GC.M.OnButtonPreClick, w)
    if w:IsBattlePet() and C_PetJournal then
        w:SendMessage(GC.M.OnButtonClickBattlePet, w)
        return
    elseif w:IsEquipmentSet() then
        w:SendMessage(GC.M.OnButtonClickEquipmentSet, w)
        return
    else
        w:UpdateRangeIndicator()
    end
    -- This prevents the button from being clicked
    -- on sequential drag-and-drops (one after another)
    if PH:IsPickingUpSomething(btn) then btn:SetAttribute("type", "empty") end
    RegisterForClicks(w, 'PreClick', down)
end

--- @param btn ButtonUI
--- @param key string The key clicked
--- @param down boolean true if the press is KeyDown
local function OnPostClick(btn, key, down)
    local w = btn.widget
    w:SendMessage(GC.M.OnButtonPostClick, w)

    ---@param handlerFn ButtonHandlerFunction
    local function CallbackFn(handlerFn) O.ActionbarPlusAPI:UpdateM6Macros(handlerFn) end
    w:SendMessage(GC.M.OnButtonPostClickExt, ns.M.ButtonUI, CallbackFn)

    -- This prevents the button from being clicked
    -- on sequential drag-and-drops (one after another)
    RegisterForClicks(w, 'PreClick', down)
end

--- @param btnUI ButtonUI
local function OnDragStart(btnUI)
    if InCombatLockdown() then return end
    --- @type ButtonUIWidget
    local w = btnUI.widget
    if w:IsEmpty() then return end

    if InCombatLockdown() or not WMX:IsDragKeyDown() then return end
    w:Reset()
    p:log(20, 'DragStarted| Actionbar-Info: %s', pformat(btnUI.widget:GetActionbarInfo()))

    PH:Pickup(btnUI.widget)

    w:SetButtonAsEmpty()
    w:ShowEmptyGrid()
    w:ShowKeybindText(true)
    w:Fire('OnDragStart')
end

--- Used with `button:RegisterForDrag('LeftButton')`
--- @param btnUI ButtonUI
local function OnReceiveDrag(btnUI)
    if InCombatLockdown() then return end
    AssertThatMethodArgIsNotNil(btnUI, 'btnUI', 'OnReceiveDrag(btnUI)')
    local cursorUtil = ns:CreateCursorUtil()
    if not cursorUtil:IsValid() then
        p:log(20, 'OnReceiveDrag| CursorInfo: %s isValid: false', pformat:B()(cursorUtil:GetCursor()))
        return false
    else
        p:log(20, 'OnReceiveDrag| CursorInfo: %s', pformat:B()(cursorUtil:GetCursor()))
    end
    ClearCursor()

    --- @type ReceiveDragEventHandler
    O.ReceiveDragEventHandler:Handle(btnUI, cursorUtil)

    btnUI.widget:Fire('OnReceiveDrag')
end

---Triggered by SetCallback('event', fn)
--- @param widget ButtonUIWidget
local function OnReceiveDragCallback(widget) widget:UpdateStateDelayed(0.01) end

--- @param widget ButtonUIWidget
--- @param event string
--- @param mouseButtonPressed string LMOUSECLICK, etc...
--- @param down boolean 1 or true if the press is KeyDown
local function OnModifierStateChanged(widget, event, mouseButtonPressed, down)
    RegisterForClicks(widget, E.MODIFIER_STATE_CHANGED, down)
    if widget:IsMacro() then if down == 1 then widget:UpdateMacroState() end end
end

--- @param widget ButtonUIWidget
local function OnBeforeEnter(widget)
    RegisterForClicks(widget, E.ON_ENTER)
    widget:RegisterEvent(E.MODIFIER_STATE_CHANGED, OnModifierStateChanged, widget)

    -- handle stuff before event
    --- @param down boolean true if the press is KeyDown
    --widget:RegisterEvent(E.MODIFIER_STATE_CHANGED, function(w, event, key, down)
    --    RegisterForClicks(w, E.MODIFIER_STATE_CHANGED, down)
    --end, widget)
end
--- @param widget ButtonUIWidget
local function OnBeforeLeave(widget)
    --RegisterMacroEvent(widget)
    if not widget:IsMacro() then
        --widget:RegisterEvent(E.MODIFIER_STATE_CHANGED, OnModifierStateChanged, widget)
        widget:UnregisterEvent(E.MODIFIER_STATE_CHANGED)
    end
    RegisterForClicks(widget, E.ON_LEAVE)
end
--- @param btn ButtonUI
local function OnEnter(btn)
    OnBeforeEnter(btn.widget)
    ---Receiver will get a func(widget, event) {}
    btn.widget:Fire(E.ON_ENTER)
end
--- @param btn ButtonUI
local function OnLeave(btn)
    OnBeforeLeave(btn.widget)
    ---Receiver will get a func(widget, event) {}
    btn.widget:Fire(E.ON_LEAVE)
end

local function OnClick_SecureHookScript(btn, mouseButton, down)
    --p:log(20, 'SecureHookScript| Actionbar: %s', pformat(btn.widget:GetActionbarInfo()))
    btn:RegisterForClicks(WMX:IsDragKeyDown() and 'AnyUp' or 'AnyDown')
    if not PH:IsPickingUpSomething() then return end
    OnReceiveDrag(btn)
end

--- @param widget ButtonUIWidget
--- @param event string Event string
local function OnUpdateButtonCooldown(widget, event)
    if widget:IsNotUpdatable() then return end

    widget:UpdateCooldown()
    local cd = widget:GetCooldownInfo();
    if (cd == nil or cd.icon == nil) then return end
    widget:SetCooldownTextures(cd.icon)
end

--- @param widget ButtonUIWidget
--- @param event string Event string
local function OnSpellUpdateUsable(widget, event)
    if widget:IsNotUpdatable() then return end
    widget:UpdateRangeIndicator()
    widget:UpdateUsable()
    widget:UpdateGlow()
end

--- @param widget ButtonUIWidget
--- @param event string
local function OnPlayerControlLost(widget, event, ...)
    if not widget:IsHideWhenTaxi() then return end
    C_Timer.NewTicker(1, function()
        local playerOnTaxi = UnitOnTaxi(GC.UnitId.player)
        --p:log(0, 'Player on Taxi: %s [%s]', playerOnTaxi, GetTime())
        if playerOnTaxi ~= true then return end
        WMX:ShowActionbars(false)
    end, 2)
end

--- @param widget ButtonUIWidget
--- @param event string
local function OnPlayerControlGained(widget, event, ...)
    if not widget:IsHideWhenTaxi() then return end
    C_Timer.NewTicker(1, function()
        WMX:ShowActionbars(false)
    end, 2)
end

--- @see "UnitDocumentation.lua"
--- @param widget ButtonUIWidget
--- @param event string
local function OnPlayerTargetChanged(widget, event)
    if widget:IsNotUpdatable() then return end
    widget:UpdateRangeIndicator()
end

--- @see "UnitDocumentation.lua"
--- @param widget ButtonUIWidget
--- @param event string
local function OnPlayerTargetChangedDelayed(widget, event)
    C_Timer.After(0.1, function() OnPlayerTargetChanged(widget, event) end)
end

---@param widget ButtonUIWidget
local function OnPlayerStoppedMoving(widget, event)
    --if widget:IsNotUpdatable() then return end
    --p:log('moving-stopped[%s]: %s', widget:GN(), GetTime())
    OnPlayerTargetChangedDelayed(widget, event)
end
--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- @param widget ButtonUIWidget
--- @param name string The widget name.
local function RegisterWidget(widget, name)
    assert(widget ~= nil)
    assert(name ~= nil)

    local WidgetBase = AceGUI.WidgetBase
    widget.userdata = {}
    widget.events = {}
    local mt = {
        __tostring = function() return name  end,
        __index = WidgetBase
    }
    setmetatable(widget, mt)
end

--- @param button ButtonUI
local function RegisterScripts(button)
    AceHook:SecureHookScript(button, 'OnClick', OnClick_SecureHookScript)

    button:SetScript("PreClick", OnPreClick)
    button:SetScript("PostClick", OnPostClick)

    button:SetScript('OnDragStart', OnDragStart)
    button:SetScript('OnReceiveDrag', OnReceiveDrag)
    button:SetScript(E.ON_ENTER, OnEnter)
    button:SetScript(E.ON_LEAVE, OnLeave)
end

--- @param widget ButtonUIWidget
local function RegisterSpellUpdateUsable(widget)
    if not ns:IsVanilla() then
        widget:RegisterEvent(E.SPELL_UPDATE_USABLE, OnSpellUpdateUsable, widget)
    else
        -- In Vanilla, SPELL_UPDATE_USABLE does not fire very often
        widget:RegisterBucketEvent({ E.SPELL_UPDATE_USABLE, E.ACTIONBAR_UPDATE_USABLE }, 0.1, function(units)
            OnSpellUpdateUsable(widget)
        end);
    end
end

--- see: Interface_[Vanilla|TBC|etc.]/FrameXML/Constants.lua
--- ClassicExpansionAtLeast(LE_EXPANSION_CLASSIC)
--- ClassicExpansionAtLeast(LE_EXPANSION_BURNING_CRUSADE)
--- @param widget ButtonUIWidget
local function RegisterUpdateRangeIndicatorOnSpellCast(widget)
    if not GC.F.ENABLE_RANGE_INDICATOR_UPDATE_ON_SPELLCAST then return end
    local bucketEvents = { E.UNIT_SPELLCAST_SENT, E.UNIT_SPELLCAST_FAILED }
    widget:RegisterBucketEvent(bucketEvents, 0.5, function(units)
        if not units.player then return end
        if widget:IsHidden() or O.API:HasTarget() ~= true then return end
        local spell, ranged = widget:GetEffectiveRangedSpellName()
        if ranged == false then return end
        widget:UpdateRangeIndicatorBySpell(spell)
    end, widget)
end

--- @param widget ButtonUIWidget
local function RegisterCallbacks(widget)

    -- TODO Next: Tracks changing spells such as Covenant abilities in Shadowlands.
    widget:RegisterEvent(E.SPELL_UPDATE_COOLDOWN, OnUpdateButtonCooldown, widget)
    widget:RegisterEvent(E.PLAYER_CONTROL_LOST, OnPlayerControlLost, widget)
    widget:RegisterEvent(E.PLAYER_CONTROL_GAINED, OnPlayerControlGained, widget)
    widget:RegisterEvent(E.MODIFIER_STATE_CHANGED, OnModifierStateChanged, widget)
    widget:RegisterEvent(E.PLAYER_STOPPED_MOVING, OnPlayerStoppedMoving, widget)
    RegisterSpellUpdateUsable(widget)
    RegisterUpdateRangeIndicatorOnSpellCast(widget)

    -- Callbacks (fired via Ace Events)
    widget:SetCallback(E.ON_RECEIVE_DRAG, OnReceiveDragCallback)

    --- @param w ButtonUIWidget
    widget:SetCallback("OnEnter", function(w)
        if InCombatLockdown() then return end
        if not GetCursorInfo() then return end
        w:SetHighlightEmptyButtonEnabled(true)
    end)
    widget:SetCallback("OnLeave", function(w)
        if InCombatLockdown() then return end
        if not GetCursorInfo() then return end
        w:SetHighlightEmptyButtonEnabled(false)
    end)
end

--[[-----------------------------------------------------------------------------
Builder Methods
-------------------------------------------------------------------------------]]

---Creates a new ButtonUI
--- @param dragFrameWidget FrameWidget The drag frame this button is attached to
--- @param rowNum number The row number
--- @param colNum number The column number
--- @param btnIndex number The button index number
--- @return ButtonUIWidget
function _B:Create(dragFrameWidget, rowNum, colNum, btnIndex)

    local btnName = GC:ButtonName(dragFrameWidget.index, btnIndex)

    --- @class __ButtonUI
    local button = CreateFrame("Button", btnName, UIParent, GC.C.SECURE_ACTION_BUTTON_TEMPLATE)
    --- @alias ButtonUI __ButtonUI|_Button

    --local button = CreateFrame("Button", btnName, UIParent, "SecureActionButtonTemplate,SecureHandlerBaseTemplate")
    button.text = WMX:CreateFontString(button)
    button.indexText = WMX:CreateIndexTextFontString(button)
    button.keybindText = WMX:CreateKeybindTextFontString(button)
    button.nameText = WMX:CreateNameTextFontString(button)
    RegisterScripts(button)

    -- todo next: add ActionButtonUseKeyDown to options UI; add to abp_info
    --            iterate through all buttons and call #RegisterForClicks()
    -- /run SetCVar("ActionButtonUseKeyDown", 1)
    -- /run SetCVar("ActionButtonUseKeyDown", 0)
    -- /dump GetCVarBool("ActionButtonUseKeyDown")

    button:RegisterForDrag("LeftButton", "RightButton");
    button:RegisterForClicks("AnyDown", "AnyUp");

    --- see: Interface/AddOns/Blizzard_APIDocumentationGenerated/CooldownFrameAPIDocumentation.lua
    --- @class CooldownFrame : _CooldownFrame
    local cooldown = CreateFrame("Cooldown", btnName .. 'Cooldown', button,  "CooldownFrameTemplate")
    cooldown:SetAllPoints(button)
    cooldown:SetSwipeColor(1, 1, 1)
    cooldown:SetCountdownFont(GameFontHighlightSmallOutline:GetFont())
    cooldown:SetDrawEdge(true)
    cooldown:SetEdgeScale(0.0)
    cooldown:SetHideCountdownNumbers(false)
    cooldown:SetUseCircularEdge(false)
    cooldown:SetPoint('CENTER')

    --- @alias ButtonUIWidget __ButtonUIWidget | BaseLibraryObject_WithAceEvent
    --- @class __ButtonUIWidget : ButtonMixin
    local __widget = {
        --- @type fun() : ActionbarPlus
        addon = function() return ABP end,
        --- @type number
        index = btnIndex,
        --- @type number
        frameIndex = dragFrameWidget:GetIndex(),
        --- @type string
        buttonName = btnName,
        --- @type fun() : FrameWidget
        dragFrame = function() return dragFrameWidget end,
        --- @type fun() : ButtonUI
        button = function() return button  end,
        --- @type fun() : CooldownFrame
        cooldown = function() return cooldown end,
        --- @type table
        cooldownInfo = nil,
        ---Don't make this 'LOW'. ElvUI AFK Disables it after coming back from AFK
        --- @type string
        frameStrata = dragFrameWidget.frameStrata or 'MEDIUM',
        frameLevel = (dragFrameWidget.frameLevel + 100) or 100,
        --- @type number
        buttonPadding = 1,
        placement = { rowNum = rowNum, colNum = colNum },
    }
    --- @type ButtonUIWidget
    local widget = __widget

    button.widget, cooldown.widget = widget, widget

    AceEvent:Embed(widget)
    ns:AceBucketEmbed(widget)

    ButtonMX:Mixin(widget)

    RegisterWidget(widget, btnName .. '::Widget')
    RegisterCallbacks(widget)

    widget:InitWidget()

    return widget
end
