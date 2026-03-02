-- MDT DB CONFIG (MariaDB/MySQL)
-- Change these to match your HeidiSQL connection.

MDT_DB = {
    host = "127.0.0.1",
    port = 3306,
    database = "s272878_mrfix",
    username = "root",
    password = "",
    charset = "utf8",

    -- Table + column mapping (your screenshot: crp_characters)
    table_characters = "crp_characters",
    col_id = "id",
    col_name = "nome",
    col_gender = "gender",
    col_dob = "ager",
    col_money = "money",
    col_user = "user",
}

MDT_MAX_RESULTS = 50