(* TODO Signals may need some interfacing with OCaml signal handling. *)

open Imports

type signal
type t = signal Handle.t

val init : ?loop:Loop.t ptr -> unit -> (t, Error.Code.t) result
val start : callback:(t -> int -> unit) -> t -> signum:int -> Error.Code.t
val start_oneshot :
  callback:(t -> int -> unit) -> t -> signum:int -> Error.Code.t
val stop : t -> Error.Code.t
val get_signum : t -> int