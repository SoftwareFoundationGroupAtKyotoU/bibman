let debug = Bibman.debug
;;

open Model
;;

let by_keywords =
  let hit keyword str = BatString.exists (String.lowercase_ascii str) keyword in

  let hit_filter isbn_to_authors books_with_entry keyword =
    List.filter
      (fun bwe ->
        let title = title_of_book_with_entry bwe in
        let isbn = isbn_of_book_with_entry bwe in
        let label = label_of_book_with_entry bwe in
        let authors = BatHashtbl.find isbn_to_authors isbn in
        hit keyword title ||
        hit keyword isbn ||
        List.exists (hit keyword) authors ||
        hit keyword label) 
      books_with_entry
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
    let keywords = List.map String.lowercase_ascii keywords in
    let books_with_entry = 
      debug "books_with_entry";
      PGSQL(dbh) "SELECT book.*, entry.title, entry.publish_year, entry.publisher_id from book INNER JOIN entry ON book.isbn = entry.isbn WHERE book_id NOT IN (SELECT book_id FROM wish_book)"
    in
      if BatList.is_empty books_with_entry then
        jsonify dbh [] (BatHashtbl.create 0) (BatHashtbl.create 0)
      else 
        let isbns = List.map isbn_of_book_with_entry books_with_entry in
        let isbn_to_authors = isbn_to_authors dbh isbns in 
        let hit_books_with_entry =
          List.fold_left
            (fun bwe keyword -> hit_filter isbn_to_authors bwe keyword)
            books_with_entry keywords
        in
        let hit_entries =
          List.map entry_of_book_with_entry hit_books_with_entry
        in
        let isbn_to_hit_entry =
          hash_of_map hit_entries isbn_of_entry (fun x -> x)
        in
        let hit_books =
          List.map book_of_book_with_entry hit_books_with_entry
        in
        jsonify dbh hit_books isbn_to_hit_entry isbn_to_authors
;;

let by_id =
  fun dbh -> function
  | bid :: [] -> json_of_book_id dbh (Int32.of_string bid)
  | _ -> assert false
;;

let by_isbn =
  let body dbh isbn =
    match normalize_isbn isbn with
    | Some isbn -> begin
        match entry_info_of_isbn dbh isbn with
        | Some (entry, authors, publisher) ->
          jsonify_entry entry authors publisher
        | None -> raise (Bibman.Invalid_argument "isbn")
      end
    | None -> raise (Bibman.Invalid_argument "isbn")
  in

  fun dbh -> function
  | isbn :: [] -> Some (body dbh isbn)
  | _ -> assert false
;;

let actions = [
  ("keyword", ([`String "keyword"; `Any (`String "keywords ...")], by_keywords));
  ("id", ([`Int32 "book-id"], by_id));
  ("isbn", ([`NonEmpty "isbn"], by_isbn));
]
;;

let () = Bibman.run actions Sys.argv
;;
