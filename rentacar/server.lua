-- SparroW MTA Script Sitemiz  : https://sparrow-mta.blogspot.com
-- Discord Adresimiz : https://discord.gg/89V5vN8
-- İyi oyunlar...
marker = {}
tableOwner = {}
timers = {}
playerMarker = {}

addEventHandler ("onResourceStart", resourceRoot, function()
for i, data in pairs (pos) do
	marker[i] = createMarker (data["rentPlace"][1], data["rentPlace"][2], data["rentPlace"][3], "cylinder", 1.5, 125, 231, 123)
	addEventHandler ("onMarkerHit", marker[i], hitMarker)
end
end)

function hitMarker (el)
if getElementType (el) == "player" then
	if isPedInVehicle (el) then return end
	triggerClientEvent (el, "showWin", el)
	playerMarker[el] = source
end
end

function startRentCar (id, name, costCar, typeButton, hour, minute)
if not carAcceptRent (source) then outputChatBox ("Zaten kiralık bir araca sahipsiniz !", source, 255, 0, 0) return end
if typeButton then
	local timer
	local cost
	if typeButton == 1 then
		timer = 1000*60*30
		cost = 0.5
	elseif typeButton == 2 then
		timer = 1000*60*60
		cost = 1
	elseif typeButton == 3 then
		timer = 1000*60*120
		cost = 2
	end
	if getPlayerMoney (source) >= costCar then
		createCar (id, source, timer)
		takePlayerMoney (source, costCar)
	else
		outputChatBox ("Yetersiz bakiye!", source, 255, 0, 0)
	end
else
	local timer = 0
	local cost
	if hour then
		timer = timer + 1000*60*60*hour
	end
	if minute then
		timer = timer + 1000*60*minute
	end
	if getPlayerMoney (source) >= costCar then
		createCar (id, source, timer)
		takePlayerMoney (source, costCar)
	else
		outputChatBox ("Yetersiz para!", source, 255, 0, 0)
	end
end
end
addEvent ("startRentCar", true)
addEventHandler ("startRentCar", root, startRentCar)


function stopRentCar ()
local veh = getVehicleOwnedPlayer (source)
if not veh then outputChatBox ("Kiralık bir aracın yok!", source, 255, 0, 0) return end
tableOwner[veh] = nil
timers[veh] = nil
destroyElement (veh)
outputChatBox ("Kiralık bir aracı teslim ettiniz !", source, 0, 255, 0)
end
addEvent ("stopRentCar", true)
addEventHandler ("stopRentCar", root, stopRentCar)

addEventHandler ("onVehicleStartEnter", root, function(pl, seat)
if seat == 0 and tableOwner[source] and tableOwner[source] ~= pl and not canPlayerUseCar then
	cancelEvent ()
	outputChatBox ("Bu araba bir oyuncu tarafından kiralandı. #FFCC00"..string.gsub (getPlayerName (tableOwner[source]), "#%x%x%x%x%x%x", ""), pl, 255, 0, 0, true)
end
end)

function createCar (id, pl, timeRent)
local pos = getCarPlaceFromMarker (pl)
local veh = createVehicle (id, pos)
if not color then
	color = {math.random (255), math.random (255), math.random (255)}
