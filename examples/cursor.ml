(* Terminal.clear_screen stdout ();; *)

print_string "1234567890";;
Terminal.move_to_bol stdout ();;
Terminal.move stdout 5 0;;
Terminal.clear_eol stdout ();;
print_newline ();;

for i = 1 to 5 do
	print_newline ()
done;;
Terminal.move stdout 0 (-5);;
print_string "A";;
Terminal.move stdout 3 0;;
print_string "B";;
Terminal.move stdout (-1) 4;;
print_string "C";;
Terminal.move stdout (-5) 0;;
print_string "D";;

print_newline ();;

let x = Terminal.save stdout (fun () ->
	Terminal.move stdout 2 (-3);
	Terminal.color stdout ~foreground:Terminal.red ();
	print_string "E"; (* red *)
	"12345"
) in
print_string x; (* not red *)
print_newline ();
