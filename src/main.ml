open Core
open Opium.Std
open Lwt.Infix

(* create the stores *)
let kv_store = Database.create_kv_store ~file:"/tmp/storekv"
let ts_store = Database.create_ts_store ~file:"/tmp/storets"
let image_store = Database.create_image_store ~file:"/tmp/storeimage"
    
let get_time () = int_of_float (Unix.time ())

let status = get "/status"
    begin fun _ ->
      respond' (`String "active")
    end

let get_image = get "/:key/image"
    begin fun req ->
      let key = param req "key" in
      let headers = Cohttp.Header.init_with "content-type" "image/jpeg" in
      Database.read_image image_store key
      >>= (fun resp -> respond' ~headers:headers (`Html resp))
    end

let post_ts_image = post "/:id/image"
    begin fun req ->
      let uuid = Uuid.create () |> Uuid.to_string in
      let json_uuid = Ezjsonm.dict [("uuid", (`String uuid))] in
      let id = param req "id" in
      (req |> App.string_of_body_exn) >>=
      fun body -> Database.write_image image_store uuid body >>=
      fun _ -> Database.write_ts ts_store id json_uuid >>=
      fun resp -> respond' (`Json resp)
    end 

let get_kv = get "/:key/kv"
    begin fun req ->
      let key = param req "key" in
      Database.read_kv kv_store key
      >>= (fun resp -> respond' (`Json resp))
    end
    
let post_kv = post "/:key/kv"
    begin fun req ->
      let key = param req "key" in
      (req |> App.json_of_body_exn)
      >>= fun body -> Database.write_kv kv_store key body
      >>= fun resp -> respond' (`Json resp)
    end    

let post_ts = post "/:id/ts"
    begin fun req ->
      let id = param req "id" in
      (req |> App.json_of_body_exn)
      >>= fun body -> Database.write_ts ts_store id body
      >>= fun resp -> respond' (`Json resp)
    end    

let get_ts_latest = get "/:id/ts/latest"
    begin fun req ->
      let id = param req "id" in
      Database.read_ts_latest ts_store id
      >>= (fun resp -> respond' (`Json resp))
    end

let get_ts_last = get "/:id/ts/last/:n"
    begin fun req ->
      let id = param req "id" in
      let n = param req "n" in
      Database.read_ts_last ts_store id (int_of_string n)
      >>= (fun resp -> respond' (`Json resp))
    end

let get_ts_since = get "/:id/ts/since/:from"
    begin fun req ->
      let id = param req "id" in
      let from = param req "from" in
      Database.read_ts_since ts_store id (int_of_string from)
      >>= (fun resp -> respond' (`Json resp))
    end

let get_ts_last_since = get "/:id/ts/last/:n/since/:from"
    begin fun req ->
      let id = param req "id" in
      let n = param req "n" in
      let from = param req "from" in
      Database.read_ts_last_since ts_store id (int_of_string n) (int_of_string from)
      >>= (fun resp -> respond' (`Json resp))
    end

let get_ts_range = get "/:id/ts/range/:from/:to"
    begin fun req ->
      let id = param req "id" in
      let t1 = param req "from" in
      let t2 = param req "to" in
      Database.read_ts_range ts_store id (int_of_string t1) (int_of_string t2)
      >>= (fun resp -> respond' (`Json resp))
    end

let get_ts_last_range = get "/:id/ts/last/:n/range/:from/:to"
    begin fun req ->
      let id = param req "id" in
      let n = param req "n" in
      let t1 = param req "from" in
      let t2 = param req "to" in
      Database.read_ts_last_range ts_store id (int_of_string n) (int_of_string t1) (int_of_string t2)
      >>= (fun resp -> respond' (`Json resp))
    end


let get_hypercat = get "/cat"
    begin fun _ ->
      let _ = Lwt_log.info_f "%d:Requesting cat\n" (get_time ()) in
      let resp = Hypercat.get_cat () in
      respond' (`Json resp) 
    end

let update_hypercat = post "/cat"
    begin fun req ->
      (req |> App.json_of_body_exn)
      >>= fun body ->
      let _ = Lwt_log.info_f "%d:Updating cat\n" (get_time ()) in
      let resp = Hypercat.update_cat (Ezjsonm.value body) in
      respond' (`Json resp)
    end

let validate_token ~f =
  let filter handler req =
    (* note we need to refuse when no X-Api-Key still *)
    match Cohttp.Header.get (Request.headers req) "X-Api-Key" with
    | Some token when not (f token (Bootstrap.get_macaroon_secret ())) ->
      let _ = Out_channel.write_all "/tmp/received_token.txt" ~data:token in
      let _ = Out_channel.write_all "/tmp/received_secret.txt" ~data:(Bootstrap.get_macaroon_secret ()) in
      `String ("Failed to validate macaroon") |> respond'
    | _ -> handler req in
  Rock.Middleware.create ~filter ~name:"validate_token"

let with_ssl () =
  App.ssl ~cert:(Bootstrap.get_http_cert ()) ~key:(Bootstrap.get_http_key ())
         
let with_macaroon () =
  middleware (validate_token ~f:Auth_token.is_valid_token)

let with_port_8080 () =
  App.port 8080
  
let run () =
  App.empty
  |> with_port_8080 ()
  |> with_ssl ()
  |> with_macaroon ()
  |> post_ts_image
  |> get_image
  |> post_kv
  |> get_kv
  |> post_ts
  |> get_ts_latest
  |> get_ts_last
  |> get_ts_since
  |> get_ts_last_since
  |> get_ts_range
  |> get_ts_last_range
  |> get_hypercat
  |> update_hypercat
  |> status
  |> App.run_command


let _ =
  let _ = Bootstrap.init () in
  run ()

