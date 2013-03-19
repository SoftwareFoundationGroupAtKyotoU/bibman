open BibmanNet
;;

let read_file (filename : string) : string =
  let ic =
    BatIO.input_channel ~autoclose:true ~cleanup:true
      (open_in filename)
  in
  BatIO.read_all ic
;;

let html_template_file = Config.static_dir ^ "main.html";
;;

let main (cgi : Netcgi.cgi) (account : string) =
  let html =
    let html_template = read_file html_template_file in
    let account =
      Netencoding.Html.encode ~in_enc:`Enc_utf8 ~out_enc:`Enc_utf8 () account
    in
    let buf = Buffer.create (String.length html_template) in
    Buffer.add_substitute buf (function "u" -> account | x -> x) html_template;
    Buffer.contents buf
  in
  cgi # out_channel # output_string html
;;

let () =
  let error_handler (cgi : Netcgi.cgi) =
    cgi # out_channel # output_string "You aren't certificated?";
    cgi # set_header
      ~status:`See_other
      ~content_type:MimeType.text
      ~fields:[("Location", [ Config.root_path; ]); ]
      ()
  in
  run
  ~req_http_method:[ `GET; `HEAD ]
  ~req_content_type:[ MimeType.html; ]
  (certification_check_wrapper ~error_handler main)
;;
