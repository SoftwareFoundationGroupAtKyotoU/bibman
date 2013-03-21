open Model
;;

let my_books dbh account (book_ids_of_uid : int32 -> int32 list) =
  let uid = Bibman.user_id_or_raise dbh account in
  let bids = book_ids_of_uid uid in
  Some (`List (BatList.filter_map (json_of_book_id dbh) bids))
;;

let lending dbh = function
  | account :: [] ->
    my_books dbh account
      (fun uid -> PGSQL(dbh) "SELECT book_id FROM lending WHERE user_id = $uid ORDER BY start_date DESC")
  | _ -> assert false
;;

let history dbh = function
  | account :: [] ->
    my_books dbh account
      (fun uid -> PGSQL(dbh) "SELECT book_id FROM history WHERE user_id = $uid ORDER BY start_date DESC")
  | _ -> assert false
;;

let reservation dbh = function
  | account :: [] ->
    my_books dbh account
      (fun uid -> PGSQL(dbh) "SELECT book_id FROM reservation WHERE user_id = $uid ORDER BY reservation_date DESC")
  | _ -> assert false
;;

let actions = [
  ("lending", ([`NonEmpty "account"; ], lending));
  ("history", ([`NonEmpty "account"; ], history));
  ("reservation", ([`NonEmpty "account"; ], reservation));
]
;;

let () = Bibman.run actions Sys.argv
;;
