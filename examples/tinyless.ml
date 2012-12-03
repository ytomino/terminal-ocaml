let filename = Sys.argv.(1);;

let expand_tab s = (
	let rec loop s i n b = (
		if i >= String.length s then Buffer.contents b else
		let c = s.[i] in
		if c = '\t' then (
			let n2 = (n + 8) land (lnot 7) in
			for j = n + 1 to n2 do
				Buffer.add_char b ' '
			done;
			loop s (i + 1) n2 b
		) else (
			Buffer.add_char b c;
			loop s (i + 1) (n + 1) b
		)
	) in
	loop s 0 0 (Buffer.create (String.length s + 32))
);;

let lines =
	let rec loop f lines = (
		try
			let s = expand_tab (input_line f) in
			loop f (s :: lines)
		with End_of_file ->
			close_in f;
			Array.of_list (List.rev lines)
	) in
	loop (open_in filename) []

let line_count = Array.length lines;;

Sys.catch_break true;;
(* install SIGINT handler *)

Terminal.title filename (fun () ->
	Terminal.screen stdout ~cursor:false ~wrap:false (fun stdout ->
		Terminal.Descr.mode Unix.stdin ~echo:false ~canonical:false (fun () ->
			try
				let left, top, right, bottom = Terminal.view stdout in
				let width = ref (right - left + 1) in
				let height = ref (bottom - top + 1) in
				let trim s = (
					if String.length s <= !width then s else
					String.sub s 0 !width
				) in
				let p = ref 0 in
				let rewrite () = (
					for i = 0 to !height - 2 do
						if !p + i < line_count then (
							output_string stdout (trim lines.(!p + i))
						);
						output_char stdout '\n'
					done
				) in
				rewrite ();
				while true do
					Terminal.clear_line stdout ();
					if !p + !height <= line_count then (
						Terminal.color stdout ~reverse:true ();
						output_string stdout "more...";
						Terminal.color stdout ~reset:true ();
					);
					flush stdout;
					let ev = Terminal.Descr.input_event (Unix.stdin) in
					if Terminal.is_char ev then (
						begin match Terminal.char_of_event ev with
						| 'q' ->
							raise Exit
						| 'j' when !p + !height - 1 < line_count ->
							Terminal.clear_line stdout ();
							output_string stdout (trim lines.(!p + !height - 1));
							output_char stdout '\n';
							incr p
						| 'k' when !p > 0 ->
							decr p;
							Terminal.scroll stdout (-1);
							Terminal.move stdout 0 (-(!height - 1));
							Terminal.move_to_bol stdout ();
							output_string stdout (trim lines.(!p));
							Terminal.move stdout 0 (!height - 1);
						| _ ->
							()
						end
					) else if Terminal.is_resized ev then (
						let left, top, right, bottom = Terminal.view stdout in
						width := right - left + 1;
						height := bottom - top + 1;
						if !p + !height - 1 > line_count then (
							p := line_count - (!height - 1)
						);
						Terminal.clear_screen stdout ();
						Terminal.set_position stdout 0 0;
						rewrite ()
					)
				done
			with Exit -> ()
		)
	)
);;
