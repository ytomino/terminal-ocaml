type color = {
	red: int;
	green: int;
	blue: int;
	intensity: int};;

let black: color        = {red = 0; green = 0; blue = 0; intensity = 0};;
let dark_red: color     = {red = 1; green = 0; blue = 0; intensity = 0};;
let dark_green: color   = {red = 0; green = 1; blue = 0; intensity = 0};;
let dark_yellow: color  = {red = 1; green = 1; blue = 0; intensity = 0};;
let dark_blue: color    = {red = 0; green = 0; blue = 1; intensity = 0};;
let dark_magenta: color = {red = 1; green = 0; blue = 1; intensity = 0};;
let dark_cyan: color    = {red = 0; green = 1; blue = 1; intensity = 0};;
let dark_white: color   = {red = 1; green = 1; blue = 1; intensity = 0};;
let gray: color         = {red = 0; green = 0; blue = 0; intensity = 1};;
let red: color          = {red = 1; green = 0; blue = 0; intensity = 1};;
let green: color        = {red = 0; green = 1; blue = 0; intensity = 1};;
let yellow: color       = {red = 1; green = 1; blue = 0; intensity = 1};;
let blue: color         = {red = 0; green = 0; blue = 1; intensity = 1};;
let magenta: color      = {red = 1; green = 0; blue = 1; intensity = 1};;
let cyan: color         = {red = 0; green = 1; blue = 1; intensity = 1};;
let white: color        = {red = 1; green = 1; blue = 1; intensity = 1};;

external set_title: string -> unit =
	"mlterminal_set_title";;
external set_title_utf8: string -> unit =
	"mlterminal_set_title_utf8";;

module Descr = struct
	open Unix;;

	external is_terminal: file_descr -> bool =
		"mlterminal_d_is_terminal";;
	
	external size: file_descr -> int * int =
		"mlterminal_d_size";;
	external set_size: file_descr -> int -> int -> unit =
		"mlterminal_d_set_size";;
	
	external view: file_descr -> int * int * int * int =
		"mlterminal_d_view"
	
	external position: file_descr -> int * int =
		"mlterminal_d_position";;
	external set_position: file_descr -> int -> int -> unit =
		"mlterminal_d_set_position";;
	external move: file_descr -> int -> int -> unit =
		"mlterminal_d_move";;
	external move_to_bol: file_descr -> unit -> unit =
		"mlterminal_d_move_to_bol";;
	
	external color:
		file_descr ->
		?reset:bool ->
		?bold:bool ->
		?underscore:bool ->
		?blink:bool ->
		?reverse:bool ->
		?concealed:bool ->
		?foreground:color ->
		?background:color ->
		unit ->
		unit =
		"mlterminal_d_color_byte" "mlterminal_d_color";;
	
	external save: file_descr -> (unit -> 'a) -> 'a =
		"mlterminal_d_save";;
	
	external clear_screen: file_descr -> unit -> unit =
		"mlterminal_d_clear_screen";;
	external clear_eol: file_descr -> unit -> unit =
		"mlterminal_d_clear_eol";;
	let clear_line f () =
		move_to_bol f ();
		clear_eol f ();;
	
	external scroll: file_descr -> int -> unit =
		"mlterminal_d_scroll";;
	
	external show_cursor: file_descr -> bool -> unit =
		"mlterminal_d_show_cursor";;
	
	external screen:
		file_descr ->
		?size:(int * int) ->
		(file_descr -> 'a) ->
		'a =
		"mlterminal_d_screen";;
	
	external output_utf8: file_descr -> string -> int -> int -> unit =
		"mlterminal_d_output_utf8";;
	let output_string_utf8 f s =
		output_utf8 f s 0 (String.length s);;
	
	external set_input_mode:
		file_descr ->
		?echo:bool ->
		?canonical:bool ->
		unit ->
		unit =
		"mlterminal_d_set_input_mode";;
	
	external input_line_utf8: file_descr -> string =
		"mlterminal_d_input_line_utf8";;
	
end;;

let compose f g = fun x -> f (g x);;

let is_terminal = compose Descr.is_terminal Unix.descr_of_out_channel;;

let size = compose Descr.size Unix.descr_of_out_channel;;
let set_size = compose Descr.set_size Unix.descr_of_out_channel;;

let view = compose Descr.view Unix.descr_of_out_channel;;

let position out = (
	flush out;
	Descr.position (Unix.descr_of_out_channel out)
);;

let set_position out x y = (
	flush out;
	Descr.set_position (Unix.descr_of_out_channel out) x y
);;

let move out x y = (
	flush out;
	Descr.move (Unix.descr_of_out_channel out) x y
);;

let move_to_bol out () = (
	flush out;
	Descr.move_to_bol (Unix.descr_of_out_channel out) ()
);;

let color
	out
	?reset
	?bold
	?underscore
	?blink
	?reverse
	?concealed
	?foreground
	?background
	()
	: unit =
(
	flush out;
	Descr.color
		(Unix.descr_of_out_channel out)
		?reset
		?bold
		?underscore
		?blink
		?reverse
		?concealed
		?foreground
		?background
		()
);;

let save out f = (
	flush out;
	Descr.save
		(Unix.descr_of_out_channel out)
		(fun () ->
			let result = f () in
			flush out;
			result)
);;

let clear_screen out () = (
	flush out;
	Descr.clear_screen (Unix.descr_of_out_channel out) ()
);;

let clear_eol out () = (
	flush out;
	Descr.clear_eol (Unix.descr_of_out_channel out) ()
);;

let clear_line out () = (
	flush out;
	Descr.clear_line (Unix.descr_of_out_channel out) ()
);;

let scroll out y = (
	flush out;
	Descr.scroll (Unix.descr_of_out_channel out) y
);;

let show_cursor out visible = (
	flush out;
	Descr.show_cursor (Unix.descr_of_out_channel out) visible
);;

let screen out ?size f = (
	flush out;
	Descr.screen
		(Unix.descr_of_out_channel out)
		?size
		(fun new_fd ->
			let new_out = Unix.out_channel_of_descr new_fd in
			set_binary_mode_out new_out false;
			let result = f new_out in
			flush new_out;
			result)
);;

let output_utf8 out s pos len = (
	flush out;
	Descr.output_utf8 (Unix.descr_of_out_channel out) s pos len
);;

let output_string_utf8 out s = (
	output_utf8 out s 0 (String.length s)
);;

let set_input_mode = compose Descr.set_input_mode Unix.descr_of_in_channel;;

let input_line_utf8 = compose Descr.input_line_utf8 Unix.descr_of_in_channel;;
