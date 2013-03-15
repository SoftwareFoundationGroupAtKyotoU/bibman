let publisher dbh _ =
  let publishers = PGSQL(dbh) "SELECT name FROM publisher" in
  Some (`List (List.map (fun p -> `String p) publishers))
;;

let actions = [
  ("publisher", ([], publisher));
]
;;

let () = Bibman.run actions Sys.argv
;;
