open BibmanNet
;;

let main (cgi: Netcgi.cgi) _ =
  redirect_to_script cgi
    ~content_type:MimeType.csv
    ~filename:"book-list.csv"
    Config.script_download_csv [ "list" ; ]
;;

let () = run
  ~req_http_method:[`GET; ]
  ~req_content_type:[ MimeType.csv; ]
  (certification_and_admin_check_wrapper main);
;;