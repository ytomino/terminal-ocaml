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
	external move_to_backward: file_descr -> unit -> unit =
		"mlterminal_d_move_to_backward";;
	
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
	
	external save: file_descr -> (unit -> unit) -> unit =
		"mlterminal_d_save";;
	
	external clear_screen: file_descr -> unit -> unit =
		"mlterminal_d_clear_screen";;
	external clear_forward: file_descr -> unit -> unit =
		"mlterminal_d_clear_forward";;
	
	external scroll: file_descr -> int -> unit =
		"mlterminal_d_scroll";;
	
	external show_cursor: file_descr -> bool -> unit =
		"mlterminal_d_show_cursor";;
	external set_title: file_descr -> string -> unit =
		"mlterminal_d_set_title";;
	
	external set_input_mode:
		file_descr ->
		?echo:bool ->
		?canonical:bool ->
		unit ->
		unit =
		"mlterminal_d_set_input_mode";;
	
end;;

let compose f g = fun x -> f (g x);;

let is_terminal = compose Descr.is_terminal Unix.descr_of_out_channel;;

let size = compose Descr.size Unix.descr_of_out_channel;;
let set_size = compose Descr.set_size Unix.descr_of_out_channel;;

let view = compose Descr.view Unix.descr_of_out_channel;;

let position out = (
	flush stdout;
	Descr.position (Unix.descr_of_out_channel out)
);;

let set_position out x y = (
	flush stdout;
	Descr.set_position (Unix.descr_of_out_channel out) x y
);;

let move out x y = (
	flush stdout;
	Descr.move (Unix.descr_of_out_channel out) x y
);;

let move_to_backward out () = (
	flush stdout;
	Descr.move_to_backward (Unix.descr_of_out_channel out) ()
);;

let color
	out_channel
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
	flush stdout;
	Descr.color
		(Unix.descr_of_out_channel out_channel)
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
	flush stdout;
	Descr.save (Unix.descr_of_out_channel out) (fun () -> f (); flush stdout)
);;

let clear_screen out () = (
	flush stdout;
	Descr.clear_screen (Unix.descr_of_out_channel out) ()
);;

let clear_forward out () = (
	flush stdout;
	Descr.clear_forward (Unix.descr_of_out_channel out) ()
);;

let scroll out y = (
	flush stdout;
	Descr.scroll (Unix.descr_of_out_channel out) y
);;

let show_cursor out visible = (
	flush stdout;
	Descr.show_cursor (Unix.descr_of_out_channel out) visible
);;

let set_title = compose Descr.set_title Unix.descr_of_out_channel;;

let set_input_mode = compose Descr.set_input_mode Unix.descr_of_in_channel;;
