open BibmanNet
;;

let main (cgi: Netcgi.cgi) (account : string) : unit =
  cgi # set_header ~content_type: MimeType.json ();
  let l = List.fold_left (fun acc target ->
    match acc with
    | None -> None
    | Some l -> begin
      match process_command Config.script_my_book [ target; account ] with
      | None -> None
      | Some json -> Some ((target, json) :: l)
    end)
    (Some []) [ "lending"; "reservation"; "history"; ]
  in
  (match l with
  | Some target_json_list ->
    let json =
      Printf.sprintf "{ %s }"
        (String.concat ", "
           (List.map
              (fun (target, json) -> Printf.sprintf "\"%s\" : %s" target json)
              target_json_list))
    in
    cgi # out_channel # output_string json
  | None -> cgi # set_header ~status:`Bad_request ());
  cgi # out_channel # commit_work ();
;;

let () = run
  ~req_http_method:[`GET; `HEAD; ]
  ~req_content_type: [ MimeType.json; ]
  (certification_check_wrapper main)
;;
