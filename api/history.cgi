#!/home/webserver/.opam/4.00.1/bin/ocaml

  (* history: book id list => (history in descending order) list */ *)
  (* [{ *)
  (*   id: number, /* book id */ *)
  (*   history: [{ *)
  (*     account: string, *)
  (*     from: string, *)
  (*     to: string, *)
  (*   }, ... ], *)
  (* }, ... ] *)

print_endline "Content-Type: application/json\n";;

print_endline "[\
 {\
  \"id\": 1,\
  \"history\": [{\
    \"account\": \"t-sekiym\",\
    \"from\": \"2012-12-10\",\
    \"to\": \"2012-12-12\"\
  }]
 }
]"
