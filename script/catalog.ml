let publisher dbh _ =
  let publishers = PGSQL(dbh) "SELECT name FROM publisher" in
  Some (`List (List.map (fun p -> `String p) publishers))
;;

let wish_book dbh _ =
  let bids = PGSQL(dbh) "SELECT book_id FROM wish_book" in
  Some (`List (BatList.filter_map (Model.json_of_book_id dbh) bids))
;;

let actions = [
  ("publisher", ([], publisher));
  ("wish_book", ([], wish_book));
]
;;

let () = Bibman.run actions Sys.argv
;;
