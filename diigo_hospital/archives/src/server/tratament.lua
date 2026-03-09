local resource = {
    Objects = {},
    Markers = {},
    Macas = {},
    Timer = {}
}
local functions = {}

for i, v in pairs(HOSPITAL.Tratament.Objects) do
    resource.Objects[i] = createObject(v[1], v[2], v[3], v[4], v[5], v[6], v[7]);
    setElementAlpha(resource.Objects[i], 0)
end

for i,v in pairs(HOSPITAL.Tratament.Markers) do
    resource.Markers[i] = createMarker(v[1], v[2], v[3] - 1, 'cylinder', 1.5, 255, 255, 255, 0)
    setElementData(resource.Markers[i], 'hospital', i)
end

addEventHandler('onMarkerHit', resourceRoot, function(element)
    if getElementType(element) == 'player' then 
        triggerClientEvent(element, 'c_core:drawText', element, '[E] Start treatment')
        bindKey(element, 'e', 'down', iniciarTratamento, source)
    end
end)

addEventHandler('onMarkerLeave', resourceRoot, function(element)
    if getElementType(element) == 'player' then 
        triggerClientEvent(element, 'c_core:hideText', element)
        unbindKey(element, 'e', 'down', iniciarTratamento)
    end
end)

iniciarTratamento = function (player, b, s, hitMarker)
    triggerClientEvent(player, 'c_core:setTextKeyPressed', player)
        local hospital = getElementData(hitMarker, 'hospital')
        if getElementHealth(player) == 100 then return exports.crp_notify:addBox(player, 'You dont need treatment', 'info') end
        if exports.crp_inventory:getItem(player, 'dinheiro') >= HOSPITAL.Tratament.price then
            for i,v in ipairs(HOSPITAL.Tratament.Positions[hospital]) do
                if not resource.Macas[hospital] then 
                    resource.Macas[hospital] = {}
                end
                if not resource.Macas[hospital][i] then 
    				exports.crp_inventory:takeItem(player, 'dinheiro', HOSPITAL.Tratament.price)
                    resource.Macas[hospital][i] = true
                    setElementPosition(player, v[1], v[2], v[3])
                    setElementRotation(player, v[4], v[5], v[6])
                    setPedAnimation(player, 'CRACK', 'crckidle2', -1, true, false, false, false)
                    local currentHealth = getElementHealth(player)
                    local healthNeeded = 100 - currentHealth
                    local iterations = math.ceil(healthNeeded / 6)  -- NC:mer
                    local totalTime = iterations * HOSPITAL.Tratament.time * 1000  -- Dur
                    triggerClientEvent(player, 'ProgressBar', player, totalTime)  -- Ajustando 
                    resource.Timer[player] = setTimer(function()
                        if getElementHealth(player) < 100 then 
                            setElementHealth(player, getElementHealth(player) + 5)
                        else
                            killTimer( resource.Timer[player])
                            setCameraTarget(player)
                            setPedAnimation(player)
                            resource.Macas[hospital][i] = nil
                            setElementData(player, 'Sangrando', false)
                        end
                    end, 1000*HOSPITAL.Tratament.time, 0)
                    break
                end 
            end
        else
            exports.crp_notify:addBox(player, 'You need $'..HOSPITAL.Tratament.price..' to start treatment.', 'error')
        end
end

addEvent('interaction >> iniciartratamento', true)
addEventHandler('interaction >> iniciartratamento', root, function(player, element)
    if not resource.Timer[element] then 
        if getElementHealth(element) == 100 then return exports.crp_notify:addBox(element, 'Patient does not need treatment .', 'error') end
        exports.crp_notify:addBox(element, 'The doctor started his treatment', 'success')
        exports.crp_notify:addBox(player, 'Patient treatment initiated.', 'success')
        local currentHealth = getElementHealth(element)
        local healthNeeded = 100 - currentHealth
        local iterations = math.ceil(healthNeeded / 6)  -- NC:mero de iteraC'C5es necessC!rias
        local totalTime = iterations * HOSPITAL.Tratament.time * 1000  -- 
        triggerClientEvent(element, 'ProgressBar', element, totalTime)  -- Aj
        triggerClientEvent(player, 'ProgressBar', player, 1000 * 5)  -- Ajustando
        setPedAnimation(player, 'int_shop', 'shop_loop', -1, false, false, false, false)
        toggleAllControls(player, false)
        setElementData(element, 'Tratamento', true)
        
        setTimer(function()
            toggleAllControls(player, true)
            setPedAnimation(player)
        end, 1000 * 5, 1)
        toggleAllControls(element, false, true, false)
        resource.Timer[element] = setTimer(function()
            if getElementHealth(element) < 100 then 
                setElementHealth(element, getElementHealth(element) +5)
            else
                toggleAllControls(element, true)
                setPedAnimation(player)
                setPedAnimation(element)
                exports.crp_notify:addBox(element, 'Treatment completed.', 'success')
                setElementData(element, 'Sangrando', false)
                setElementData(element, 'Tratamento', false)
                killTimer( resource.Timer[element])
                resource.Timer[element] = nil
            end
        end, 1000*HOSPITAL.Tratament.time, 0)
    end
end)

addEventHandler("onPlayerQuit", root, function()
    if resource.Timer[source] then 
        killTimer( resource.Timer[source])
        resource.Timer[source] = nil
    end
end)

setTimer(function()
    for i,v in ipairs(getElementsByType('player')) do 
        if getElementData(v, 'Sangrando') then 
            setElementHealth(v, getElementHealth(v)-1)
            exports.crp_notify:addBox(v, 'You are bleeding. Go to the hospital immediately.', 'error')
            local x, y, z = getElementPosition(v)
            triggerClientEvent(root, 'createBlood', root, v, x, y, z, 0)
        end
    end
end, 60000, 0)

addEvent('callEms : Medic', true)
addEventHandler('callEms : Medic', root, function()
    if client then
        exports.crp_police:call(client, 'medic', 'Death', {getElementPosition(client)}, 'paramedic >> duty', {
            ['Sent by'] = getPlayerName(client),
            ['Description'] = 'Unconscious',
        })
    end
end)