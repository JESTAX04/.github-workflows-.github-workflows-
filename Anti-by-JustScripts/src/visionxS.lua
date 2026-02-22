-- Webhook Here
local WebhookURL = "https://discord.com/api/webhooks/1475079964792586291/yl2l9J5_XRTt2E97bZ20L1-zhZ0uvPW-mYyabLi4AGwoF1AfHHjXbDzAo-9uyFGQ9gdZ"  -- Webhook 
local ImageURL = "https://media"  -- small image
local LargeImageURL = "https://media" -- large image

function VisionXGuardEmbedSend(playerName, playerSerial, playerIP, triggerEvent)
    local sendOptions = {
        content = "||@everyone||",
        embeds = {
            {
                title = ":satellite:  [VisionX-Ac] This cheater has been detected.",
                color = 0x009966CC,
                fields = {
                    {name="Player Name:shield: : ", value="```"..playerName.."```", inline=false},
                    {name="Address IP :globe_with_meridians: : ", value="```"..playerIP.."```", inline=false},
                    {name="Serial Number :mag:  : ", value="```"..playerSerial.."```", inline=false},
                    {name="Reason:joy: :", value="```"..triggerEvent.."```", inline=false},
                },
                thumbnail = {
                    url = ImageURL 
                },
                image = {
                    url = LargeImageURL 
                }
            },
        },
    }

    local jsonData = toJSON(sendOptions):sub(2, -2)
    fetchRemote(WebhookURL, {
        queueName = "VisionX-AC",
        connectionAttempts = 3,
        connectTimeout = 10000,
        method = "POST",
        headers = {
            ["Content-Type"] = "multipart/form-data",
        },
        formFields = {
            payload_json = jsonData,
        },
    }, function(responseData, response)
        if not response.success then
            print("Response Error:", response.statusCode, responseData)
        end
    end)
end

addEvent("onUnauthorizedGUIFound", true)
addEventHandler("onUnauthorizedGUIFound", resourceRoot, function()
    local player = client 
    if not isElement(player) then return end

    local playerName = getPlayerName(player) or "Unknown"
    local playerSerial = getPlayerSerial(player) or "Unknown"
    local playerIP = getPlayerIP(player) or "Unknown"
    local triggerEvent = "Lua Menu Detected"

    banPlayer(player, false, false, true, getRootElement(), "[VisionX-Ac] Lua Menu Detected.", 0)
    outputChatBox("[VisionX-Ac] Lua Menu Detected for " .. playerName, root, 255, 0, 0)

    VisionXGuardEmbedSend(playerName, playerSerial, playerIP, triggerEvent)
end)
