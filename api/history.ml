(*
  JSON FORMAT

  [{
    id: number, /* book id */
    history: [{
      account: string,
      from: string,
      to: string,
    }, ... ],
  }, ... ]
*)

open BibmanNet
;;

let main (cgi: Netcgi.cgi) _ =
  let book_ids =
    BatList.sort_unique
      String.compare
      (List.map (fun arg -> arg # value) (cgi # multiple_argument "id"))
  in
  redirect_to_script
    cgi
    Config.script_lending
    ([ "book-history"; ] @ book_ids)
;;

let () = run
  ~req_http_method:[`GET; `HEAD; ]
  ~req_content_type:[ MimeType.json; ]
  ~required_params:[("id", `Int32); ]
  (certification_check_wrapper main)
;;
