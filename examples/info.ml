let isatty = Terminal.is_terminal_out stdout in
Printf.printf "isatty(stdout): %b\n" isatty;;

let isatty = Terminal.is_terminal_out stderr in
Printf.printf "isatty(stderr): %b\n" isatty;;

let isatty = Terminal.is_terminal_in stdin in
Printf.printf "isatty(stdin): %b\n" isatty;;

let w, h = Terminal.size stdout in
Printf.printf "size: %dx%d\n" w h;;

let left, top, right, bottom = Terminal.view stdout in
Printf.printf "view: (%d, %d)-(%d, %d)\n" left top right bottom;;

let x, y = Terminal.position stdout in
Printf.printf "position: (%d, %d)\n" x y;;
