

module Macaroon = Sodium_macaroons

let mint_token ?(id = "id") ?(location = "location") ?(key = "key")
    ?(target = "target") ?(meth = "method") ~path =
  let m = Macaroon.create ~id ~location ~key in
  let m = Macaroon.add_first_party_caveat m target in
  let m = Macaroon.add_first_party_caveat m path in
  let m = Macaroon.add_first_party_caveat m meth in
  Macaroon.serialize m

(* called for each caveat *)
let check_caveats s =
  true

let validate_macaroon m secret =
  Macaroon.verify m ~key:secret ~check:check_caveats []

let is_valid_token token key =
  match Macaroon.deserialize token with
  | `Ok m -> (validate_macaroon m key)
  | `Error _ -> false



