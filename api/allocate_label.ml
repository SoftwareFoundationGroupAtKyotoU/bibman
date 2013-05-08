open BibmanNet
;;

let main (cgi: Netcgi.cgi) _ =
  let id = cgi # argument_value "id" in
  redirect_to_script
    cgi
    ~content_type:MimeType.text
    Config.script_edit
    [ "allocate-label"; id; ]
;;

let () = run
  ~req_http_method:[ `POST; ]
  ~req_content_type:[ MimeType.form_encoded; ]
  ~required_params:[ ("id", `Int32); ]
  (certification_check_wrapper main)
;;
