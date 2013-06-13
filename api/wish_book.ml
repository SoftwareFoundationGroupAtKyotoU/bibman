open BibmanNet
;;

let list (cgi : Netcgi.cgi) =
  redirect_to_script cgi Config.script_catalog [ "wish_book"; ]
;;

let remove (cgi : Netcgi.cgi) =
  redirect_to_script
    cgi
    ~content_type:MimeType.text
    Config.script_remove
    [ "wish_book"; cgi # argument_value "id"; ]
;;

let main (cgi: Netcgi.cgi) _ =
  let req_method = cgi # request_method in
  match cgi # argument_value "action" with
  | "list" when req_method = `GET || req_method = `HEAD ->
    ignore (list cgi)
  | "remove" when req_method = `POST ->
    ignore (remove cgi)
  | _ ->
    cgi # set_header ~status:`Method_not_allowed ()
;;

let () = run
  ~req_content_type:[ MimeType.json; MimeType.form_encoded; ]
  ~required_params:[
    ("action", `Action [
      ("list", []);
      ("remove", [ "id", `Int32 ]);
    ]);
  ]
  (certification_check_wrapper main)
;;
