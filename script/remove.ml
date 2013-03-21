let wish_book =
  let remove_book dbh bid =
    PGSQL(dbh) "DELETE FROM book WHERE book_id = $bid";
    PGSQL(dbh) "DELETE FROM history WHERE book_id = $bid";
    PGSQL(dbh) "DELETE FROM lending WHERE book_id = $bid";
    PGSQL(dbh) "DELETE FROM reservation WHERE book_id = $bid";
  in

  let body dbh bid =
    match
      Model.exists (PGSQL(dbh) "SELECT 1 FROM wish_book WHERE book_id = $bid")
    with
    | false -> raise (Bibman.Invalid_argument "book-id")
    | true -> begin
      remove_book dbh bid;
      PGSQL(dbh) "DELETE FROM wish_book WHERE book_id = $bid"
        (* TODO: mail to registerer *)
    end
  in

  fun dbh -> function
  | bid :: [] ->
    body dbh (Int32.of_string bid);
    None
  | _ -> assert false

let actions = [
  ("wish_book", ([ `Int32 "book-id"; ], wish_book));
]
;;

let () = Bibman.run actions Sys.argv
;;
