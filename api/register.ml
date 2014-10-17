open BibmanNet
;;

let main (cgi: Netcgi.cgi) (account : string) =
  let arg_value = cgi # argument_value in
  let isbn = arg_value "isbn" in
  let title = arg_value "title" in
  let authors = arg_value "author" in
  let pyear = arg_value "publish_year" in
  let publisher = arg_value "publisher" in
  ignore (
    process_command
      Config.script_add
      [ "entry"; isbn; title; authors; pyear; publisher; ]
  );
  let kind = arg_value "kind" in
  let status = arg_value "status" in
  let loc = arg_value "location" in
  let bid = ref "" in
  let success =
    redirect_to_script
      cgi
      ~content_type:MimeType.text
      ~output: (fun id -> bid := id; cgi # out_channel # output_string id)
      Config.script_add
      [ "book"; isbn; loc; kind; ""; status; ]
  in
  if success then ignore (
    if BatString.trim status = Config.status_purchase then
      process_command Config.script_edit [ "purchase"; !bid; ]
    else
      process_command Config.script_add [ "wish_book"; account; !bid ]
  )
;;

let () = run
  ~req_http_method:[ `POST; ]
  ~req_content_type:[ MimeType.form_encoded; ]
  ~required_params:[
    ("isbn", `NonEmpty);
    ("title", `NonEmpty);
    ("author", `NonEmpty);
    ("publish_year", `Int32);
    ("publisher", `NonEmpty);
    ("kind", `Symbol Config.kind_values);
    ("status", `Symbol Config.status_values);
    ("location", `Symbol Config.location_names);
  ]
  (certification_check_wrapper main)
;;
