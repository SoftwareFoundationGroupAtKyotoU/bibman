module MimeType = struct

  let html = "text/html"
  ;;

  let json = "application/json"
  ;;

  let text = "text/plain"
  ;;

  (* for POST method *)
  let form_encoded = "application/x-www-form-urlencoded"
  ;;

  let all_types = [
    html;
    json;
    text;
    form_encoded;
  ]
  ;;

end

exception Absent_argument of string
;;

exception Invalid_argument of string
;;

type spec = [
| `Any
| `NonEmpty
| `Int32
| `Symbol of string list
]
;;

let assert_arguments =
  let rec iter (cgi : Netcgi.cgi) = function
    | [] -> ()
    | (param, spec) :: t -> begin
      if not (cgi # argument_exists param) then
        raise (Absent_argument param)
      else
        let args = cgi # multiple_argument param in
        List.iter (fun arg ->
          let v = arg # value in
          match spec with
          | `Any -> ()
          | `NonEmpty when v <> "" -> ()
          | `Int32
              when (try ignore(Int32.of_string v); true with Failure _ -> false)
                -> ()
          | `Symbol l when List.exists ((=) v) l -> ()
          | _ -> raise (Invalid_argument param)
        ) args;
        iter cgi t
    end
  in

  fun (cgi : Netcgi.cgi) (req_params : (string * spec) list) ->
    iter cgi req_params
;;

let exception_handler =
  let set_env env status content =
    env # set_output_header_fields [
      ("Content-type", "text/plain");
    ];
    env # set_status status;
    env # send_output_header ();
    let out = env # out_channel in
    out # output_string content;
    out # close_out ()
  in

  fun (env : Netcgi.cgi_environment) (f : unit -> unit) ->
    try f () with
    | Absent_argument param ->
      set_env env `Not_found
        (Printf.sprintf "The parameter %s is absent" param)
    | Invalid_argument param ->
      set_env env `Forbidden
        (Printf.sprintf "The parameter %s is invalid" param)
;;

let run
    ?(config : Netcgi.config = Netcgi.default_config)
    ?(output_type : Netcgi.output_type =
        `Transactional (fun _ ch -> new Netchannels.buffered_trans_channel ch))
    ?(arg_store : Netcgi.arg_store = fun _ _ _ -> `Automatic)
    ?(exn_handler : Netcgi.exn_handler = exception_handler)
    ?(req_http_method : Netcgi.http_method list = [ `GET; `HEAD; `POST ])
    ?(req_content_type : string list = [])
    ?(required_params : (string * spec) list = [])
    (f : Netcgi.cgi -> unit)
    : unit =
  let config = { config with
    Netcgi.permitted_http_methods = req_http_method;
    Netcgi.permitted_input_content_types = req_content_type;
  } in
  Netcgi_cgi.run
    ~config
    ~output_type
    ~arg_store
    ~exn_handler
    (fun cgi -> assert_arguments cgi required_params; f cgi)
;;

let process_command (prog : string) (args : string list) : string option =
    let mine_in_fd, prog_out_fd = Unix.pipe () in
    let pid =
      Unix.create_process prog (Array.of_list (prog :: args))
        Unix.stdin prog_out_fd Unix.stderr
    in
    Unix.close prog_out_fd;
    let in_ch =
      BatIO.input_channel
        ~autoclose:true
        ~cleanup:true
        (Unix.in_channel_of_descr mine_in_fd)
    in
    let res = BatIO.read_all in_ch in
    let _, status = Unix.waitpid [ Unix.WUNTRACED ] pid in
    match status with
    | Unix.WEXITED 0 -> Some res
    | _ -> None
;;

let redirect_to_script
    (cgi : Netcgi.cgi)
    ?(content_type = MimeType.json)
    ?(output : string -> unit = cgi # out_channel  # output_string)
    (script_file : string)
    (args : string list)
    : bool
    =
  cgi # set_header ~content_type ();
  let res = process_command script_file args in
  let res = match res with
  | Some txt -> output txt; true
  | None -> cgi # set_header ~status:`Bad_request (); false
  in
  cgi # out_channel # commit_work ();
  res
;;
