local db = dbConnect('sqlite', 'data.db')
dbExec(db, 'CREATE TABLE IF NOT EXISTS players_caido (id)')

local functions = {}
local resource = {
    medical_bagObj = {},
    medical_bagFloor = {},
    medical_stretcher = {},
}

function createDiscordLogs(title, description, link)
    local data = {
        embeds = {
            {
                ["color"] = 2829617,
                ["title"] = title,
                
                ["description"] = description,
                
                ['thumbnail'] = {
                    ['url'] = "",
                },

                ["footer"] = {
                    ["text"] = "Numidia Roleplay",
                    ['icon_url'] = ""
                },
            }
        },
    }

    data = toJSON(data);
    data = data:sub(2, -2);
    fetchRemote(link, {["queueName"] = "logs", ["connectionAttempts"] = 5, ["connectTimeout"] = 5000, ["headers"] = {["Content-Type"] = "application/json"}, ['postData'] = data}, function() end);
end

functions.revive = function(element)
    triggerClientEvent(element, 'medic >> open', resourceRoot)
    --spawnPlayer(element, pos.x, pos.y, pos.z, 0, getElementModel(element), getElementInterior(element), getElementDimension(element))
    setElementHealth(element, 70)
    setCameraTarget(element)
    setElementData(element, 'player >> caido', false)
    setElementData(element, 'KeyBlocked', false)
    setPedAnimation(element)
    dbExec(db, 'DELETE FROM players_caido WHERE id = ?', getElementData(element, 'ID'))
    toggleAllControls(element, true)
end

functions.kill = function(player)
    if isGuestAccount(getPlayerAccount(player)) then return end
    cancelEvent()
    local pos = Vector3(getElementPosition(player))
    spawnPlayer(player, pos.x, pos.y, pos.z, 0, getElementModel(player), getElementInterior(player), getElementDimension(player))   
    setElementHealth(player, 1)
    local pos = Vector3(getElementPosition(player))
    triggerClientEvent(player, 'medic >> open', player)
    setElementData(player, 'player >> caido', true)
    setElementData(player, 'Sangrando', false)
    setElementPosition(player, pos.x, pos.y, pos.z)
    --setCameraMatrix(player, pos.x + 3.5, pos.y, pos.z + 1, pos.x + 0.4, pos.y + 0.4, pos.z, 0, 90)
    setElementData(player, 'KeyBlocked', true)
    triggerClientEvent(player, 'fecharInventario', player)
    triggerClientEvent(player, 'managePhone', player, 'close')
    exports.crp_weapons:desequiparArma(player, getElementData(player, 'Arma-Equipada'))
    --setTimer(function() triggerClientEvent(root, 'onSetAnimationIFP', player, player, {'newAnims', 'baleado2', -1, false, false, false}) end, 2000, 1)
    setTimer(setPedAnimation, 2000, 1, player, 'CRACK', 'crckidle2', 1, false, true, false, true)
    toggleAllControls(player, false)
end

functions.onKill = function(ammo, killer, weapon)
    if not getElementData(source, 'player >> caido') then 
        if getPedOccupiedVehicle(source) then
            removePedFromVehicle(source)
        end
        functions.kill(source)    
        if killer and getElementType(killer) == 'player' then
            createDiscordLogs('KILL', 'The player ' .. getPlayerName(killer) .. ' killed ' .. getPlayerName(source)..'.', 'https://discord.com/api/webhooks/1339920124152643737/kpsK-C7O-JJfaqHgA59Pz7BbPnD6TdRUDaVkEfDFVcSzV1RQLGxcGClxUszOYckw6wtF' )
        else
            createDiscordLogs('KILL', 'The player ' .. getPlayerName(source) .. ' Died alone.', 'https://discord.com/api/webhooks/1339920124152643737/kpsK-C7O-JJfaqHgA59Pz7BbPnD6TdRUDaVkEfDFVcSzV1RQLGxcGClxUszOYckw6wtF' )
        end
    end
end
addEventHandler('onPlayerWasted', root, functions.onKill)

