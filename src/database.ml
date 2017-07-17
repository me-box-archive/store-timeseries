open Core
open Lwt.Infix

module Store_kv = Ezirmin.FS_lww_register(Irmin.Contents.Json)
module Store_ts = Ezirmin.FS_log(Tc.Pair (Tc.Int)(Irmin.Contents.Json))
module Store_image = Ezirmin.FS_lww_register(Irmin.Contents.String)
      

let get_time () = int_of_float (Unix.time ())

let json_ok = Ezjsonm.dict [("status", (`Bool true))]
let json_empty = Ezjsonm.dict []

let create_kv_store ~file =
  Store_kv.init ~root:file ~bare:true () >>= Store_kv.master

let create_ts_store ~file =
  Store_ts.init ~root:file ~bare:true () >>= Store_ts.master

let create_image_store ~file =
  Store_image.init ~root:file ~bare:true () >>= Store_image.master

let write_image store k v =
  store >>= fun store' ->
  Store_image.write ~message:"write_image" store' ~path:["image"; k] v >>=
  fun _ -> Lwt.return ""

let read_image store k =
  store >>= fun store ->
  Store_image.read store ~path:["image"; k] >>=
  fun data -> match data with
  | Some string -> Lwt.return string
  | None -> Lwt.return ""

let write_kv store k v =
  store >>= fun store' ->
  Store_kv.write ~message:"write_kv" store' ~path:["kv"; k] v >>=
  fun _ -> Lwt.return json_ok

let read_kv store k =
  store >>= fun store ->
  Store_kv.read store ~path:["kv"; k] >>=
  fun data -> match data with
  | Some json -> Lwt.return json
  | None -> Lwt.return json_empty

let write_ts store id v =
  store >>= fun store' ->
  let t = get_time () in
  Store_ts.append ~message:"write_ts" store' ~path:["ts"; id] (t,v) >>=
  fun _ -> Lwt.return json_ok

let get_cursor store id =
  store >>= fun store' ->
  Store_ts.get_cursor store' ~path:["ts"; id]

let read_from_cursor cursor n =
  match cursor with
  | Some c -> Store_ts.read c n
  | None -> Lwt.return ([], cursor)

(* returns dataset with cursor *)
let read_ts store id n =
  store >>= fun store' ->
  Store_ts.get_cursor store' ~path:["ts"; id] >>=
  fun cursor -> read_from_cursor cursor n

(* returns just the dataset *)
let read_ts_data store id n =
  read_ts store id n >>=
  fun (data,_) -> Lwt.return data

(* remove timestamp from dataset *)
let ts_remove_timestamp l  =
  List.map ~f:(fun (_,json) -> (Ezjsonm.value json)) l |>
  fun l -> Ezjsonm.(`A l)

let read_ts_latest store id =
  read_ts store id 1 >>=
  fun (data,_) -> match data with
  | [] -> Lwt.return json_empty
  | (_,json)::_ -> Lwt.return json

let read_ts_last store id n =
  read_ts_data store id n >>=
  fun data -> Lwt.return (ts_remove_timestamp data)

let ts_since t l =
  List.filter ~f:(fun (ts,_) -> ts >= t ) l

let ts_until t l =
  List.filter ~f:(fun (ts,_) -> ts < t ) l

let ts_range t1 t2 l =
  ts_since t1 l |> ts_until t2

let read_ts_last_since store id n t =
  read_ts_data store id n >>=
  fun l -> Lwt.return (ts_remove_timestamp (ts_since t l))

let read_ts_last_range store id n t1 t2 =
  read_ts_data store id n >>=
  fun l -> Lwt.return (ts_remove_timestamp (ts_range t1 t2 l))

let read_ts_data_all store id =
  store >>= fun store' ->
  Store_ts.read_all store' ~path:["ts"; id]

(* might need to look at paging this back for large sets *)
let read_ts_all store id =
  read_ts_data_all store id >>=
  fun data -> Lwt.return (ts_remove_timestamp data)

let read_ts_since store id t  =
  read_ts_data_all store id >>=
  fun l -> Lwt.return (ts_remove_timestamp (ts_since t l))

let read_ts_range store id t1 t2 =
  read_ts_data_all store id >>=
  fun l -> Lwt.return (ts_remove_timestamp (ts_range t1 t2 l))








