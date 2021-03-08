open Config_file
;;

module Map = Map.Make (struct
                          type t = string
                          let compare = compare
                        end);;

let group = new group
;;

let root_path =
  new string_cp ~group ["root_path"; ] ""
    "root path with path separator (i.e., '/')."
;;

let lending_days =
  new int_cp ~group ["lending_days"; ] 0 "days for lending."
;;

let number_of_history_records =
  new int_cp ~group ["number_of_history_records"; ] 0
    "number of history records to be output."
;;


let session_period_seconds =
  new int_cp ~group ["session"; "period"; "seconds"; ] 0 "seconds."
;;

let session_period_minutes =
  new int_cp ~group ["session"; "period"; "minutes"; ] 0 "minutes."
;;

let session_period_hours =
  new int_cp ~group ["session"; "period"; "hours"; ] 0 "hours."
;;

let session_period_days =
  new int_cp ~group ["session"; "period"; "days"; ] 0 "days."
;;

let session_salt =
  new string_cp ~group ["session"; "salt"; ] "" "salt to generate session id."
;;

let kind_values =
  new list_cp string_wrappers ~group ["kind"; "values"; ] [] "options."
;;

let kind_expendable =
  new int_cp ~group ["kind"; "expendable"; ] (-1)
    "the index at which the value means \"expendable\" state."
;;

let status_values =
  new list_cp string_wrappers ~group ["status"; "values"; ] [] "options."
;;

let status_purchase =
  new int_cp ~group ["status"; "purchase"; ] (-1)
    "the index at which the value means \"expendable\" state."
;;

let locations =
  new list_cp (tuple2_wrappers string_wrappers string_wrappers) ~group
    ["locations"] []
    "locations where books are put: the first and second components are roles and identifiers of places, respectively."
;;

(* MAIL *)

let mail_domain =
  new string_cp ~group ["mail"; "domain"; ] "" "mail domain."
;;

let mail_sender =
  new tuple2_cp string_wrappers string_wrappers ~group ["mail"; "sender"]
    ("","") "name (in the first component) and address (in the second component) of mail sender."
;;

let mail_staff =
   new tuple2_cp string_wrappers string_wrappers ~group ["mail"; "staff"]
    ("","") "name and address of staff."
;;

let lending_subject =
  new string_cp ~group ["mail"; "lending"; "subject"; ] ""
    "subject of the mail for lending notifications."
;;

let lending_content =
  new string_cp ~group ["mail"; "lending"; "content"; ] ""
"content of the mail for lending notifications. Each alphabet following $ is replaced with information of a book.\n\
\t$t: title\n\
\t$a: author names\n\
\t$p: publisher\n\
\t$y: publisher year\n\
\t$l: location\n"
;;

let purchase_subject =
  new string_cp ~group ["mail"; "purchase"; "subject"; ] "" "Same as lending."
;;

let purchase_content =
  new string_cp ~group ["mail"; "purchase"; "content"; ] "" "Same as lending"
;;

let wish_book_registered_subject =
  new string_cp ~group ["mail"; "wish_book_registered"; "subject"; ] "" "Same as lending."
;;

let wish_book_registered_content =
  new string_cp ~group ["mail"; "wish_book_registered"; "content"; ] "" "Same as lending"
;;

let wish_book_removed_subject =
  new string_cp ~group ["mail"; "wish_book_removed"; "subject"; ] "" "Same as lending."
;;

let wish_book_removed_content =
  new string_cp ~group ["mail"; "wish_book_removed"; "content"; ] "" "Same as lending"
;;

let regen_password_subject =
  new string_cp ~group ["mail"; "regen_password"; "subject"; ] "" ""
;;

let regen_password_content =
  new string_cp ~group ["mail"; "regen_password"; "content"; ] "" ""
;;


(* DATABASE *)

let db_host = new string_cp ~group ["database"; "host"; ] ""
  "host name on which the database service is working"
;;

let db_username = new string_cp ~group ["database"; "username"; ] ""
  "user name as who the program connects to the database"
;;

let db_password = new string_cp ~group ["database"; "password"; ] ""
  "password for aurhoization of login to the database"
;;

let db_database = new string_cp ~group ["database"; "name"; ] ""
  "name of the database to be connected"
;;

(* SCRIPT *)
let script_search = new string_cp ~group ["script"; "search"; ] "" ""
;;

let script_my_book = new string_cp ~group ["script"; "my_book"; ] "" ""
;;

let script_edit = new string_cp ~group ["script"; "edit"; ] "" ""
;;

let script_add = new string_cp ~group ["script"; "add"; ] "" ""
;;

let script_remove = new string_cp ~group ["script"; "remove"; ] "" ""
;;

let script_catalog = new string_cp ~group ["script"; "catalog"; ] "" ""
;;

let script_lending = new string_cp ~group ["script"; "lending"; ] "" ""
;;

let script_user = new string_cp ~group ["script"; "user"; ] "" ""
;;

let script_tex = new string_cp ~group ["script"; "tex"; ] "" ""
;;

let script_download_csv = new string_cp ~group ["script"; "download_csv"; ] "" ""
;;

