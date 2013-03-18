(** Terminal library for Objective-Caml *)

(** {6 Title} *)

val title: string -> (unit -> 'a) -> 'a;;
(** [title t f] saves old window title,
    sets it to given local encoded string [t], and restores it. *)
val title_utf8: string -> (unit -> 'a) -> 'a;;
(** [title_utf8 t f] saves old window title,
    sets it to given UTF-8 encoded string [t], and restores it.
    In POSIX, it's same as [set_title]. *)

(** {6 Color type and values} *)

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

(** {6 Event} *)

type event = private string;;
(** Event. One of inputed char or string, the terminal window is resized,
    any special key is typed, any mouse button is clicked or others. *)

val escape_sequence_of_event: event -> string;;
(** Represent given event as escape sequence. *)

val is_char: event -> bool;;
(** Check whether given event contains a char or not. *)
val char_of_event: event -> char;;
(** Retrun a char of given event. *)

val is_string: event -> bool;;
(** Check whether given event contains a string(non-escape sequence) or not. *)
val string_of_event: event -> string;;
(** Retrun a string of given event. *)

val is_resized: event -> bool;;
(** Check whether given event means terminal window has been resized.
    It install sigwinch handler (in POSIX) or change console mode (in Windows)
    when calling [size], [set_size], [view] or [screen]. *)

val size_of_event: event -> int * int;;
(** Return new window size of given event. *)

type key = [
	| `up
	| `down
	| `right
	| `left
	| `home
	| `end_key
	| `insert
	| `delete
	| `pageup
	| `pagedown
	| `f1
	| `f2
	| `f3
	| `f4
	| `f5
	| `f6
	| `f7
	| `f8
	| `f9
	| `f10
	| `f11
	| `f12];;
(** Key. *)

type shift_state = private int;;
(** Set of [shift_key]. *)

val is_key: event -> bool;;
(** Check whether given event contains a key or not. *)
val key_of_event: event -> [key | `unknown];;
(** Retrun a key of given event. *)
val shift_of_event: event -> shift_state;;
(** Retrun shift state of given event.
    [shift_of_event] works for key event and also mouse clicked event.
    But modifier+Click is normally unavailable because popup menu. *)

type shift_key = private int;;
(** One of shift key, control key or alt(meta) key. *)

val empty: shift_state;;
(** The empty set. *)

val shift: shift_key;;
val control: shift_key;;
val alt: shift_key;;

val mem: shift_key -> shift_state -> bool;;
(** [mem a s] is true if [a] is included in [s]. *)
external add: shift_key -> shift_state -> shift_state = "%orint";;
(** [add a s] returns a set containing all elements of [s] and [a]. *)

type button = [
	| `button1
	| `button2
	| `button3
	| `wheelup
	| `wheeldown
	| `released];;
(** Mouse button. *)

val is_clicked: event -> bool;;
(** Check whether given event means a mouse button is clicked. *)
val button_of_event: event -> [button | `unknown];;
(** Return a clicked mouse button of given event. *)
val position_of_event: event -> int * int;;
(** Retrun mouse position of given event. *)

(** {6 Operations for Unix.file_descr} *)

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
	val wrap: file_descr -> bool -> unit;;
	
	val screen:
		file_descr ->
		?size:(int * int) ->
		?cursor:bool ->
		?wrap:bool ->
		(file_descr -> 'a) ->
		'a;;
	
	val output: file_descr -> string -> int -> int -> unit;;
	(** Same as [Unix.write], but return type is unit. *)
	val output_string: file_descr -> string -> unit;;
	(** Same as [output fd s 0 (String.length s)]. *)
	
	val output_utf8: file_descr -> string -> int -> int -> unit;;
	val output_string_utf8: file_descr -> string -> unit;;
	
	val output_newline: file_descr -> unit -> unit;;
	(** Write '\n' in POSIX, or write '\r\n' in Windows. *)
	
	val mode:
		file_descr ->
		?echo:bool ->
		?canonical:bool ->
		?control_c:bool ->
		?mouse:bool ->
		(unit -> 'a) ->
		'a;;
	
	val input: file_descr -> string -> int -> int -> int;;
	(** Same as [Unix.read]. *)
	
	val input_line_utf8: file_descr -> string;;
	
	val is_empty: file_descr -> bool;;
	(** Check whether given file descripter is empty or has any events. *)
	
	val input_event: file_descr -> event;;
	(** Read one event from given file descripter. *)
	
end;;
(** Operations for Unix.file_descr.
    [Descr.anyf fd] is equal to [anyf (Unix.out_channel_of_descr fd)]
    or [anyf (Unix.in_channel_of_descr fd)].
    This module has additional output function [output_newline],
    and additional input functions [is_empty] and [input_event]
    for event handling. *)

(** {6 Operations for output channel} *)

val is_terminal_out: out_channel -> bool;;
(** [is_terminal_out oc] returns true if given output channel is associated
    to terminal. *)

val size: out_channel -> int * int;;
(** [size oc] gets size of current screen buffer. *)
val set_size: out_channel -> int -> int -> unit;;
(** [set_size oc width height] sets size of current screen buffer. *)

val view: out_channel -> int * int * int * int;;
(** [view oc] gets range of current view port that is a part of
    current screen buffer. *)

val position: out_channel -> int * int;;
(** [position oc] gets the cursor position in absolute coordinates. *)
val set_position: out_channel -> int -> int -> unit;;
(** [set_position oc x y] moves the cursor in absolute coordinates. *)
val move: out_channel -> int -> int -> unit;;
(** [move oc x y] moves the cursor in relative coordinates
    from current position. *)
val move_to_bol: out_channel -> unit -> unit;;
(** [move_to_bol oc ()] moves the cursor to the begin of line. *)

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
(** [color oc ~reset ~bold ~underscore ~blink ~reverse ~concealed ~foreground
    ~background ()] sets a color to write new text. *)

val save: out_channel -> (unit -> 'a) -> 'a;;
(** [save oc f] saves and restores current position and color. *)

val clear_screen: out_channel -> unit -> unit;;
(** [clear_screen oc ()] clears all of given screen buffer. *)
val clear_eol: out_channel -> unit -> unit;;
(** [clear_eol oc ()] clears from the cursor position to the end of line. *)
val clear_line: out_channel -> unit -> unit;;
(** [clear_line oc ()] is a shorthand of [move_to_bol oc ()]
    and then [clear_eol oc ()]. *)

val scroll: out_channel -> int -> unit;;
(** [scroll oc y] scrolls contents in view port. *)

val show_cursor: out_channel -> bool -> unit;;
(** [show_cursor oc flag] show or hide the cursor. *)
val wrap: out_channel -> bool -> unit;;
(** [wrap oc flag] enables or disables line wrapping. *)

val screen:
	out_channel ->
	?size:(int * int) ->
	?cursor:bool ->
	?wrap:bool ->
	(out_channel -> 'a) ->
	'a;;
(** [screen oc ~size ~cursor ~wrap f] saves current screen buffer,
    uses new screen buffer and restore old it.
    If [~size] is given, same as [set_size oc size].
    If [~cursor] is given, same as [show_cursor oc cursor].
    If [~wrap:w] is given, same as [wrap oc w]. *)

val output_utf8: out_channel -> string -> int -> int -> unit;;
(** Write a part of a UTF-8 encoded string to the given output channel.
    In POSIX, It's same as [Pervasives.output]. *)
val output_string_utf8: out_channel -> string -> unit;;
(** Write a UTF-8 encoded string to the given output channel.
    In POSIX, It's same as [Pervasives.output_string]. *)

(** {6 Operations for input channel} *)

val is_terminal_in: in_channel -> bool;;
(** [is_terminal_in ic] returns true if given input channel is associated
    to terminal. *)

val buffered_in: in_channel -> int;;
(** Return size of buffered contents of given input channel
    that has not been read yet. *)

val buffered_line_in: in_channel -> int;;
(** Return size of buffered contents of given input channel
    that has not been read yet,
    from current position until ['\n'].
    If returned value is [max_int], no ['\n'] is in buffer.
    It means current line is continuing.
    Otherwide, all of current line is buffered. *)

val mode:
	in_channel ->
	?echo:bool ->
	?canonical:bool ->
	?control_c:bool ->
	?mouse:bool ->
	(unit -> 'a) ->
	'a;;
(** [mode ic ~echo ~canonical ~control_c ~mouse f] saves, changes and restores
    mode of given input channel.
    If [~echo] is false, disable echoing.
    If [~canonical] is false, disable line editing.
    If [~control_c] is false, ignore Ctrl+C.
    (Use [Sys.catch_break] to handle Ctrl+C as exception.)
    If [~mouse] is true, get mouse events. *)

val input_line_utf8: in_channel -> string;;
(** Read from the given input channel until a newline.
    And return a UTF-8 encoded string.
    In POSIX, It's same as [Pervasives.input_line]. *)

(** {6 Miscellany} *)

val utf8_of_locale: string -> string;;
(** In windows, encode string from active code page to UTF-8.
    In POSIX, It's no effect. *)
val locale_of_utf8: string -> string;;
(** In windows, encode string from UTF-8 to active code page.
    In POSIX, It's no effect. *)

val sleep: float -> unit;;
(** [float] version of [Unix.sleep]. *)
