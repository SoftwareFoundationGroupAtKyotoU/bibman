open Model
;;

let list dbh _ =
  (* CONCAT_WS (',' ,entry.title, book.location, book.kind, book.status, book.label, entry.isbn, entry.title, member.account) *)
  (* DB values defined utf-8 in db configuration *)
  (* ShiftJIS needs for default excel *)
  let lists = 
    PGSQL(dbh) "nullable-results" 
    "SELECT convert_to(CONCAT_WS(',', entry.title, book.location, book.kind, book.status, book.label, entry.isbn, COALESCE(member.account, '')), 'shift_jis') from book \ \
    INNER JOIN entry ON book.isbn = entry.isbn \
    LEFT OUTER JOIN lending ON book.book_id = lending.book_id \
    LEFT OUTER JOIN member ON lending.user_id = member.user_id \
    WHERE book.book_id NOT IN (SELECT book_id FROM wish_book)"
  in
  let dq = "\"" in
  let concat_symbol = "\",\"" in
  let csv_str = (List.fold_left
    (fun a b -> a ^ b)
    (dq ^ "title" ^ concat_symbol ^ "location" ^ concat_symbol ^ "kind"
    ^ concat_symbol ^ "status" ^ concat_symbol ^ "label" ^ concat_symbol ^ "isbn" ^ concat_symbol ^ "account" ^ "\"\n")
    (List.map (fun bd -> csv_of_book_detail bd) lists))
  in
    (Some (`Stringlit (csv_str)))
;;

let actions = [
  ("list", ([], list));
]
;;

let () = Bibman.run actions Sys.argv
;;