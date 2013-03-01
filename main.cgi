#!/home/webserver/.opam/4.00.1/bin/ocaml

let buffer_size = 1024
;;
let html_template_file = "static/main.html";
;;

let read_file filename =
  let rec add_contents buf ic =
    try
      let line = input_line ic in
      Buffer.add_string buf line;
      Buffer.add_char buf '\n';
      add_contents buf ic
    with 
      End_of_file -> ()
  in
  let ic = open_in filename in
  let buf = Buffer.create buffer_size in
  add_contents buf ic;
  close_in ic;
  Buffer.contents buf
;;

let contents =
  let html_template  = read_file html_template_file in
  let buf = Buffer.create buffer_size in
  (* map $u to [account] *)
  Buffer.add_substitute buf (function "u" -> "t-sekiym" | x -> x) html_template; (* TODO *)
  Buffer.contents buf
;;


print_endline "Content-Type: text/html\n";
print_endline contents;
