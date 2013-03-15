open Model
;;

let uid_to_account dbh =
  let users = PGSQL(dbh) "SELECT user_id, account FROM lab8_user" in
  hash_of_list users fst snd
;;

let string_of_date : CalendarLib.Date.t -> string  =
  CalendarLib.Printer.DatePrinter.sprint "%F"
;;

let book_history =
  let history dbh uid_to_account bid =
    let history_num = Config.number_of_history_records in
    let histories =
      PGSQL(dbh)
        "SELECT * FROM history WHERE book_id = $bid ORDER BY start_date DESC LIMIT $history_num"
    in 
    match exists histories with
    | false -> None
    | true -> begin
      let histories =
        List.map (fun history ->
          let uid = user_id_of_history history in
          let sdate = start_date_of_history history in
          let rdate = return_date_of_history history in
          `Assoc [
            ("account", `String (BatHashtbl.find uid_to_account uid));
            ("from", `String (string_of_date sdate));
            ("to", `String (string_of_date rdate));
          ])
          histories
      in
      Some (`Assoc [
        ("id", `Int (Int32.to_int bid));
        ("history", `List histories);
      ])
    end
  in
  let body dbh bids =
    let uid_to_account = uid_to_account dbh in
    `List (BatList.filter_map (history dbh uid_to_account) bids)
  in

  fun dbh bids -> Some (body dbh (List.map Int32.of_string bids))
;;

let book_lending =
  let lending dbh uid_to_account bid =
    let lendings = PGSQL(dbh) "SELECT * FROM lending WHERE book_id = $bid" in
    match first lendings with
    | None -> None
    | Some lending -> begin
      let due_date = string_of_date (due_date_of_lending lending) in
      let owner =
        BatHashtbl.find uid_to_account (user_id_of_lending lending)
      in
      let reservers =
        let reserver_ids =
          PGSQL(dbh)
            "SELECT user_id FROM reservation WHERE book_id = $bid ORDER BY reservation_date ASC"
        in
        List.map (BatHashtbl.find uid_to_account) reserver_ids
      in
      Some (`Assoc [
        ("id", `Int (Int32.to_int bid));
        ("owner", `String owner);
        ("reserver", `List (List.map (fun x -> `String x) reservers));
        ("due_date", `String due_date);
      ])
    end
  in

  let body dbh bids =
    let uid_to_account = uid_to_account dbh in
    `List (BatList.filter_map (lending dbh uid_to_account) bids)
  in

  fun dbh bids -> Some (body dbh (List.map Int32.of_string bids))
;;

let lend =
  let body dbh uid bid =
    match exists (PGSQL(dbh) "SELECT 1 FROM lending WHERE book_id = $bid") with
    | false -> begin
      let module Date = CalendarLib.Date in
      let start_date = Date.today () in
      let due_date = Date.add start_date (Date.Period.day Config.lending_days) in
      PGSQL (dbh)
        "INSERT INTO lending (book_id, user_id, start_date, due_date) VALUES ($bid, $uid, $start_date, $due_date)"
    end
    | true -> begin
      (match exists (PGSQL(dbh) "SELECT 1 FROM book WHERE book_id = $bid") with
      | true ->
        prerr_endline "The book has been lent already"
      | false ->
        prerr_endline "The book doesn't exist"
      );
      raise (Bibman.Invalid_argument "book-id")
    end
  in

  fun dbh -> function
  | account :: bid :: [] -> begin
    body dbh (Bibman.user_id_or_raise dbh account) (Int32.of_string bid);
    None
  end
  | _ -> assert false
;;

(* TODO: split into 'return' and 'next_reserver' *)
let return =
  let lend_reserver dbh bid reserver_id =
    let module Date = CalendarLib.Date in
    let start_date = Date.today () in
    let due_date =
      Date.add start_date (Date.Period.day Config.lending_days)
    in
    PGSQL(dbh)
      "INSERT INTO lending (book_id, user_id, start_date, due_date) VALUES ($bid, $reserver_id, $start_date, $due_date)";
    PGSQL(dbh)
      "DELETE FROM reservation WHERE book_id = $bid AND user_id = $reserver_id";
    let reserver_account = BatList.first
      (PGSQL(dbh) "SELECT account FROM lab8_user WHERE user_id = $reserver_id")
    in
    ignore
      (Bibman.send_book_mail
         dbh bid reserver_account
         Config.lending_subject  Config.lending_content)
  in

  let body dbh bid =
    let l =
      PGSQL(dbh) "SELECT start_date, user_id FROM lending WHERE book_id = $bid"
    in
    match first l with
    | None ->
      Bibman.error
        "book-id and/or account"
        "The user aren't lending the book"
    | Some (start_date, uid) ->
      let today = CalendarLib.Date.today () in
      PGSQL(dbh)
        "DELETE FROM lending WHERE book_id = $bid";
      PGSQL(dbh)
        "INSERT INTO history (book_id, user_id, start_date, return_date) VALUES ($bid, $uid, $start_date, $today)";
      let reserver_ids =
        PGSQL(dbh)
          "SELECT user_id FROM reservation WHERE book_id = $bid ORDER BY reservation_date ASC LIMIT 1"
      in
      (* lend a reserver the book *)
      match first reserver_ids with
      | None -> ()
      | Some reserver_id -> lend_reserver dbh bid reserver_id
  in

  fun dbh -> function
  | bid :: [] ->
    body dbh (Int32.of_string bid);
    None
  | _ -> assert false
;;

let reserve =
  let body dbh uid bid =
    match exists (PGSQL(dbh) "SELECT 1 FROM lending WHERE book_id = $bid") with
    | false -> raise (Bibman.Invalid_argument "book-id")
    | true -> begin
      let l =
        PGSQL(dbh)
          "SELECT 1 FROM reservation WHERE book_id = $bid AND user_id = $uid"
      in
      match exists l with
      | true ->
        Bibman.error
          "book-id and/or account"
          "The user has reserved the book already"
      | false ->
        PGSQL(dbh)
          "INSERT INTO reservation (book_id, user_id) VALUES ($bid, $uid)"
    end
  in

  fun dbh -> function
  | account :: bid :: [] -> begin
    body dbh (Bibman.user_id_or_raise dbh account) (Int32.of_string bid);
    None
  end
  | _ -> assert false
;;

let cancel =
  let body dbh uid bid =
    let l =
      PGSQL(dbh)
        "SELECT 1 FROM reservation WHERE book_id = $bid AND user_id = $uid"
    in
    match exists l with
    | false -> raise (Bibman.Invalid_argument "book-id")
    | true ->
      PGSQL(dbh)
        "DELETE FROM reservation WHERE book_id = $bid AND user_id = $uid"
  in

  fun dbh -> function
  | account :: bid :: [] -> begin
    body dbh (Bibman.user_id_or_raise dbh account) (Int32.of_string bid);
    None
  end
  | _ -> assert false
;;


let actions = [
  ("book-history", (
    [`Int32 "book-id"; `Any (`Int32 "book-ids ..."); ], book_history));
  ("book-lending", (
    [`Int32 "book-id"; `Any (`Int32 "book-ids ..."); ], book_lending));

  ("lend", ([`NonEmpty "account"; `Int32 "book-id"; ], lend));
  ("return", ([`Int32 "book-id"; ], return));
  ("reserve", ([`NonEmpty "account"; `Int32 "book-id"; ], reserve));
  ("cancel",  ([`NonEmpty "account"; `Int32 "book-id"; ], cancel));
]
;;

let () = Bibman.run actions Sys.argv
;;
