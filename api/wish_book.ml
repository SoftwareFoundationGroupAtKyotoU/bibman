open BibmanNet
;;

let main (cgi: Netcgi.cgi) _ =
  redirect_to_script cgi Config.script_catalog [ "wish_book"; ]
;;

let () = run
  ~req_http_method:[`GET; `HEAD; ]
  ~req_content_type:[ MimeType.json; ]
  (certification_check_wrapper main)
;;
