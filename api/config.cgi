#!/home/webserver/.opam/4.00.1/bin/ocaml

print_endline "Content-Type: application/json\n";;

print_endline "\
{\
  \"book\": {\
   \"publisher\" : {\
      \"item\": [ \"ACM\", \"Springer\", \"MIT\" ] \
   },\
    \"kind\": {\
      \"item\": [ \"五十嵐\", \"消耗品\", \"図書\" ] \
    }\
  }\
}"
;;
