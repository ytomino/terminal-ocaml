(* Terminal.clear_screen stdout ();; *)

print_string "1234567890";;
Terminal.move_to_backward stdout ();;
Terminal.move stdout 5 0;;
Terminal.clear_forward stdout ();;
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

(*
Terminal.save stdout (fun () ->
	Terminal.move stdout 2 (-3);
	print_string "E"
);;
*)

