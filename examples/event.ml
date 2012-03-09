Terminal.set_input_mode stdin ~echo:false ~canonical:false ();;

let write_string fd s =
	let (_: int) = Unix.write fd s 0 (String.length s) in ();;

let playing = ref true;;
let dx = ref 1;;
let dy = ref 0;;

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
		Terminal.Descr.save Unix.stdout (fun () ->
			Terminal.Descr.color Unix.stdout ~foreground:Terminal.red ();
			Terminal.Descr.set_position Unix.stdout 0 0;
			write_string Unix.stdout ("{" ^ String.escaped seq ^ "}");
		);
		if Terminal.is_up ev then (
			dx := 0;
			dy := -1
		) else if Terminal.is_down ev then (
			dx := 0;
			dy := 1
		) else if Terminal.is_right ev then (
			dx := 1;
			dy := 0
		) else if Terminal.is_left ev then (
			dx := -1;
			dy := 0
		) else if Terminal.is_char ev && Terminal.char_of_event ev = '\x1b' then (
			playing := false
		)
	)
done;;

Terminal.set_input_mode stdin ~echo:true ~canonical:true ();;
