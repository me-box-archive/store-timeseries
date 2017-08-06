open Opium.Std;

open Lwt.Infix; 

/* create the stores */
let kv_store = Database.create_kv_store file::"/tmp/storekv";

let ts_store = Database.create_ts_store file::"/tmp/storets";

let image_store =
  Database.create_image_store file::"/tmp/storeimage"; 
  
/* http credentials */
let http_cert = Bootstrap.get_http_cert ();

let http_key = Bootstrap.get_http_key (); 

/* utility funcs */
let get_time () => 
  int_of_float (Unix.time ());

let list_last l => 
  List.nth l (List.length l - 1);

let string_split_at s n => 
  (String.sub s 0 n, String.sub s n (String.length s - n));

let string_drop_prefix n s => 
  string_split_at s n |> snd;  

let prefix_path s =>
  String.split_on_char ':' s |> 
    list_last |> 
      (fun s' => "path = " ^ string_drop_prefix 4 s');

let prefix_meth s => "method = " ^ s;

let prefix_target s => "target = " ^ s;

let status = get "/status" (fun _ => respond' (`String "active"));

let get_image = get "/:key/image" {
      fun req => {
        let key = param req "key";
        let headers = Cohttp.Header.init_with "content-type" "image/jpeg";
        Database.read_image image_store key >>=
          fun resp => respond' ::headers (`Html resp)
      }
};

let post_ts_image = post "/:id/image" {
      fun req => {
        let uuid = Uuidm.v4_gen (Random.State.make_self_init ()) () |> Uuidm.to_string;
        let json_uuid = Ezjsonm.dict [("uuid", `String uuid)];
        let id = param req "id";
        req |> App.string_of_body_exn >>=
          fun body =>
            Database.write_image image_store uuid body >>=
              fun _ =>
                Database.write_ts ts_store id json_uuid >>=
                  fun resp => respond' (`Json resp)
      }
};

let get_kv = get "/:key/kv" {
      fun req => {
        let key = param req "key";
        Database.read_kv kv_store key >>= (fun resp => respond' (`Json resp))
      }
};

let post_kv = post "/:key/kv" {
      fun req => {
        let key = param req "key";
        req |> App.json_of_body_exn >>=
          fun body =>
            Database.write_kv kv_store key body >>= (fun resp => respond' (`Json resp))
      }
};

let post_ts = post "/:id/ts" {
      fun req => {
        let id = param req "id";
        req |> App.json_of_body_exn >>=
          fun body =>
            Database.write_ts ts_store id body >>= (fun resp => respond' (`Json resp))
      }
};

let get_ts_latest = get "/:id/ts/latest" {
      fun req => {
        let id = param req "id";
        Database.read_ts_latest ts_store id >>= (fun resp => respond' (`Json resp))
      }
};

let get_ts_last = get "/:id/ts/last/:n" {
      fun req => {
        let id = param req "id";
        let n = param req "n";
        Database.read_ts_last ts_store id (int_of_string n) >>=
          fun resp => respond' (`Json resp)
      }
};

let get_ts_since = get "/:id/ts/since/:from" {
      fun req => {
        let id = param req "id";
        let from = param req "from";
        Database.read_ts_since ts_store id (int_of_string from) >>=
          fun resp => respond' (`Json resp)
      }
};

let get_ts_last_since = get "/:id/ts/last/:n/since/:from" {
      fun req => {
        let id = param req "id";
        let n = param req "n";
        let from = param req "from";
        Database.read_ts_last_since ts_store id (int_of_string n) (int_of_string from) >>=
          fun resp => respond' (`Json resp)
      }
};

let get_ts_range = get "/:id/ts/range/:from/:to" {
      fun req => {
        let id = param req "id";
        let t1 = param req "from";
        let t2 = param req "to";
        Database.read_ts_range ts_store id (int_of_string t1) (int_of_string t2) >>=
          fun resp => respond' (`Json resp)
      }
};

let get_ts_last_range = get "/:id/ts/last/:n/range/:from/:to" {
      fun req => {
        let id = param req "id";
        let n = param req "n";
        let t1 = param req "from";
        let t2 = param req "to";
        Database.read_ts_last_range
          ts_store id (int_of_string n) (int_of_string t1) (int_of_string t2) >>=
          fun resp => respond' (`Json resp)
      }
};

let get_hypercat = get "/cat" {
      fun _ => {
        let _ = Lwt_log.info_f "%d:Requesting cat\n" (get_time ());
        let resp = Hypercat.get_cat ();
        respond' (`Json resp)
      }
};

let update_hypercat = post "/cat" {
      fun req =>
        req |> App.json_of_body_exn >>=
          fun body => {
            let _ = Lwt_log.info_f "%d:Updating cat\n" (get_time ());
            let resp = Hypercat.update_cat (Ezjsonm.value body);
            respond' (`Json resp)
          }
};

let validate_token ::f => {
  let filter handler req => {
    let code = `Unauthorized;
    let headers = Request.headers req;
    let token = Cohttp.Header.get headers "X-Api-Key";
    switch token {
    | None => `String "Missing/Invalid API key" |> respond' ::code
    | Some token =>
      let meth = req |> Request.meth |> Cohttp.Code.string_of_method |> prefix_meth;
      let path = req |> Request.uri |> Uri.to_string |> prefix_path;
      let target = Bootstrap.get_local_name () |> prefix_target;
      Auth_token.set_network_credentials [target, meth, path];
      let secret = Bootstrap.get_macaroon_secret ();
      if (not (f token secret)) {
        `String "Failed to validate macaroon" |> respond' ::code
      } else {
        handler req
      }
    }
  };
  Rock.Middleware.create ::filter name::"validate_token"
};

let with_ssl () => 
  App.ssl cert::http_cert key::http_key;

let with_macaroon () => 
  middleware (validate_token f::Auth_token.is_valid_token);

let with_port_8080 () => 
  App.port 8080;

let run () =>
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
  |> App.run_command;

{
  let _ = Bootstrap.init ();
  run ()
};