functions.getMedicalBag = function(player, element)
    if player then
        if (resource.medical_bagObj[player] and isElement(resource.medical_bagObj[player])) then 
            if not resource.medical_bagFloor[player] then

                setPedAnimation(player, 'int_shop', 'shop_loop', -1, false, false, false)

                setTimer(function(player)
                    toggleControl(player, 'fire', true)
                    setPedAnimation(player)
                    destroyElement(resource.medical_bagObj[player])
                    resource.medical_bagObj[player] = nil
                    resource.medical_bagFloor[player] = nil
                end, 1000, 1, player)

            --else

            end

        else

            setPedAnimation(player, 'int_shop', 'shop_loop', -1, false, false, false)
            setTimer(function(player)
                toggleControl(player, 'fire', false)
                setPedAnimation(player)
                resource.medical_bagObj[player] = createObject(HOSPITAL.Object.Id, 0, 0, 0)
                exports.pAttach:attach(resource.medical_bagObj[player], player, unpack(HOSPITAL.Object.config))
                setObjectScale(resource.medical_bagObj[player], HOSPITAL.Object.Scale)
                resource.medical_bagFloor[player] = false
            end, 1000, 1, player)

        end
    end
end
addEvent('medical >> getBag', true)
addEventHandler('medical >> getBag', root, functions.getMedicalBag)


functions.getFloorBag = function(player)
    if player then
        if (resource.medical_bagObj[player] and isElement(resource.medical_bagObj[player])) then 
            local pos = Vector3(getElementPosition(player))
            local posobj = Vector3(getElementPosition(resource.medical_bagObj[player]))
            local rot = Vector3(getElementRotation(player))
            if not resource.medical_bagFloor[player] then
                setPedAnimation(player, 'bomber', 'bom_plant', -1, false, false, false)
                setTimer(function(player)
                    exports.pAttach:detach(resource.medical_bagObj[player], player)
                    setElementPosition(resource.medical_bagObj[player], pos.x+0.5, pos.y, pos.z-1)
                    setElementRotation(resource.medical_bagObj[player], rot.x, rot.y, rot.z)
                    resource.medical_bagFloor[player] = true
                    setPedAnimation(player)
                end, 1000, 1, player)
            else
                if getDistanceBetweenPoints3D(pos.x, pos.y, pos.z, posobj.x, posobj.y, posobj.z) <= 2 then
                    setPedAnimation(player, 'bomber', 'bom_plant', -1, false, false, false)
                    setTimer(function(player)
                        resource.medical_bagFloor[player] = false
                        exports.pAttach:attach(resource.medical_bagObj[player], player, unpack(HOSPITAL.Object.config))
                        setPedAnimation(player)
                    end, 1000, 1, player)
                else
                    return exports.crp_notify:addBox(player, 'You are too far from the backpack.', 'error')
                end
            end
        end
    end
end
addEvent('medical >> bagInFloor', true)
addEventHandler('medical >> bagInFloor', root, functions.getFloorBag)

functions.blockBag = function(player)
    if getElementType(player) == 'player' then
        if resource.medical_bagObj[player] and isElement(resource.medical_bagObj[player]) then
            exports.crp_notify:addBox(player, 'Your bag is not in the car.', 'error')
            cancelEvent()
        end
    end
end
addEventHandler('onVehicleStartEnter', root, functions.blockBag)

functions.ondestroy = function()
    for player, obj in pairs(resource.medical_bagObj) do
        if obj and isElement(obj) then
            if source == obj then
                resource.medical_bagObj[player] = nil
                resource.medical_bagFloor[player] = nil
                exports.crp_notify:addBox(player, "His medical bag went to the car.", "info")
            end
        end
    end
end
addEventHandler('onElementDestroy', root, functions.ondestroy)

functions.onQuitDestroy = function()
    local player = source
    if resource.medical_bagObj[player] then
        resource.medical_bagObj[player] = nil
        resource.medical_bagFloor[player] = nil
    end

    if getElementData(player, 'player >> caido') then 
        dbExec(db, 'INSERT INTO players_caido VALUES (?)', getElementData(player, 'ID'))
    end
end
addEventHandler('onPlayerQuit', root, functions.onQuitDestroy)

