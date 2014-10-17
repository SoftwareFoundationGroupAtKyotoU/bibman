let tosho =
  let location dbh bid =
    let loc = BatList.first (
      PGSQL(dbh) "SELECT location FROM book WHERE book_id = $bid"
    ) in
    try
      Config.Map.find loc Config.locations
    with
      Not_found -> loc
  in

  let body dbh bid purchaser sent_date budget number price note =
    let content =
      BatIO.read_all
        (BatIO.input_channel
           ~autoclose:true
           ~cleanup:true
           (open_in Config.tex_tosho))
    in
    match Bibman.substitute_book_info dbh bid content with
    | None -> raise (Bibman.Invalid_argument "book-id")
    | Some content -> begin
      let kind =
        BatList.first (PGSQL(dbh) "SELECT kind FROM book WHERE book_id = $bid")
      in
      let mc = if kind = Config.kind_expendable then "1" else "0" in
      let loc = location dbh bid in
      let content =
        Bibman.substitute_symbol
          (function
          | "mc" -> Some mc
          | "purchaser" -> Some purchaser
          | "sd" -> Some sent_date
          | "location" -> Some loc
          | "budget" -> Some budget
          | "number" -> Some number
          | "price" -> Some price
          | "note" -> Some note
          | _ -> None)
          content
      in
      `Stringlit content
    end
  in

  fun dbh -> function
  | bid :: purchase :: sent_date :: budget :: number :: price :: note :: [] ->
    Some (body dbh (Int32.of_string bid) purchase sent_date budget number price note)
  | _ -> assert false
;;

let actions = [
  ("tosho", ([
    `Int32 "book-id";
    `NonEmpty "purchaser";
    `NonEmpty "sent-date";
    `NonEmpty "budget";
    `NonEmpty "number";
    `NonEmpty "price";
    `String "note";
  ], tosho));
]

let () = Bibman.run actions Sys.argv
;;
