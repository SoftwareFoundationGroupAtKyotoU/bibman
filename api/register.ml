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
  redirect_to_script
    cgi
    ~content_type:MimeType.text
    "../script/add"
    [ "book"; isbn; loc; kind; label; status; ]
;;

  (* let publishers = *)
  (*   match process_command "../script/catalog" [ "publisher"; ] with *)
  (*   | None -> assert false *)
  (*   | Some json -> begin *)
  (*     let module JSON = Yojson.Basic in *)
  (*     List.map JSON.Util.to_string *)
  (*       (JSON.Util.to_list (JSON.from_string json)) *)
  (*   end *)
  (* in *)

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
