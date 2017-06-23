open Core.Std
open Opium.Std
open Lwt.Infix

let epoch () = int_of_float (Unix.time ())

let get_kv = get "/:key/kv"
    begin fun req ->
      let key = param req "key" in
      Database.read_kv key
      >>= (fun resp -> respond' (`Json resp))
    end
    
let post_kv = post "/:key/kv"
    begin fun req ->
      let key = param req "key" in
      (req |> App.json_of_body_exn)
      >>= fun body -> Database.write_kv key body
      >>= fun resp -> respond' (`Json resp)
    end    

let post_ts = post "/:id/ts"
    begin fun req ->
      let id = param req "id" in
      (req |> App.json_of_body_exn)
      >>= fun body -> Database.write_ts id body
      >>= fun resp -> respond' (`Json resp)
    end    

let get_ts_latest = get "/:id/ts/latest"
    begin fun req ->
      let id = param req "id" in
      Database.read_ts_latest id
      >>= (fun resp -> respond' (`Json resp))
    end

let remove_ts_latest = get "/:id/ts/remove/latest"
    begin fun req ->
      let id = param req "id" in
      Database.remove_ts_latest id
      >>= (fun resp -> respond' (`Json resp))
    end

let get_ts_since = get "/:id/ts/since/:from"
    begin fun req ->
      let id = param req "id" in
      let from = param req "from" in
      Database.read_ts_since id (int_of_string from)
      >>= (fun resp -> respond' (`Json resp))
    end

let get_ts_range = get "/:id/ts/range/:from/:to"
    begin fun req ->
      let id = param req "id" in
      let t1 = param req "from" in
      let t2 = param req "to" in
      Database.read_ts_range id (int_of_string t1) (int_of_string t2)
      >>= (fun resp -> respond' (`Json resp))
    end

let get_hypercat = get "/cat"
    begin fun _ ->
      let _ = Lwt_log.info_f "%d:Requesting cat\n" (epoch ()) in
      let resp = Hypercat.get_cat () in
      respond' (`Json resp) 
    end

let update_hypercat = post "/cat"
    begin fun req ->
      (req |> App.json_of_body_exn)
      >>= fun body ->
      let _ = Lwt_log.info_f "%d:Updating cat\n" (epoch ()) in
      let resp = Hypercat.update_cat (Ezjsonm.value body) in
      respond' (`Json resp)
    end


let macaroon_secret = "key" (* we need to get this from arbiter instead *)

let validate_token ~f =
  let filter handler req =
    (* note we need to refuse when no X-Api-Key still *)
    match Cohttp.Header.get (Request.headers req) "X-Api-Key" with
    | Some token when not (f token macaroon_secret) ->
      `String ("Invalid token") |> respond'
    | _ -> handler req in
  Rock.Middleware.create ~filter ~name:"validate_token"

let _ =
  App.empty
  |> post_kv
  |> get_kv
  |> post_ts
  |> get_ts_latest
  |> remove_ts_latest
  |> get_ts_since
  |> get_ts_range
  |> get_hypercat
  |> update_hypercat
  |> middleware (validate_token ~f:Auth_token.is_valid_token)
  |> App.run_command
