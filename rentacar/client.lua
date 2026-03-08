-- SparroW MTA Script Sitemiz  : https://sparrow-mta.blogspot.com
-- Discord Adresimiz : https://discord.gg/89V5vN8
-- İyi oyunlar...
local button = {}
local window = {}
local edit = {}
local radiobutton = {}
local label = {}

window[1] = guiCreateWindow(0.32, 0.38, 0.37, 0.28, "RENT A Car", true)
guiWindowSetSizable(window[1], false)
guiSetVisible (window[1], false)

local gridlist = guiCreateGridList(0.02, 0.10, 0.96, 0.69, true, window[1])
guiGridListAddColumn(gridlist, "ID", 0.1)
guiGridListAddColumn(gridlist, "İsim", 0.6)
guiGridListAddColumn(gridlist, "Saat Fiyatı", 0.2)
button[1] = guiCreateButton(0.02, 0.83, 0.21, 0.12, "Kirala", true, window[1])
button[2] = guiCreateButton(0.25, 0.83, 0.21, 0.12, "Teslim Et", true, window[1])
button[3] = guiCreateButton(0.77, 0.83, 0.21, 0.12, "Kapat", true, window[1])


window[2] = guiCreateWindow(0.70, 0.38, 0.16, 0.21, "Kiralama Süresi", true)
guiWindowSetSizable(window[2], false)
guiSetVisible (window[2], false)

radiobutton[1] = guiCreateRadioButton(0.04, 0.12, 0.92, 0.08, "30 Dakika", true, window[2])
radiobutton[2] = guiCreateRadioButton(0.04, 0.26, 0.92, 0.08, "1 Saat", true, window[2])
radiobutton[3] = guiCreateRadioButton(0.04, 0.40, 0.92, 0.08, "2 Saat", true, window[2])
label[1] = guiCreateLabel(0.04, 0.51, 0.93, 0.11, "Zamanı", true, window[2])
guiLabelSetHorizontalAlign(label[1], "center", false)
edit[1] = guiCreateEdit(0.13, 0.67, 0.27, 0.10, "Saat", true, window[2])
edit[2] = guiCreateEdit(0.60, 0.67, 0.27, 0.10, "Dakika", true, window[2])
button[5] = guiCreateButton(0.51, 0.82, 0.45, 0.13, "Kapat", true, window[2])
button[4] = guiCreateButton(0.04, 0.82, 0.45, 0.13, "Kirala", true, window[2])

addCommandHandler ("rentCar", function ()
guiSetVisible (window[1], not guiGetVisible (window[1]))
showCursor (guiGetVisible (window[1]))
if guiGetVisible (window[1]) then
	writeCars ()
end
end)

function showWin ()
guiSetVisible (window[1], true)
showCursor (true)
if guiGetVisible (window[1]) then
	writeCars ()
end
end
addEvent ("showWin", true)
addEventHandler ("showWin", root, showWin)

function writeCars ()
guiGridListClear (gridlist)
for id, data in pairs (tableCars) do
	local row = guiGridListAddRow (gridlist, id, data[1], data[2].."$")
end
end

local id
local name
local cost
local hour
local minute
local costCar
addEventHandler ("onClientGUIClick", root, function()
if source == button[1] then
	if guiGetVisible (window[2]) then guiSetVisible (window[2], false) return end
	local i = guiGridListGetSelectedItem (gridlist)
	if i == -1 then outputChatBox ("Kiralamak İstediğin Aracı Seç !", 255, 0, 0) return end
	id = guiGridListGetItemText (gridlist, i, 1)
	name = guiGridListGetItemText (gridlist, i, 2)
	cost = string.gsub(guiGridListGetItemText (gridlist, i, 3), "%D", "")
	guiSetVisible (window[2], true)
	guiSetText (edit[1], "Saat")
	guiSetText (edit[2], "Dakika")
elseif source == button[2] then
	triggerServerEvent ("stopRentCar", localPlayer)
elseif source == button[3] then
	guiSetVisible (window[1], false)
	if guiGetVisible (window[2]) then guiSetVisible (window[2], false) end
	showCursor (false)
elseif source == button[4] then
	if guiGetText (edit[1]) == "Saat" and guiGetText (edit[2]) == "Dakika" then
		if not getSelectedRadio () then outputChatBox ("Kiralama süresini seç !", 255, 0, 0) return end
		triggerServerEvent ("startRentCar", localPlayer, id, name, costCar, getSelectedRadio())
		guiSetVisible (window[1], false)
		if guiGetVisible (window[2]) then guiSetVisible (window[2], false) end
		showCursor (false)
	else
		local hours = guiGetText (edit[1])
		local minutes = guiGetText (edit[2])
		if hours ~= "Saat" then
			hour = tonumber(guiGetText (edit[1]))
		end
		if minutes ~= "Dakika" then
			minute = tonumber(guiGetText (edit[2]))
		end 
		triggerServerEvent ("startRentCar", localPlayer, id, name, costCar, nil, hour, minute)
		guiSetVisible (window[1], false)
		if guiGetVisible (window[2]) then guiSetVisible (window[2], false) end
		showCursor (false)
	end
elseif source == button[5] then
	guiSetVisible (window[2], false)
elseif source == radiobutton[1] then
	costCar = cost * 0.5
	guiSetText (button[4], "Kirala\n"..math.ceil(costCar).."$")
elseif source == radiobutton[2] then
	costCar = cost * 1
	guiSetText (button[4], "Kirala\n"..math.ceil(costCar).."$")
elseif source == radiobutton[3] then
	costCar = cost * 2
	guiSetText (button[4], "Kirala\n"..math.ceil(costCar).."$")
end
end)

addEventHandler ("onClientGUIChanged", root, function()
if source == edit[1] or source == edit[2] then
	if not tonumber (guiGetText (source)) then return end
	guiSetText (source, math.ceil(string.gsub (guiGetText(source), "%D", "")))
	if tonumber (guiGetText (edit[2])) and tonumber (guiGetText (edit[2])) > 60 then guiSetText (edit[2], "60") end
	if tonumber (guiGetText (edit[1])) and tonumber (guiGetText (edit[1])) > 5 then guiSetText (edit[1], "5") end
	updateCost ()
end
end)



function updateCost ()
costCar = 0
if guiGetText (edit[1]) ~= "Saat" then
	costCar = costCar + cost * tonumber(guiGetText(edit[1]))
end
if guiGetText (edit[2]) ~= "Dakika" then
	costCar = costCar + cost * tonumber(guiGetText(edit[2])) / 60
end
guiSetText (button[4], "Kirala\n"..math.ceil(costCar).."$")
end

function getSelectedRadio ()
for i, v in pairs (radiobutton) do
	if guiRadioButtonGetSelected (v) then
		return i
	end
end
return false
end