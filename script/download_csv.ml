open Model
;;

let list dbh _ =
  (* CONCAT_WS (',' ,entry.title, book.location, book.kind, book.status, book.label, entry.isbn, entry.title, member.account) *)
  let lists = 
    PGSQL(dbh) "nullable-results" "SELECT entry.title, book.location, book.kind, book.status, book.label, entry.isbn, member.account from book \
    INNER JOIN entry ON book.isbn = entry.isbn \
    LEFT OUTER JOIN lending ON book.book_id = lending.book_id \
    LEFT OUTER JOIN member ON lending.user_id = member.user_id \
    WHERE book.book_id NOT IN (SELECT book_id FROM wish_book)"
  in
  let dq = "\"" in
  let concat_symbol = "\",\"" in
  Some (`Stringlit
    (List.fold_left
    (fun a b -> a ^ b)
    (dq ^ "title" ^ concat_symbol ^ "location" ^ concat_symbol ^ "kind"
     ^ concat_symbol ^ "status" ^ concat_symbol ^ "label" ^ concat_symbol ^ "isbn" ^ concat_symbol ^ "account" ^ "\"\n")
    (List.map (fun bd -> csv_of_book_detail bd) lists))
  )
;;

let actions = [
  ("list", ([], list));
]
;;

let () = Bibman.run actions Sys.argv
;;