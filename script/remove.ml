let remove_book dbh bid =
  PGSQL(dbh) "DELETE FROM book WHERE book_id = $bid";
  PGSQL(dbh) "DELETE FROM history WHERE book_id = $bid";
  PGSQL(dbh) "DELETE FROM lending WHERE book_id = $bid";
  PGSQL(dbh) "DELETE FROM reservation WHERE book_id = $bid";
  PGSQL(dbh) "DELETE FROM wish_book WHERE book_id = $bid"
;;

let wish_book =

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
      remove_book dbh bid
    end
  in

  fun dbh -> function
  | bid :: [] ->
    body dbh (Int32.of_string bid);
    None
  | _ -> assert false
;;

let entry =

  let body dbh isbn =
    (* remove books *)
    let () =
      let bids = PGSQL(dbh) "SELECT book_id FROM book WHERE isbn = $isbn" in
      List.iter (remove_book dbh) bids
    in
    (* remove authors *)
    let () =
      let aids =
        PGSQL(dbh) "SELECT author_id FROM rel_entry_authors WHERE isbn = $isbn"
      in

      (* remove relationship to the isbn *)
      PGSQL(dbh) "DELETE FROM rel_entry_authors WHERE isbn = $isbn";

      let live_authors =
        PGSQL(dbh) "SELECT author_id FROM rel_entry_authors WHERE author_id IN $@aids"
      in

      (* remove author unless he/she is live *)
      PGSQL(dbh)
        "DELETE FROM author WHERE author_id IN $@aids AND author_id NOT IN $@live_authors"
    in

    (* remove entry *)
    PGSQL(dbh) "DELETE FROM entry WHERE isbn = $isbn"
  in

  fun dbh -> function
  | isbn :: [] -> begin
    match Model.normalize_isbn isbn with
    | Some isbn -> body dbh isbn; None
    | None -> raise (Invalid_argument "isbn")
  end
  | _ -> assert false
;;

let actions = [
  ("wish_book", ([ `Int32 "book-id"; ], wish_book));
  ("entry", ([ `NonEmpty "isbn" ], entry));
]
;;

let () = Bibman.run actions Sys.argv
;;
