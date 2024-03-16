let isatty = Terminal.is_terminal_out stdout in
Printf.printf "isatty(stdout): %B\n" isatty;;

let isatty = Terminal.is_terminal_out stderr in
Printf.printf "isatty(stderr): %B\n" isatty;;

let isatty = Terminal.is_terminal_in stdin in
Printf.printf "isatty(stdin): %B\n" isatty;;

let w, h = Terminal.size stdout in
Printf.printf "size: %dx%d\n" w h;;

let left, top, right, bottom = Terminal.view stdout in
Printf.printf "view: (%d, %d)-(%d, %d)\n" left top right bottom;;

let x, y = Terminal.position stdout in
Printf.printf "position: (%d, %d)\n" x y;;

let c256 = Terminal.supports_256 () in
Printf.printf "256 color: %B\n" c256;;
