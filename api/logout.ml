open BibmanNet
;;

let main (cgi : Netcgi.cgi) (account : string) =
  redirect_to_script
    cgi
    ~content_type:MimeType.text
    Config.script_user
    [ "logout"; account; ]
;;

let () = run
  ~req_http_method:[ `POST; ]
  ~req_content_type:[ MimeType.form_encoded; ]
  (certification_check_wrapper main)
;;