(* TEX *)
let tex_tosho = new string_cp ~group ["tex"; "tosho"; ] "" ""
;;

let tex_purchasers = new list_cp string_wrappers ~group ["tex"; "purchasers"; ] [] ""
;;

let tex_budgets = new list_cp string_wrappers ~group ["tex"; "budgets"; ] [] ""
;;


let find_entity (exists : string -> bool) (rel_path : string) =
  let module PathGen = BatPathGen.OfString in
  let (//@) = PathGen.Operators.(//@) in
  let rel_path = PathGen.of_string rel_path in
  let rec iter cur_path =
    let path = PathGen.to_string (cur_path //@ rel_path) in
    if exists path then Some path
    else
      let parent_path =
        try Some (PathGen.parent cur_path) with Invalid_argument _ -> None
      in
      match parent_path with
      | None -> None
      | Some parent_path -> iter parent_path
  in
  iter (PathGen.of_string (Sys.getcwd ()))
;;

let find_file (rel_path : string) = find_entity Sys.file_exists rel_path
;;

let find_file_or_exit (rel_path : string) =
  match find_file rel_path with
  | Some path -> path
  | None ->
    prerr_endline
      (Printf.sprintf "Cannot find the file '%s'" rel_path);
    exit 1
;;

let find_directory =
  let exists path =
    try Sys.is_directory path with
    | Sys_error _ -> false
  in

  fun (rel_path : string) ->
    BatOption.Monad.bind
      (find_entity exists rel_path)
      (fun dir_path -> (* with separator (/) *)
        let module PathGen = BatPathGen.OfString in
        let dir_path = PathGen.of_string dir_path in
        Some (PathGen.to_string (PathGen.Operators.(/:) dir_path "")))
;;

let find_directory_or_exit rel_path =
  match find_directory rel_path with
  | Some dir -> dir
  | None ->
    prerr_endline
      (Printf.sprintf "Cannot find the directory '%s' for scripts" rel_path);
    exit 1
;;


let read_script (group : Config_file.group) =
  let rel_path =
    let module PathGen = BatPathGen.OfString in
    let open PathGen.Operators in
    PathGen.to_string ((PathGen.of_string "config") /: "configure.ml")
  in
  let path = find_file_or_exit rel_path in
  group # read ~no_default:true path
;;

let () = read_script group
;;


let root_path =
  let module PathGen = BatPathGen.OfString in
  let path =
    PathGen.Operators.(/:) (PathGen.of_string root_path # get) ""
  in
  PathGen.to_string path
;;

let lending_days = lending_days # get
;;

let number_of_history_records = Int64.of_int (number_of_history_records # get)
;;


let session_period_seconds = session_period_seconds # get
;;

let session_period_minutes = session_period_minutes # get
;;

let session_period_hours = session_period_hours # get
;;

let session_period_days = session_period_days # get
;;

let session_salt = session_salt # get
;;


let kind_values = kind_values # get
;;

let kind_expendable =
  List.nth kind_values (kind_expendable # get)
;;

let status_values = status_values # get
;;

let status_purchase =
  List.nth status_values (status_purchase # get)
;;

let locations =
  List.fold_left
    (fun m (k,v) ->
     if Map.mem k m then begin
       prerr_endline "there are two or more places whose names are the same.";
       exit 1
     end else
       Map.add k v m)
    Map.empty (locations # get)
;;

let location_names = List.map fst (Map.bindings locations)

let mail_domain = mail_domain # get
;;

let mail_sender = mail_sender # get
;;

let mail_staff = mail_staff # get
;;

let lending_subject = lending_subject # get
;;

let lending_content = lending_content # get
;;

let purchase_subject = purchase_subject # get
;;

let purchase_content = purchase_content # get
;;

let wish_book_registered_subject = wish_book_registered_subject # get
;;

let wish_book_registered_content = wish_book_registered_content # get
;;

let wish_book_removed_subject = wish_book_removed_subject # get
;;

let wish_book_removed_content = wish_book_removed_content # get
;;

let regen_password_subject = regen_password_subject # get
;;

let regen_password_content = regen_password_content # get
;;


let db_host = db_host # get
;;

let db_username = db_username # get
;;

let db_password = db_password # get
;;

let db_database = db_database # get
;;


let file_path dir filename = dir ^ (filename # get)
;;


let script_dir = find_directory_or_exit "script"
;;

let script_file_path = file_path script_dir
;;

let script_search = script_file_path script_search
;;

let script_my_book = script_file_path script_my_book
;;

let script_edit = script_file_path script_edit
;;

let script_add = script_file_path script_add
;;

let script_remove = script_file_path script_remove
;;

let script_catalog = script_file_path script_catalog
;;

let script_lending = script_file_path script_lending
;;

let script_user = script_file_path script_user
;;

let script_tex = script_file_path script_tex
;;

let script_download_csv = script_file_path script_download_csv
;;


let static_dir = find_directory_or_exit "static"
;;

let static_file_path = file_path static_dir
;;

let tex_tosho = static_file_path tex_tosho
;;

let tex_purchasers = tex_purchasers # get
;;

let tex_budgets = tex_budgets # get
;;
