-- SparroW MTA Script Sitemiz  : https://sparrow-mta.blogspot.com
-- Discord Adresimiz : https://discord.gg/89V5vN8
-- İyi oyunlar...
createBlip ( -1990.893, 274.501, 34.33, 34 ) -- blip ikon haritadaki
pos = {
[1] = {
	["rentPlace"] = {-1990.893, 274.501, 34.33}, -- marker
	["createCar"] = {-1989.59, 265.75, 34.77}, -- aracın doğduğu bölge
	},
}

tableCars = {--[ID] = {"Название", цена за 1 час},
[411] = {"İnfernus", 100}, --- bu şekilde kiralık araçlar ekleye  bilirsiniz.
}



------    Номера    ------
number = true -- Ставить номера или нет
numberGTA = true -- Ставить номера как в GTA или обычные российские
reg = "77" -- Если хотите рандомный регион то false (если numberGTA = false)
--------------------------

------     Цвет     ------
color = {213, 123, 165} -- Цвет машины color = {r, g, b}, если хотите рандомный то color = false, 
--------------------------

------    Прочие    ------
canPlayerUseCar = false -- Могут ли другие игроки садится за руль арендованного ТС
canVehicleDamageProof = false -- Делать арендованные ТС бесмертными
--------------------------