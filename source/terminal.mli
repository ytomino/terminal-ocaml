type color = {
	red: int;
	green: int;
	blue: int;
	intensity: int};;

val black: color;;
val dark_red: color;;
val dark_green: color;;
val dark_yellow: color;;
val dark_blue: color;;
val dark_magenta: color;;
val dark_cyan: color;;
val dark_white: color;;
val gray: color;;
val blue: color;;
val green: color;;
val cyan: color;;
val red: color;;
val magenta: color;;
val yellow: color;;
val white: color;;

type event = private string;;

val set_title: string -> unit;;
(** Set title to a local encoded string.
    On POSIX, it's no effect. *)
val set_title_utf8: string -> unit;;
(** Set title to a UTF-8 encoded string.
    On POSIX, it's no effect. *)

val is_char: event -> bool;;
(** Check whether given event contains a char or not. *)
val char_of_event: event -> char;;
(** Retrun a char of given event. *)

val is_string: event -> bool;;
(** Check whether given event contains a string(non-escape sequence) or not. *)
val string_of_event: event -> string;;
(** Retrun a string of given event. *)

val is_left: event -> bool;;
val is_up: event -> bool;;
val is_right: event -> bool;;
val is_down: event -> bool;;

val is_home: event -> bool;;
val is_end: event -> bool;;
val is_pageup: event -> bool;;
val is_pagedown: event -> bool;;

val is_delete: event -> bool;;

val is_f: event -> bool;;
(** Check whether given event contains a function key or not. *)
val f_of_event: event -> int;;
(** Retrun the number of a function key of given event. *)

val is_resized: event -> bool;;
(** Check whether given event means terminal window has been resized.
    It install sigwinch handler (on POSIX) or change console mode (on Windows)
    when calling [size], [set_size], [view] or [screen]. *)

val escape_sequence_of_event: event -> string;;
(** Represent given event as escape sequence. *)

module Descr: sig
	open Unix;;
	
	val is_terminal: file_descr -> bool;;
	
	val size: file_descr -> int * int;;
	val set_size: file_descr -> int -> int -> unit;;
	
	val view: file_descr -> int * int * int * int;;
	
	val position: file_descr -> int * int;;
	val set_position: file_descr -> int -> int -> unit;;
	val move: file_descr -> int -> int -> unit;;
	val move_to_bol: file_descr -> unit -> unit;;
	
	val color:
		file_descr ->
		?reset:bool ->
		?bold:bool -> (* only POSIX *)
		?underscore:bool -> (* only POSIX *)
		?blink:bool -> (* only POSIX *)
		?reverse:bool ->
		?concealed:bool ->
		?foreground:color ->
		?background:color ->
		unit ->
		unit;;
	
	val save: file_descr -> (unit -> 'a) -> 'a;;
	
	val clear_screen: file_descr -> unit -> unit;;
	val clear_eol: file_descr -> unit -> unit;;
	val clear_line: file_descr -> unit -> unit;;
	
	val scroll: file_descr -> int -> unit;;
	
	val show_cursor: file_descr -> bool -> unit;;
	
	val screen:
		file_descr ->
		?size:(int * int) ->
		(file_descr -> 'a) ->
		'a;;
	
	val output_utf8: file_descr -> string -> int -> int -> unit;;
	val output_string_utf8: file_descr -> string -> unit;;
	
	val set_input_mode:
		file_descr ->
		?echo:bool ->
		?canonical:bool ->
		unit ->
		unit;;
	
	val input_line_utf8: file_descr -> string;;
	
	val is_empty: file_descr -> bool;;
	(** Check whether given file descripter is empty or has any events. *)
	
	val input_event: file_descr -> event;;
	(** Read one event from given file descripter. *)
	
end;;

val is_terminal: out_channel -> bool;;

val size: out_channel -> int * int;;
val set_size: out_channel -> int -> int -> unit;;

val view: out_channel -> int * int * int * int;;
(** Get range of current view port that is a part of the screen buffer. *)

val position: out_channel -> int * int;;
val set_position: out_channel -> int -> int -> unit;;
val move: out_channel -> int -> int -> unit;;
val move_to_bol: out_channel -> unit -> unit;;

val color:
	out_channel ->
	?reset:bool ->
	?bold:bool ->
	?underscore:bool ->
	?blink:bool ->
	?reverse:bool ->
	?concealed:bool ->
	?foreground:color ->
	?background:color ->
	unit ->
	unit;;

val save: out_channel -> (unit -> 'a) -> 'a;;
(** Save and restore current position and color. *)

val clear_screen: out_channel -> unit -> unit;;
val clear_eol: out_channel -> unit -> unit;;
val clear_line: out_channel -> unit -> unit;;
(** This is a shorthand for move_to_bol and clear_eol. *)

val scroll: out_channel -> int -> unit;;
(** Scroll contents in view port. *)

val show_cursor: out_channel -> bool -> unit;;

val screen:
	out_channel ->
	?size:(int * int) ->
	(out_channel -> 'a) ->
	'a;;
(** Save current screen, use new screen and restore old screen. *)

val output_utf8: out_channel -> string -> int -> int -> unit;;
(** Write a part of a UTF-8 encoded string to the given output channel.
    On POSIX, It's same as [Pervasives.output]. *)
val output_string_utf8: out_channel -> string -> unit;;
(** Write a UTF-8 encoded string to the given output channel.
    On POSIX, It's same as [Pervasives.output_string]. *)

val set_input_mode:
	in_channel ->
	?echo:bool ->
	?canonical:bool ->
	unit ->
	unit;;

val input_line_utf8: in_channel -> string;;
(** Read from the given input channel until a newline.
    And return a UTF-8 encoded string.
    On POSIX, It's same as [Pervasives.input_line]. *)
