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
            
module To_test = struct
  let post_kv path data = Lwt_main.run (post path data)
end

let post_kv () =
  Alcotest.(check string) "status true" "{\"status\":true}" (To_test.post_kv "/foo/kv" "{\"bar\":42}")

let test_set = [
  "post kv" , `Quick, post_kv;
]

let () =
  Alcotest.run "My first test" [
    "test_set", test_set;
  ]
    
