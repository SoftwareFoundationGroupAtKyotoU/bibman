open BibmanNet
;;

(* TODO: check value for kind, location and so on *)

let main (cgi: Netcgi.cgi) : unit =
  let arg_value = cgi # argument_value in
  let book_id = arg_value "id" in
  let item = arg_value "item" in
  let value = arg_value "value" in
  redirect_to_script
    cgi
    ~content_type:MimeType.text
    "../script/edit"
    [ item; book_id; value; ]
;;

let () = run
  ~req_http_method:[ `POST; ]
  ~req_content_type:[ MimeType.form_encoded; ]
  ~required_params:[
    ("id", `Int32);
    ("item", `Symbol ["isbn"; "title"; "publish_year"; "publisher";
                      "location"; "kind"; "label"; "status"; ]);
    ("value", `Any);
  ]
  main
;;
