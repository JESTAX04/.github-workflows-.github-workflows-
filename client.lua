local sx, sy = guiGetScreenSize()
local visible = false

-- layout
local wSidebar = 300
local pad = 18
local radius = 12

local pages = {"dashboard","citizens","vehicles","warrants","bolos"}
local pageLabels = {
  dashboard="Dashboard",
  citizens="Citizens",
  vehicles="Vehicles",
  warrants="Warrants",
  bolos="BOLOs",
}
local currentPage = "dashboard"

local searchEdit
local searchBtn = {x=0,y=0,w=90,h=36}
local navBtns = {}
local closeBtn = {x=0,y=0,w=90,h=34}

local reqCounter = 0
local pending = {}
local lastData = {
  dashboard = {incidents={}, bolos={}},
  citizens = {rows={}},
  vehicles = {rows={}},
  warrants = {rows={}},
  bolos = {rows={}},
}

local function rgba(r,g,b,a) return tocolor(r,g,b,a) end

local function dbg(msg)
  outputConsole("[MDT_DX] "..tostring(msg))
end

local function isIn(x,y,w,h, mx,my)
  return mx>=x and mx<=x+w and my>=y and my<=y+h
end

local function api(action, payload)
  reqCounter = reqCounter + 1
  local reqId = tostring(reqCounter)..":"..tostring(getTickCount())
  pending[reqId] = action
  triggerServerEvent("mdt:api", localPlayer, action, payload or {}, reqId)
end

local function setVisible(state)
  visible = state
  showCursor(state)
  guiSetInputEnabled(state)
  if searchEdit and isElement(searchEdit) then
    guiSetVisible(searchEdit, state)
  end
end

local function ensureUI()
  if searchEdit and isElement(searchEdit) then return end
  searchEdit = guiCreateEdit(0,0,0,0,"")
  guiEditSetMaxLength(searchEdit, 48)
  guiSetAlpha(searchEdit, 0.85)
  guiSetVisible(searchEdit, false)
end

local function openMDT()
  ensureUI()
  setVisible(true)
  api("dashboard.get", {})
  dbg("Opened (DX)")
end

local function closeMDT()
  setVisible(false)
  dbg("Closed")
end

bindKey(CFG.keyToggle, "down", function()
  if visible then closeMDT() else openMDT() end
end)

addCommandHandler("mdt", function()
  if visible then closeMDT() else openMDT() end
end)

addEvent("mdt:api:resp", true)
addEventHandler("mdt:api:resp", root, function(reqId, ok, data)
  local action = pending[reqId]
  pending[reqId] = nil
  if not ok then
    dbg("API error: "..tostring(data and data.error))
    return
  end
  if action == "dashboard.get" then
    lastData.dashboard = data or lastData.dashboard
  elseif action == "citizens.search" or action == "citizens.online" or action == "citizens.list" then
    lastData.citizens = data or lastData.citizens
  elseif action == "vehicles.search" or action == "vehicles.list" then
    lastData.vehicles = data or lastData.vehicles
  elseif action == "warrants.list" then
    lastData.warrants = data or lastData.warrants
  elseif action == "bolos.list" then
    lastData.bolos = data or lastData.bolos
  end
end)

local function drawRoundedRect(x,y,w,h,color)
  -- simple rect (no shader)
  dxDrawRectangle(x,y,w,h,color,true)
end

local function drawText(t,x,y,w,h,scale,color,alignX,alignY, bold)
  local font = bold and "default-bold" or "default"
  dxDrawText(t,x,y,x+w,y+h,color,scale,font,alignX or "left",alignY or "center",false,false,true,true)
end

local function layout()
  local x0,y0 = pad,pad
  local mainX = x0 + wSidebar + 14
  local mainW = sx - mainX - pad
  local mainH = sy - pad*2

  -- sidebar nav buttons
  local ny = y0 + 92
  navBtns = {}
  for i,p in ipairs(pages) do
    navBtns[p] = {x=x0+14, y=ny + (i-1)*52, w=wSidebar-28, h=42}
  end

  -- top search
  local topY = y0 + 16
  local searchW = math.min(380, mainW*0.45)
  local editX = mainX + mainW - (searchW + 10 + searchBtn.w)
  local editY = topY + 2
  local editH = 32

  if searchEdit and isElement(searchEdit) then
    guiSetPosition(searchEdit, editX, editY, false)
    guiSetSize(searchEdit, searchW, editH, false)
  end

  searchBtn.x = editX + searchW + 10
  searchBtn.y = editY
  searchBtn.w = 90
  searchBtn.h = editH

  closeBtn.x = x0 + wSidebar - 14 - closeBtn.w
  closeBtn.y = y0 + (sy - pad*2) - 14 - closeBtn.h
