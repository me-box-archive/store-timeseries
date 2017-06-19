open Lwt
open Cohttp
open Cohttp_lwt_unix
open Alcotest

let url = "http://127.0.0.1:3000"

let get path =
  Client.get (Uri.of_string (url ^ path))
  >>= fun (_, body) ->
  body |> Cohttp_lwt_body.to_string

let post path data =
  Client.post ~body:(Cohttp_lwt_body.of_string data)
    (Uri.of_string (url ^ path))
  >>= fun (_, body) ->
  body |> Cohttp_lwt_body.to_string

(* key values *)

module Test_kv = struct
  let post_kv path data = Lwt_main.run (post path data)
  let get_kv path = Lwt_main.run (get path)
  let key = "/foo/kv"
  let value = "{\"bar\":42}"
  let status_true = "{\"status\":true}"
  let key_not_found = "/bar/kv"
  let value_not_found = "{}"
end

let post_kv () =
  Alcotest.(check string) "status true" Test_kv.status_true (Test_kv.post_kv Test_kv.key Test_kv.value)

let get_kv () =
  Alcotest.(check string) "match value" Test_kv.value (Test_kv.get_kv Test_kv.key)

let get_kv_not_found () =
  Alcotest.(check string) "match empty" Test_kv.value_not_found (Test_kv.get_kv Test_kv.key_not_found)

let test_kv = [
  "post kv" , `Quick, post_kv;
  "get kv" , `Quick, get_kv;
  "get kv not found", `Quick, get_kv_not_found;
]

(* time series *)

module Test_ts = struct
  let post_ts path data = Lwt_main.run (post path data)
  let remove_ts_latest path =  Lwt_main.run (get path)
  let get_ts_latest path =  Lwt_main.run (get path)
  let get_ts_since path = Lwt_main.run (get path)
  let get_ts_range path = Lwt_main.run (get path)
  let key = "/foo/ts"
  let key_remove_latest = "/foo/ts/remove/latest"
  let key_latest = "/foo/ts/latest"
  let key_since = "/foo/ts/since/0"
  let key_range = "/foo/ts/range"
  let key_range_empty = "/foo/ts/range/0/0"
  let value = "{\"bar\":42}"
  let value_array = "[{\"bar\":42},{\"bar\":42},{\"bar\":42}]"
  let status_true = "{\"status\":true}"
  let key_not_found = "/bar/ts"
  let value_not_found = "{}"
  let value_array_empty = "[]"
end

let post_ts () =
  Alcotest.(check string) "status true" Test_ts.status_true (Test_ts.post_ts Test_ts.key Test_ts.value)

let remove_ts_latest () =
  Alcotest.(check string) "match value" Test_ts.value (Test_ts.remove_ts_latest Test_ts.key_remove_latest)

let get_ts_latest_empty () =
  Alcotest.(check string) "match empty" Test_ts.value_not_found (Test_ts.get_ts_latest Test_ts.key_latest)

let get_ts_latest () =
  Alcotest.(check string) "match value" Test_ts.value (Test_ts.get_ts_latest Test_ts.key_latest)

let get_ts_since () =
  Alcotest.(check string) "match value" Test_ts.value_array (Test_ts.get_ts_since Test_ts.key_since)

let get_ts_range_empty () =
  Alcotest.(check string) "match empty" Test_ts.value_array_empty (Test_ts.get_ts_range Test_ts.key_range_empty)

let get_ts_range () =
  let now = int_of_float (Unix.time ()) in
  let ten_seconds_before = now - 10 in
  let ten_seconds_after = now + 10 in
  let t1 = Printf.sprintf "%d" ten_seconds_before in
  let t2 = Printf.sprintf "%d" ten_seconds_after in
  let path = Test_ts.key_range ^ "/" ^ t1 ^ "/" ^ t2 in
  Alcotest.(check string) "match value" Test_ts.value_array (Test_ts.get_ts_range path)

let test_ts = [
  (* add 3 values *)
  "post ts" , `Quick, post_ts;
  "post ts" , `Quick, post_ts;
  "post ts" , `Quick, post_ts;
  (* remove 3 values *)
  "remove ts latest" , `Quick, remove_ts_latest;
  "remove ts latest" , `Quick, remove_ts_latest;
  "remove ts latest" , `Quick, remove_ts_latest;
  (* check empty *)
  "get ts latest empty" , `Quick, get_ts_latest_empty;
  (* add 3 values *)
  "post ts" , `Quick, post_ts;
  "post ts" , `Quick, post_ts;
  "post ts" , `Quick, post_ts;
  (* get latest *)
  "get ts latest" , `Quick, get_ts_latest;
  (* get since *)
  "get ts since start of time" , `Quick, get_ts_since;
  (* nothing in range *)
  "get ts range empty" , `Quick, get_ts_range_empty;
  (* get range *)
  "get ts range" , `Quick, get_ts_range; 
  (* remove values to leave empty state *)
  "remove ts latest" , `Quick, remove_ts_latest;
  "remove ts latest" , `Quick, remove_ts_latest;
  "remove ts latest" , `Quick, remove_ts_latest;
]

let () =
  Alcotest.run "Data store" [
    "test_kv", test_kv;
    "test_ts", test_ts;
  ]