addEventHandler('onPlayerLogin', root, function()
    setTimer(function(player)
        local result = dbPoll(dbQuery(db, 'SELECT * FROM players_caido WHERE id = ?', getElementData(player, 'ID')), -1)
        if #result > 0 then 
            dbExec(db, 'DELETE FROM players_caido WHERE id = ?', getElementData(player, 'ID'))
            functions.kill(player)
        end
    end, 5000, 1, source)
end)
-- Exports

isMedicalBag = function(player)
    if player then
        if (resource.medical_bagObj[player] and isElement(resource.medical_bagObj[player])) then 
            return true
        else
            return false
        end
    end
end

isMedicalBagInFloor = function(player)
    if player then
        if (resource.medical_bagFloor[player]) then
            return true
        else
            return false
        end
    end
end

savesMedic = function(player, element)
    if player then
        if isGuestAccount(getPlayerAccount(player)) then return end
        if isGuestAccount(getPlayerAccount(element)) then return end
        if not isObjectInACLGroup('user.'..getAccountName(getPlayerAccount(player)), aclGetGroup('Admin')) then return end -- Paramedic
        if (resource.medical_bagObj[player] and isElement(resource.medical_bagObj[player])) then
            if (resource.medical_bagFloor[player]) then
                local pos = Vector3(getElementPosition(player))
                local posObj = Vector3(getElementPosition(resource.medical_bagObj[player]))
                if getDistanceBetweenPoints3D(pos.x, pos.y, pos.z, posObj.x, posObj.y, posObj.z) <= 3 then
                    if getElementData(element, 'player >> caido') then 
                        setPedAnimation(player, 'MEDIC', 'CPR', -1, false, true, false)
                        setTimer(function()
                            local randomNumber = math.random(1, 5)
                            if randomNumber == 2 then
                                return exports.crp_notify:addBox(player, 'Unable to restore the patient heart rhythm, please try again.', 'error')
                            else
                                setPedAnimation(player)
                                functions.revive(element)
                            end
                        end, (1000 * 8), 1)
                    end
                else
                    return exports.crp_notify:addBox(player, 'Your bag is too far away.', 'error')
                end
            else
                return exports.crp_notify:addBox(player, 'Place your bag on the floor.', 'error')
            end
        else
            return exports.crp_notify:addBox(player, 'You are without your medical bag, take it in your car.', 'error')
        end
    end
end

function killedSpawn ()
    if client then
        fadeCamera (client, false)
        setPlayerMoney(client, 0)
        if not getElementData(client, 'Preso') then
            setTimer(spawnPlayer, 2000, 1, client, 1157.924, -1346.148, 15.414, 275, getElementModel(client))
        else
            setTimer(spawnPlayer, 2000, 1, client, -613.71545410156,-519.23028564453,25.534187316895, 0, getElementModel(client))
        end
        setElementData(client, 'fome', 100)
        setElementData(client, 'Stress', 0)
        setElementData(client, 'sede', 100)
        setElementData(client, 'player >> caido', false)
        setElementData(client, 'KeyBlocked', false)
        setCameraTarget(client)
        exports.crp_weapons:desequiparArma(client, getElementData(client, 'Arma-Equipada'))
        setTimer(fadeCamera, 5000, 1, client, true)
    end
end
addEvent('medic >> spawn', true)
addEventHandler('medic >> spawn', root, killedSpawn)

function savePlayer (player)
    if getElementData(player, 'player >> caido') then
        functions.revive(player)
    end
end

function onStealthKill(targetPlayer)
    cancelEvent() 
end
addEventHandler("onPlayerStealthKill", root, onStealthKill)

function createDiscordLogs(title, description, link)
    local data = {
        embeds = {
            {
                ["color"] = 2829617,
                ["title"] = title,
                
                ["description"] = description,
                
                ['thumbnail'] = {
                    ['url'] = "",
                },

                ["footer"] = {
                    ["text"] = "Numidia Roleplay",
                    ['icon_url'] = ""
                },
            }
        },
    }

    data = toJSON(data);
    data = data:sub(2, -2);
    fetchRemote(link, {["queueName"] = "logs", ["connectionAttempts"] = 5, ["connectTimeout"] = 5000, ["headers"] = {["Content-Type"] = "application/json"}, ['postData'] = data}, function() end);
end