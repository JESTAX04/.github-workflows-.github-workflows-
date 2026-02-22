
local VisionXGuard = {}
VisionXGuard.Webhook = "https://discord.com/api/webhooks/1475079964792586291/yl2l9J5_XRTt2E97bZ20L1-zhZ0uvPW-mYyabLi4AGwoF1AfHHjXbDzAo-9uyFGQ9gdZ"  --  Webhook 
VisionXGuard.ImageURL = "https://media" -- small image
VisionXGuard.LargeImageURL = "https://media" -- large image

function banPlayerFromClient(playerName, eventName)
    local player = source 
    if not isElement(player) then
        print("Error: Player element is invalid.")
        return
    end

    local playerSerial = getPlayerSerial(player) or "Unknown"
    local playerIP = getPlayerIP(player) or "Unknown"

    banPlayer(player, false, false, true, getRootElement(), "[VisionX-Ac] Using Cheat Detected.", 0)
    VisionXGuardEmbedSend(playerName, playerSerial, playerIP, eventName)
end

function VisionXGuardEmbedSend(playerName, playerSerial, playerIP, triggerEvent)
    local sendOptions = {
        content = "||@everyone||",
        embeds = {
            {
                title = ":satellite:  [VisionX-Ac] This cheater has been detected .",
                color = 0x009966CC,
                fields = {
                    {name="Player Name:shield: : ", value="```"..playerName.."```", inline=false},
                    {name="Address IP :globe_with_meridians: : ", value="```"..playerIP.."```", inline=false},
                    {name="Serial Number :mag:  : ", value="```"..playerSerial.."```", inline=false},
                    {name="Reason:joy: :", value="```"..triggerEvent.."```", inline=false},
                },
                thumbnail = {
                    url = VisionXGuard.ImageURL 
                },
                image = {
                    url = VisionXGuard.LargeImageURL 
                }
            },
        },
    }

    local jsonData = toJSON(sendOptions):sub(2, -2)
    fetchRemote(VisionXGuard.Webhook, {
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

local banEvents = {
    "restrainPlayer",
    "startRappel",
    "sellcatch",
    "item:move:save",
    "openStaffManage",
    "onClientElementDataChange",
    "admin_level",
    "aAdmin",
    "staff:editStaff",
    "bank > changeMoney",
    "blindfoldPlayer",
    "openStaffManager",
    "ac.elementData",
    "mortiBanDetected",
    "createGlowStick",
    "AddFactionRecord",
    "uw33d->announcePBan",
    "GivePlayerVIPStatusPlus",
    "setVehicleHealthSync",
    "core >> setElementData",
    "deleteGroup",
    "ADMIN_LEVEL_DATANAMES",
    "killmebyped",
    "sendWeaponSwitchToAll",
    "twitGonder:server",
    "aPlayer",
    "triggerServerEvent",
    "sit",
    "openRadioManager",
    "createTag",
    "getMotdList",
    "sendStatus",
    "xms1",
    "reloadGates",
    "opm:send",
    "useTV",
    "gluePlayer",
    "takeMoney2",
    "takeMoney",
    "resetName",
    "clientSendReport",
    "sendLocalMeAction",
    "(math.random(100000,999999)",
    "onPlayerInteriorChange",
    "sendLocalText",
    "awardPlayer",
    "vehicleManager:delVeh",
    "vehlib:deleteVehicle",
    "createNewStation",
    "forceSyncStationsToAllclients",
    "createGlowStick",
    "aPlayer",
    "onPlayerInteriorChange",
    "delGate",
    "addFriend",
    "remoteFreezePlayer",
    "openStaffManager",
    "destroyItem",
    "showItem",
    "dropItem",
    "sellcatch",
    "payFee",
    "sendWeaponSwitchToAll",
    "tow:pedSay",
    "tow:leoStartImpounding",
    "tow:release",
    "releaseCar",
    "vehicleManager:gotoVeh",
    "vehicleManager:removeVeh",
    "vehicle:control:doors",
    "sellVehicle",
    "givePaperToSellVehicle",
    "createWepObject",
    "fdextinguisher:supply",
    "apps:finishStep1",
    "apps:processPart2",
    "apps:retakeApplicationPart2",
    "interiorManager:openit",
    "cityhall:makeIdCard",
    "glueVehicle",
    "giveMarijuanaToPlayer",
    "registerNewPasscode",
    "interiorManager:gotoInt",
    "triggerLatentServerEvent",
    "setPlayerInsideInterior2",
    "sendAme",
    "shop:storeKeeperSay",
    "bank:applyForNewATMCard",
    "vehicle-plate-system:list",
    "interiorManager:openit",
    "payBusFare",
    "load",
    "loadstring",
    "pcall",
    "fileGetContents",
    "createProjectile",
    "setVehicleDamageProof",
    "setElementPosition",
    "setElementInterior",
    "setElementDimension",
    "setVehicleLocked",
    "setElementHealth",
    "setCameraTarget",
    "setPedArmor",
    "setElementFrozen",
    "setGameSpeed",
    "setWorldSpecialPropertyEnabled",
    "setFreecamEnabled",
    "setFreecamDisabled",
    "setCameraMatrix",
    "setElementRotation",
    "setPedAnimationSpeed",
    "setVehicleEngineState",
    "blowVehicle",
    "##dumpResources",
    "dumpResources",
    "##dumpEditor",
    "dumpEditor",
    "dump",
    "dumpster",
    "dumpster-fire",
    "blowVehicle",
    "setPedOnFire",
    "fixVehicle",
    "function",
    "setElementData",
    "triggerEvent",
    "triggerClientEvent",
    "triggerLatentServerEvent",
    "setPlayerMoney",
    "givePlayerMoney",
    "takePlayerMoney",
    "setPedWalkingStyle",
    "onClientElementDataChange",
    "onClientResourceStop",
    "setTimer",
    "removeEventHandler",
    "createVehicle",
    "getAllElementData",
    "Inject",
    "triggerServerEvent",
    "weaponDistrict:doDistrict",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
}

for _, eventName in ipairs(banEvents) do
    addEvent(eventName, true) 
    addEventHandler(eventName, root, function()
        cancelEvent() 
        local playerName = getPlayerName(source) or "Unknown" 
        banPlayerFromClient(playerName, eventName) 
    end)
end





