
val read_kv : string -> Ezjsonm.t Lwt.t

val write_kv : string -> Ezjsonm.t -> Ezjsonm.t Lwt.t

val write_ts : string -> Ezjsonm.t -> Ezjsonm.t Lwt.t 

val read_ts_latest : string -> Ezjsonm.t Lwt.t

val read_ts_since : string -> int -> Ezjsonm.t Lwt.t

val read_ts_range : string -> int -> int -> Ezjsonm.t Lwt.t

val read_ts_last : string -> int -> Ezjsonm.t Lwt.t

val read_ts_last_since : string -> int -> int -> Ezjsonm.t Lwt.t

val read_ts_last_range : string -> int -> int -> int -> Ezjsonm.t Lwt.t
    


