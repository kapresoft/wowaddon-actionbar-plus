--- @alias ActionBarFrame _ActionBarFrame | _Frame
--- @class _ActionBarFrame : _Frame_
local ActionBarFrame = {
    --- @type fun():ActionBarWidget
    widget = {},
}
--[[-----------------------------------------------------------------------------
ActionBarButton
-------------------------------------------------------------------------------]]
--- @alias ActionButton _ActionButton | _CheckButton
--- #### See: Interface/FrameXML/ActionButtonTemplate.xml
--- @class _ActionButton : __CheckButton
local _ActionButton = {
    --- @type fun():ActionButtonWidget
    widget = nil,
    --- @type CooldownFrame
    cooldown = nil,
    --- @type _Texture
    NormalTexture = nil,
}