end

local function drawTable(x,y,w,h, columns, rows)
  -- header
  drawRoundedRect(x,y,w,34, rgba(255,255,255,12))
  local cx = x
  for _,c in ipairs(columns) do
    drawText(c.label, cx+10, y, c.w, 34, 1, rgba(232,234,237,220), "left","center", true)
    cx = cx + c.w
  end
  local rowH = 30
  local maxRows = math.floor((h-34)/rowH)
  for i=1, math.min(#rows, maxRows) do
    local ry = y+34 + (i-1)*rowH
    drawRoundedRect(x,ry,w,rowH, rgba(255,255,255, (i%2==0) and 6 or 10))
    cx = x
    local r = rows[i]
    for _,c in ipairs(columns) do
      local val = r[c.key]
      if val == nil then val = "" end
      drawText(tostring(val), cx+10, ry, c.w, rowH, 1, rgba(232,234,237,200), "left","center", false)
      cx = cx + c.w
    end
  end
end

addEventHandler("onClientRender", root, function()
  if not visible then return end
  ensureUI()
  layout()

  local x0,y0 = pad,pad
  local mainX = x0 + wSidebar + 14
  local mainW = sx - mainX - pad
  local mainH = sy - pad*2

  -- background panels
  drawRoundedRect(x0,y0,wSidebar,mainH, rgba(45,48,52,235))
  drawRoundedRect(mainX,y0,mainW,mainH, rgba(45,48,52,235))

  -- brand
  drawText("Los Santos Police Department", x0+18, y0+16, wSidebar-36, 22, 1, rgba(232,234,237,235), "left","center", true)
  drawText("Mobile Data Terminal (DX)", x0+18, y0+40, wSidebar-36, 18, 0.95, rgba(232,234,237,140), "left","center", false)

  -- nav
  for _,p in ipairs(pages) do
    local b = navBtns[p]
    local active = (p == currentPage)
    drawRoundedRect(b.x,b.y,b.w,b.h, active and rgba(77,163,255,35) or rgba(255,255,255,10))
    drawText(pageLabels[p], b.x+14, b.y, b.w-28, b.h, 1, rgba(232,234,237, active and 235 or 210), "left","center", active)
  end

  -- close
  drawRoundedRect(closeBtn.x, closeBtn.y, closeBtn.w, closeBtn.h, rgba(255,120,120,35))
  drawText("Close", closeBtn.x, closeBtn.y, closeBtn.w, closeBtn.h, 1, rgba(255,220,220,235), "center","center", true)

  -- topbar
  drawText(pageLabels[currentPage], mainX+16, y0+16, 240, 24, 1.05, rgba(232,234,237,235), "left","center", true)

  -- search bg hint
  drawRoundedRect(searchBtn.x- (guiGetSize(searchEdit,false)) , 0,0,0, rgba(0,0,0,0)) -- noop

  drawRoundedRect(searchBtn.x, searchBtn.y, searchBtn.w, searchBtn.h, rgba(77,163,255,55))
  drawText("Search", searchBtn.x, searchBtn.y, searchBtn.w, searchBtn.h, 1, rgba(232,234,237,235), "center","center", true)

  -- content area
  local contentX = mainX + 16
  local contentY = y0 + 56
  local contentW = mainW - 32
  local contentH = mainH - 72

  if currentPage == "dashboard" then
    local cardW = (contentW - 24) / 3
    local cardH = 190
    for i=1,3 do
      local cx = contentX + (i-1)*(cardW+12)
      drawRoundedRect(cx, contentY, cardW, cardH, rgba(255,255,255,10))
    end
    drawText("Citizen Results", contentX+12, contentY+10, cardW-24, 20, 1, rgba(232,234,237,210), "left","center", true)
    drawText("Use search box (top-right).", contentX+12, contentY+36, cardW-24, 18, 0.95, rgba(232,234,237,140), "left","center", false)

    local incidents = (lastData.dashboard and lastData.dashboard.incidents) or {}
    drawText("Recent Incidents", contentX+cardW+12+12, contentY+10, cardW-24, 20, 1, rgba(232,234,237,210), "left","center", true)
    if #incidents == 0 then
      drawText("No data.", contentX+cardW+12+12, contentY+40, cardW-24, 18, 0.95, rgba(232,234,237,140), "left","center", false)
    else
      local cols = {{key="title",label="Title",w=cardW-120},{key="officer",label="Officer",w=120}}
      drawTable(contentX+cardW+12, contentY+40, cardW, 140, cols, incidents)
    end

    local bolos = (lastData.dashboard and lastData.dashboard.bolos) or {}
    local bx = contentX + 2*(cardW+12)
    drawText("Recent BOLOs", bx+12, contentY+10, cardW-24, 20, 1, rgba(232,234,237,210), "left","center", true)
    if #bolos == 0 then
      drawText("No data.", bx+12, contentY+40, cardW-24, 18, 0.95, rgba(232,234,237,140), "left","center", false)
    else
      local cols = {{key="title",label="Title",w=cardW-120},{key="status",label="Status",w=120}}
      drawTable(bx, contentY+40, cardW, 140, cols, bolos)
    end

  elseif currentPage == "citizens" then
    local rows = (lastData.citizens and lastData.citizens.rows) or {}
    local cols = {
      {key="id",label="#",w=60},
      {key="nome",label="Name",w=320},
      {key="dob",label="DOB",w=160},
      {key="phone",label="Phone",w=160},
      {key="online",label="Online",w=120},
    }
    drawRoundedRect(contentX, contentY, contentW, contentH, rgba(255,255,255,10))
    drawTable(contentX+10, contentY+10, contentW-20, contentH-20, cols, rows)

  elseif currentPage == "vehicles" then
    local rows = (lastData.vehicles and lastData.vehicles.rows) or {}
    local cols = {
      {key="plate",label="Plate",w=160},
      {key="model",label="Model",w=220},
      {key="color",label="Color",w=160},
      {key="stolen",label="Stolen",w=90},
      {key="owner_citizen_id",label="OwnerID",w=120},
    }
    drawRoundedRect(contentX, contentY, contentW, contentH, rgba(255,255,255,10))
    drawTable(contentX+10, contentY+10, contentW-20, contentH-20, cols, rows)

  elseif currentPage == "warrants" then
    local rows = (lastData.warrants and lastData.warrants.rows) or {}
    local cols = {
      {key="id",label="#",w=60},
      {key="title",label="Title",w=260},
      {key="status",label="Status",w=110},
      {key="firstname",label="First",w=160},
      {key="lastname",label="Last",w=160},
      {key="created_at",label="Date",w=220},
    }
    drawRoundedRect(contentX, contentY, contentW, contentH, rgba(255,255,255,10))
    drawTable(contentX+10, contentY+10, contentW-20, contentH-20, cols, rows)

  elseif currentPage == "bolos" then
    local rows = (lastData.bolos and lastData.bolos.rows) or {}
    local cols = {
      {key="id",label="#",w=60},
      {key="type",label="Type",w=120},
      {key="title",label="Title",w=360},
      {key="status",label="Status",w=120},
      {key="created_at",label="Date",w=240},
    }
    drawRoundedRect(contentX, contentY, contentW, contentH, rgba(255,255,255,10))
    drawTable(contentX+10, contentY+10, contentW-20, contentH-20, cols, rows)
  end
end)

addEventHandler("onClientClick", root, function(button, state, mx, my)
  if not visible then return end
  if button ~= "left" or state ~= "down" then return end

  -- sidebar nav
  for _,p in ipairs(pages) do
    local b = navBtns[p]
    if b and isIn(b.x,b.y,b.w,b.h,mx,my) then
      currentPage = p
      if p == "dashboard" then api("dashboard.get", {}) end
      if p == "warrants" then api("warrants.list", {}) end
      if p == "bolos" then api("bolos.list", {}) end
      if p == "citizens" then api("citizens.list", {limit=50, offset=0}) end
      if p == "vehicles" then api("vehicles.list", {limit=50, offset=0}) end
      if p == "vehicles" then api("vehicles.list", {limit=50, offset=0}) end
      return
    end
  end

  -- close
  if isIn(closeBtn.x, closeBtn.y, closeBtn.w, closeBtn.h, mx,my) then
    closeMDT()
    return
  end

  -- search
  if isIn(searchBtn.x, searchBtn.y, searchBtn.w, searchBtn.h, mx,my) then
    local term = guiGetText(searchEdit) or ""
    term = term:gsub("^%s+",""):gsub("%s+$","")
    if currentPage == "vehicles" then
      if term == "" then
        api("vehicles.list", {limit=50, offset=0})
      else
        api("vehicles.search", {term=term})
      end
    else
      currentPage = "citizens"
      if term == "" then
        api("citizens.list", {limit=50, offset=0})
      else
        api("citizens.search", {term=term})
      end
    end
    return
  end
end)
