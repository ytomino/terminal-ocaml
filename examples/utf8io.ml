Terminal.title_utf8 "たいとる" (fun () ->
	Terminal.output_string_utf8 stdout
		"Please, input over 3 single-byte and trailing multi-byte text ≫ ";
	let take3 = really_input_string stdin 3 in
	Terminal.output_string_utf8 stdout "【";
	output_string stdout take3;
	Terminal.output_string_utf8 stdout "】";
	output_char stdout '\n';
	let line = Terminal.input_line_utf8 stdin in
	Terminal.output_string_utf8 stdout ("【" ^ line ^ "】");
	output_char stdout '\n';
	output_string stdout (Terminal.locale_of_utf8 ("【" ^ line ^ "】"));
	output_char stdout '\n'
);;
