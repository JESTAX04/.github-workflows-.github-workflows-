screen = {guiGetScreenSize ()}
resolution = {1920, 1080}
sx, sy = screen[1] / resolution[1], screen[2] / resolution[2]

function setScreenPosition (x, y, w, h)
    return ((x / resolution[1]) * screen[1]), ((y / resolution[2]) * screen[2]), ((w / resolution[1]) * screen[1]), ((h / resolution[2]) * screen[2])
end

local fontsCache = {}
function getFont(font, size, isLocal, ...)
    local size = size or 10
    size = math.ceil(size * (72 / 96))

    if not fontsCache[font] then
        fontsCache[font] = {}
    end

    if not fontsCache[font][size] then
        fontsCache[font][size] = isLocal and dxCreateFont("assets/fonts/" .. font .. ".ttf", size, ...) or exports.crp_assets:getFont(font, size, ...)
    end

    return fontsCache[font][size] or "default"
end

function isCursorOnElement (x, y, w, h)
    if isCursorShowing () then
        local cursor = {getCursorPosition ()}
        local mx, my = cursor[1] * screen[1], cursor[2] * screen[2]
        return mx > x and mx < x + w and my > y and my < y + h
    end
    return false
end

_dxDrawRectangle = dxDrawRectangle
function dxDrawRectangle (x, y, w, h, ...)
    local x, y, w, h = setScreenPosition (x, y, w, h)
    
    return _dxDrawRectangle (x, y, w, h, ...)
end

_dxDrawImage = dxDrawImage
function dxDrawImage (x, y, w, h, ...)
    local x, y, w, h = setScreenPosition (x, y, w, h)
    
    return _dxDrawImage (x, y, w, h, ...)
end

_dxDrawImageSection = dxDrawImageSection
function dxDrawImageSection (x, y, w, h, ...)
    local x, y, w, h = setScreenPosition (x, y, w, h)
    
    return _dxDrawImageSection (x, y, w, h, ...)
end

_dxDrawText = dxDrawText
function dxDrawText (text, x, y, w, h, ...)
    local x, y, w, h = setScreenPosition (x, y, w, h)
    
    return _dxDrawText (text, x, y, (x + w), (y + h), ...)
end

_isCursorOnElement = isCursorOnElement
function isCursorOnElement (x, y, w, h)
    local x, y, w, h = setScreenPosition (x, y, w, h)

    return _isCursorOnElement (x, y, w, h)
end

local lastTick = 0
local clearTimer = false
local roundedRectangles = {}

function dxDrawRoundedRectangle(x, y, w, h, radius, ...)
    if (not radius or radius < 1) then
        return dxDrawRectangle(x, y, w, h, ...)
    end

    w = (w > 1) and w or 1
    h = (h > 1) and h or 1

    local identify = ("%d_%d_%d"):format(radius, w, h)
    if (not roundedRectangles[identify]) then
        roundedRectangles[identify] = svgCreate(w, h, [[
            <svg width="]] .. w .. [[" height="]] .. h .. [[">
                <rect x="0" y="0" width="]] .. w .. [[" height="]] .. h .. [[" rx="]] .. radius .. [[" ry="]] .. radius .. [[" fill="white" />
            </svg>
        ]])
    end

    if (not clearTimer) then
        clearTimer = setTimer(function() -- free memory
            if ((getTickCount() - lastTick) > 1000) then
                for _, svg in pairs(roundedRectangles) do
                    destroyElement(svg)
                end

                killTimer(sourceTimer)
                clearTimer = false
                roundedRectangles = {}
            end
        end, 1000, 0)
    end

    lastTick = getTickCount()

    local blend = dxGetBlendMode()
    dxSetBlendMode("modulate_add")
        dxDrawImage(x, y, w, h, roundedRectangles[identify], ...)
    dxSetBlendMode(blend)
end

function createEvent (event, ...)
    addEvent(event, true)
    addEventHandler(event, ...)
end

function formatTime ( sec )
    local minutos, segundos = math.modf(sec/60)
    segundos = segundos*60
    return string.format("%02d:%02d", minutos, segundos)
end