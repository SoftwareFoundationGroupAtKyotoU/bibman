(* Utilities *)

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

let hash_of_map ?(seed=128) l keyfun valfun =
  let hash = BatHashtbl.create seed in
  List.iter
    (fun x ->
      let key = keyfun x in
      let v = valfun x in
      BatHashtbl.add hash key v)
    l;
  hash
;;

let exists l = not (BatList.is_empty l)
;;
let first = function
  | [] -> None
  | x::_ -> Some x
;;


(* Model *)

(** book **)
type book =
  int32 *    (* book id *)
  string *   (* ISBN *)
  string *   (* location *)
  string *   (* kind *)
  string *   (* label *)
  string *   (* status *)
  CalendarLib.Date.t *      (* register_date *)
  CalendarLib.Date.t option (* purchase_date *)
;;

let id_of_book ((id, _, _, _, _, _, _, _) : book) = id
;;
let isbn_of_book ((_, isbn, _, _, _, _, _, _) : book) = isbn
;;
let location_of_book ((_, _, loc, _, _, _, _, _) : book) = loc
;;
let kind_of_book ((_, _, _, kind, _, _, _, _) : book) = kind
;;
let label_of_book ((_, _, _, _, label, _, _, _) : book) = label
;;    
let status_of_book ((_, _, _, _, _, status, _, _) : book) = status
;;


(** entry **)
type entry =
  string *   (* ISBN *)
  string *   (* title *)
  int32 *    (* publish year *)
  int32      (* publisher id *)
;;

let isbn_of_entry ((isbn, _, _, _) : entry) = isbn
;;
let title_of_entry ((_, title, _, _) : entry) = title
;;
let publish_year_of_entry ((_, _, pyear, _) : entry) = pyear
;;
let publisher_id_of_entry ((_, _, _, pid) : entry) = pid
;;

let isbn_exists dbh isbn =
  exists (PGSQL (dbh) "SELECT 1 FROM entry WHERE isbn = $isbn")
;;

let book_exists dbh bid =
  exists (PGSQL(dbh) "SELECT 1 FROM book WHERE book_id = $bid")
;;

let normalize_isbn =
  let correct isbn =
    if Str.string_match (Str.regexp "[^0-9]") isbn 0 then
      false
    else
      let len = String.length isbn in
      if len = 10 then true
      else if len = 13 then
        let prefix = String.sub isbn 0 3 in
        prefix = "978" || prefix = "979"
      else false
  in

  fun (isbn : string) ->
    let isbn = BatString.trim isbn in
    let isbn = Str.global_replace (Str.regexp "-") "" isbn in
    if correct isbn then Some isbn else None
;;

let entry_info_of_isbn dbh isbn =
  match first (PGSQL(dbh) "SELECT * FROM entry WHERE isbn = $isbn") with
  | None -> None
  | Some entry -> begin
    let authors =
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
    Some (entry, authors, publisher)
  end
;;

let book_info_of_book_id dbh id =
  match first (PGSQL(dbh) "SELECT * FROM book WHERE book_id = $id") with
  | None -> None
  | Some book -> begin
    let isbn = isbn_of_book book in
    match entry_info_of_isbn dbh isbn with
    | Some (entry, authors, publisher) -> Some (book, entry, authors, publisher)
    | None -> assert false
  end
;;

let jsonify_entry entry authors publisher =
  let authors = List.map (fun author -> `String author) authors in
  `Assoc [
    ("title", `String (title_of_entry entry));
    ("publish_year", `Int (Int32.to_int (publish_year_of_entry entry)));
    ("author", `List authors);
    ("publisher", `String publisher);
    ("isbn", `String (isbn_of_entry entry));
  ]

let jsonify_book book entry authors publisher =
  match jsonify_entry entry authors publisher with
  | `Assoc l ->
    `Assoc ([
      ("id", `Int (Int32.to_int (id_of_book book)));
      ("kind", `String (kind_of_book book));
      ("status", `String (status_of_book book));
      ("label", `String (label_of_book book));
      ("location", `String (location_of_book book));
    ] @ l)
  | _ -> assert false
;;

let json_of_book_id dbh bid =
  match book_info_of_book_id dbh bid with
  | None -> None
  | Some (book, entry, authors, publisher) ->
    Some (jsonify_book book entry authors publisher)
;;


