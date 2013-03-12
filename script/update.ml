let error msg =
  prerr_endline msg;
  exit 1
;;

let registered_already name v =
  prerr_endline (Printf.sprintf "%s %s has been registered already" name v);
  exit 126
;;

open Model
;;

let isbn_exists dbh isbn =
  not (BatList.is_empty (PGSQL (dbh) "SELECT 1 FROM entry WHERE isbn = $isbn"))
;;

let isbn_exists_in_book dbh isbn =
  not (BatList.is_empty (PGSQL (dbh) "SELECT 1 FROM book WHERE isbn = $isbn"))
;;

let rec find_publisher dbh publisher =
  match PGSQL(dbh) "SELECT publisher_id FROM publisher WHERE name = $publisher" with
  | [] -> None
  | [pid] -> Some pid
  | _ -> assert false
;;

let register_entry =
  let find_author dbh author =
    match PGSQL(dbh) "SELECT author_id FROM author WHERE name = $author" with
    | [aid] -> Some aid
    | [] -> None
    | _ -> assert false (* TODO *)
  in
  let find_or_insert_author dbh author =
    match find_author dbh author with
    | Some aid -> aid
    | None -> begin
      PGSQL(dbh) "INSERT INTO author (name) VALUES ($author)";
      match find_author dbh author with
      | Some aid -> aid
      | None -> assert false
    end
  in

  let body dbh isbn title authors pyear publisher =
    let pid = match find_publisher dbh publisher with
      | Some pid -> pid
      | None ->
        error (Printf.sprintf "Publisher %s hasn't been registered" publisher)
    in
    if isbn_exists dbh isbn then registered_already "ISBN" isbn
    else begin
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
    let authors = List.map BatString.trim (BatString.nsplit authors ",") in
    if List.exists BatString.is_empty authors then
      raise (Bibman.Invalid_argument "authors");
    body dbh isbn title authors (Int32.of_string pyear) publisher;
    None
  end
  | _ -> assert false
;;

let register_book =
  let body dbh isbn loc kind label status =
    if not (isbn_exists dbh isbn) then
      error (Printf.sprintf "ISBN %s hasn't been registered as entry" isbn);
    if (isbn_exists_in_book dbh isbn) then
      registered_already "ISBN"  isbn;
    PGSQL(dbh)
      "INSERT INTO book (isbn, location, kind, label, status) VALUES ($isbn, $loc, $kind, $label, $status)";
    let bid =
      BatList.first (PGSQL(dbh) "SELECT book_id FROM book WHERE isbn = $isbn")
    in
    `Int (Int32.to_int bid)
  in

  fun dbh -> function
  | isbn :: loc :: kind :: label :: status :: [] ->
    Some (body dbh isbn loc kind label status)
  | _ -> assert false
;;

let register_publisher =
  let body dbh publisher =
    (match find_publisher dbh publisher with
    | Some _ -> registered_already "Publisher" publisher
    | None -> ());
    PGSQL(dbh) "INSERT INTO publisher (name) VALUES ($publisher)"
  in

  fun dbh -> function
  | publisher :: [] -> begin
    body dbh publisher;
    None
  end
  | _ -> assert false
;;

let edit =
  let isbn dbh id orig_isbn new_isbn =
    if orig_isbn = new_isbn then ()
    (* 既存の ISBN への変更は不可 (許すと書籍の参照先自体が変わってしまうため) *)
    else if isbn_exists dbh new_isbn then
      raise Exit
    else begin
      PGSQL(dbh) "UPDATE entry SET (isbn) = ($new_isbn) WHERE isbn = $orig_isbn";
      PGSQL(dbh) "UPDATE book SET (isbn) = ($new_isbn) WHERE book_id = $id";
      let aids =
        PGSQL(dbh) "SELECT author_id FROM rel_entry_authors WHERE isbn = $orig_isbn"
      in
      List.iter (fun aid ->
        PGSQL(dbh)
          "UPDATE rel_entry_authors SET (isbn) = ($new_isbn) WHERE isbn = $orig_isbn AND author_id  = $aid")
        aids
    end
  in
  let title dbh _ isbn title =
    PGSQL(dbh) "UPDATE entry SET (title) = ($title) WHERE isbn = $isbn"
  in
  let publish_year dbh _ isbn pyear =
    let pyear = try Int32.of_string pyear with Failure _ -> raise Exit in
    PGSQL(dbh) "UPDATE entry SET (publish_year) = ($pyear) WHERE isbn = $isbn"
  in
  let publisher dbh _ isbn publisher =
    let pids =
      PGSQL(dbh) "SELECT publisher_id FROM publisher WHERE name = $publisher"
    in
    if BatList.is_empty pids then raise Exit
    else begin
      let pid = BatList.first pids in
      PGSQL(dbh) "UPDATE entry SET (publisher_id) = ($pid) WHERE isbn = $isbn"
    end
  in
  let location dbh id _ loc =
    PGSQL(dbh) "UPDATE book SET (location) = ($loc) WHERE book_id = $id"
  in
  let kind dbh id _ kind =
    PGSQL(dbh) "UPDATE book SET (kind) = ($kind) WHERE book_id = $id"
  in
  let label dbh id _ label =
    PGSQL(dbh) "UPDATE book SET (label) = ($label) WHERE book_id = $id"
  in
  let status dbh id _ status =
    PGSQL(dbh) "UPDATE book SET (status) = ($status) WHERE book_id = $id"
  in

  let body dbh id item v =
    let items = [
      ("isbn", isbn);
      ("title", title);
      ("publish_year", publish_year);
      ("publisher", publisher);
      ("location", location);
      ("kind", kind);
      ("label", label);
      ("status", status);
    ]
    in
    let books = PGSQL(dbh) "SELECT * FROM book WHERE book_id = $id" in
    if BatList.is_empty books then
      raise (Bibman.Invalid_argument "book-id")
    else begin
      let editor = try List.assoc item items with
        | Not_found -> raise (Bibman.Invalid_argument "item")
        | Exit -> raise (Bibman.Invalid_argument "value")
      in
      editor dbh id (isbn_of_book (BatList.first books)) v
    end
  in
  fun dbh -> function
  | id :: item :: v :: [] -> body dbh (Int32.of_string id) item v; None
  | _ -> assert false
;;



let actions = [
  ("register-entry",
   ([
     `NonEmpty "isbn";
     `NonEmpty "title";
     `NonEmpty "authors (separated by comma)";
     `Int32 "publish year";
     `NonEmpty "publisher"
    ], register_entry));
  ("register-book", (
    [
      `NonEmpty "isbn";
      `NonEmpty "location";
      `NonEmpty "kind";
      `String "label";
      `NonEmpty "status"
    ], register_book));
  ("register-publisher", ([`NonEmpty "publisher"], register_publisher));
  ("edit", ([`Int32 "book-id"; `NonEmpty "item"; `String "value"], edit));
]
;;

let () = Bibman.run actions Sys.argv
;;
