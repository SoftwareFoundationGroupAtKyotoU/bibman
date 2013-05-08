open BibmanNet
;;

let main (cgi: Netcgi.cgi) _ =
  let arg_val = cgi # argument_value in
  redirect_to_script cgi
    ~content_type:MimeType.tex
    Config.script_tex [
      "tosho";
      arg_val "id";
      arg_val "purchaser";
      arg_val "sent-date";
      arg_val "budget";
      arg_val "number";
      arg_val "price";
      arg_val "note";
    ]
;;

let () = run
  ~req_http_method:[ `GET; `HEAD; ]
  ~required_params:[
    ("id", `Int32);
    ("purchaser", `NonEmpty);
    ("sent-date", `NonEmpty);
    ("budget", `NonEmpty);
    ("number", `NonEmpty);
    ("price", `NonEmpty);
    ("note", `Any);
  ]
  (certification_check_wrapper main)
;;
