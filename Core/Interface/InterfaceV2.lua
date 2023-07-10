--- @alias ActionBarFrame _ActionBarFrame | _Frame
--- @class _ActionBarFrame : _Frame_
local ActionBarFrame = {
    --- @type number
    frameIndex = -1,
    --- @type fun():ActionBarWidget
    widget = {},
}
