let tosho =
  let body dbh bid =
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
      let content =
        Bibman.substitute_symbol
          (function
          | "mc" -> Some mc
          | _ -> None)
          content
      in
      `Stringlit content
    end
  in

  fun dbh -> function
  | bid :: [] ->
    Some (body dbh (Int32.of_string bid))
  | _ -> assert false
;;

let actions = [
  ("tosho", ([ `Int32 "book-id"; ], tosho));
]

let () = Bibman.run actions Sys.argv
;;
