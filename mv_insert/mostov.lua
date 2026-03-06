local screenW, screenH = guiGetScreenSize()
local x, y = (screenW/1366), (screenH/768)
local font = dxCreateFont("font.otf",y*12)
local font2 = dxCreateFont("font.otf",y*11)
alpha = 0
balaboro = fakse
lightanim = 255
detail = dxCreateTexture( "files/sc1.png" )
bg = dxCreateTexture( "files/sc2.png" )
light = dxCreateTexture( "files/sc3.png" )

addEventHandler("onClientRender",root,function()
if getKeyState("insert") then
 if alpha < 255 then
  alpha = alpha + 15
 end
else
 if alpha > 0 then
  alpha = alpha - 15
 end
end

 --dxDrawImage(x*730,y*0,x*500,y*155,bg,0,0,0,tocolor(255,255,255,alpha))
 
  if alpha >= 150 then
 
  if balaboro then
   lightanim = lightanim + 2 
  else
   lightanim = lightanim - 2 
  end
  if lightanim >= 255 then
   balaboro = false
  elseif lightanim <= 50 then
   balaboro = true
  end
 
 dxDrawImage(x*1000,y*100,x*280,y*455,light,0,0,0,tocolor(255,255,255,lightanim))
 end
 
dxDrawImage(x*1000,y*100,x*280,y*455,detail,0,0,0,tocolor(255,255,255,alpha))

 
dxDrawText ( "b*  Store Robbery ", x*1030,y*260,x*300,y*300, tocolor ( 255, 255, 255, alpha ), 1, font )
dxDrawText ( "b*  Bank Robbery ", x*1030,y*295,x*300,y*300, tocolor ( 255, 255, 255, alpha ), 1, font )
dxDrawText ( "b*  Jewelery Robbery ", x*1030,y*330,x*300,y*300, tocolor ( 255, 255, 255, alpha ), 1, font )

dxDrawText ( "b*  Police :", x*1030,y*365,x*300,y*300, tocolor ( 255, 255, 255, alpha ), 1, font )
dxDrawText ( "b*  Medic :", x*1030,y*400,x*300,y*300, tocolor ( 255, 255, 255, alpha ), 1, font )
dxDrawText ( "b*  Mecano :", x*1030,y*435,x*300,y*300, tocolor ( 255, 255, 255, alpha ), 1, font )
dxDrawText ( "Green Time :  ", x*1080,y*470,x*300,y*300, tocolor ( 255, 255, 255, alpha ), 1, font )
 
 pddutys = 0
 mddutys = 0
 mecdutys = 0
 jusdutys = 0
 gtime = "bo8"
 store = "b"
 bank = "b"
 jewelery = "b"
 
 for k,v in ipairs(getElementsByType("player")) do
  if getElementData(v,"police >> duty") then
   pddutys = pddutys +1
  -- elseif getElementData(v,"mecanico >> duty") then
  elseif getElementData(v,"paramedic >> duty") then
   mddutys = mddutys +1
  elseif getElementData(v,"mecanico >> duty") then
   mecdutys = mecdutys +1
  elseif getElementData(v,"Justice-ComPonto") then
   mecdutys = mecdutys +1
  end
 end
 
 if pddutys >= 2 then
    store = "bo8"
   end

   if pddutys >= 6 then
    bank = "bo8"
   end

   if pddutys >= 5 then
    jewelery = "bo8"
   end



 if pddutys >= 2 then
  gtime = "b"
 end
 
 if pddutys >= 4 then
    pddutys = "+4"
   end

 if mddutys >= 4 then
  mddutys = "+4"
 end
 
 if mecdutys >= 4 then
  mecdutys = "+4"
 end

 if jusdutys >= 4 then
  jusdutys = "+4"
 end

 dxDrawText ( "Total Players  :   "..#getElementsByType("player").." of 500", x*920,y*510,x*1350,y*300, tocolor ( 0, 0, 0, alpha ), 1, font,"center" )
 dxDrawText ( "Total Players  :   "..#getElementsByType("player").." of 500", x*920,y*510,x*1350,y*300, tocolor ( 255, 255, 255, alpha ), 1, font,"center" )
 --dxDrawText ( " Your CCP : "..getElementData(localPlayer,"ID").."", x*925,y*190,x*1350,y*300, tocolor ( 0, 0, 0, alpha ), 1.03, font,"center" )
-- dxDrawText ( "  Your CCP : "..getElementData(localPlayer,"ID").."", x*925,y*180,x*1350,y*300, tocolor ( 0, 0, 0, alpha ), 1.03, font,"center" )
 dxDrawText ( " Your CCP : "..getElementData(localPlayer,"ID").."", x*925,y*150,x*1350,y*300, tocolor ( 255, 255, 255, alpha ), 1, font,"center" )
 dxDrawText ( pddutys, x*1100,y*365,x*1350,y*300, tocolor ( 0, 255, 208, alpha ), 1, font2,"center" )
 dxDrawText ( store, x*1100,y*260,x*1350,y*300, tocolor ( 0, 255, 208, alpha ), 1, font2,"center" )
 dxDrawText ( bank, x*1100,y*295,x*1350,y*300, tocolor ( 0, 255, 208, alpha ), 1, font2,"center" )
 dxDrawText ( jewelery, x*1100,y*330,x*1350,y*300, tocolor ( 0, 255, 208, alpha ), 1, font2,"center" )
 dxDrawText ( gtime, x*1040,y*471,x*1350,y*300, tocolor ( 255, 255, 255, alpha ), 1, font2,"center" )
 dxDrawText ( mddutys, x*1100,y*400,x*1350,y*300, tocolor ( 0, 255, 208, alpha ), 1, font2,"center" )
 dxDrawText ( mecdutys, x*1100,y*435,x*1350,y*300, tocolor ( 0, 255, 208, alpha ), 1, font2,"center" )
 --dxDrawText ( jusdutys, x*420,y*111,x*1350,y*300, tocolor ( 0, 255, 208, alpha ), 1, font2,"center" )


end)