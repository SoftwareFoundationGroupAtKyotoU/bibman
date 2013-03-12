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
(* let isbn_of_book ((_, isbn, _, _, _, _, _, _) : book) = isbn *)
(* ;; *)
(* let isbn_of_book ((_, isbn, _, _, _, _, _, _) : book) = isbn *)
(* ;; *)


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
