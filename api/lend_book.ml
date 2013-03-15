open BibmanNet
;;

(* TODO: SESSION MANAGE *)

let default_action cgi =
  let arg_value = cgi # argument_value in
  redirect_to_script
    cgi
    ~content_type:MimeType.text
    "../script/lending"
    [ arg_value "action"; arg_value "account"; arg_value "id"; ]
;;

let return_action cgi =
  let book_id = cgi # argument_value "id" in
  match process_command "../script/lending" [ "return"; book_id; ] with
  | None -> cgi # set_header ~status: `Bad_request ()
  | Some _ -> begin
    try process_command "../script/lending" [ "next_reserver"; book_id; ] with
    | None -> cgi # set_header ~status:`Bad_request ()
    | Some reserver -> begin
      let addr = Printf.sprintf "%s@%s" reserver Config.mail_domain in
      let in_ch =
        Unix.open_process_in (Printf.sprintf "cat %s" Config.lending_content)
      in
      ignore (
        process_command
          ~in_fd: Unix.descr_of_in_channel in_ch
          "../script/lending"
          [ book_id; reserver; addr; Config.mail_sender_name;
            Config.mail_sender_address; Config.lending_subject;
          ]
      );
      ignore (Unix.close_process_in in_ch);
      ()
    end
  end
  redirect_to_script
    cgi
    ~content_type:MimeType.text
  

let main (cgi: Netcgi.cgi) : unit =
  if (cgi # argument_value "action") = "return" then
    return_action cgi
  else
    default_action cgi
;;

let () = run
  ~req_http_method:[ `POST; ]
  ~req_content_type:[ MimeType.form_encoded; ]
  ~required_params:[
    ("action", `Symbol ["lend"; "return"; "reserve"; "cancel"]);
    ("account", `NonEmpty);
    ("id", `Int32);
  ]
  main
;;
