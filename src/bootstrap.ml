open Core.Std
open Lwt
open Cohttp
open Cohttp_lwt_unix

type t = {
  mutable macaroon_secret: string;
  arbiter_endpoint: string;
  arbiter_token_file: string;
}

let env = {
  macaroon_secret = "not set yet";
  arbiter_endpoint = "http://127.0.0.1:8888/store/secret";
  arbiter_token_file = "/tmp/run/secrets/ARBITER_TOKEN"
}

let arbiter_token () =
  Fpath.v env.arbiter_token_file |>
  Bos.OS.File.read |>
  Rresult.R.get_ok |>
  String.strip |>
  B64.decode

let macaroon_secret token =
  let key = ["X-Api-Key", token] in
  let headers = Cohttp.Header.of_list key in
  Client.get ~headers (Uri.of_string env.arbiter_endpoint) >>=
  fun (_, body) -> body |> Cohttp_lwt_body.to_string  

let set_macaroon_secret key =
  env.macaroon_secret <- key

let get_macaroon_secret () =
  env.macaroon_secret

let init_macaroon_secret token =
  Lwt_main.run (macaroon_secret token) |>
  set_macaroon_secret

let init () =
  init_macaroon_secret (arbiter_token ())
