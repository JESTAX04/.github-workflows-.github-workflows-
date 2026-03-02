local dbSqlite
local dbMysql

local function log(msg)
  outputServerLog("[MDT_DX] " .. tostring(msg))
end

local function isPolice(player)
  local acc = getPlayerAccount(player)
  if not acc or isGuestAccount(acc) then return false end
  local name = getAccountName(acc)
  return isObjectInACLGroup("user."..name, aclGetGroup(CFG.policeACL))
end

local function nowISO()
  local rt = getRealTime()
  return string.format("%04d-%02d-%02d %02d:%02d:%02d",
    rt.year+1900, rt.month+1, rt.monthday, rt.hour, rt.minute, rt.second)
end

local function qMysql(sql, ...)
  if not dbMysql then return {} end
  local h = dbQuery(dbMysql, sql, ...)
  return dbPoll(h, -1) or {}
end

local function qSqlite(sql, ...)
  if not dbSqlite then return {} end
  local h = dbQuery(dbSqlite, sql, ...)
  return dbPoll(h, -1) or {}
end

addEventHandler("onResourceStart", resourceRoot, function()
  -- SQLite (MDT internal: warrants/bolos/incidents fallback)
  dbSqlite = dbConnect("sqlite", "mdt.db")
  if not dbSqlite then
    log("SQLite connect failed!")
  else
    dbExec(dbSqlite, [[
      CREATE TABLE IF NOT EXISTS warrants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        citizen_id INTEGER,
        title TEXT,
        description TEXT,
        status TEXT DEFAULT 'active',
        created_at TEXT
      );
    ]])
    dbExec(dbSqlite, [[
      CREATE TABLE IF NOT EXISTS bolos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT,
        title TEXT,
        description TEXT,
        plate TEXT,
        citizen_name TEXT,
        status TEXT DEFAULT 'active',
        created_at TEXT
      );
    ]])
    dbExec(dbSqlite, [[
      CREATE TABLE IF NOT EXISTS incidents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        description TEXT,
        officer TEXT,
        created_at TEXT
      );
    ]])
    log("SQLite ready")
  end

  -- MySQL (CRP)
  if CFG.mysql and CFG.mysql.enabled then
    local ok, conn = pcall(function()
      return dbConnect("mysql",
        string.format("dbname=%s;host=%s;charset=utf8mb4", CFG.mysql.db, CFG.mysql.host),
        CFG.mysql.user, CFG.mysql.pass
      )
    end)
    if ok and conn then
      dbMysql = conn
      log("MySQL connected to " .. tostring(CFG.mysql.db))
    else
      log("MySQL connect failed (check CFG.mysql).* Using SQLite-only.")
    end
  end
end)