(** author **)
let find_author dbh author =
  match PGSQL(dbh) "SELECT author_id FROM author WHERE name = $author" with
  | [aid] -> Some aid
  | [] -> None
  | _ -> assert false (* assume the uniqueness of authors *)
;;

let find_or_insert_author dbh author =
  match find_author dbh author with
  | Some aid -> aid
  | None -> begin
    PGSQL(dbh) "INSERT INTO author (name) VALUES ($author)";
    match find_author dbh author with
    | Some aid -> aid
    | None -> assert false
  end
;;

let authors_of_string authors =
  let authors = List.map BatString.trim (BatString.split_on_string "," authors) in
  if BatList.is_empty authors || List.exists BatString.is_empty authors then
    None
  else
    Some authors
;;

(** publisher **)
let find_publisher dbh publisher =
  match PGSQL(dbh) "SELECT publisher_id FROM publisher WHERE name = $publisher" with
  | [] -> None
  | [pid] -> Some pid
  | _ -> assert false
;;


(** member **)
let find_user_id dbh account =
  let uids =
    PGSQL(dbh) "SELECT user_id FROM member WHERE account = $account"
  in
  first uids
;;

let account_of_user_id dbh uid =
  BatList.first
    (PGSQL(dbh) "SELECT account FROM member WHERE user_id = $uid")
;;

let is_admin_of_user_id dbh uid =
  BatList.first
    (PGSQL(dbh) "SELECT is_admin FROM member WHERE user_id = $uid")
;;

(** history **)
type history =
  int32 *   (* book id *)
  int32 *   (* user id *)
  CalendarLib.Date.t *   (* start date *)
  CalendarLib.Date.t     (* return date *)
;;

let book_id_of_history (bid, _, _, _) = bid
;;
let user_id_of_history (_, uid, _, _) = uid
;;
let start_date_of_history (_, _, sdate, _) = sdate
;;
let return_date_of_history (_, _, _, rdate) = rdate
;;


(** lending **)
type lending =
  int32 *   (* book id *)
  int32 *   (* user id *)
  CalendarLib.Date.t *   (* start date *)
  CalendarLib.Date.t     (* due date *)

let book_id_of_lending (bid, _, _, _) = bid
;;
let user_id_of_lending (_, uid, _, _) = uid
;;
let start_date_of_lending (_, _, sdate, _) = sdate
;;
let due_date_of_lending (_, _, _, ddate) = ddate
;;

(** book_with_entry **)

type book_with_entry =
  int32 *    (* book id *)
  string *   (* ISBN *)
  string *   (* location *)
  string *   (* kind *)
  string *   (* label *)
  string *   (* status *)
  CalendarLib.Date.t *      (* register_date *)
  CalendarLib.Date.t option * (* purchase_date *)
  string *   (* title *)
  int32 *    (* publish year *)
  int32      (* publisher id *)
;;

let id_of_book_with_entry ((id, _, _, _, _, _, _, _, _, _, _) : book_with_entry) = id
;;
let isbn_of_book_with_entry ((_, isbn, _, _, _, _, _, _, _, _, _) : book_with_entry) = isbn
;;
let location_of_book_with_entry ((_, _, loc, _, _, _, _, _, _, _, _) : book_with_entry) = loc
;;
let kind_of_book_with_entry ((_, _, _, kind, _, _, _, _, _, _, _) : book_with_entry) = kind
;;
let label_of_book_with_entry ((_, _, _, _, label, _, _, _, _, _, _) : book_with_entry) = label
;;    
let status_of_book_with_entry ((_, _, _, _, _, status, _, _, _, _, _) : book_with_entry) = status
;;
let title_of_book_with_entry ((_, _, _, _, _, _, _, _, title, _, _) : book_with_entry) = title
;;
let publisher_id_of_book_with_entry ((_, _, _, _, _, _, _, _, _, _, publisher_id) : book_with_entry) = publisher_id
;;
let book_of_book_with_entry ((id, isbn, loc, kind, label, status, register_date, purchase_date, _, _, _) : book_with_entry) = (id, isbn, loc, kind, label, status, register_date, purchase_date)
;;
let entry_of_book_with_entry ((_, isbn, _, _, _, _, _, _, title, publish_year, publisher_id) : book_with_entry) = (isbn, title, publish_year, publisher_id)
;;