open Config_file
;;

let group = new group
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

let status_values =
  new list_cp string_wrappers ~group ["status"; "values"; ] [] "options."
;;

let status_purchase =
  new string_cp ~group ["status"; "purchase"; ] ""
    "the value meaning \"purchase\" state."
;;

let location_values =
  new list_cp string_wrappers ~group ["location"; "values"; ] [] "options."
;;


let mail_domain =
  new string_cp ~group ["mail"; "domain"; ] "" "mail domain."
;;

let mail_sender =
  new tuple2_cp string_wrappers string_wrappers ~group ["mail"; "sender"]
    ("","") "name (in the first component) and address (in the second component) of mail sender."
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

let wish_book_subject =
  new string_cp ~group ["mail"; "wish_book"; "subject"; ] ""
    "subject of the mail for wish-book notifications."
;;

let wish_book_content =
  new string_cp ~group ["mail"; "wish_book"; "content"; ] ""
"content of the mail for wish-book notifications. Each alphabet following $ is replaced with information of a book.\n\
\t$t: title\n\
\t$a: author names\n\
\t$p: publisher\n\
\t$y: publisher year\n\
\t$l: location\n"
;;

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

let find_file name =
  let module PathGen = BatPathGen.OfString in
  let (/:) = PathGen.Operators.(/:) in
  let rec iter cur_path =
    let path = PathGen.to_string (cur_path /: name) in
    if Sys.file_exists path then Some path
    else
      let parent_path =
        try Some (PathGen.parent cur_path) with Invalid_argument _ -> None
      in
      match parent_path with
      | None -> None
      | Some parent_path -> iter parent_path
  in
  iter (PathGen.of_string (Sys.getcwd ()))

let path =
  try Sys.getenv "BIBMAN_CONFIG" with
    Not_found -> begin
      let filename = "configure.ml" in
      match find_file filename with
      | Some config_file -> config_file
      | None ->
        prerr_endline
          (Printf.sprintf "Cannot file the configure file '%s'" filename);
        exit 1
    end
;;

(* group # write path *)
(* ;; *)

group # read ~no_default:true path
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

let status_values = status_values # get
;;

let status_purchase =
  let v = status_purchase # get in
  if (List.exists ((=) v) status_values) then v
  else begin
    prerr_endline "specify a item within statsu values as the purchase state";
    exit 1
  end
;;

let location_values = location_values # get
;;

let mail_domain = mail_domain # get
;;

let mail_sender = mail_sender # get
;;

let lending_subject = lending_subject # get
;;

let lending_content = lending_content # get
;;

let wish_book_subject = wish_book_subject # get
;;

let wish_book_content = wish_book_content # get
;;

let db_host = db_host # get
;;

let db_username = db_username # get
;;

let db_password = db_password # get
;;

let db_database = db_database # get
;;
