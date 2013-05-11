let () =
  let dbh = PGOCaml.connect
    ~host: Config.db_host
    ~user: Config.db_username
    ~password: Config.db_password
    ~database: Config.db_database
    ()
  in
  ignore (PGSQL (dbh) "SELECT nextval('label_multiplicative_sequence')");
  ignore (PGSQL (dbh) "SELECT setval('label_additive_sequence', 0, false)")

