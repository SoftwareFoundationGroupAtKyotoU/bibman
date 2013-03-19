open BibmanNet
;;

let main (cgi: Netcgi.cgi) : unit =
  let arg_value = cgi # argument_value in
  let isbn = arg_value "isbn" in
  let title = arg_value "title" in
  let authors = arg_value "author" in
  let pyear = arg_value "publish_year" in
  let publisher = arg_value "publisher" in
  ignore (
    process_command
      "../script/add"
      [ "entry"; isbn; title; authors; pyear; publisher; ]
  );
  let kind = arg_value "kind" in
  let label = arg_value "label" in
  let status = arg_value "status" in
  let loc = arg_value "location" in
  let bid = ref "" in
  let success =
    redirect_to_script
      cgi
      ~content_type:MimeType.text
      ~output: (fun id -> bid := id; cgi # out_channel # output_string id)
      "../script/add"
      [ "book"; isbn; loc; kind; label; status; ]
  in
  if success then ignore (
    if status = Config.status_purchase then
      process_command "../script/edit" [ "purchase"; !bid; ]
    else
      process_command "../script/add" [ "wish_book"; "t-sekiym"; !bid ] (* TODO: user account *)
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
    ("label", `Any);
    ("status", `Symbol Config.status_values);
    ("location", `Symbol Config.location_values);
  ]
  main
;;
