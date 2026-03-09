CFG = {
  keyToggle = "F6",
  policeACL = "Police",
  maxResults = 25,

  -- If you have MariaDB/MySQL with CRP tables, enable this
  mysql = {
    enabled = true,
    host = "127.0.0.1",
    db = "s272878_mrfix",
    user = "root",
    pass = "",
  },

  crp = {
    -- Vehicles
    vehicles_table = "crp_carshop_vehicles",
    veh_id = "id",
    veh_owner = "owner",
    veh_model = "model",
    veh_color = "color",
    veh_stats = "stats",

    characters_table = "crp_characters",
    char_id = "id",
    char_name = "nome",
    char_dob = "ager",     -- your column 'ager' holds DOB/date string
    char_user = "user",    -- account name / identifier
    char_serial = "serial",
  }
}
