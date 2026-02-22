-- client.lua

function onCheatDetected()
    local playerName = getPlayerName(localPlayer) 
    triggerServerEvent("VisionXGuard:banPlayer", resourceRoot, playerName)
end

addEvent("cheatDetectedEvent", true)
addEventHandler("cheatDetectedEvent", root, onCheatDetected)


addCommandHandler("testcheat", function()
    triggerEvent("cheatDetectedEvent", localPlayer)
end)
