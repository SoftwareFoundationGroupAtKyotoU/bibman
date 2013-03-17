open BibmanNet
;;

(* TODO: SESSION MANAGE *)

let main (cgi: Netcgi.cgi) =
  let arg_value = cgi # argument_value in
  let action = arg_value "action" in
  let account = arg_value "account" in
  let book_id = arg_value "id" in
  let args =
    if action = "return" then [ action; book_id; ]
    else [ action; account; book_id ]
  in
  redirect_to_script
    cgi
    ~content_type:MimeType.text
    "../script/lending" args
;;

let () = run
  ~req_http_method:[ `POST; ]
  ~req_content_type:[ MimeType.form_encoded; ]
  ~required_params:[
    ("action", `Symbol ["lend"; "return"; "reserve"; "cancel"]);
    ("account", `NonEmpty);
    ("id", `Int32);
  ]
  main
;;
