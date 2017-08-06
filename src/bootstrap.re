
open Lwt;

open Cohttp;

open Cohttp_lwt_unix;

type t = {
  mutable macaroon_secret: string,
  mutable local_name: string,
  arbiter_endpoint: string,
  arbiter_token_file: string,
  http_certs_file: string
};

let env = {
  macaroon_secret: "",
  local_name: "",
  arbiter_endpoint: "https://arbiter:8080/store/secret",
  arbiter_token_file: "/run/secrets/ARBITER_TOKEN",
  http_certs_file: "/run/secrets/DATABOX.pem"
};

let get_http_key () => env.http_certs_file;

let get_http_cert () => env.http_certs_file;

let arbiter_token () =>
  Fpath.v env.arbiter_token_file |> Bos.OS.File.read |> Rresult.R.get_ok |> B64.encode;

let macaroon_secret token => {
  let key = [("X-Api-Key", token)];
  let headers = Cohttp.Header.of_list key;
  Client.get ::headers (Uri.of_string env.arbiter_endpoint) >>= (
    fun (_, body) => body |> Cohttp_lwt_body.to_string
  )
};

let get_macaroon_secret () => env.macaroon_secret;

let set_macaroon_secret key => env.macaroon_secret = key;

let init_macaroon_secret token =>
  macaroon_secret token >>= (fun secret => Lwt.return (set_macaroon_secret secret));

let set_local_name () => 
  /* need exceptiom handling */
  env.local_name = Sys.getenv "DATABOX_LOCAL_NAME";

let get_local_name () => env.local_name;

let init () => {
  set_local_name ();
  init_macaroon_secret (arbiter_token ())
};