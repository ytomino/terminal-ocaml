(* rgb *)
for r1 = 0 to 1 do
	for g = 0 to 7 do
		for r2 = 0 to 3 do
			for b = 0 to 7 do
				let background =
					Terminal.rgb
						~red:(float_of_int (r1 * 4 + r2) /. 7.0)
						~green:(float_of_int g /. 7.0)
						~blue:(float_of_int b /. 7.0)
				in
				Terminal.color stdout ~background ();
				print_string "  "
			done;
			Terminal.color stdout ~reset:true ();
			if r2 < 3 then print_string "  "
		done;
		print_newline ()
	done;
	print_newline ()
done;;

(* grayscale *)
for s = 0 to 25 do
	let background = Terminal.grayscale ((float_of_int s) /. 25.0) in
	Terminal.color stdout ~background ();
	print_string "  "
done;;
Terminal.color stdout ~reset:true ();;
print_newline ();;
