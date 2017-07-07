module Store_kv :
sig
  type branch = Ezirmin.FS_lww_register(Irmin.Contents.Json).branch
end

module Store_ts :
sig
  type branch = Ezirmin.FS_log(Tc.Pair(Tc.Int)(Irmin.Contents.Json)).branch      
end

val create_kv_store : file:string -> Store_kv.branch Lwt.t

val create_ts_store : file:string -> Store_ts.branch Lwt.t

val read_kv : Store_kv.branch Lwt.t -> string -> Ezjsonm.t Lwt.t

val write_kv : Store_kv.branch Lwt.t -> string -> Ezjsonm.t -> Ezjsonm.t Lwt.t

val write_ts : Store_ts.branch Lwt.t -> string -> Ezjsonm.t -> Ezjsonm.t Lwt.t 

val read_ts_latest : Store_ts.branch Lwt.t -> string -> Ezjsonm.t Lwt.t

val read_ts_since : Store_ts.branch Lwt.t -> string -> int -> Ezjsonm.t Lwt.t

val read_ts_range : Store_ts.branch Lwt.t -> string -> int -> int -> Ezjsonm.t Lwt.t

val read_ts_last : Store_ts.branch Lwt.t -> string -> int -> Ezjsonm.t Lwt.t

val read_ts_last_since : Store_ts.branch Lwt.t -> string -> int -> int -> Ezjsonm.t Lwt.t

val read_ts_last_range : Store_ts.branch Lwt.t -> string -> int -> int -> int -> Ezjsonm.t Lwt.t
    


