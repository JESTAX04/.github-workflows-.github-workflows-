local db = nil
local connected = false

local function log(msg, lvl)
    outputDebugString("[mdt_web_dx_citizens_live_fixmap4] "..tostring(msg), lvl or 3)
end

local function connectDB()
    if db and isElement(db) then destroyElement(db) end
    db = nil
    connected = false

    local cfg = MDT_DB
    if not cfg then
        log("MDT_DB config missing!", 1)
        return false
    end

    local connStr = string.format(
        "dbname=%s;host=%s;port=%d;charset=%s",
        cfg.database, cfg.host, tonumber(cfg.port) or 3306, cfg.charset or "utf8"
    )

    db = dbConnect("mysql", connStr, cfg.username, cfg.password, "share=1")

    if db then
        connected = true
        log("MySQL/MariaDB connected OK")
        return true
    else
        log("MySQL/MariaDB connection FAILED. Check config.lua credentials.", 1)
        return false
    end
end

addEventHandler("onResourceStart", resourceRoot, function()
    connectDB()
    log("Started. Press F6 or /mdt to open.")
end)

addEventHandler("onResourceStop", resourceRoot, function()
    if db and isElement(db) then destroyElement(db) end
    db = nil
    connected = false
end)

addCommandHandler("mdt_db", function(player)
    if player and isElement(player) then
        local ok = connectDB()
        outputChatBox(ok and "MDT DB: connected" or "MDT DB: failed", player, ok and 80 or 255, ok and 255 or 80, 80)
    end
end)

local function safeName(name)
    name = tostring(name or "")
    if name:match("^[%w_]+$") then return name end
    return nil
end

local function normalizeCitizenRow(row, cfg)
    if type(row) ~= "table" then return nil end

    -- configured keys (optional)
    local idKey = safeName(cfg.col_id) or "id"
    local nameKey = safeName(cfg.col_name) or "nome"
    local genderKey = safeName(cfg.col_gender) or "gender"
    local dobKey = safeName(cfg.col_dob) or "ager"
    local moneyKey = safeName(cfg.col_money) or "money"
    local userKey = safeName(cfg.col_user) or "user"

    -- HARD fallbacks (for any driver weirdness)
    local id = row[idKey] or row.id or row.ID or row["id"] or row["ID"]
    local name = row[nameKey] or row.name or row.NOME or row["nome"] or row["Nome"] or row["NOME"]

    return {
        id = id,
        name = name,
        gender = row[genderKey] or row.gender or row.GENDER or row["gender"],
        dob = row[dobKey] or row.dob or row.DOB or row["ager"] or row["dob"],
        money = row[moneyKey] or row.money or row.MONEY or row["money"],
        user = row[userKey] or row.user or row.USER or row["user"],
    }
end

local function runQuery(callback, sql, params)
    if type(params) ~= "table" or #params == 0 then
        dbQuery(callback, db, sql)
    else
        local u = (table and table.unpack) or unpack
        if u then
            dbQuery(callback, db, sql, u(params))
        else
            dbQuery(callback, db, sql, params[1])
        end
    end
end

addEvent("mdt:searchCitizens", true)
addEventHandler("mdt:searchCitizens", resourceRoot, function(q)
    if not connected or not db then
        log("searchCitizens called but DB not connected", 2)
        return
    end
    local player = client

    q = tostring(q or "")
    if #q > 64 then q = q:sub(1, 64) end

    local cfg = MDT_DB
    local tbl = safeName(cfg.table_characters) or "crp_characters"
    local col_name = safeName(cfg.col_name) or "nome"
    local col_id = safeName(cfg.col_id) or "id"
    local max = tonumber(MDT_MAX_RESULTS) or 25

    local sql, params = nil, {}
    if q == "" then
        sql = string.format("SELECT * FROM %s ORDER BY %s DESC LIMIT %d", tbl, col_id, max)
    else
        sql = string.format("SELECT * FROM %s WHERE %s LIKE ? ORDER BY %s DESC LIMIT %d", tbl, col_name, col_id, max)
        params = {"%"..q.."%"}
    end

    runQuery(function(qh)
        local rows = dbPoll(qh, 0)
        if type(rows) ~= "table" then
            log("DB query failed (rows not table). SQL="..sql, 1)
            triggerClientEvent(player, "mdt:citizensResult", resourceRoot, {})
            return
        end

        local out = {}
        for _,r in ipairs(rows) do
            local n = normalizeCitizenRow(r, cfg)
            if n then table.insert(out, n) end
        end

        log(("Citizens search '%s' -> %d rows"):format(q, #out), 3)
        triggerClientEvent(player, "mdt:citizensResult", resourceRoot, out)
    end, sql, params)
end)

addEvent("mdt:getCitizenProfile", true)
addEventHandler("mdt:getCitizenProfile", resourceRoot, function(id)
    if not connected or not db then return end
    local player = client
    id = tonumber(id) or 0
    if id <= 0 then return end

    local cfg = MDT_DB
    local tbl = safeName(cfg.table_characters) or "crp_characters"
    local col_id = safeName(cfg.col_id) or "id"
    local sql = string.format("SELECT * FROM %s WHERE %s = ? LIMIT 1", tbl, col_id)

    runQuery(function(qh)
        local rows = dbPoll(qh, 0) or {}
        local row = rows[1] and normalizeCitizenRow(rows[1], cfg) or {}
        triggerClientEvent(player, "mdt:citizenProfileResult", resourceRoot, row)
    end, sql, {id})
end)
