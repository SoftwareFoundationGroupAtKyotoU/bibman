let debug = Bibman.debug
;;

let hash_of_relation ?(seed=128) rel keyfun valfun =
  let hash = BatHashtbl.create seed in
  List.iter
    (fun x ->
      let key = keyfun x in
      let v = valfun x in
      BatHashtbl.add hash key (v :: (BatHashtbl.find_default hash key [])))
    rel;
  hash
;;

let hash_of_list ?(seed=128) l keyfun valfun =
  let hash = BatHashtbl.create seed in
  List.iter
    (fun x ->
      let key = keyfun x in
      let v = valfun x in
      BatHashtbl.add hash key v)
    l;
  hash
;;

open Model
;;

let jsonify_book
    bid title authors publish_year publisher isbn kind status label loc =
  let authors = List.map (fun author -> `String author) authors in
  `Assoc [
    ("id", `Int (Int32.to_int bid));
    ("title", `String title);
    ("publish_year", `Int (Int32.to_int publish_year));
    ("author", `List authors);
    ("publisher", `String publisher);
    ("isbn", `String isbn);
    ("kind", `String kind);
    ("status", `String status);
    ("label", `String label);
    ("location", `String loc);
  ]
;;

let by_keywords =
  let hit keyword str = BatString.exists (String.lowercase str) keyword in

  let hit_filter isbn_to_authors entries keyword =
    List.filter
      (fun entry ->
        let title = title_of_entry entry in
        let isbn = isbn_of_entry entry in
        let authors = BatHashtbl.find isbn_to_authors isbn in
        hit keyword title || List.exists (hit keyword) authors)
      entries
  in

  let isbn_to_authors dbh isbns : (string, string list) BatHashtbl.t =
    let isbn_aid =
      debug "isbn_aid";
      PGSQL(dbh) "SELECT * FROM rel_entry_authors WHERE isbn IN $@isbns"
    in
    let authors =
      let aids = BatList.sort_unique compare (List.map snd isbn_aid) in
      debug "authors";
      PGSQL(dbh) "SELECT * FROM author WHERE author_id IN $@aids"
    in
    let isbn_to_aids = hash_of_relation isbn_aid fst snd in
    let aid_to_author = hash_of_list authors fst snd in
    let isbn_authors =
      List.map (fun isbn ->
        let aids = BatHashtbl.find isbn_to_aids isbn in
        (isbn, List.map (Hashtbl.find aid_to_author) aids))
        isbns
    in
    hash_of_list isbn_authors fst snd
  in

  let jsonify dbh books isbn_to_entry isbn_to_authors =
    let pid_to_publisher =
      let publishers = debug "publishers"; PGSQL(dbh) "SELECT * from publisher" in
      hash_of_list publishers fst snd
    in
    Some (`List (
      List.map
        (fun book ->
          let isbn = isbn_of_book book in
          let entry = BatHashtbl.find isbn_to_entry isbn in
          let pid = publisher_id_of_entry entry in
          let publisher = BatHashtbl.find pid_to_publisher pid in
          let authors = BatHashtbl.find isbn_to_authors isbn in
          jsonify_book
            (id_of_book book)
            (title_of_entry entry)
            authors
            (publish_year_of_entry entry)
            publisher
            isbn
            (kind_of_book book)
            (status_of_book book)
            (label_of_book book)
            (location_of_book book)
        )
        books
    ))
  in

  (* search_book *)
  fun dbh keywords ->
    let keywords = List.map String.lowercase keywords in
    let books = debug "books"; PGSQL(dbh) "SELECT * from book" in
    if BatList.is_empty books then
      jsonify dbh [] (BatHashtbl.create 0) (BatHashtbl.create 0)
    else
      let isbns = List.map isbn_of_book books in
      let entries =
        debug "entries";
        PGSQL(dbh) "SELECT * FROM entry WHERE isbn IN $@isbns"
      in
      let isbn_to_authors = isbn_to_authors dbh isbns in
      let hit_entries =
        List.fold_left
          (fun entries keyword -> hit_filter isbn_to_authors entries keyword)
          entries keywords
      in
      let isbn_to_hit_entry =
        hash_of_list hit_entries isbn_of_entry (fun x -> x)
      in
      let hit_books =
        List.filter
          (fun book -> BatHashtbl.mem isbn_to_hit_entry (isbn_of_book book))
          books
      in
      jsonify dbh hit_books isbn_to_hit_entry isbn_to_authors
;;

let by_id =
  let fst_or_raise l =
    if BatList.is_empty l then raise Exit else BatList.first l
  in 
  let body dbh id =
    let id = Int32.of_string id in
    let book =
      fst_or_raise (PGSQL(dbh) "SELECT * FROM book WHERE book_id = $id")
    in
    let isbn = isbn_of_book book in
    let entry =
      BatList.first (PGSQL(dbh) "SELECT * FROM entry WHERE isbn = $isbn")
    in
    let authors : string list =
      let aids =
        PGSQL(dbh) "SELECT author_id FROM rel_entry_authors WHERE isbn = $isbn"
      in
      PGSQL(dbh) "SELECT name FROM author WHERE author_id IN $@aids"
    in
    let pid = publisher_id_of_entry entry in
    let publisher =
      BatList.first
        (PGSQL(dbh) "SELECT name FROM publisher WHERE publisher_id = $pid")
    in
    Some (jsonify_book
            (id_of_book book)
            (title_of_entry entry)
            authors
            (publish_year_of_entry entry)
            publisher
            isbn
            (kind_of_book book)
            (status_of_book book)
            (label_of_book book)
            (location_of_book book))
  in

  fun dbh -> function
  | id :: [] -> begin
    try body dbh id with
    | Exit -> Some (`Null)
  end
  | _ -> assert false
;;

let actions = [
  ("keyword", ([`String "keyword"; `Any (`String "keywords ...")], by_keywords));
  ("id", ([`Int32 "book-id"], by_id));
]
;;

let () = Printexc.record_backtrace true;;

let () = try Bibman.run actions Sys.argv with _ -> Printexc.print_backtrace stdout
;;
