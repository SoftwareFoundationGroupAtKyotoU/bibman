open BibmanNet
;;

let main (cgi : Netcgi.cgi) =
  let account =
    try cgi # argument_value "account" with
    | Not_found -> raise (BibmanNet.Invalid_argument "account")
  in
  ignore (
    process_command Config.script_user [ "regenerate_password"; account; ]
  );
  cgi # set_header
    ~status:`See_other
    ~fields:[("Location", [ "../index.html"; ])]
    ()
;;

let () = run
  ~req_http_method:[ `POST; ]
  ~req_content_type:[ MimeType.form_encoded; ]
  ~required_params:[ ("account", `NonEmpty); ]
  main
;;
