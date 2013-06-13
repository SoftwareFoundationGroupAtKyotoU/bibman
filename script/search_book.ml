let debug = Bibman.debug
;;

open Model
;;

let by_keywords =
  let hit keyword str = BatString.exists (String.lowercase str) keyword in

  let hit_filter isbn_to_authors entries keyword =
    List.filter
      (fun entry ->
        let title = title_of_entry entry in
        let isbn = isbn_of_entry entry in
        let authors = BatHashtbl.find isbn_to_authors isbn in
        hit keyword title ||
        hit keyword isbn ||
        List.exists (hit keyword) authors)
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
    let aid_to_author = hash_of_map authors fst snd in
    let isbn_authors =
      List.map (fun isbn ->
        let aids = BatHashtbl.find isbn_to_aids isbn in
        (isbn, List.map (Hashtbl.find aid_to_author) aids))
        isbns
    in
    hash_of_map isbn_authors fst snd
  in

  let jsonify dbh books isbn_to_entry isbn_to_authors =
    let pid_to_publisher =
      let publishers = debug "publishers"; PGSQL(dbh) "SELECT * from publisher" in
      hash_of_map publishers fst snd
    in
    Some (`List (
      List.map
        (fun book ->
          let entry = BatHashtbl.find isbn_to_entry (isbn_of_book book) in
          let pid = publisher_id_of_entry entry in
          let publisher = BatHashtbl.find pid_to_publisher pid in
          let authors = BatHashtbl.find isbn_to_authors (isbn_of_entry entry) in
          jsonify_book book entry authors publisher)
        books))
  in

  (* search_book *)
  fun dbh keywords ->
    let keywords = List.map String.lowercase keywords in
    let books =
      debug "books";
      PGSQL(dbh) "SELECT * from book WHERE book_id NOT IN (SELECT book_id FROM wish_book)"
    in
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
        hash_of_map hit_entries isbn_of_entry (fun x -> x)
      in
      let hit_books =
        List.filter
          (fun book -> BatHashtbl.mem isbn_to_hit_entry (isbn_of_book book))
          books
      in
      jsonify dbh hit_books isbn_to_hit_entry isbn_to_authors
;;

let by_id =
  fun dbh -> function
  | bid :: [] -> json_of_book_id dbh (Int32.of_string bid)
  | _ -> assert false
;;

let actions = [
  ("keyword", ([`String "keyword"; `Any (`String "keywords ...")], by_keywords));
  ("id", ([`Int32 "book-id"], by_id));
]
;;

let () = Bibman.run actions Sys.argv
;;
