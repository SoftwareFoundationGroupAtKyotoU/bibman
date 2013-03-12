#!/home/webserver/.opam/4.00.1/bin/ocaml

(* isbn & title & author & publish_year & publisher & kind & label & status  => book *)
(* id => book *)

print_endline "Content-Type: application/json\n";;

print_endline "{\
  \"id\": 105,\
  \"title\": \"Introduction to Happy Programming\",\
  \"publish_year\": 2010,\
  \"author\": [ \"1 John\" ],\
  \"publisher\": \"MIT\",\
  \"isbn\": \"1824923-3294\",\
  \"status\": \"未購入\"\,
  \"kind\": \"未定\",
  \"label\": \"\"
}";;
