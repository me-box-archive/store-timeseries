open Core.Std
open Lwt
open Cohttp
open Cohttp_lwt_unix

type t = {
  macaroon_secret_file: string;
  http_key_file: string;
  http_cert_file: string;
  arbiter_endpoint: string;
  arbiter_token_file: string;
  http_certs_file: string;
}

let env = {
  macaroon_secret_file = "/tmp/secret";
  http_key_file = "/tmp/key";
  http_cert_file = "/tmp/cert";
  arbiter_endpoint = "https://databox-arbiter:8080/store/secret";
  arbiter_token_file = "/run/secrets/ARBITER_TOKEN";
  http_certs_file = "/run/secrets/DATABOX_PEM";
}

let set_http_key key =
  let f = Fpath.v env.http_key_file in
  let _ = Bos.OS.File.write f key in
  ()

let set_http_cert cert =
  let f = Fpath.v env.http_cert_file in
  let _ = Bos.OS.File.write f cert in
  ()

let init_http_cert () =
  Fpath.v env.http_certs_file |>
  Bos.OS.File.read |>
  Rresult.R.get_ok |>
  Ezjsonm.from_string |>
  Ezjsonm.get_dict |>
  fun dict ->
  let key = List.Assoc.find_exn dict "clientprivate" ~equal:(=) in
  let cert = List.Assoc.find_exn dict "clientcert" ~equal:(=) in
  set_http_key (Ezjsonm.get_string key);
  set_http_cert (Ezjsonm.get_string cert)
  
let get_http_key () =
  env.http_key_file

let get_http_cert () =
  env.http_cert_file

let arbiter_token () =
  Fpath.v env.arbiter_token_file |>
  Bos.OS.File.read |>
  Rresult.R.get_ok |>
  B64.encode

let macaroon_secret token =
  let key = ["X-Api-Key", token] in
  let headers = Cohttp.Header.of_list key in
  Client.get ~headers (Uri.of_string env.arbiter_endpoint) >>=
  fun (_, body) -> body |> Cohttp_lwt_body.to_string


let get_macaroon_secret () =
  Fpath.v env.macaroon_secret_file |>
  Bos.OS.File.read |>
  Rresult.R.get_ok

let set_macaroon_secret key =
  let f = Fpath.v env.macaroon_secret_file in
  let _ = Bos.OS.File.write f key in
  ()

let init_macaroon_secret token =
  Lwt_main.run (macaroon_secret token) |>
  B64.decode |>
  set_macaroon_secret

let init () =
  init_http_cert ();
  init_macaroon_secret (arbiter_token ())
