let debug =
  let df = try Sys.getenv "DEBUG" <> "" with Not_found -> false in
  if df then prerr_endline else (fun _ -> ())

type spec = [
| `String of string
| `NonEmpty of string
| `Int32 of string
| `Any of spec
]
;;

let rec check_args (schema : spec list) (args : string list) : bool =
  let error msg =
    prerr_endline msg;
    false
  in
  match schema, args with
  | [], [] -> true
  | `String _ :: ts, str :: ta -> check_args ts ta
  | `NonEmpty name :: ts, str :: ta -> begin
    if BatString.is_empty str then
      error (Printf.sprintf "The %s must be non-empty" name)
    else
      check_args ts ta
  end
  | `Int32 name :: ts, str :: ta -> begin
    let convertible =
      try ignore (Int32.of_string str); true with
        Failure _ ->
          error (Printf.sprintf "The %s must be an integer" name)
    in
    convertible && check_args ts ta
  end
  | `Any spec :: _, _ ->
    List.for_all (fun x -> check_args [spec] [x]) args
  | (`String name | `NonEmpty name | `Int32 name) :: _, [] ->
    error (Printf.sprintf "The argument for %s isn't given" name)
  | [], _ :: _ ->
    error "The arguments are too many"
;;

exception Invalid_argument of string
;;

type 'a process = 'a PGOCaml.t PGOCaml.monad -> string list -> Yojson.json option
;;
type 'a action = string * (spec list * 'a process)
;;

let run =
  let rec name_of_spec = function
    | `String x | `NonEmpty x | `Int32 x -> x
    | `Any spec -> name_of_spec spec
  in

  let body actions user password database action args =
    let (schema, process) = try List.assoc action actions with
      | Not_found -> 
        prerr_endline (Printf.sprintf "Action %s is not found" action);
        exit 1
    in
    let usage =
      let names =
        List.map (fun spec -> Printf.sprintf "[%s]" (name_of_spec spec)) schema
      in
      Printf.sprintf "usage: program [user] [password] [database] %s %s"
        action
        (String.concat " " names)
    in
    let args = List.map BatString.trim args in
    if List.exists (fun arg -> arg = "--help" or arg = "-h") args then
      print_endline usage
    else if not (check_args schema args) then begin
      prerr_endline usage; exit 1
    end else
      let dbh = PGOCaml.connect ~user ~password ~database () in
      let closed = ref false in
      let finally () =
        if not !closed then (PGOCaml.close dbh; closed := true)
      in
      at_exit finally;
      try
        (match process dbh args with
        | Some json -> print_endline (Yojson.pretty_to_string json)
        | None -> ());
        finally ()
      with
      | Invalid_argument name -> begin
        prerr_endline (Printf.sprintf "The argument for %s is invalid" name);
        finally ()
      end
      | e -> finally (); raise e
  in

  fun (actions :  'a action list) (argv : string array) ->
    match Array.to_list argv with
    | _ :: user :: passwd :: db :: action :: args ->
      body actions user passwd db action args
    | _ -> begin
      prerr_endline "usage: program [user] [password] [database] [action] ...";
      prerr_endline
        (Printf.sprintf
           "       [action] ::= %s"
           (String.concat ", " (List.map fst actions)));
      exit 1
    end
