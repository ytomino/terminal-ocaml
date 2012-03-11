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

type event = string;;

let escape_sequence_of_event ev = ev;;

let is_char ev = (
	String.length ev = 1
);;

let char_of_event ev = (
	assert (is_char ev);
	ev.[0]
);;

let is_string ev = (
	let length = String.length ev in
	length = 1 || (length >= 2 && ev.[0] <> '\x1b')
);;

let string_of_event ev = (
	assert (is_string ev);
	ev
);;

let is_resized ev = (
	match ev with
	| "\x1b[Sz" -> true
	| _ -> false
);;

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

type shift_state = int;;

let is_digit c = c >= '0' && c <= '9';;

let rec take_digits s start = (
	if String.length s <= start || not (is_digit s.[start]) then start else
	take_digits s (start + 1)
);;

let read_digits = (
	let rec loop init s start length = (
		if length <= 0 then init else
		let n = int_of_char s.[start] - int_of_char '0' in
		loop (init * 10 + n) s (start + 1) (length - 1)
	) in
	loop 0
);;

let parse (f: int -> int -> char -> 'a) (bad: 'a) (ev: string): 'a = (
	let length = String.length ev in
	if length < 3 || ev.[0] <> '\x1b' then bad else
	begin match ev.[1] with
	| 'O' ->
		if length <> 3 then bad else
		f 1 1 ev.[2]
	| '[' ->
		let p1s = 2 in
		let p1e = take_digits ev p1s in
		if p1e >= length then bad else
		let k = if p1s = p1e then 1 else read_digits ev p1s (p1e - p1s) in
		if ev.[p1e] <> ';' then (
			if p1e <> length - 1 then bad else
			let c = ev.[p1e] in
			if c = '~' then f k 1 ev.[p1e] else f 1 k ev.[p1e]
		) else (
			let p2s = p1e + 1 in
			let p2e = take_digits ev p2s in
			let s = if p2s = p2e then 1 else read_digits ev p2s (p2e - p2s) in
			if p2e <> length - 1 then (
				if p2e = length - 2 && ev.[p2e] = 'V' && ev.[p2e + 1] = 'k' then (
					f k s '@' (* fictitious, k is virtual key code *)
				) else (
					bad
				)
			) else (
				f k s ev.[p2e]
			)
		)
	| _ ->
		bad
	end
);;

let is_key = parse (fun _ _ _ -> true) false;;

let key_of_event = parse
	(fun k _ c ->
		begin match k with
		| 1 ->
			begin match c with
			| 'A' -> `up
			| 'B' -> `down
			| 'C' -> `right
			| 'D' -> `left
			| 'F' -> `end_key
			| 'H' -> `home
			| 'P' -> `f1
			| 'Q' -> `f2
			| 'R' -> `f3
			| 'S' -> `f4
			| _ -> `unknown
			end
		| 2 when c = '~'->
			`insert
		| 3 when c = '~' ->
			`delete
		| 5 when c = '~' ->
			`pageup
		| 6 when c = '~' ->
			`pagedown
		| 11 when c = '~' ->
			`f1
		| 12 when c = '~' ->
			`f2
		| 13 when c = '~' ->
			`f3
		| 14 when c = '~' ->
			`f4
		| 15 when c = '~' ->
			`f5
		| 17 when c = '~' ->
			`f6
		| 18 when c = '~' ->
			`f7
		| 19 when c = '~' ->
			`f8
		| 20 when c = '~' ->
			`f9
		| 21 when c = '~' ->
			`f10
		| 23 when c = '~' ->
			`f11
		| 24 when c = '~' ->
			`f12
		| _ ->
			`unknown
		end
	)
	`unknown;;

let shift_of_event = parse (fun _ s _ -> s - 1) 0;;

type shift_key = int;;

let empty = 0;;

let shift = 1;;
let control = 4;;
let alt = 8;;

let mem sk ss = sk land ss <> 0;;
external add: shift_key -> shift_state -> shift_state = "%orint";;

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
	external wrap: file_descr -> bool -> unit =
		"mlterminal_d_wrap";;
	
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
	
	external mode:
		file_descr ->
		?echo:bool ->
		?canonical:bool ->
		?ctrl_c:bool ->
		(unit -> 'a) ->
		'a =
		"mlterminal_d_mode";;
	
	external input_line_utf8: file_descr -> string =
		"mlterminal_d_input_line_utf8";;
	
	external is_empty: file_descr -> bool =
		"mlterminal_d_is_empty";;
	external input_event: file_descr -> event =
		"mlterminal_d_input_event";;
	
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

let wrap out enabled = (
	flush out;
	Descr.wrap (Unix.descr_of_out_channel out) enabled
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

let mode ic ?echo ?canonical ?ctrl_c f = (
	Descr.mode (Unix.descr_of_in_channel ic) ?echo ?canonical ?ctrl_c f
);;

let input_line_utf8 = compose Descr.input_line_utf8 Unix.descr_of_in_channel;;
