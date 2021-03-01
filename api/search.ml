
(*
  JSON FORMAT

  id:
    {
      id: number, /* book id */
      title: string,
      publish_year: number,
      author: [ string ],
      publisher: string,
      isbn: string,
      kind: string,
      status: string,
      label: string,
      location: string
     }

  isbn:
    {
      title: string,
      publish_year: number,
      author: [ string ],
      publisher: string,
      isbn: string,
    }

  query:
    [ { id: number, ... /* same as above */ } , ...]
*)

open BibmanNet
;;

let query (cgi: Netcgi.cgi) query =
  let queries =
    BatList.sort_unique
      String.compare
      (BatString.split_on_string " " query)
  in
  redirect_to_script
    cgi
    Config.script_search
    ([ "keyword"; ] @ queries)
;;

let id (cgi: Netcgi.cgi) id =
  redirect_to_script
    cgi
    Config.script_search
    [ "id"; id; ]
;;

let isbn (cgi: Netcgi.cgi) isbn =
  redirect_to_script
    cgi
    Config.script_search
    [ "isbn"; isbn; ]

let actions = [
  ("query", query);
  ("id", id);
  ("isbn", isbn);
]
;;

let main (cgi: Netcgi.cgi) _ =
  try
    List.iter (function (param, action) ->
      if cgi # argument_exists param then
        let p = cgi # argument_value param in
        if not (BatString.is_empty p) then begin
          ignore (action cgi p);
          raise Exit
        end)
      actions;
    raise (BibmanNet.Absent_argument (String.concat " or " (List.map fst actions)))
  with
    Exit -> ()
;;

let () = run
  ~req_http_method:[`GET; `HEAD; ]
  ~req_content_type:[ MimeType.json; ]
  (certification_check_wrapper main)
;;
