#!/home/webserver/.opam/4.00.1/bin/ocaml

   (* book: keyword => book list *)
  (* [{ *)
  (*   id: number, /* book id */ *)
  (*  title: string, *)
  (*   publish_year: number, *)
  (*   author: [ string ], *)
  (*   publisher: string, *)
  (*   isbn: string, *)
  (*   kind: string, *)
  (* }, ...] *)

print_endline "Content-Type: application/json\n";;

print_endline "[\
{\
  \"id\": 1,\
  \"title\": \"Induction to Programming\",\
  \"publish_year\": 1982,\
  \"author\": [ \"John\",\"Michael\" ],\
  \"publisher\": \"ACM\",\
  \"isbn\": \"9r239r29fj\",\
  \"kind\": \"Igarashi Lab\"
}
]";;
