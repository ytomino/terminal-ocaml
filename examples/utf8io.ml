Terminal.set_title_utf8 "たいとる";;

Terminal.output_string_utf8 stdout
	"Please, input over 3 single-byte and trailing multi-byte text ≫ ";;
let take3 = String.create 3;;
really_input stdin take3 0 3;;
output_string stdout ("【" ^ take3 ^ "】");;
output_char stdout '\n';;
let line = Terminal.input_line_utf8 stdin;;
Terminal.output_string_utf8 stdout ("【" ^ line ^ "】");;
output_char stdout '\n';;
output_string stdout ("【" ^ Terminal.locale_of_utf8 line ^ "】");;
output_char stdout '\n';;
