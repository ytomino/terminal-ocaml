let isatty = Terminal.is_terminal stdout in
Printf.printf "isatty: %b\n" isatty;;

let w, h = Terminal.size stdout in
Printf.printf "size: %dx%d\n" w h;;

let left, top, right, bottom = Terminal.view stdout in
Printf.printf "view: (%d, %d)-(%d, %d)\n" left top right bottom;;

let x, y = Terminal.position stdout in
Printf.printf "position: (%d, %d)\n" x y;;
