open Model
;;

let title dbh _ isbn title =
  PGSQL(dbh) "UPDATE entry SET (title) = ($title) WHERE isbn = $isbn"
;;

let author dbh _ isbn authors =
  match authors_of_string authors with
  | None -> raise (Bibman.Invalid_argument "authors")
  | Some authors -> begin
    PGSQL(dbh) "DELETE FROM rel_entry_authors WHERE isbn = $isbn";
    let new_aids = List.map (find_or_insert_author dbh) authors in
    List.iter (fun aid ->
      PGSQL(dbh) "INSERT INTO rel_entry_authors (isbn, author_id) VALUES ($isbn, $aid)"
    ) new_aids
  end
;;

let publish_year dbh _ isbn pyear =
  let pyear = try Int32.of_string pyear with Failure _ -> raise Exit in
  PGSQL(dbh) "UPDATE entry SET (publish_year) = ($pyear) WHERE isbn = $isbn"
;;

let publisher dbh _ isbn publisher =
  match find_publisher dbh publisher with
  | None -> raise Exit
  | Some pid ->
    PGSQL(dbh) "UPDATE entry SET (publisher_id) = ($pid) WHERE isbn = $isbn"
;;

let location dbh id _ loc =
  PGSQL(dbh) "UPDATE book SET (location) = ($loc) WHERE book_id = $id"
;;

let kind dbh id _ kind =
  PGSQL(dbh) "UPDATE book SET (kind) = ($kind) WHERE book_id = $id"
;;

let label dbh id _ label =
  PGSQL(dbh) "UPDATE book SET (label) = ($label) WHERE book_id = $id"
;;

let status dbh id _ status =
  PGSQL(dbh) "UPDATE book SET (status) = ($status) WHERE book_id = $id"
;;

let purchase =
  let body dbh bid =
    let () =
      PGSQL(dbh) "UPDATE book SET (purchase_date) = (now()) WHERE book_id = $bid"
    in
    match
      first (PGSQL(dbh) "SELECT user_id FROM wish_book WHERE book_id = $bid")
    with
    | None -> ()
    | Some uid -> begin
      PGSQL(dbh) "DELETE FROM wish_book WHERE book_id = $bid";
      let account =
        BatList.first
          (PGSQL(dbh) "SELECT account FROM lab8_user WHERE user_id = $uid")
      in
      ignore (
        Bibman.send_book_mail
          dbh bid account
          Config.purchase_subject Config.purchase_content
      )
    end
  in

  fun dbh -> function
  | bid :: [] -> body dbh (Int32.of_string bid); None
  | _ -> assert false
;;

let action_generator =
  let body editor dbh id v =
    match first (PGSQL(dbh) "SELECT isbn FROM book WHERE book_id = $id") with
    | None -> raise (Bibman.Invalid_argument "book-id")
    | Some isbn -> begin
      try editor dbh id isbn v with
      | Exit -> raise (Bibman.Invalid_argument "value")
    end
  in

  fun (name, editor) ->
    let action dbh = function
      | id :: v :: [] -> body editor dbh (Int32.of_string id) v; None
      | _ -> assert false
    in
    (name, ([`Int32 "book-id"; `String "value"], action))
;;

let actions = [
  ("purchase", ([`Int32 "book-id"; ], purchase));
] @ (List.map action_generator [
  ("title", title);
  ("author", author);
  ("publish_year", publish_year);
  ("publisher", publisher);
  ("location", location);
  ("kind", kind);
  ("label", label);
  ("status", status);
])
;;

let () = Bibman.run actions Sys.argv
;;
