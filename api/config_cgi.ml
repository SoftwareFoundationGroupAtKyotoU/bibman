(*
  JSON FORMAT

  {
    book : {
      publisher : {
        values : [ string ]
      },
      kind : {
        values : [ string ]
      },
      status : {
        values : [ string ],
        purchase : string
      },
      location : {
        values : [ string ]
      }
    }
  }

*)

open BibmanNet
;;

let json_of_string_list l =
  `List (List.map (fun x -> `String x) l)
;;

let main (cgi: Netcgi.cgi) : unit =
  match process_command "../script/catalog" [ "publisher"; ] with
  | None -> cgi # set_header ~status:`Bad_request ()
  | Some publishers -> begin
    let json = `Assoc [
      ("book", `Assoc [
        ("publisher", `Assoc [
          ("values", `Stringlit publishers);
        ]);
        ("kind", `Assoc [
          ("values", json_of_string_list Config.kind_values);
        ]);
        ("status", `Assoc [
          ("values", json_of_string_list Config.status_values);
          ("purchase", `String Config.status_purchase);
        ]);
        ("location", `Assoc [
          ("values", json_of_string_list Config.location_values);
        ]);
      ]);
    ]
    in
    cgi # out_channel # output_string (Yojson.pretty_to_string json);
    cgi # out_channel # commit_work ()
  end
;;

let () = run
  ~req_http_method:[`GET; `HEAD; ]
  ~req_content_type:[ MimeType.json; ]
  main
;;
