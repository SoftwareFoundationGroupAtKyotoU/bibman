#!/home/webserver/.opam/4.00.1/bin/ocaml

  (* lending: book_id list => lending status list */ *)
  (* [{ *)
  (*   id: number, /* book id */ *)
  (*   owner: string, *)
  (*   reserver: string array, *)
  (*   due_date: string | null, *)
  (* }, ... ] *)

print_endline "Content-Type: application/json\n";;

print_endline "[\
 {\
  \"id\": 1,\
  \"owner\": \"t-sekiym\",
  \"reserver\": [\"t-sekiym\"],
  \"due_date\": \"2013-03-12\"
 }
]";;
