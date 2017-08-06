module Macaroon = Sodium_macaroons;

type t = {mutable credentials: list string};

let network = {credentials: []};

let mint_token
    ::id="id"
    ::location="location"
    ::path="path"
    ::target="target"
    ::meth="meth"
    ::key => {
  let m = Macaroon.create ::id ::location ::key;
  let m = Macaroon.add_first_party_caveat m target;
  let m = Macaroon.add_first_party_caveat m path;
  let m = Macaroon.add_first_party_caveat m meth;
  Macaroon.serialize m
};

let set_network_credentials creds => network.credentials = creds;

let check_caveats s => List.mem s network.credentials;

let validate_macaroon m secret => Macaroon.verify m key::secret check::check_caveats [];

let is_valid_token token key =>
  switch (Macaroon.deserialize token) {
  | `Ok m => validate_macaroon m key
  | `Error _ => failwith "could not deserialize macaroon"
  };