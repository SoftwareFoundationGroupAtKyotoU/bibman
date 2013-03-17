open BibmanNet
;;

let main (cgi: Netcgi.cgi) =
  redirect_to_script cgi "../script/catalog" [ "wish_book"; ]
;;

let () = run
  ~req_http_method:[`GET; `HEAD; ]
  ~req_content_type:[ MimeType.json; ]
  main
;;
