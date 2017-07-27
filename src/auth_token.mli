
val mint_token :
  ?id:string ->
  ?location:string ->
  ?path:string -> ?target:string -> ?meth:string -> key:string -> string

val is_valid_token : string -> string -> bool

val set_network_credentials : string list -> unit
