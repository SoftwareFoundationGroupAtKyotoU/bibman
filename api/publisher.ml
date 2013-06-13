open BibmanNet
;;

let add (cgi: Netcgi.cgi) publisher =
  redirect_to_script
    cgi
    ~content_type:MimeType.text
    Config.script_add
    [ "publisher"; publisher; ]
;;

let main (cgi: Netcgi.cgi) _ =
  let arg_value = cgi # argument_value in
  match arg_value "action" with
  | "add" -> add cgi (arg_value "publisher")
  | _ -> assert false
;;

let () = run
  ~req_http_method:[ `POST; ]
  ~req_content_type:[ MimeType.form_encoded; ]
  ~required_params:[
    ("action", `Action [
      ("add", [ ("publisher", `NonEmpty); ]);
    ]);
  ]
  (certification_check_wrapper main)
;;
