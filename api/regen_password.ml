open BibmanNet
;;

let main (cgi : Netcgi.cgi) =
  let account = cgi # argument_value "account" in
  ignore (
    process_command Config.script_add [ "user"; account; "hoge"; ]
  );
  ignore (
    process_command Config.script_user [ "regenerate_password"; account; ]
  );
  cgi # set_header
    ~status:`See_other
    ~fields:[("Location", [ Config.root_path; ])]
    ()
;;

let () = run
  ~req_http_method:[ `POST; ]
  ~req_content_type:[ MimeType.form_encoded; ]
  ~required_params:[ ("account", `NonEmpty); ]
  main
;;
