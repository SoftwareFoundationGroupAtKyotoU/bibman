let wish_book =
  let remove_book dbh bid =
    PGSQL(dbh) "DELETE FROM book WHERE book_id = $bid";
    PGSQL(dbh) "DELETE FROM history WHERE book_id = $bid";
    PGSQL(dbh) "DELETE FROM lending WHERE book_id = $bid";
    PGSQL(dbh) "DELETE FROM reservation WHERE book_id = $bid";
  in

  let body dbh bid =
    match
      Model.first (PGSQL(dbh) "SELECT user_id FROM wish_book WHERE book_id = $bid")
    with
    | None -> raise (Bibman.Invalid_argument "book-id")
    | Some uid -> begin
      let account = Model.account_of_user_id dbh uid in
      ignore (
        Bibman.send_book_mail
          dbh
          bid
          account
          Config.wish_book_removed_subject
          Config.wish_book_removed_content
      );
      remove_book dbh bid;
      PGSQL(dbh) "DELETE FROM wish_book WHERE book_id = $bid"
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
