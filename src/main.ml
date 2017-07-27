open Core
open Opium.Std
open Lwt.Infix

(* create the stores *)
let kv_store = Database.create_kv_store ~file:"/tmp/storekv"
let ts_store = Database.create_ts_store ~file:"/tmp/storets"
let image_store = Database.create_image_store ~file:"/tmp/storeimage"

(* http credentials *)
let http_cert = Bootstrap.get_http_cert ()
let http_key = Bootstrap.get_http_key () 

(* utility funcs *)
let get_time () = int_of_float (Unix.time ())

let prefix_path s =
  String.split s ':' |>
  List.last_exn |>
  fun s' -> "path = " ^ String.drop_prefix s' 4

let prefix_meth s =
  "method = " ^ s

let prefix_target s =
  "target = " ^ s

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
    let code = `Unauthorized in
    let headers = Request.headers req in
    let token = Cohttp.Header.get headers "X-Api-Key" in
    match token with
    | None ->
      `String "Missing/Invalid API key" |> respond' ~code
    | Some token ->
      let meth = req |> Request.meth |> Cohttp.Code.string_of_method |> prefix_meth in
      let path = req |> Request.uri |> Uri.to_string |> prefix_path in
      let target = Bootstrap.get_local_name () |> prefix_target in
      Auth_token.set_network_credentials [target; meth; path];
      let secret = Bootstrap.get_macaroon_secret () in
      if not (f token secret) then
        `String "Failed to validate macaroon" |> respond' ~code
      else handler req in
  Rock.Middleware.create ~filter ~name:"validate_token"
          
let with_ssl () =
  App.ssl ~cert:http_cert ~key:http_key
         
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

