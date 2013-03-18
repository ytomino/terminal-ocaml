let (_: int * int * int * int) = Terminal.Descr.view Unix.stdout;;
(* install SIGWINCH handler *)

Sys.catch_break true;;
(* install SIGINT handler *)

let mouse = true in
Terminal.Descr.mode Unix.stdin ~echo:false ~canonical:false ~mouse (fun () ->
	let write_string fd s =
		let (_: int) = Unix.write fd s 0 (String.length s) in ()
	in
	let playing = ref true in
	let dx = ref 1 in
	let dy = ref 0 in
	while !playing do
		if Terminal.Descr.is_empty Unix.stdin then (
			Terminal.Descr.save Unix.stdout (fun () ->
				write_string Unix.stdout "*"
			);
			Terminal.Descr.move Unix.stdout !dx !dy;
			Unix.sleep 1;
		) else (
			let ev = Terminal.Descr.input_event Unix.stdin in
			let seq = Terminal.escape_sequence_of_event ev in
			let desc = ref "" in
			if Terminal.is_key ev || Terminal.is_clicked ev then (
				let ss = Terminal.shift_of_event ev in
				if Terminal.mem Terminal.shift ss then (
					desc := !desc ^ "shift+";
				);
				if Terminal.mem Terminal.control ss then (
					desc := !desc ^ "control+";
				);
				if Terminal.mem Terminal.alt ss then (
					desc := !desc ^ "alt+";
				)
			);
			if Terminal.is_key ev then (
				begin match Terminal.key_of_event ev with
				| `up ->
					desc := !desc ^ "up";
					dx := 0;
					dy := -1
				| `down ->
					desc := !desc ^ "down";
					dx := 0;
					dy := 1
				| `right ->
					desc := !desc ^ "right";
					dx := 1;
					dy := 0
				| `left ->
					desc := !desc ^ "left";
					dx := -1;
					dy := 0
				| `home ->
					desc := !desc ^ "home"
				| `end_key ->
					desc := !desc ^ "end"
				| `pageup ->
					desc := !desc ^ "pageup"
				| `pagedown ->
					desc := !desc ^ "pagedown"
				| `insert ->
					desc := !desc ^ "insert"
				| `delete ->
					desc := !desc ^ "delete"
				| `f1 ->
					desc := !desc ^ "F1"
				| `f2 ->
					desc := !desc ^ "F2"
				| `f3 ->
					desc := !desc ^ "F3"
				| `f4 ->
					desc := !desc ^ "F4"
				| `f5 ->
					desc := !desc ^ "F5"
				| `f6 ->
					desc := !desc ^ "F6"
				| `f7 ->
					desc := !desc ^ "F7"
				| `f8 ->
					desc := !desc ^ "F8"
				| `f9 ->
					desc := !desc ^ "F9"
				| `f10 ->
					desc := !desc ^ "F10"
				| `f11 ->
					desc := !desc ^ "F11"
				| `f12 ->
					desc := !desc ^ "F12"
				| `unknown ->
					desc := !desc ^ "unknown"
				end
			) else if Terminal.is_clicked ev then (
				begin match Terminal.button_of_event ev with
				| `button1 ->
					desc := !desc ^ "button1"
				| `button2 ->
					desc := !desc ^ "button2"
				| `button3 ->
					desc := !desc ^ "button3"
				| `wheelup ->
					desc := !desc ^ "wheelup"
				| `wheeldown ->
					desc := !desc ^ "wheeldown"
				| `released ->
					desc := !desc ^ "released"
				| `unknown ->
					desc := !desc ^ "unknown"
				end;
				let x, y = Terminal.position_of_event ev in
				desc := !desc ^ "(" ^ string_of_int x ^ "," ^ string_of_int y ^ ")"
			) else if Terminal.is_resized ev then (
				let w, h = Terminal.size_of_event ev in
				desc := "resized" ^ ":" ^ string_of_int w ^ "x" ^ string_of_int h
			) else if Terminal.is_char ev then (
				let c = Terminal.char_of_event ev in
				desc := "'" ^ Char.escaped c ^ "'";
				if c = '\x1b' then playing := false
			) else if Terminal.is_string ev then (
				let c = Terminal.string_of_event ev in
				desc := "\"" ^ String.escaped c ^ "\""
			);
			Terminal.Descr.save Unix.stdout (fun () ->
				Terminal.Descr.color Unix.stdout ~foreground:Terminal.red ();
				Terminal.Descr.set_position Unix.stdout 0 0;
				write_string Unix.stdout ("{" ^ String.escaped seq ^ "}" ^ !desc ^ " ");
			)
		)
	done
);;
