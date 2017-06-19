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
            
module Test_kv = struct
  (* funcs *)
  let post_kv path data = Lwt_main.run (post path data)
  let get_kv path = Lwt_main.run (get path)
  (* some values *)
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

let () =
  Alcotest.run "Data store" [
    "test_kv", test_kv;
  ]