-- ========= API =========
addEvent("mdt:api", true)
addEventHandler("mdt:api", root, function(action, payload, reqId)
  local player = client
  if not isElement(player) then return end
  if not isPolice(player) then
    triggerClientEvent(player, "mdt:api:resp", player, reqId, false, { error="NO_ACCESS" })
    return
  end

  payload = payload or {}

  -- Dashboard
  if action == "dashboard.get" then
    local incidents = qSqlite("SELECT id, title, officer, created_at FROM incidents ORDER BY id DESC LIMIT 5")
    local bolos = qSqlite("SELECT id, type, title, status, created_at FROM bolos ORDER BY id DESC LIMIT 5")
    triggerClientEvent(player, "mdt:api:resp", player, reqId, true, { incidents=incidents, bolos=bolos })
    return
  end

  -- Warrants list (SQLite)
  if action == "warrants.list" then
    local rows = qSqlite("SELECT id, citizen_id, title, status, created_at FROM warrants ORDER BY id DESC LIMIT 50")
    triggerClientEvent(player, "mdt:api:resp", player, reqId, true, { rows=rows })
    return
  end

  -- BOLO list (SQLite)
  if action == "bolos.list" then
    local rows = qSqlite("SELECT id, type, title, status, created_at FROM bolos ORDER BY id DESC LIMIT 50")
    triggerClientEvent(player, "mdt:api:resp", player, reqId, true, { rows=rows })
    return
  end

  -- Citizens: ONLINE (CRP MySQL)
  if action == "citizens.online" then
    local out = {}

    if dbMysql and CFG.crp then
      local T = CFG.crp.characters_table
      local f_id = CFG.crp.char_id
      local f_name = CFG.crp.char_name
      local f_dob = CFG.crp.char_dob
      local f_user = CFG.crp.char_user

      for _, p in ipairs(getElementsByType("player")) do
        local acc = getPlayerAccount(p)
        if acc and not isGuestAccount(acc) then
          local accName = getAccountName(acc)
          local rows = qMysql(
            string.format("SELECT %s as id, %s as nome, %s as dob FROM %s WHERE %s=? ORDER BY %s DESC LIMIT 1",
              f_id, f_name, f_dob, T, f_user, f_id
            ),
            accName
          )
          if rows[1] then
            table.insert(out, {
              id = rows[1].id,
              nome = rows[1].nome or accName,
              dob = rows[1].dob or "-",
              phone = "-",
              online = "YES"
            })
          else
            table.insert(out, {
              id = 0,
              nome = accName,
              dob = "-",
              phone = "-",
              online = "YES"
            })
          end
        end
      end
    end

    triggerClientEvent(player, "mdt:api:resp", player, reqId, true, { rows=out })
    return
  end

  -- Citizens: SEARCH (CRP MySQL)
  if action == "citizens.search" then
    local term = tostring(payload.term or ""):sub(1, 48)
    local out = {}

    if dbMysql and CFG.crp then
      local T = CFG.crp.characters_table
      local f_id = CFG.crp.char_id
      local f_name = CFG.crp.char_name
      local f_dob = CFG.crp.char_dob

      local rows = qMysql(
        string.format("SELECT %s as id, %s as nome, %s as dob FROM %s WHERE %s LIKE ? ORDER BY %s DESC LIMIT ?",
          f_id, f_name, f_dob, T, f_name, f_id
        ),
        "%" .. term .. "%", CFG.maxResults
      )

      for _, r in ipairs(rows) do
        table.insert(out, { id=r.id, nome=r.nome or "-", dob=r.dob or "-", phone="-", online="?" })
      end
    end

    triggerClientEvent(player, "mdt:api:resp", player, reqId, true, { rows=out })
    return
  end

  -- Citizens: LIST (CRP MySQL) -> latest citizens (online/offline)
  if action == "citizens.list" then
    local limit = tonumber(payload.limit) or 50
    local offset = tonumber(payload.offset) or 0
    if limit > 200 then limit = 200 end
    if limit < 1 then limit = 50 end
    if offset < 0 then offset = 0 end

    local out = {}

    if dbMysql and CFG.crp then
      local T = CFG.crp.characters_table
      local f_id = CFG.crp.char_id
      local f_name = CFG.crp.char_name
      local f_dob = CFG.crp.char_dob
      local f_user = CFG.crp.char_user

      -- online map by account name
      local onlineMap = {}
      for _, p in ipairs(getElementsByType("player")) do
        local acc = getPlayerAccount(p)
        if acc and not isGuestAccount(acc) then
          onlineMap[getAccountName(acc)] = true
        end
      end

      local rows = qMysql(
        string.format("SELECT %s as id, %s as nome, %s as dob, %s as usr FROM %s ORDER BY %s DESC LIMIT ? OFFSET ?",
          f_id, f_name, f_dob, f_user, T, f_id
        ),
        limit, offset
      )

      for _, r in ipairs(rows) do
        local usr = tostring(r.usr or "")
        table.insert(out, {
          id = r.id,
          nome = r.nome or "-",
          dob = r.dob or "-",
          phone = "-",
          online = onlineMap[usr] and "YES" or "NO",
        })
      end
    end

    triggerClientEvent(player, "mdt:api:resp", player, reqId, true, { rows=out })
    return
  end

  -- Vehicles search (left as TODO; can be bound later)
  if action == "vehicles.search" then
    triggerClientEvent(player, "mdt:api:resp", player, reqId, true, { rows={} })
    return
  end

  
  -- Vehicles: LIST (CRP MySQL)
  if action == "vehicles.list" then
    local limit = tonumber(payload.limit) or 50
    local offset = tonumber(payload.offset) or 0
    if limit > 200 then limit = 200 end
    if offset < 0 then offset = 0 end

    if not dbMysql or not CFG.crp then
      triggerClientEvent(player, "mdt:api:resp", player, reqId, true, { rows = {} })
      return
    end

    local T = CFG.crp.vehicles_table
    local f_id = CFG.crp.veh_id
    local f_owner = CFG.crp.veh_owner
    local f_model = CFG.crp.veh_model
    local f_color = CFG.crp.veh_color
    local f_stats = CFG.crp.veh_stats

    local rows = qMysql(string.format(
      "SELECT %s as id, %s as owner, %s as model, %s as color, %s as stats FROM %s ORDER BY %s DESC LIMIT ? OFFSET ?",
      f_id, f_owner, f_model, f_color, f_stats, T, f_id
    ), limit, offset)

    local function extractPlate(stats)
      stats = tostring(stats or "")
      local p = stats:match("[Pp][Ll][Aa][Tt][Ee]'?%s*[:=]%s*'([^']+)'")
      if not p then p = stats:match("[Pp][Ll][Aa][Tt][Ee]\"%s*:%s*\"([^\"]+)\"") end
      if not p then p = stats:match("[Pp][Ll][Aa][Tt][Ee]%s*=%s*\"([^\"]+)\"") end
      return p or "-"
    end

    local out = {}
    for _, r in ipairs(rows or {}) do
      table.insert(out, {
        plate = extractPlate(r.stats),
        model = tostring(r.model or "-"),
        color = tostring(r.color or "-"),
        stolen = "NO",
        owner = tostring(r.owner or "-"),
      })
    end

    triggerClientEvent(player, "mdt:api:resp", player, reqId, true, { rows = out })
    return
  end

  -- Vehicles: SEARCH (CRP MySQL) - by plate/owner/model
  if action == "vehicles.search" then
    local term = tostring(payload.term or ""):sub(1, 48)
    term = term:gsub("%%", "")
    if term == "" then
      triggerClientEvent(player, "mdt:api:resp", player, reqId, true, { rows = {} })
      return
    end

    if not dbMysql or not CFG.crp then
      triggerClientEvent(player, "mdt:api:resp", player, reqId, true, { rows = {} })
      return
    end

    local T = CFG.crp.vehicles_table
    local f_id = CFG.crp.veh_id
    local f_owner = CFG.crp.veh_owner
    local f_model = CFG.crp.veh_model
    local f_color = CFG.crp.veh_color
    local f_stats = CFG.crp.veh_stats

    local like = "%" .. term .. "%"
    local rows = qMysql(string.format(
      "SELECT %s as id, %s as owner, %s as model, %s as color, %s as stats FROM %s WHERE %s LIKE ? OR %s LIKE ? OR CAST(%s AS CHAR) LIKE ? ORDER BY %s DESC LIMIT ?",
      f_id, f_owner, f_model, f_color, f_stats, T, f_stats, f_owner, f_model, f_id
    ), like, like, like, CFG.maxResults)

    local function extractPlate(stats)
      stats = tostring(stats or "")
      local p = stats:match("[Pp][Ll][Aa][Tt][Ee]'?%s*[:=]%s*'([^']+)'")
      if not p then p = stats:match("[Pp][Ll][Aa][Tt][Ee]\"%s*:%s*\"([^\"]+)\"") end
      if not p then p = stats:match("[Pp][Ll][Aa][Tt][Ee]%s*=%s*\"([^\"]+)\"") end
      return p or "-"
    end

    local out = {}
    for _, r in ipairs(rows or {}) do
      table.insert(out, {
        plate = extractPlate(r.stats),
        model = tostring(r.model or "-"),
        color = tostring(r.color or "-"),
        stolen = "NO",
        owner = tostring(r.owner or "-"),
      })
    end

    triggerClientEvent(player, "mdt:api:resp", player, reqId, true, { rows = out })
    return
  end

triggerClientEvent(player, "mdt:api:resp", player, reqId, false, { error="UNKNOWN_ACTION" })
end)
