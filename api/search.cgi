#!/home/webserver/.opam/4.00.1/bin/ocaml

  (* book: query => book list *)
  (* [{ *)
  (*   id: number, /* book id */ *)
  (*  title: string, *)
  (*   publish_year: number, *)
  (*   author: [ string ], *)
  (*   publisher: string, *)
  (*   isbn: string, *)
  (*   kind: string, *)
  (*   status: string, *)
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
  \"kind\": \"Igarashi Lab\"\
},\
{\
  \"id\": 2,\
  \"title\": \"Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"824923-3294\",\
  \"kind\": \"消耗品\"\
},\
{\
  \"id\": 3,\
  \"title\": \"Jappy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"1 Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"1824923-3294\",\
  \"kind\": \"消耗品\"\
},\
{\
  \"id\": 4,\
  \"title\": \"2 Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"2 Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"2824923-3294\",\
  \"kind\": \"消耗品\"\
},\
{\
  \"id\": 5,\
  \"title\": \"Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"824923-3294\",\
  \"kind\": \"消耗品\"\
},\
{\
  \"id\": 6,\
  \"title\": \"Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"824923-3294\",\
  \"kind\": \"消耗品\"\
},\
{\
  \"id\": 7,\
  \"title\": \"Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"824923-3294\",\
  \"kind\": \"消耗品\"\
},\
{\
  \"id\": 8,\
  \"title\": \"Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"824923-3294\",\
  \"kind\": \"消耗品\"\
},\
{\
  \"id\": 9,\
  \"title\": \"Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"824923-3294\",\
  \"kind\": \"消耗品\"\
},\
{\
  \"id\": 10,\
  \"title\": \"Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"824923-3294\",\
  \"kind\": \"消耗品\"\
},\
{\
  \"id\": 11,\
  \"title\": \"Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"824923-3294\",\
  \"kind\": \"消耗品\"\
},\
{\
  \"id\": 12,\
  \"title\": \"Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"824923-3294\",\
  \"kind\": \"消耗品\"\
},\
{\
  \"id\": 13,\
  \"title\": \"Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"824923-3294\",\
  \"kind\": \"消耗品\"\
},\
{\
  \"id\": 14,\
  \"title\": \"Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"824923-3294\",\
  \"kind\": \"消耗品\"\
},\
{\
  \"id\": 15,\
  \"title\": \"Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"824923-3294\",\
  \"kind\": \"消耗品\"\
},\
{\
  \"id\": 16,\
  \"title\": \"Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"824923-3294\",\
  \"kind\": \"消耗品\"\
},\
{\
  \"id\": 17,\
  \"title\": \"Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"824923-3294\",\
  \"kind\": \"消耗品\"\
},\
{\
  \"id\": 18,\
  \"title\": \"Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"824923-3294\",\
  \"kind\": \"消耗品\"\
},\
{\
  \"id\": 19,\
  \"title\": \"Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"824923-3294\",\
  \"kind\": \"消耗品\"\
},\
{\
  \"id\": 20,\
  \"title\": \"Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"824923-3294\",\
  \"kind\": \"消耗品\"\
},\
{\
  \"id\": 21,\
  \"title\": \"Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"824923-3294\",\
  \"kind\": \"消耗品\"\
}\
]";;
