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

Sys.catch_break true;;
(* install SIGINT handler *)

Terminal.screen stdout (fun stdout ->
	Terminal.mode stdin ~echo:false ~canonical:false (fun () ->
		let left, top, right, bottom = Terminal.view stdout in
		let height = bottom - top + 1 in
		Terminal.show_cursor stdout false;
		try
			let p = ref 0 in
			for i = 0 to height - 2 do
				if i < line_count then output_string stdout lines.(i);
				output_char stdout '\n'
			done;
			flush stdout;
			while true do
				if !p + height <= line_count then (
					Terminal.clear_line stdout ();
					Terminal.color stdout ~reverse:true ();
					output_string stdout "more...";
					Terminal.color stdout ~reset:true ();
				);
				match input_char stdin with
				| 'q' -> raise Exit
				| 'j' when !p + height <= line_count ->
					Terminal.clear_line stdout ();
					output_string stdout lines.(!p + height - 1);
					output_char stdout '\n';
					flush stdout;
					incr p
				| 'k' when !p > 0 ->
					decr p;
					Terminal.scroll stdout (-1);
					Terminal.move stdout 0 (-(height - 1));
					Terminal.move_to_bol stdout ();
					output_string stdout lines.(!p);
					Terminal.move stdout 0 (height - 1);
				| _ -> ()
			done
		with exn ->
			Terminal.show_cursor stdout true;
			if exn <> Exit then raise exn
	)
);;
