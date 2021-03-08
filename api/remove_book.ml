open BibmanNet
;;

let main (cgi: Netcgi.cgi) _ =
  let arg_value = cgi # argument_value in
  let book_id = arg_value "id" in
  redirect_to_script cgi
    ~content_type:MimeType.text
    Config.script_remove [ "book" ; book_id; ]
;;

let () = run
  ~req_http_method:[`POST; ]
  ~req_content_type:[ MimeType.form_encoded; ]
  ~required_params:[
    ("id", `Int32)
  ]
  (certification_and_admin_check_wrapper main);
;;