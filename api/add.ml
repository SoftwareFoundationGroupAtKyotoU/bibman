open BibmanNet
;;

let main (cgi: Netcgi.cgi) _ =
  let arg_value = cgi # argument_value in
  let item = arg_value "item" in
  let value = arg_value "value" in
  redirect_to_script
    cgi
    ~content_type:MimeType.text
    Config.script_add
    [ item; value; ]
;;

let () = run
  ~req_http_method:[ `POST; ]
  ~req_content_type:[ MimeType.form_encoded; ]
  ~required_params:[
    ("item", `Symbol [ "publisher"; ]);
    ("value", `NonEmpty);
  ]
  (certification_check_wrapper main)
;;
