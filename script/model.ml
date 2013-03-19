(* Misc *)
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

let exists l = not (BatList.is_empty l)
;;
let first = function
  | [] -> None
  | x::xs -> Some x
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

let book_info_of_book_id dbh id =
  match first (PGSQL(dbh) "SELECT * FROM book WHERE book_id = $id") with
  | None -> None
  | Some book -> begin
    let isbn = isbn_of_book book in
    let entry =
      BatList.first (PGSQL(dbh) "SELECT * FROM entry WHERE isbn = $isbn")
    in
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
    Some (book, entry, authors, publisher)
  end
;;

let jsonify_book book entry authors publisher =
  let authors = List.map (fun author -> `String author) authors in
  `Assoc [
    ("id", `Int (Int32.to_int (id_of_book book)));
    ("title", `String (title_of_entry entry));
    ("publish_year", `Int (Int32.to_int (publish_year_of_entry entry)));
    ("author", `List authors);
    ("publisher", `String publisher);
    ("isbn", `String (isbn_of_entry entry));
    ("kind", `String (kind_of_book book));
    ("status", `String (status_of_book book));
    ("label", `String (label_of_book book));
    ("location", `String (location_of_book book));
  ]
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
  let authors = List.map BatString.trim (BatString.nsplit authors ",") in
  if BatList.is_empty authors || List.exists BatString.is_empty authors then
    None
  else
    Some authors
;;

(** publisher **)
let rec find_publisher dbh publisher =
  match PGSQL(dbh) "SELECT publisher_id FROM publisher WHERE name = $publisher" with
  | [] -> None
  | [pid] -> Some pid
  | _ -> assert false
;;


(** lab8_user **)
let find_user_id dbh account =
  let uids =
    PGSQL(dbh) "SELECT user_id FROM lab8_user WHERE account = $account"
  in
  first uids
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
