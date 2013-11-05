let () =
  let dbh = PGOCaml.connect
    ~host: Config.db_host
    ~user: Config.db_username
    ~password: Config.db_password
    ~database: Config.db_database
    ()
  in
  ignore (PGSQL (dbh) "SELECT nextval('label_year_sequence')");
  ignore (PGSQL (dbh) "SELECT setval('label_suffix_id_sequence', 1, false)")

