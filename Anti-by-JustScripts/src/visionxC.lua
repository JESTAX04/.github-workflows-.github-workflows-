
function checkForUnauthorizedGUI()
    local unauthorized = false

    for _, element in ipairs(getElementsByType("gui-button")) do
        local buttonText = guiGetText(element)
        if buttonText == "Reparar" then
            unauthorized = true
            break
        end
    end

    for _, element in ipairs(getElementsByType("gui-button")) do
        local buttonText = guiGetText(element)
        if buttonText == "Revive" then
            unauthorized = true
            break
        end
    end
    
        for _, element in ipairs(getElementsByType("gui-button")) do
        local buttonText = guiGetText(element)
        if buttonText == "Set" then
            unauthorized = true
            break
        end
    end

    for _, element in ipairs(getElementsByType("gui-button")) do
        local buttonText = guiGetText(element)
        if buttonText == "Fly" then
            unauthorized = true
            break
        end
    end

    for _, element in ipairs(getElementsByType("gui-button")) do
        local buttonText = guiGetText(element)
        if buttonText == "Клик" then
            unauthorized = true
            break
        end
    end

        for _, element in ipairs(getElementsByType("gui-button")) do
            local buttonText = guiGetText(element)
            if buttonText == "CLICK FOR INJECT" then
                unauthorized = true
                break
            end
        end

    for _, element in ipairs(getElementsByType("gui-button")) do
        local buttonText = guiGetText(element)
        if buttonText == "Run Code" then
            unauthorized = true
            break
        end
    end

    if unauthorized then
        triggerServerEvent("onUnauthorizedGUIFound", resourceRoot)
        outputChatBox("[VisionX-Ac] Lua Menu Detected.", 255, 0, 0)
    end
end

setTimer(checkForUnauthorizedGUI, 3000, 0)
