open BibmanNet
;;

let check_item =
  let item_to_range = [
    ("location", Config.location_names);
    ("kind", Config.kind_values);
    ("status", Config.status_values);
  ]
  in

  fun (item : string) (value : string) ->
    let res =
      try List.exists ((=) value) (List.assoc item item_to_range) with
      | Not_found -> true
    in
    if not res then
      raise (BibmanNet.Invalid_argument "value")
;;

let main (cgi: Netcgi.cgi) _ : unit =
  let arg_value = cgi # argument_value in
  let book_id = arg_value "id" in
  let item = arg_value "item" in
  let value = arg_value "value" in
  check_item item value;
  let success =
    redirect_to_script
      cgi
      ~content_type:MimeType.text
      Config.script_edit
      [ item; book_id; value; ]
  in
  if success && item = "status" && value = Config.status_purchase then
    ignore (process_command Config.script_edit [ "purchase"; book_id; ])
;;

let () = run
  ~req_http_method:[ `POST; ]
  ~req_content_type:[ MimeType.form_encoded; ]
  ~required_params:[
    ("id", `Int32);
    ("item", `Symbol ["title"; "author"; "publish_year"; "publisher";
                      "location"; "kind"; "label"; "status"; ]);
    ("value", `Any);
  ]
  (certification_check_wrapper main)
;;
