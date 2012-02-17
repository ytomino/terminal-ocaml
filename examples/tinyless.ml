let filename = Sys.argv.(1);;

Terminal.set_title filename;;

let lines =
	let rec loop f lines = (
		try
			let s = input_line f in
			loop f (s :: lines)
		with End_of_file ->
			close_in f;
			Array.of_list (List.rev lines)
	) in
	loop (open_in filename) []

let line_count = Array.length lines;;

let left, top, right, bottom = Terminal.view stdout;;
let height = bottom - top + 1;;

exception Exit;;

if line_count < height then (
	for i = 0 to line_count - 1 do
		print_string lines.(i);
		print_newline ()
	done
) else (
	Terminal.set_input_mode stdin ~echo:false ~canonical:false ();
	Terminal.show_cursor stdout false;
	try
		let p = ref 0 in
		for i = 0 to height - 2 do
			print_string lines.(i);
			print_newline ()
		done;
		while true do
			if !p + height - 1 < line_count then (
				Terminal.move_to_backward stdout ();
				Terminal.clear_forward stdout ();
				Terminal.color stdout ~reverse:true ();
				print_string "more...";
				Terminal.color stdout ~reset:true ();
			);
			match input_char stdin with
			| 'q' -> raise Exit
			| 'j' when !p + height <= line_count ->
				Terminal.move_to_backward stdout ();
				Terminal.clear_forward stdout ();
				print_string lines.(!p + height - 1);
				print_newline ();
				incr p
			| 'k' when !p > 0 ->
				decr p;
				Terminal.scroll stdout (-1);
				Terminal.move stdout 0 (-(height - 1));
				Terminal.move_to_backward stdout ();
				print_string lines.(!p);
				Terminal.move stdout 0 (height - 1);
			| _ -> ()
		done
	with exn ->
		Terminal.set_input_mode stdin ~echo:true ~canonical:true ();
		Terminal.show_cursor stdout true;
		if exn <> Exit then raise exn
);;
