local functions = {}
local resource = {
    timer = {},
    timer2 = {},
    morto = false,
    respawn = false,
    painel = false
}
local font_title = exports.crp_assets:getFont('inter-bold', 20, false)
function math.round(num, decimals)
    decimals = math.pow(10, decimals or 0)
    num = num * decimals
    if num >= 0 then num = math.floor(num + 0.5) else num = math.ceil(num - 0.5) end
    return num
end


local pressStartTimer = false
functions.cancelDamage = function()
    if getElementData(localPlayer, 'player >> caido') then 
        cancelEvent()
    end
end
addEventHandler('onClientPlayerDamage', localPlayer, functions.cancelDamage)

functions.stealthKill = function(targetPlayer)
    cancelEvent() 
end
addEventHandler("onClientPlayerStealthKill", root, functions.stealthKill)

functions.render = function()
    dxDrawImage(0, 0, 1920, 1080, 'archives/assets/imgs/background.png', 0, 0, 0, tocolor(255, 255, 255, 255))
    if resource.morto then
        local timer = math.round(getTimerDetails(resource.timer[localPlayer])/1000)
        dxDrawText('#FFFFFFRespawn available after #8CDD8D'..formatTime ( timer )..' seconds', 655, 744-50, 603, 19, tocolor(255, 255, 255, 0.7*255), 0.5, font_title, 'center', 'center', false, false, false, true)
    elseif resource.respawn then

        dxDrawText('#FFFFFFPress #8CDD8D[G] #FFFFFFto send help signal', 837, 758-50, 337, 18, tocolor(255, 255, 255, 0.7*255), 0.5, font_title, 'center', 'center', false, false, false, true)
        dxDrawText('#FFFFFFPress #8CDD8D[E] #FFFFFFfor 3 seconds to respawn', 816, 812-50, 388, 18, tocolor(255, 255, 255, 0.7*255), 0.5, font_title, 'center', 'center', false, false, false, true)
        local timer = math.round(getTimerDetails(resource.timer[localPlayer])/1000)
        dxDrawText('#FFFFFFBrain death in #D83A43'..formatTime ( timer )..' seconds', 845, 785-50, 348, 18, tocolor(255, 255, 255, 0.7*255), 0.5, font_title, 'center', 'center', false, false, false, true)
   
    else
        local timer = math.round(getTimerDetails(resource.timer[localPlayer])/1000)
        dxDrawText('#FFFFFFYou will bleed to death in #D83A43'..formatTime ( timer )..' seconds', 655, 744-50, 603, 19, tocolor(255, 255, 255, 0.7*255), 0.5, font_title, 'center', 'center', false, false, false, true)
    end
end

functions.callEms = function(key, press, player)
    triggerServerEvent('callEms : Medic', localPlayer)
end

functions.respawn = function()
    removeEventHandler('onClientRender', root, functions.render)
    unbindKey('g', 'down', functions.callEms)
    unbindKey("e", "down", functions.onKeyPressE)
    unbindKey("e", "up", functions.onKeyReleaseE)
    if isTimer(resource.timer[localPlayer]) then
        killTimer(resource.timer[localPlayer])
        resource.timer[localPlayer] = nil
    end
    resource = {
        timer = {},
        timer2 = {},
        morto = false,
        respawn = false,
        painel = false
    }
    setElementData(localPlayer, 'KeyBlocked', false)
    toggleAllControls(true)
    triggerServerEvent('medic >> spawn', localPlayer, localPlayer)
end

functions.onKeyPressE = function()
    if not pressStartTimer then
        pressStartTimer = setTimer(function()
            functions.respawn()
            pressStartTimer = nil
        end, 3000, 1)
    end
end

functions.onKeyReleaseE = function()

    if pressStartTimer then
        killTimer(pressStartTimer)
        pressStartTimer = nil
    end
end

functions.show = function()
    if not resource.painel then 
        resource.morto = false
        addEventHandler('onClientRender', root, functions.render)
        resource.painel = true
        toggleAllControls(false)
        resource.timer[localPlayer] = setTimer(function()
            resource.morto = true
            resource.timer[localPlayer] = setTimer(function()
                resource.respawn = true
                resource.morto = false
                bindKey('g', 'down', functions.callEms)
                bindKey("e", "down", functions.onKeyPressE)
                bindKey("e", "up", functions.onKeyReleaseE)
                resource.timer[localPlayer] = setTimer(function()
                    removeEventHandler('onClientRender', root, functions.render)
                    resource.painel = false
                    resource.morto = false
                    resource.respawn = false
                    setElementData(localPlayer, 'KeyBlocked', false)
                    toggleAllControls(true)
                    triggerServerEvent('medic >> spawn', localPlayer, localPlayer)
                    if isTimer(resource.timer[localPlayer]) then
                        killTimer(resource.timer[localPlayer])
                        resource.timer[localPlayer] = nil
                    end
                end, 60000*HOSPITAL.tempFulDie, 1)
            end, 60000*HOSPITAL.tempRespawn, 1)
        end, 60000*HOSPITAL.tempDie, 1)
    else
        removeEventHandler('onClientRender', root, functions.render)
        toggleAllControls(true)
        if isTimer(resource.timer[localPlayer]) then
            killTimer(resource.timer[localPlayer])
            resource.timer[localPlayer] = nil
        end
        resource = {
            timer = {},
            timer2 = {},
            morto = false,
            respawn = false,
            painel = false
        }
        setElementData(localPlayer, 'player >> caido', false)
    end
end
addEvent('medic >> open', true)
addEventHandler('medic >> open', root, functions.show)

blood = {}

addEvent('createBlood', true)
addEventHandler('createBlood', root, function(element, x, y, z, rz)
	if blood[element] and isElement(blood[element]) then
        destroyElement(blood[element])
        blood[element] = nil
	end
    blood[element] = createEffect("blood_heli", x, y, z+0.5, 0, 0, rz, 4, true)
end)