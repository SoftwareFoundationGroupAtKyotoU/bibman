CalendarLib.Time_Zone.change CalendarLib.Time_Zone.Local
;;

let debug =
  let df = try Sys.getenv "DEBUG" <> "" with Not_found -> false in
  if df then prerr_endline else (fun _ -> ())

type spec = [
| `String of string
| `NonEmpty of string
| `Int32 of string
| `Any of spec
]
;;

let rec check_args (schema : spec list) (args : string list) : bool =
  let error msg =
    prerr_endline msg;
    false
  in
  match schema, args with
  | [], [] -> true
  | `String _ :: ts, _ :: ta -> check_args ts ta
  | `NonEmpty name :: ts, str :: ta -> begin
    if BatString.is_empty str then
      error (Printf.sprintf "The %s must be non-empty" name)
    else
      check_args ts ta
  end
  | `Int32 name :: ts, str :: ta -> begin
    let convertible =
      try ignore (Int32.of_string str); true with
        Failure _ ->
          error (Printf.sprintf "The %s must be an integer" name)
    in
    convertible && check_args ts ta
  end
  | `Any spec :: _, _ ->
    List.for_all (fun x -> check_args [spec] [x]) args
  | (`String name | `NonEmpty name | `Int32 name) :: _, [] ->
    error (Printf.sprintf "The argument for %s isn't given" name)
  | [], _ :: _ ->
    error "The arguments are too many"
;;

exception Invalid_argument of string
;;

let error name msg =
  prerr_endline msg;
  raise (Invalid_argument name)
;;

type 'a process = 'a PGOCaml.t PGOCaml.monad -> string list -> Yojson.json option
;;
type 'a action = string * (spec list * 'a process)
;;

let db_options () =
    let host = ref Config.db_host in
    let user = ref Config.db_username in
    let passwd = ref Config.db_password in
    let db = ref Config.db_database in
    let options = [
      ("-host", Arg.Set_string host,
       " Host name on which the database service is working");
      ("-user", Arg.Set_string user,
       " User name as who the program connects to the database");
      ("-password", Arg.Set_string passwd,
       " Password for aurhoization of login to the database");
      ("-database", Arg.Set_string db,
       " Name of the database to be connected");
    ]
    in
    (options, host, user, passwd, db)
;;

let run =
  let rec name_of_spec = function
    | `String x | `NonEmpty x | `Int32 x -> x
    | `Any spec -> name_of_spec spec
  in

  let body actions host user password database action args =
    let (schema, process) = try List.assoc action actions with
      | Not_found -> 
        prerr_endline (Printf.sprintf "Action %s is not found" action);
        exit 1
    in
    let usage =
      let names =
        List.map (fun spec -> Printf.sprintf "[%s]" (name_of_spec spec)) schema
      in
      Printf.sprintf "Usage: %s %s" action (String.concat " " names)
    in
    let args = List.map BatString.trim args in
    if not (check_args schema args) then begin
      prerr_endline usage; exit 1
    end else
      let dbh = PGOCaml.connect ~host ~user ~password ~database () in
      let closed = ref false in
      let finally () =
        if not !closed then (PGOCaml.close dbh; closed := true)
      in
      at_exit finally;
      try
        (match process dbh args with
        | Some json -> print_endline (Yojson.pretty_to_string json)
        | None -> ());
        finally ()
      with
      | Invalid_argument name -> begin
        prerr_endline (Printf.sprintf "The argument for %s is invalid" name);
        exit 1
      end
      | e -> finally (); raise e
  in

  let general_usage actions =
    let options, _, _, _, _ = db_options () in
    let usage =
      let action_names =
        List.map (fun (name, _) -> Printf.sprintf "'%s'" name) actions
      in
      Printf.sprintf "Usage: [ %s ] [args ...]"
        (String.concat " | " action_names)
    in
    Arg.usage_string (Arg.align options) usage
  in

  let parse_argv argv actions =
    let options, host, user, passwd, db = db_options () in
    let args = ref [] in
    let args_fun str = args := str :: !args in
    let helped =
      try Arg.parse_argv argv options args_fun ""; false with
      | Arg.Help _ -> print_endline (general_usage actions); true
      | Arg.Bad msg -> prerr_endline msg; true
    in
    if helped then `Helped
    else match List.rev !args with
      | [] -> `NoAction
      | action :: rest_args ->
        `Action (action, rest_args, !host, !user, !passwd, !db)
  in

  fun (actions :  'a action list) (argv : string array) ->
    match parse_argv argv actions with
    | `Action (action, args, host, user, passwd, db) ->
      body actions host user passwd db action args
    | `NoAction -> prerr_endline (general_usage actions);
    | `Helped -> ()
;;


(* Misc *)
let substitute_symbol =
  let rex = Pcre.regexp ~flags:[ `UTF8; ] "\\$[a-zA-Z_]+" in
  fun (f : string -> string option) (content : string) ->
    let subst str =
      let name = String.sub str 1 (String.length str - 1) in
      match f name with
      | Some v -> v
      | None -> str
    in
    Pcre.substitute ~rex ~subst content
;;

let substitute_book_info =
  let substitute (book, entry, authors, publisher) = function
    | "i" -> Some (Model.isbn_of_entry entry)
    | "t" -> Some (Model.title_of_entry entry)
    | "a" -> Some (String.concat ", " authors)
    | "p" -> Some publisher
    | "y" -> Some (Int32.to_string (Model.publish_year_of_entry entry))
    | "l" -> Some (Model.location_of_book book)
    | _ -> None
  in

  fun dbh bid content ->
    match Model.book_info_of_book_id dbh bid with
    | None -> None
    | Some info ->
      Some (substitute_symbol (substitute info) content)
;;

let send_mail
  (account : string)
  ?(address = Printf.sprintf "%s@%s" account Config.mail_domain)
  (subject : string)
  (content : string)
  : unit =
  let message = Netsendmail.compose
    ~from_addr: Config.mail_sender
    ~to_addrs:  [account, address]
    ~subject:   subject
    content
  in
  Netsendmail.sendmail message
;;

let send_book_mail
    dbh
    (bid : int32)
    (account : string)
    ?(address = Printf.sprintf "%s@%s" account Config.mail_domain)
    (subject : string)
    (content : string)
  : bool =
  match substitute_book_info dbh bid content with
  | None -> false
  | Some content ->
    send_mail account ~address subject content;
    true
;;

let user_id_or_raise dbh account =
  match Model.find_user_id dbh account with
  | None -> raise (Invalid_argument "account")
  | Some uid -> uid
;;

let encrypt password =
  let hash = Cryptokit.Hash.sha256 () in
  hash # add_string password;
  hash # result
;;
