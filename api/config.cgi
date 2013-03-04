#!/home/webserver/.opam/4.00.1/bin/ocaml

print_endline "Content-Type: application/json\n";;

print_endline "\
{\
  \"book\": {\
   \"publisher\" : {\
     \"values\": [ \"ACM\", \"Springer\", \"MIT\" ] \
   },\
   \"kind\": {\
     \"values\": [  \"未定\", \"五十嵐\", \"消耗品\", \"図書\" ] \
   },\
   \"status\": {\
     \"values\": [ \"未購入\", \"注文済み\", \"購入済\" ], \
     \"purchase\": \"購入済\"
   }\
  },\
  lending: {\
    \"interval_days\": 30\
  }\
 }"
;;
