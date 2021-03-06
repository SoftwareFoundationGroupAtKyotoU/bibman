let generate_session =
  let session_id account uid =
    let id =
      let module Time = CalendarLib.Time in
      let second = Time.Second.to_int (Time.to_seconds (Time.now ())) in
      let hash = Cryptokit.Hash.sha256 () in
      hash # add_string account;
      hash # add_string (Int32.to_string uid);
      hash # add_byte second;
      hash # add_string Config.session_salt;
      hash # result
    in
    let trans = Cryptokit.Base64.encode_compact () in
    trans # put_string id;
    trans # get_string
  in

  let body dbh account uid =
    let module Calendar = CalendarLib.Calendar in
    let expiration =
      let period =
        Calendar.Period.make
          0 0
          Config.session_period_days
          Config.session_period_hours
          Config.session_period_minutes
          (CalendarLib.Time.Second.from_int Config.session_period_seconds)
      in
      (Calendar.add (Calendar.now ()) period, CalendarLib.Time_Zone.current ())
    in
    let session_id = session_id account uid in
    PGSQL(dbh)
      "UPDATE member SET (session_id, session_expiration) = ($session_id, $expiration) WHERE user_id = $uid";
    `Stringlit session_id
  in

  fun dbh -> function
  | account :: [] ->
    Some (body dbh account (Bibman.user_id_or_raise dbh account))
  | _ -> assert false
;;

let certificate =
  let raise_exception () =
    raise (Bibman.Invalid_argument "session_id")
  in

  let body dbh uid session_id =
    let expiration_opt =
      PGSQL(dbh)
        "SELECT session_expiration FROM member WHERE user_id = $uid AND session_id = $session_id"
    in
    match expiration_opt with
    | [Some (expiration, _)] -> begin
      let module Calendar = CalendarLib.Calendar in
      let now = Calendar.now () in
      if compare now expiration <= 0 then ()
      else raise_exception ()
    end
    | _ -> raise_exception ()
  in

  fun dbh -> function
  | account :: session_id :: [] ->
    body dbh (Bibman.user_id_or_raise dbh account) session_id;
    None
  | _ -> assert false
;;

let confirm =
  let body dbh uid password =
    let password = Bibman.encrypt password in
    match Model.exists
      (PGSQL(dbh)
         "SELECT 1 FROM member WHERE user_id = $uid AND password = $password")
    with
    | false -> raise (Bibman.Invalid_argument "account and/or password")
    | true -> ()
  in

  fun dbh -> function
  | account :: password :: [] ->
    body dbh (Bibman.user_id_or_raise dbh account) password;
    None
  | _ -> assert false
;;

let logout =
  let body dbh uid =
    PGSQL(dbh)
      "UPDATE member SET (session_id, session_expiration) = (NULL, NULL) WHERE user_id = $uid"
  in

  fun dbh -> function
  | account :: [] ->
    body dbh (Bibman.user_id_or_raise dbh account);
    None
  | _ -> assert false
;;

let regenerate_password =

  let generate_password () =
    let password_length = 10 in
    let module Random = Cryptokit.Random in
    let raw = Random.string Random.secure_rng password_length in
    let trans = Cryptokit.Base64.encode_compact () in
    trans # put_string raw;
    let password = trans # get_string in
    String.sub password 0 10
  in

  let body dbh uid account =
    let new_password = generate_password () in
    let () =
      let content =
        Bibman.substitute_symbol
          (function
          | "u" -> Some account
          | "p" -> Some new_password
          | _ -> None)
          Config.regen_password_content
      in
      Bibman.send_mail account Config.regen_password_subject content
    in
    let encrypted_password = Bibman.encrypt new_password in
    PGSQL(dbh) "UPDATE member SET (password) = ROW($encrypted_password) WHERE user_id = $uid"
  in

  fun dbh -> function
  | account :: [] ->
    body dbh (Bibman.user_id_or_raise dbh account) account;
    None
  | _ -> assert false
;;

let is_user_admin =
  let raise_exception () =
    raise (Bibman.Invalid_argument "is_admin")
  in

  let body dbh uid =
    match (Model.is_admin_of_user_id dbh uid) with
    | true -> ()
    | false -> raise_exception ()
  in

  fun dbh -> function
  | account :: [] ->
    body dbh (Bibman.user_id_or_raise dbh account);
    None
  | _ -> assert false
;;

let actions = [
  ("generate_session", ([`NonEmpty "account"; ], generate_session));
  ("certificate", ([`NonEmpty "account"; `NonEmpty "session_id"], certificate));
  ("confirm", ([`NonEmpty "account"; `NonEmpty "password"], confirm));
  ("logout", ([`NonEmpty "account"; ], logout));
  ("regenerate_password", ([`NonEmpty "account"; ], regenerate_password));
  ("is_user_admin", ([`NonEmpty "account"; ], is_user_admin));
]
;;

let () = Bibman.run actions Sys.argv
;;
