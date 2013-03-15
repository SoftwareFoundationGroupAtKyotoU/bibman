let send_book_mail
    dbh
    (bid : int32)
    (account : string)
    (address : string)
    (sender_name : string)
    (sender_address : string)
    (subject : string)
    (content : string)
    : bool =
  match Model.book_info_of_book_id dbh bid with
  | None -> false
  | Some (book, entry, authors, publisher) ->
    let buf = Buffer.create 1024 in
    let () =
      Buffer.add_substitute buf
        (function
        | "t" -> Model.title_of_entry entry
        | "a" -> String.concat ", " authors
        | "p" -> publisher
        | "y" -> Int32.to_string (Model.publish_year_of_entry entry)
        | "l" -> Model.location_of_book book
        | x -> x)
        content
    in
    let message = Netsendmail.compose
      ~from_addr: (sender_name, sender_address)
      ~to_addrs:  [account, address]
      ~subject:   subject
      (Buffer.contents buf)
    in
    Netsendmail.sendmail message;
    true
;;

let () =
  let usage =
    Printf.sprintf
"Usage: %s [book-id] [account] [address] [sender-name] [sender-address] [subject]\n\
\ %s sends to [address] of [account] a mail about the book specified by\
\ [book-id] as [sender-name] from [sender-address].\
\ The subject of that mail is given by [subject] and the content of it is read\
\ from the standard input.\
\ Each alphabet following $ in the content is replaced with information of the\
\ book.\n\
\   $t: title\n\
\   $a: author names\n\
\   $p: publisher\n\
\   $y: publish year\n\
\   $l: location\n\
" Sys.argv.(0) Sys.argv.(0)
  in
  let options, host, user, passwd, db = Bibman.db_options () in
  let usage_with_option = Arg.usage_string (Arg.align options) usage in
  let args = ref [] in
  let args_fun str = args := str :: !args in
  (try Arg.parse_argv Sys.argv options args_fun usage with
  | Arg.Help msg -> print_endline msg; exit 0
  | Arg.Bad msg -> prerr_endline msg; exit 1);
  if List.length !args <> 6 then
    prerr_endline usage_with_option
  else match List.rev !args with
  | bid :: _
      when (try ignore (Int32.of_string bid); false with Failure _ -> true)
        -> prerr_endline "The book id must be integer";
           exit 1
  | bid :: account :: address :: sender_name :: sender_address :: subject :: []
    -> begin
      let content = BatIO.read_all BatIO.stdin in
      let host, user, password, database = !host, !user, !passwd, !db in
      let dbh = PGOCaml.connect ~host ~user ~password ~database () in
      let res =
        send_book_mail
          dbh
          (Int32.of_string bid)
          account
          address
          sender_name
          sender_address
          subject
          content
      in
    (match res  with
    | false -> prerr_endline "The book id is invalid"
    | true -> ());
    PGOCaml.close dbh
  end
  | _ -> assert false
;;
