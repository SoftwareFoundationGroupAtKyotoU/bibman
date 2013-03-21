let added_already name v =
  prerr_endline (Printf.sprintf "%s %s has been added already" name v);
  raise (Bibman.Invalid_argument name)
;;

open Model
;;

let isbn_exists_in_book dbh isbn =
  not (BatList.is_empty (PGSQL (dbh) "SELECT 1 FROM book WHERE isbn = $isbn"))
;;

let entry =
  let body dbh isbn title authors pyear publisher =
    if isbn_exists dbh isbn then added_already "ISBN" isbn
    else begin
      let pid = match find_publisher dbh publisher with
        | Some pid -> pid
        | None ->
          Bibman.error
            "publisher"
            (Printf.sprintf "Publisher %s hasn't been registered" publisher)
      in
      PGSQL(dbh)
        "INSERT INTO entry (isbn, title, publish_year, publisher_id) VALUES ($isbn, $title, $pyear, $pid)";
      let aids = List.map (find_or_insert_author dbh) authors in
      List.iter
        (fun aid ->
          PGSQL(dbh)
            "INSERT INTO rel_entry_authors (isbn, author_id) VALUES ($isbn, $aid)")
        aids
    end
  in

  fun dbh -> function
  | isbn :: title :: authors :: pyear :: publisher :: [] -> begin
    match authors_of_string authors, normalize_isbn isbn with
    | None, _ -> raise (Bibman.Invalid_argument "authors")
    | _, None -> raise (Bibman.Invalid_argument "isbn")
    | Some authors, Some isbn ->
      body dbh isbn title authors (Int32.of_string pyear) publisher;
      None
  end
  | _ -> assert false
;;

let book =
  let body dbh isbn loc kind label status =
    if not (isbn_exists dbh isbn) then
      Bibman.error
        "isbn"
        (Printf.sprintf "ISBN %s hasn't been registered as entry" isbn)
    else begin
      PGSQL(dbh)
        "INSERT INTO book (isbn, location, kind, label, status) VALUES ($isbn, $loc, $kind, $label, $status)";
      let bid_opt = BatList.first (PGSQL(dbh) "SELECT currval('book_book_id_seq')") in
      match bid_opt with
      | Some bid -> `Intlit (Int64.to_string bid)
      | None -> assert false
    end
  in

  fun dbh -> function
  | isbn :: loc :: kind :: label :: status :: [] -> begin
    match normalize_isbn isbn with
    | None -> raise (Bibman.Invalid_argument "isbn")
    | Some isbn -> Some (body dbh isbn loc kind label status)
  end
  | _ -> assert false
;;

let wish_book =
  let body dbh uid bid =
    match exists (PGSQL(dbh) "SELECT 1 FROM book WHERE book_id = $bid") with
    | false -> raise (Bibman.Invalid_argument "book-id")
    | true -> begin
      match
        exists (PGSQL(dbh) "SELECT 1 FROM wish_book WHERE book_id = $bid")
      with
      | true ->
        prerr_endline "The book has been registered already";
        raise (Bibman.Invalid_argument "book-id")
      | false ->
        PGSQL(dbh)
          "INSERT INTO wish_book (book_id, user_id) VALUES ($bid, $uid)";
        ignore (
          Bibman.send_book_mail
            dbh
            bid
            (fst Config.mail_staff)
            ~address: (snd Config.mail_staff)
            Config.wish_book_subject
            Config.wish_book_content
        )
    end
  in

  fun dbh -> function
  | account :: bid :: [] ->
    body dbh (Bibman.user_id_or_raise dbh account) (Int32.of_string bid);
    None
  | _ -> assert false
;;

let publisher =
  let body dbh publisher =
    match find_publisher dbh publisher with
    | Some _ -> added_already "Publisher" publisher
    | None -> PGSQL(dbh) "INSERT INTO publisher (name) VALUES ($publisher)"
  in

  fun dbh -> function
  | publisher :: [] -> begin
    body dbh publisher;
    None
  end
  | _ -> assert false
;;

let user =
  let account_exists dbh account =
    not (BatList.is_empty
           (PGSQL(dbh) "SELECT 1 FROM lab8_user WHERE account = $account"))
  in

  let body dbh account password =
    if account_exists dbh account then added_already "Account" account
    else
      let password = Bibman.encrypt password in
      PGSQL(dbh)
        "INSERT INTO lab8_user (account, password) VALUES ($account, $password)"
  in

  fun dbh -> function
  | account :: password :: [] -> begin
    body dbh account password;
    None
  end
  | _ -> assert false
;;

let actions = [
  ("entry",
   ([
     `NonEmpty "isbn";
     `NonEmpty "title";
     `NonEmpty "authors (separated by comma)";
     `Int32 "publish year";
     `NonEmpty "publisher"
    ], entry));
  ("book", (
    [
      `NonEmpty "isbn";
      `NonEmpty "location";
      `NonEmpty "kind";
      `String "label";
      `NonEmpty "status"
    ], book));
  ("wish_book", ([ `NonEmpty "account"; `Int32 "book-id"; ], wish_book));
  ("publisher", ([`NonEmpty "publisher"], publisher));
  ("user", ([`NonEmpty "account"; `NonEmpty "password"], user));
]
;;

let () = Bibman.run actions Sys.argv
;;
