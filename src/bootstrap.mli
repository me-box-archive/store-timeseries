
val init : unit -> unit Lwt.t

val get_macaroon_secret : unit -> string

val get_http_key : unit -> string

val get_http_cert : unit -> string

val get_local_name : unit -> string

