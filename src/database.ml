open Core.Std

module M = Ezirmin.FS_queue(Tc.Pair (Tc.Int)(Tc.String))
open M
open Lwt.Infix


let db = Lwt_main.run (init ~root:"/tmp/ezirminq" ~bare:true () >>= master)

let epoch () = int_of_float (Unix.time ())

let to_object_array list =
  List.map ~f:(fun (_,string) -> Ezjsonm.from_string string) list
    
let since time list =
  List.filter ~f:(fun (timestamp,_) -> timestamp >= time ) list
  
let until time list =
  List.filter ~f:(fun (timestamp,_) -> timestamp < time ) list

let range t1 t2 list =
  since t1 list |> until t2


let latest list =
  let rec last list =
    match list with
    | [] -> (0,"{}")
    | [item] -> item
    | _::tl -> last tl in
  last list

let first list =
  match list with
  | [] -> (0, "{}")
  | item::_ -> item

let read_ts_latest id =
  Lwt.bind
    (to_list db ~path:["ts"; id])
    (fun list ->
       let (_,string) = latest list in
       let timestamp = epoch () in
       let _ = Lwt_log.info_f "%d:read_ts_latest -> value:%s\n" timestamp string in
       let json = Ezjsonm.from_string string in
       Lwt.return (json))


let read_kv id =
  Lwt.bind
    (to_list db ~path:["kv"; id])
    (fun list ->
       let (_,string) = first list in
       let timestamp = epoch () in
       let _ = Lwt_log.info_f "%d:read_kv -> value:%s\n" timestamp string in
       let json = Ezjsonm.from_string string in
       Lwt.return (json))


let read_ts_since id from =
  let open Ezjsonm in
  Lwt.bind
    (to_list db ~path:["ts"; id])
    (fun list ->
       let l1 = since from list in
       let l2 = to_object_array l1 in
       let len = List.length l2 in
       let timestamp = epoch () in
       let _ = Lwt_log.info_f "%d:read_ts_since -> returning %d items\n" timestamp len in
       Lwt.return (`A l2))    

let read_ts_range id t1 t2 =
  let open Ezjsonm in
  Lwt.bind
    (to_list db ~path:["ts"; id])
    (fun list ->
       let l1 = range t1 t2 list in
       let l2 = to_object_array l1 in
       let len = List.length l2 in
       let timestamp = epoch () in
       let _ = Lwt_log.info_f "%d:read_ts_range -> returning %d items\n" timestamp len in
       Lwt.return (`A l2)) 

let remove_ts_latest k =
  let unwrap tuple = match tuple with
    | Some tuple -> tuple
    | None -> (0,"{}") in
  Lwt.bind
    (pop ~message:"remove_ts_latest" db ~path:["ts"; k])
    (fun resp ->
       let (_,string) = unwrap resp in
       let timestamp = epoch () in
       let _ = Lwt_log.info_f "%d:read_kv_queue -> value:%s\n" timestamp string in
       let json = Ezjsonm.from_string string in
       Lwt.return (json))
    
let write_kv key json =
  let open Ezjsonm in
  let string = to_string json in
  let timestamp = epoch () in
  let _ = Lwt_log.info_f "%d:write_kv -> key:%s, value:%s\n" timestamp key string in
  create ~message:"create kv" db ~path:["kv"; key] (* always start with empty db *)
  >>= (fun _ ->
      let message = (Printf.sprintf "write_kv:%d" timestamp) in
      push ~message:message db ~path:["kv"; key] (timestamp,string))
  >>= (fun _ -> Lwt.return (dict [("status", (`Bool true))]))
      

let write_ts id json =
  let open Ezjsonm in
  let string = to_string json in
  let timestamp = epoch () in
  let _ = Lwt_log.info_f "%d:write_ts -> id:%s, value:%s\n" timestamp id string in
  let message = (Printf.sprintf "write_ts:%d" timestamp) in
  push ~message:message db ~path:["ts"; id] (timestamp,string)
  >>= (fun _ -> Lwt.return (dict [("status", (`Bool true))]))

