(* reference:
     xterm
       http://invisible-island.net/xterm/ctlseqs/ctlseqs.html
     Terminal.app
       https://developer.apple.com/library/mac/#documentation/OpenSource/
         Conceptual/ShellScripting/AdvancedTechniques/
         AdvancedTechniques.html%23//apple_ref/doc/uid/
         TP40004268-TP40003521-SW9
     Win32 API
       http://msdn.microsoft.com/en-us/library/windows/desktop/
         ms682087(v=vs.85).aspx *)

external title: string -> (unit -> 'a) -> 'a = "mlterminal_title";;
external title_utf8: string -> (unit -> 'a) -> 'a = "mlterminal_title_utf8";;

type color = int;;

external system_16: red:int -> green:int -> blue:int -> intensity:int ->
	color =
	"mlterminal_system_16";;

let black: color        = system_16 ~red:0 ~green:0 ~blue:0 ~intensity:0;;
let dark_red: color     = system_16 ~red:1 ~green:0 ~blue:0 ~intensity:0;;
let dark_green: color   = system_16 ~red:0 ~green:1 ~blue:0 ~intensity:0;;
let dark_yellow: color  = system_16 ~red:1 ~green:1 ~blue:0 ~intensity:0;;
let dark_blue: color    = system_16 ~red:0 ~green:0 ~blue:1 ~intensity:0;;
let dark_magenta: color = system_16 ~red:1 ~green:0 ~blue:1 ~intensity:0;;
let dark_cyan: color    = system_16 ~red:0 ~green:1 ~blue:1 ~intensity:0;;
let gray: color         = system_16 ~red:1 ~green:1 ~blue:1 ~intensity:0;;
let dark_gray: color    = system_16 ~red:0 ~green:0 ~blue:0 ~intensity:1;;
let red: color          = system_16 ~red:1 ~green:0 ~blue:0 ~intensity:1;;
let green: color        = system_16 ~red:0 ~green:1 ~blue:0 ~intensity:1;;
let yellow: color       = system_16 ~red:1 ~green:1 ~blue:0 ~intensity:1;;
let blue: color         = system_16 ~red:0 ~green:0 ~blue:1 ~intensity:1;;
let magenta: color      = system_16 ~red:1 ~green:0 ~blue:1 ~intensity:1;;
let cyan: color         = system_16 ~red:0 ~green:1 ~blue:1 ~intensity:1;;
let white: color        = system_16 ~red:1 ~green:1 ~blue:1 ~intensity:1;;

external supports_256: unit -> bool = "mlterminal_supports_256";;
external rgb: red:float -> green:float -> blue:float -> color =
	"mlterminal_rgb";;
external grayscale: float -> color = "mlterminal_grayscale";;

type event = string;;

let escape_sequence_of_event ev = ev;;

let is_char ev = String.length ev = 1;;

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

let is_digit c = c >= '0' && c <= '9';;

let rec take_digits s start = (
	if String.length s <= start || not (is_digit s.[start]) then start else
	take_digits s (start + 1)
);;

let read_digits: string -> int -> int -> int =
	let rec loop init s start length = (
		if length <= 0 then init else
		let n = int_of_char s.[start] - int_of_char '0' in
		loop (init * 10 + n) s (start + 1) (length - 1)
	) in
	loop 0;;

let parse_3 (f: int -> int -> int -> char -> 'a) (bad: 'a) (ev: string) = (
	let result = ref bad in (* optimized away *)
	let length = String.length ev in
	if length >= 5 && ev.[0] = '\x1b' && ev.[1] = '[' then (
		let p1s = 2 in
		let p1e = take_digits ev p1s in
		if p1e < length then (
			let p1v = if p1s = p1e then 1 else read_digits ev p1s (p1e - p1s) in
			if ev.[p1e] = ';' then (
				let p2s = p1e + 1 in
				let p2e = take_digits ev p2s in
				if p2e < length then (
					let p2v = if p2s = p2e then 1 else read_digits ev p2s (p2e - p2s) in
					if ev.[p2e] = ';' then (
						let p3s = p2e + 1 in
						let p3e = take_digits ev p3s in
						if p3e = length - 1 then (
							let p3v = if p3s = p3e then 1 else read_digits ev p3s (p3e - p3s) in
							result := f p1v p2v p3v ev.[p3e]
						)
					)
				)
			)
		)
	);
	!result
);;

let is_resized ev = (
	let length = String.length ev in
	length >= 6
		&& ev.[0] = '\x1b'
		&& ev.[1] = '['
		&& ev.[2] = '8'
		&& ev.[3] = ';'
		&& ev.[length - 1] = 't'
);;

let size_of_event ev = (
	assert (is_resized ev);
	parse_3 (fun k h w t -> assert (k = 8 && t = 't'); (w, h)) (1, 1) ev
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

let parse_key (f: int -> int -> char -> 'a) (bad: 'a) (ev: string) = (
	let result = ref bad in (* optimized away *)
	let length = String.length ev in
	if length >= 3 && ev.[0] = '\x1b' then (
		begin match ev.[1] with
		| 'O' ->
			if length = 3 then (
				result := f 1 1 ev.[2] (* \eOP *)
			)
		| '[' ->
			let p1s = 2 in
			let p1e = take_digits ev p1s in
			if p1e < length then (
				let k = if p1s = p1e then 1 else read_digits ev p1s (p1e - p1s) in
				if p1e = length - 1 then (
					let c = ev.[p1e] in
					if c = '~' then (
						result := f k 1 ev.[p1e] (* \e[3~ *)
					) else
					result := f 1 k ev.[p1e] (* \e[A *)
				) else if ev.[p1e] =';' then (
					let p2s = p1e + 1 in
					let p2e = take_digits ev p2s in
					let s = if p2s = p2e then 1 else read_digits ev p2s (p2e - p2s) in
					if p2e = length - 1 then (
						result := f k s ev.[p2e] (* \e[3;2~ \e1;2A *)
					) else if p2e = length - 2 && ev.[p2e] = 'V' && ev.[p2e + 1] = 'k' then (
						result := f k s '@' (* fictitious, k is virtual key code *)
					)
				)
			)
		| _ ->
			()
		end
	);
	!result
);;

let is_key = parse_key (fun _ _ _ -> true) false;;

let key_of_event =
	parse_key (fun k _ c ->
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
	) `unknown;;

type shift_key = int;;

let empty = 0;;

let shift = 1;;
let meta = 2;;
let control = 4;;
let alt = 8;;

let mem sk ss = sk land ss <> 0;;

external add: shift_key -> shift_state -> shift_state = "%orint";;

let is_clicked ev = (
	String.length ev = 6 && ev.[0] = '\x1b' && ev.[1] = '[' && ev.[2] = 'M'
);;

let position_of_event ev = (
	assert (is_clicked ev);
	let x = int_of_char ev.[4] - 0x21 in
	let y = int_of_char ev.[5] - 0x21 in
	x, y
);;

type button = [
	| `button1
	| `button2
	| `button3
	| `wheelup
	| `wheeldown
	| `released];;

let button_of_event ev = (
	assert (is_clicked ev);
	let m = int_of_char ev.[3] in
	begin match m land 0b01000011 with
	| 0b00000000 -> `button1
	| 0b00000001 -> `button2
	| 0b00000010 -> `button3
	| 0b00000011 -> `released
	| 0b01000000 -> `wheelup
	| 0b01000001 -> `wheeldown
	| _ -> `unknown
	end
);;

let shift_of_event ev = (
	if not (is_clicked ev) then (
		(* keyboard event *)
		parse_key (fun _ s _ -> s - 1) 0 ev
	) else (
		(* mouse event *)
		let m = int_of_char ev.[3] in
		let result = empty in
		let result = if m land 4 = 0 then result else add shift result in
		let result = if m land 8 = 0 then result else add meta result in
		let result = if m land 16 = 0 then result else add control result in
		result
	)
);;

module Descr = struct
	open Unix;;

	let is_terminal = Unix.isatty;;
	
	external size: file_descr -> int * int = "mlterminal_d_size";;
	external set_size: file_descr -> int -> int -> unit = "mlterminal_d_set_size";;
	external view: file_descr -> int * int * int * int = "mlterminal_d_view"
	external position: file_descr -> int * int = "mlterminal_d_position";;
	external set_position: file_descr -> int -> int -> unit =
		"mlterminal_d_set_position";;
	external move: file_descr -> int -> int -> unit = "mlterminal_d_move";;
	external move_to_bol: file_descr -> unit -> unit = "mlterminal_d_move_to_bol";;
	external color: file_descr -> ?reset:bool -> ?bold:bool -> ?underscore:bool ->
		?blink:bool -> ?reverse:bool -> ?concealed:bool -> ?foreground:color ->
		?background:color -> unit -> unit =
		"mlterminal_d_color_byte" "mlterminal_d_color";;
	external save: file_descr -> (unit -> 'a) -> 'a = "mlterminal_d_save";;
	external clear_screen: file_descr -> unit -> unit =
		"mlterminal_d_clear_screen";;
	external clear_eol: file_descr -> unit -> unit = "mlterminal_d_clear_eol";;
	
	let clear_line f () = (
		move_to_bol f ();
		clear_eol f ()
	);;
	
	external scroll: file_descr -> int -> unit = "mlterminal_d_scroll";;
	external show_cursor: file_descr -> bool -> unit = "mlterminal_d_show_cursor";;
	external wrap: file_descr -> bool -> unit = "mlterminal_d_wrap";;
	external screen: file_descr -> ?size:(int * int) -> ?cursor:bool ->
		?wrap:bool -> (file_descr -> 'a) -> 'a =
		"mlterminal_d_screen";;
	
	let output fd s pos len = (
		let w = Unix.write fd s pos len in
		if w < len then failwith("Terminal.Descr.output")
	);;
	
	let output_substring fd s pos len = (
		let w = Unix.write_substring fd s pos len in
		if w < len then failwith("Terminal.Descr.output_substring")
	);;
	
	let output_string fd s = output_substring fd s 0 (String.length s);;
	
	external unsafe_output_substring_utf8: file_descr -> string -> int -> int ->
		unit =
		"mlterminal_d_unsafe_output_substring_utf8";;
	
	let output_substring_utf8 f s pos len = (
		if pos >= 0 && len >= 0 && len <= String.length s - pos
		then unsafe_output_substring_utf8 f s pos len
		else invalid_arg "Terminal.Descr.output_substring_utf8" (* __FUNCTION__ *)
	);;
	
	let output_string_utf8 f s = (
		unsafe_output_substring_utf8 f s 0 (String.length s)
	);;
	
	external output_newline: file_descr -> unit -> unit =
		"mlterminal_d_output_newline";;
	external mode: file_descr -> ?echo:bool -> ?canonical:bool ->
		?control_c:bool -> ?mouse:bool -> (unit -> 'a) -> 'a =
		"mlterminal_d_mode_byte" "mlterminal_d_mode";;
	
	let input = Unix.read;;
	
	external input_line_utf8: file_descr -> string =
		"mlterminal_d_input_line_utf8";;
	external is_empty: file_descr -> bool = "mlterminal_d_is_empty";;
	external input_event: file_descr -> event = "mlterminal_d_input_event";;
end;;

let compose f g = fun x -> f (g x);;

let is_terminal_out = compose Descr.is_terminal Unix.descr_of_out_channel;;

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

let color out ?reset ?bold ?underscore ?blink ?reverse ?concealed ?foreground
	?background () =
(
	flush out;
	Descr.color (Unix.descr_of_out_channel out) ?reset ?bold ?underscore ?blink
		?reverse ?concealed ?foreground ?background ()
);;

let save out f = (
	flush out;
	Descr.save (Unix.descr_of_out_channel out) (fun () ->
		Fun.protect ~finally:(fun () ->
			flush out
		) (fun () ->
			f ()
		)
	)
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

let screen out ?size ?cursor ?wrap f = (
	flush out;
	Descr.screen (Unix.descr_of_out_channel out) ?size ?cursor ?wrap (fun new_fd ->
		let new_out = Unix.out_channel_of_descr new_fd in
		set_binary_mode_out new_out false;
		let result =
			Fun.protect ~finally:(fun () ->
				flush new_out
			) (fun () ->
				f new_out
			)
		in
		result
	)
);;

let unsafe_output_substring_utf8 out s pos len = (
	flush out;
	Descr.unsafe_output_substring_utf8 (Unix.descr_of_out_channel out) s pos len
);;

let output_substring_utf8 out s pos len = (
	if pos >= 0 && len >= 0 && len <= String.length s - pos
	then unsafe_output_substring_utf8 out s pos len
	else invalid_arg "Terminal.output_substring_utf8" (* __FUNCTION__ *)
);;

let output_string_utf8 out s = (
	unsafe_output_substring_utf8 out s 0 (String.length s)
);;

let is_terminal_in = compose Descr.is_terminal Unix.descr_of_in_channel;;

external buffered_in: in_channel -> int = "mlterminal_buffered_in";;
external buffered_line_in: in_channel -> int = "mlterminal_buffered_line_in";;

let mode ic ?echo ?canonical ?control_c ?mouse f = (
	Descr.mode (Unix.descr_of_in_channel ic) ?echo ?canonical ?control_c ?mouse f
);;

external utf8_of_locale: string -> string = "mlterminal_utf8_of_locale";;
external locale_of_utf8: string -> string = "mlterminal_locale_of_utf8";;

let input_line_utf8 ic = (
	if not (is_terminal_in ic) then (
		input_line ic (* normal file *)
	) else (
		let buffered_line_length = buffered_line_in ic in
		if buffered_line_length = max_int then (
			(* current line is continuing... *)
			let buffered_length = buffered_in ic in
			if buffered_length <= 0 then (
				(* empty *)
				Descr.input_line_utf8 (Unix.descr_of_in_channel ic)
			) else (
				(* continuing *)
				let buffered_s = really_input_string ic buffered_length in
				let s1 = utf8_of_locale buffered_s in
				let s2 = Descr.input_line_utf8 (Unix.descr_of_in_channel ic) in
				s1 ^ s2
			)
		) else (
			(* '\n' is found *)
			assert (buffered_line_length > 0);
			let line_length = buffered_line_length - 1 in
			let line_s = really_input_string ic line_length in
			let (_: char) = input_char ic in (* drop '\n' *)
			utf8_of_locale line_s
		)
	)
);;
