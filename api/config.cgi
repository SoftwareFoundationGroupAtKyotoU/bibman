#!/home/webserver/.opam/4.00.1/bin/ocaml

print_endline "Content-Type: application/json\n";;

print_endline "\
{\
  \"book\": {\
   \"publisher\" : {\
      \"values\": [ \"ACM\", \"Springer\", \"MIT\" ] \
   },\
    \"kind\": {\
      \"values\": [ \"五十嵐\", \"消耗品\", \"図書\" ] \
    }\
  }\
}"
;;
