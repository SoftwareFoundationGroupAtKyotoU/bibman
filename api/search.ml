
(*
  JSON FORMAT

  [{
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
   }, ...]
*)

open BibmanNet
;;

let main (cgi: Netcgi.cgi) =
  let queries =
    BatList.sort_unique
      String.compare
      (BatString.nsplit (cgi # argument_value "query") " ")
  in
  redirect_to_script
    cgi
    "../script/search_book"
    ([ "keyword"; ] @ queries)
;;

let () = run
  ~req_http_method:[`GET; `HEAD; ]
  ~req_content_type:[ MimeType.json; ]
  ~required_params:[("query", `NonEmpty); ]
  main
;;
