(** Terminal library for Objective-Caml *)

(** {6 Title} *)

val title: string -> (unit -> 'a) -> 'a
(** [title t f] saves the old window title, sets it to a given string [t],
    and restores it.
    In Windows, the parameter should be encoded as the active code page. *)

val title_utf8: string -> (unit -> 'a) -> 'a
(** [title_utf8 t f] saves the old window title, sets it to a given UTF-8
    encoded string [t], and restores it.
    In POSIX, it's same as [set_title]. *)

(** {6 Color type and values} *)

type color = private int
(** Color. The representation is not portable. *)

val system_16: red:int -> green:int -> blue:int -> intensity:int -> color
(** The 16 system colors.
    It's discriminated whether each value of [red], [green], [blue], or
    [intensity] is 0 or not. *)

val black: color
val dark_red: color
val dark_green: color
val dark_yellow: color
val dark_blue: color
val dark_magenta: color
val dark_cyan: color
val gray: color
val dark_gray: color
val blue: color
val green: color
val cyan: color
val red: color
val magenta: color
val yellow: color
val white: color

val supports_256: unit -> bool
(** Check whether the terminal supports 256 color. *)

val rgb: red:float -> green:float -> blue:float -> color
(** The RGB colors. The each parameter should be in 0.0 to 1.0. *)

val grayscale: float -> color
(** The grayscale colors. The parameter should be in 0.0 to 1.0. *)

(** {6 Event} *)

type event = private string
(** Event.
    One of an inputed char or string, the terminal window is resized,
    any special key is typed, any mouse button is clicked, or others. *)

val escape_sequence_of_event: event -> string
(** Represent a given event as escape sequence. *)

val is_char: event -> bool
(** Check whether a given event contains some char or not. *)

val char_of_event: event -> char
(** Return the char of a given event. *)

val is_string: event -> bool
(** Check whether a given event contains some string(non-escape sequence) or
    not. *)

val string_of_event: event -> string
(** Return the string of a given event. *)

val is_resized: event -> bool
(** Check whether a given event means the terminal window has been resized.
    It installs the sigwinch handler (in POSIX) or change the console mode (in
    Windows) when calling [size], [set_size], [view], or [screen]. *)

val size_of_event: event -> int * int
(** Return the new window size of a given event. *)

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
	| `f12]
(** Key. *)

type shift_state = private int
(** Set of [shift_key]. *)

val is_key: event -> bool
(** Check whether a given event contains some key or not. *)

val key_of_event: event -> [key | `unknown]
(** Return the key of a given event. *)

val shift_of_event: event -> shift_state
(** Return the shift state of a given event.
    [shift_of_event] works for key events and also mouse button events. *)

type shift_key = private int
(** One of shift key, control key, or alt(meta) key. *)

val empty: shift_state
(** The empty set. *)

val shift: shift_key
val meta: shift_key
val control: shift_key
val alt: shift_key

val mem: shift_key -> shift_state -> bool
(** [mem a s] is true if [a] is included in [s]. *)

external add: shift_key -> shift_state -> shift_state = "%orint"
(** [add a s] returns a set containing all elements of [s] plus [a]. *)

type button = [
	| `button1
	| `button2
	| `button3
	| `wheelup
	| `wheeldown
	| `released]
(** Mouse button. *)

val is_clicked: event -> bool
(** Check whether a given event means some mouse button is clicked. *)

val button_of_event: event -> [button | `unknown]
(** Return the clicked mouse button of a given event. *)

val position_of_event: event -> int * int
(** Return the pointed position of a given event. *)

(** {6 Operations for Unix.file_descr} *)

module Descr: sig
	open Unix
	
	val is_terminal: file_descr -> bool
	
	val size: file_descr -> int * int
	val set_size: file_descr -> int -> int -> unit
	
	val view: file_descr -> int * int * int * int
	
	val position: file_descr -> int * int
	val set_position: file_descr -> int -> int -> unit
	val move: file_descr -> int -> int -> unit
	val move_to_bol: file_descr -> unit -> unit
	
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
		unit
	
	val save: file_descr -> (unit -> 'a) -> 'a
	
	val clear_screen: file_descr -> unit -> unit
	val clear_eol: file_descr -> unit -> unit
	val clear_line: file_descr -> unit -> unit
	
	val scroll: file_descr -> int -> unit
	
	val show_cursor: file_descr -> bool -> unit
	val wrap: file_descr -> bool -> unit
	
	val screen: file_descr -> ?size:(int * int) -> ?cursor:bool -> ?wrap:bool ->
		(file_descr -> 'a) -> 'a
	
	val output: file_descr -> bytes -> int -> int -> unit
	(** Same as [Unix.write], but the returned type is unit. *)
	
	val output_substring: file_descr -> string -> int -> int -> unit
	(** Same as output but take a string instead of a bytes. *)
	
	val output_string: file_descr -> string -> unit
	(** Same as [output_substring fd s 0 (String.length s)]. *)
	
	val output_substring_utf8: file_descr -> string -> int -> int -> unit
	val output_string_utf8: file_descr -> string -> unit
	
	val output_newline: file_descr -> unit -> unit
	(** Write "\n" (in POSIX) or "\r\n" (in Windows). *)
	
	val mode: file_descr -> ?echo:bool -> ?canonical:bool -> ?control_c:bool ->
		?mouse:bool -> (unit -> 'a) -> 'a
	
	val input: file_descr -> bytes -> int -> int -> int
	(** Same as [Unix.read]. *)
	
	val input_line_utf8: file_descr -> string
	
	val is_empty: file_descr -> bool
	(** Check whether a given file descriptor is empty or having any events. *)
	
	val input_event: file_descr -> event
	(** Read one event from a given file descriptor. *)
end
(** Operations for Unix.file_descr.
    [Descr.any_func fd] is equal to [any_func (Unix.out_channel_of_descr fd)]
    or [any_func (Unix.in_channel_of_descr fd)].
    This module has the additional output function [output_newline], and the
    additional input functions [is_empty] and [input_event] for event handling.
    *)

(** {6 Operations for output channel} *)

val is_terminal_out: out_channel -> bool
(** [is_terminal_out oc] returns true if a given output channel is associated
    to the terminal. *)

val size: out_channel -> int * int
(** [size oc] gets the size of the current screen buffer. *)

val set_size: out_channel -> int -> int -> unit
(** [set_size oc width height] sets the size of the current screen buffer. *)

val view: out_channel -> int * int * int * int
(** [view oc] gets the range of the current view port that is a part of the
    current screen buffer. *)

val position: out_channel -> int * int
(** [position oc] gets the cursor position in absolute coordinates. *)

val set_position: out_channel -> int -> int -> unit
(** [set_position oc x y] moves the cursor in absolute coordinates. *)

val move: out_channel -> int -> int -> unit
(** [move oc x y] moves the cursor in relative coordinates from the current
    position. *)

val move_to_bol: out_channel -> unit -> unit
(** [move_to_bol oc ()] moves the cursor to the beginning of the line. *)

val color: out_channel -> ?reset:bool -> ?bold:bool -> ?underscore:bool ->
	?blink:bool -> ?reverse:bool -> ?concealed:bool -> ?foreground:color ->
	?background:color -> unit -> unit
(** [color oc ~reset ~bold ~underscore ~blink ~reverse ~concealed ~foreground
    ~background ()] sets the color for writing. *)

val save: out_channel -> (unit -> 'a) -> 'a
(** [save oc f] saves and restores the current position and the color. *)

val clear_screen: out_channel -> unit -> unit
(** [clear_screen oc ()] clears all of a given screen buffer. *)

val clear_eol: out_channel -> unit -> unit
(** [clear_eol oc ()] clears from the cursor position to the end of the line.
    *)

val clear_line: out_channel -> unit -> unit
(** [clear_line oc ()] is a combination of [move_to_bol oc ()] and
    [clear_eol oc ()]. *)

val scroll: out_channel -> int -> unit
(** [scroll oc y] scrolls the contents in the current view port. *)

val show_cursor: out_channel -> bool -> unit
(** [show_cursor oc flag] show or hide the cursor. *)

val wrap: out_channel -> bool -> unit
(** [wrap oc flag] enables or disables line wrapping. *)

val screen: out_channel -> ?size:(int * int) -> ?cursor:bool -> ?wrap:bool ->
	(out_channel -> 'a) -> 'a
(** [screen oc ~size ~cursor ~wrap f] saves the current screen buffer,
    uses new screen buffer, and restores it.
    If [~size] is given, same as [set_size oc size].
    If [~cursor] is given, same as [show_cursor oc cursor].
    If [~wrap:w] is given, same as [wrap oc w]. *)

val output_substring_utf8: out_channel -> string -> int -> int -> unit
(** Write a part of a UTF-8 encoded string to a given output channel.
    In POSIX, It's same as [Pervasives.output]. *)

val output_string_utf8: out_channel -> string -> unit
(** Write a UTF-8 encoded string to a given output channel.
    In POSIX, It's same as [Pervasives.output_string]. *)

(** {6 Operations for input channel} *)

val is_terminal_in: in_channel -> bool
(** [is_terminal_in ic] returns true if a given input channel is associated to
    the terminal. *)

val buffered_in: in_channel -> int
(** Return the size of the buffered contents of a given input channel that has
    not been read yet. *)

val buffered_line_in: in_channel -> int
(** Return the size of the buffered contents of a given input channel that has
    not been read yet, from current position until ['\n'].
    If a returned value is [max_int], no ['\n'] is in the buffer.
    It means the current line is continuing.
    Otherwise, all of the current line is buffered. *)

val mode: in_channel -> ?echo:bool -> ?canonical:bool -> ?control_c:bool ->
	?mouse:bool -> (unit -> 'a) -> 'a
(** [mode ic ~echo ~canonical ~control_c ~mouse f] saves, changes, and restores
    the mode of a given input channel.
    If [~echo] is given, enables or disables echoing.
    If [~canonical] is given, enables or disables line editing.
    If [~control_c] is given, accepts or ignores Ctrl+C.
    (Use [Sys.catch_break] to handle Ctrl+C as the exception.)
    If [~mouse] is given, enables or disables mouse button events. *)

val input_line_utf8: in_channel -> string
(** Read from a given input channel until a newline.
    And return a UTF-8 encoded string.
    In POSIX, It's same as [Pervasives.input_line]. *)

(** {6 Miscellany} *)

val utf8_of_locale: string -> string
(** In windows, encode a string from the active code page to UTF-8.
    In POSIX, It's no effect. *)

val locale_of_utf8: string -> string
(** In windows, encode a string from UTF-8 to the active code page.
    In POSIX, It's no effect. *)
