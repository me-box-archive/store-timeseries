val read_ts_latest : string -> Ezjsonm.t Lwt.t

val read_kv : string -> Ezjsonm.t Lwt.t

val read_ts_since : string -> int -> Ezjsonm.t Lwt.t

val read_ts_range : string -> int -> int -> Ezjsonm.t Lwt.t

val remove_ts_latest : string -> Ezjsonm.t Lwt.t

val write_kv : string -> Ezjsonm.t -> Ezjsonm.t Lwt.t

val write_ts : string -> Ezjsonm.t -> Ezjsonm.t Lwt.t 
    


