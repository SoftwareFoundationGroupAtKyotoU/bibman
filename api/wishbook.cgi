#!/home/webserver/.opam/4.00.1/bin/ocaml

print_endline "Content-Type: application/json\n";;

print_endline "[\
{\
  \"id\": 101,\
  \"title\": \"Induction to Programming\",\
  \"publish_year\": 1982,\
  \"author\": [ \"John\",\"Michael\" ],\
  \"publisher\": \"ACM\",\
  \"isbn\": \"9r239r29fj\",\
  \"kind\": \"五十嵐\",
  \"status\": \"未購入\"\
},\
{\
  \"id\": 102,\
  \"title\": \"Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"824923-3294\",\
  \"kind\": \"消耗品\",
  \"status\": \"注文済\"\
},\
{\
  \"id\": 103,\
  \"title\": \"1 Happy Programming\",\
  \"publish_year\": 2011,\
  \"author\": [ \"1 Church\" ],\
  \"publisher\": \"Springer\",\
  \"isbn\": \"1824923-3294\",\
  \"kind\": \"未定\",
  \"status\": \"未購入\"\
}]";;
