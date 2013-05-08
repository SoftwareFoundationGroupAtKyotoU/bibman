
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

  query:
    [ { id: number, ... /* same as above */ } , ...]
*)

open BibmanNet
;;

let query (cgi: Netcgi.cgi) =
  let queries =
    BatList.sort_unique
      String.compare
      (BatString.nsplit (cgi # argument_value "query") " ")
  in
  redirect_to_script
    cgi
    Config.script_search
    ([ "keyword"; ] @ queries)
;;

let id (cgi: Netcgi.cgi) =
  redirect_to_script
    cgi
    Config.script_search
    [ "id"; cgi # argument_value "id"; ]
;;

let actions = [
  ("query", query);
  ("id", id);
]
;;

let main (cgi: Netcgi.cgi) _ =
  try
    List.iter (function (param, action) ->
      if cgi # argument_exists param &&
        not (BatString.is_empty (cgi # argument_value param)) then begin
          ignore (action cgi);
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
