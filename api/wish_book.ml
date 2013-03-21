open BibmanNet
;;

let list (cgi : Netcgi.cgi) =
  redirect_to_script cgi Config.script_catalog [ "wish_book"; ]
;;

let remove (cgi : Netcgi.cgi) =
  let id =
    try
      let id = cgi # argument_value "id" in
      ignore (Int32.of_string id);
      id
    with
    | Not_found | Failure _ -> raise (BibmanNet.Invalid_argument "id")
  in
  redirect_to_script
    cgi
    ~content_type:MimeType.text
    Config.script_remove
    [ "wish_book"; id; ]
;;

let main (cgi: Netcgi.cgi) _ =
  let action = cgi # argument_value "action" in
  let req_method = cgi # request_method in
  if action = "list" && (req_method = `GET || req_method = `HEAD) then
    ignore (list cgi)
  else if action = "remove" && (req_method = `POST) then
    ignore (remove cgi)
  else
    cgi # set_header ~status:`Method_not_allowed ()
;;

let () = run
  ~req_content_type:[ MimeType.json; MimeType.form_encoded; ]
  ~required_params:[
    ("action", `Symbol [ "list"; "remove"; ]);
  ]
  (certification_check_wrapper main)
;;
