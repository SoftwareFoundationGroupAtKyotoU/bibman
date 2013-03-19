open BibmanNet
;;

let main (cgi: Netcgi.cgi) (account : string) =
  let arg_value = cgi # argument_value in
  let action = arg_value "action" in
  let book_id = arg_value "id" in
  let args =
    if action = "return" then [ action; book_id; ]
    else [ action; account; book_id ]
  in
  redirect_to_script
    cgi
    ~content_type:MimeType.text
    Config.script_lending args
;;

let () = run
  ~req_http_method:[ `POST; ]
  ~req_content_type:[ MimeType.form_encoded; ]
  ~required_params:[
    ("action", `Symbol ["lend"; "return"; "reserve"; "cancel"]);
    ("id", `Int32);
  ]
  (certification_check_wrapper main)
;;
