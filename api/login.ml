open BibmanNet
;;

let main (cgi : Netcgi.cgi) =
  let account = cgi # argument_value "account" in
  let password = cgi # argument_value "password" in
  let open BatOption.Monad in
  let m = process_command Config.script_user [ "confirm"; account; password; ] in
  let m = bind m (fun _ -> 
    process_command Config.script_user [ "generate_session"; account; ]
  )
  in
  match m with
  | None -> raise (BibmanNet.Invalid_argument "account")
  | Some session_id -> begin
    set_certification_info ~account ~session_id ~cookie_path:Config.root_path cgi;
    cgi # out_channel # output_string account;
    cgi # out_channel # commit_work ()
  end
;;

let () = run
  ~req_http_method:[ `POST; ]
  ~req_content_type:[ MimeType.form_encoded; ]
  ~required_params:[ ("account", `NonEmpty); ("password", `NonEmpty); ]
  main
;;
