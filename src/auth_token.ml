

module Macaroon = Sodium_macaroons

type t = { mutable credentials: string list }

let network = { credentials = [] }

let mint_token ?(id = "id") ?(location = "location") ?(path = "path")
    ?(target = "target") ?(meth = "meth") ~key =
  let m = Macaroon.create ~id ~location ~key in
  let m = Macaroon.add_first_party_caveat m target in
  let m = Macaroon.add_first_party_caveat m path in
  let m = Macaroon.add_first_party_caveat m meth in
  Macaroon.serialize m

let set_network_credentials creds =
  network.credentials <- creds

let check_caveats s =
  List.mem s network.credentials

let validate_macaroon m secret =
  Macaroon.verify m ~key:secret ~check:check_caveats []

let is_valid_token token key =
  match Macaroon.deserialize token with
  | `Ok m -> (validate_macaroon m key)
  | `Error _ -> failwith "could not deserialize macaroon"



