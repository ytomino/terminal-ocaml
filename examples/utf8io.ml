Terminal.set_title_utf8 "たいとる";;
Terminal.output_string_utf8 stdout "Please, input multi-byte characters ≫ ";;
let line = Terminal.input_line_utf8 stdin in
Terminal.output_string_utf8 stdout ("【" ^ line ^ "】");;
output_char stdout '\n';;