end
setVehicleColor (veh, color[1], color[2], color[3])
tableOwner[veh] = pl
outputChatBox ("Bir araba kiraladınız "..secondsToTimeDesc(timeRent / 1000), pl, 0, 255, 0)
timers[veh] = setTimer (stopRentCar, timeRent, 1, veh)
local num
if not number then return end
if not numberGTA then
	if not reg then
		num = smb[math.random(#smb)]..math.random(999)..smb[math.random(#smb)]..smb[math.random(#smb)]..regru[math.random(#regru)]
	else
		num = smb[math.random(#smb)]..math.random(999)..smb[math.random(#smb)]..smb[math.random(#smb)]..reg
	end
	setElementData (veh, "numberType", "ru")
	setElementData (veh, "number:plate", num)
else
	num = generateString (8)
	setVehiclePlateText (veh, num)
end
setVehicleDamageProof(veh, canVehicleDamageProof)
end


function generateString ( len )
    local allowed = { { 48, 57 }, { 65, 90 }, { 97, 122 } }
    if tonumber ( len ) then
        math.randomseed ( getTickCount () )
        local str = ""
        for i = 1, len do
            local charlist = allowed[math.random ( 1, 3 )]
            str = str .. string.char ( math.random ( charlist[1], charlist[2] ) )
        end
        return str
    end
    return false   
end

function stopRentCar (veh)
destroyElement (veh)
outputChatBox ("Kiralık araç hizmeti sona erdi !", tableOwner[veh], 255, 0, 0)
tableOwner[veh] = nil
end

function carAcceptRent (pl)
for veh, player in pairs (tableOwner) do
	if player == pl then
		return false
	end
end
return true
end

function getCarPlaceFromMarker (pl)
local mark = playerMarker[pl]
if not mark then
mark = getMarkerPlayer (pl)
end
for i, data in pairs (marker) do
	if data == mark then
		return Vector3 (pos[i]["createCar"][1], pos[i]["createCar"][2], pos[i]["createCar"][3])
	end
end
end

function getMarkerPlayer (el)
for i, v in ipairs (getElementsByType ("marker")) do
	if isElementWithinMarker (el, v) then
		return v
	end
end
return false
end

function getVehicleOwnedPlayer (pl)
for veh, player in pairs (tableOwner) do
	if player == pl then
		return veh
	end
end
return false
end

function secondsToTimeDesc( seconds )
	if seconds then
		local results = {}
		local sec = math.floor ( ( seconds % 60 ) )
		local min = math.floor ( ( seconds % 3600 ) /60 )
		local hou = math.floor ( ( seconds % 86400 ) /3600 )
		local day = math.floor ( seconds /86400 )
		
		if day > 0 then table.insert( results, day .. ( day == 1 and " Gün" or " Gün" ) ) end
		if hou > 0 then table.insert( results, hou .. ( hou == 1 and " Saat" or " Saat" ) ) end
		if min > 0 then table.insert( results, min .. ( min == 1 and " Dakika" or " Dakika" ) ) end
		if sec > 0 then table.insert( results, sec .. ( sec == 1 and " Saniye" or " Saniye" ) ) end
		
		return string.reverse ( table.concat ( results, ", " ):reverse():gsub(" ,", " и ", 1 ) )
	end
	return ""
end

smb = {
	'A',
	'B',
	'C',
	'Y',
	'O',
	'P',
	'T',
	'E',
	'X',
	'M',
	'H',
	'K'
}

regru = { 
'01',
'02', 
'03', 
'04', 
'05',  
'06', 
'07', 
'09',  
'10',  
'11',  
'12',  
'13',  
'14',  
'15',  
'16',  
'17',  
'18',  
'19',  
'20',  
'21',  
'22',  
'23',  
'24',  
'25',  
'26',  
'27',  
'28',  
'29',  
'30',  
'31',  
'32',  
'33',  
'34',  
'35',  
'36',  
'37',  
'38',  
'39',  
'40',  
'41',  
'42',  
'43',  
'44',  
'45',  
'46',  
'47',  
'48',  
'49',  
'50',  
'51',  
'52',  
'53',  
'54',  
'55',  
'56',  
'57',  
'58',  
'59',  
'60',  
'61',  
'62',  
'63',  
'64',  
'65',  
'66',  
'67',  
'68',  
'69',  
'70',  
'71',  
'72',  
'73',  
'74',  
'75',  
'76',  
'77',  
'78',  
'79',   
'80',   
'81',   
'82',   
'83',   
'84',   
'85',   
'86',   
'87',   
'88',   
'89',   
'90',     
'93',     
'95',   
'96',   
'97',   
'98',   
'99',   
'777',   
'178',   
'126',   
'123',   
'116',   
'161',
'150',
'176', 
'197',
'177',
'186',
'716',
'50',
'134',
'799',
}