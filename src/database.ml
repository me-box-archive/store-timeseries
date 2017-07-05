open Lwt.Infix

module Store_kv = Ezirmin.FS_lww_register(Irmin.Contents.Json)
module Store_ts = Ezirmin.FS_log(Tc.Pair (Tc.Int)(Irmin.Contents.Json))

let kv_store = Lwt_main.run (Store_kv.init ~root:"/tmp/storekv" ~bare:true () >>= Store_kv.master)
let ts_store = Lwt_main.run (Store_ts.init ~root:"/tmp/storets" ~bare:true () >>= Store_ts.master)

let get_time () = int_of_float (Unix.time ())

let json_ok = Ezjsonm.dict [("status", (`Bool true))]
let json_empty = Ezjsonm.dict []

(* currently borked: waiting on issue to be fixed in ezirmin *)
let write_kv k v =
  Store_kv.write ~message:"write_kv" kv_store ~path:["kv"; k] v >>=
  fun _ -> Lwt.return json_ok

let read_kv k =
  Store_kv.read kv_store ~path:["kv"; k] >>=
  fun data -> match data with
  | Some json -> Lwt.return json
  | None -> Lwt.return json_empty

let write_ts id v =
  let t = get_time () in
  Store_ts.append ~message:"write_ts" ts_store ~path:["ts"; id] (t,v) >>=
  fun _ -> Lwt.return json_ok

let get_cursor id =
   Store_ts.get_cursor ts_store ~path:["ts"; id]

let read_from_cursor cursor n =
  match cursor with
  | Some c -> Store_ts.read c n
  | None -> Lwt.return ([], cursor)

(* returns dataset with cursor *)
let read_ts id n =
  Store_ts.get_cursor ts_store ~path:["ts"; id] >>=
  fun cursor -> read_from_cursor cursor n

(* returns just the dataset *)
let read_ts_data id n =
  read_ts id n >>=
  fun (data,_) -> Lwt.return data

(* remove timestamp from dataset *)
let ts_remove_timestamp l  =
  List.map (fun (_,json) -> (Ezjsonm.value json)) l |>
  fun l -> Ezjsonm.(`A l)

let read_ts_latest id =
  read_ts id 1 >>=
  fun (data,_) -> match data with
  | [] -> Lwt.return json_empty
  | (_,json)::_ -> Lwt.return json

let read_ts_last id n =
  read_ts_data id n >>=
  fun data -> Lwt.return (ts_remove_timestamp data)

let ts_since t l =
  List.filter (fun (ts,_) -> ts >= t ) l

let ts_until t l =
  List.filter (fun (ts,_) -> ts < t ) l

let ts_range t1 t2 l =
  ts_since t1 l |> ts_until t2

let read_ts_last_since id n t =
  read_ts_data id n >>=
  fun l -> Lwt.return (ts_remove_timestamp (ts_since t l))

let read_ts_last_range id n t1 t2 =
  read_ts_data id n >>=
  fun l -> Lwt.return (ts_remove_timestamp (ts_range t1 t2 l))

let read_ts_data_all id =
  Store_ts.read_all ts_store ~path:["ts"; id]

(* might need to look at paging this back for large sets *)
let read_ts_all id =
  read_ts_data_all id >>=
  fun data -> Lwt.return (ts_remove_timestamp data)

let read_ts_since id t  =
  read_ts_data_all id >>=
  fun l -> Lwt.return (ts_remove_timestamp (ts_since t l))

let read_ts_range id t1 t2 =
  read_ts_data_all id >>=
  fun l -> Lwt.return (ts_remove_timestamp (ts_range t1 t2 l))








