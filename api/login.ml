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
  let is_user_admin = process_command Config.script_user [ "is_user_admin"; account] in
  match m, is_user_admin with
  | Some session_id, Some _ -> begin
    let json = `Assoc [
      ("account", `String account);
      ("is_admin", `String "true")
    ]
    in
    set_certification_info ~account ~session_id ~cookie_path:Config.root_path cgi;
    cgi # out_channel # output_string (Yojson.pretty_to_string json);
    cgi # out_channel # commit_work ()
  end
  | Some session_id, None -> begin
    let json = `Assoc [
      ("account", `String account);
      ("is_admin", `String "false")
    ]
    in
    set_certification_info ~account ~session_id ~cookie_path:Config.root_path cgi;
    cgi # out_channel # output_string (Yojson.pretty_to_string json);
    cgi # out_channel # commit_work ()
  end
  | _ -> raise (BibmanNet.Invalid_argument "account")
;;

let () = run
  ~req_http_method:[ `POST; ]
  ~req_content_type:[ MimeType.form_encoded; ]
  ~required_params:[ ("account", `NonEmpty); ("password", `NonEmpty); ]
  main
;;
