open BibmanNet
;;

let main (cgi: Netcgi.cgi) _ =
  let bid = cgi # argument_value "id" in
  redirect_to_script cgi
    ~content_type:MimeType.tex
    Config.script_tex
    [ "tosho"; bid; ]
;;

let () = run
  ~req_http_method:[ `GET; `HEAD; ]
  ~required_params:[
    ("id", `Int32);
  ]
  (certification_check_wrapper main)
;;
