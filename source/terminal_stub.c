#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/unixsupport.h>

#include <stdbool.h>

#ifdef __WINNT__

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

static HANDLE handle_of_descr(value x)
{
	if(Descr_kind_val(x) != KIND_HANDLE){
		failwith("the channel is not a file handle");
	}
	return Handle_val(x);
}

static int code_of_color(value x)
{
	int result = 0;
	if(Int_val(Field(x, 0))) result |= FOREGROUND_RED;
	if(Int_val(Field(x, 1))) result |= FOREGROUND_GREEN;
	if(Int_val(Field(x, 2))) result |= FOREGROUND_BLUE;
	if(Int_val(Field(x, 3))) result |= FOREGROUND_INTENSITY;
	return result;
}

static void clear_rect(HANDLE f, SMALL_RECT *rect)
{
	COORD buf_size = {
		.X = rect->Right - rect->Left + 1,
		.Y = rect->Bottom - rect->Top + 1};
	size_t sizeof_buf = buf_size.X * buf_size.Y * sizeof(CHAR_INFO);
	CHAR_INFO *buf = malloc(sizeof_buf);
	memset(buf, 0, sizeof_buf);
	WriteConsoleOutput(f, buf, buf_size, (COORD){.X = 0, .Y = 0}, rect);
	free(buf);
}

#else

#include <stdio.h>
#include <termios.h>
#include <unistd.h>
#include <sys/ioctl.h>

static int handle_of_descr(value x)
{
	return Int_val(x);
}

static int code_of_color(value x)
{
	int result = 0;
	if(Int_val(Field(x, 0))) result |= 1; /* red */
	if(Int_val(Field(x, 1))) result |= 2; /* green */
	if(Int_val(Field(x, 2))) result |= 4; /* blue */
	return result;
}

#endif

CAMLprim value mlterminal_set_title(value title)
{
	CAMLparam1(title);
#ifdef __WINNT__
	SetConsoleTitle(String_val(title));
#else
	/* no effect */
#endif
	CAMLreturn(Val_unit);
}

CAMLprim value mlterminal_d_is_terminal(value out)
{
	CAMLparam1(out);
	CAMLlocal1(result);
#ifdef __WINNT__
	HANDLE f = handle_of_descr(out);
	result = Val_bool(GetFileType(f) == FILE_TYPE_CHAR);
#else
	int f = handle_of_descr(out);
	result = Val_bool(isatty(f));
#endif
	CAMLreturn(result);
}

CAMLprim value mlterminal_d_size(value out)
{
	CAMLparam1(out);
	CAMLlocal1(result);
	int w, h;
#ifdef __WINNT__
	HANDLE f = handle_of_descr(out);
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(f, &info);
	w = info.dwSize.X;
	h = info.dwSize.Y;
#else
	int f = handle_of_descr(out);
	struct ttysize win;
	if(ioctl(f, TIOCGSIZE, &win) < 0){
		failwith("mlterminal_size");
	}
	w = win.ts_cols;
	h = win.ts_lines;
#endif
	result = caml_alloc_tuple(2);
	Field(result, 0) = Val_int(w);
	Field(result, 1) = Val_int(h);
	CAMLreturn(result);
}

CAMLprim value mlterminal_d_set_size(value out, value w, value h)
{
	CAMLparam3(out, w, h);
#ifdef __WINNT__
	HANDLE f = handle_of_descr(out);
	CONSOLE_SCREEN_BUFFER_INFO info;
	SetConsoleScreenBufferSize(f, (COORD){
		.X = Int_val(w),
		.Y = Int_val(h)});
	GetConsoleScreenBufferInfo(f, &info);
	SetConsoleWindowInfo(f, true, &(SMALL_RECT){
		.Left = 0,
		.Top = 0,
		.Right = info.dwSize.X - 1,
		.Bottom = info.dwSize.Y - 1});
#else
	int f = handle_of_descr(out);
	struct ttysize win;
	win.ts_cols = Int_val(w);
	win.ts_lines = Int_val(h);
	if(ioctl(f, TIOCSSIZE, &win) < 0){
		failwith("mlterminal_set_size");
	}
#endif
	CAMLreturn(Val_unit);
}

CAMLprim value mlterminal_d_view(value out)
{
	CAMLparam1(out);
	CAMLlocal1(result);
	int left, top, right, bottom;
#ifdef __WINNT__
	HANDLE f = handle_of_descr(out);
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(f, &info);
	left = info.srWindow.Left;
	top = info.srWindow.Top;
	right = info.srWindow.Right;
	bottom = info.srWindow.Bottom;
#else
	int f = handle_of_descr(out);
	struct ttysize win;
	if(ioctl(f, TIOCGSIZE, &win) < 0){
		failwith("mlterminal_size");
	}
	left = 0;
	top = 0;
	right = win.ts_cols - 1;
	bottom = win.ts_lines - 1;
#endif
	result = caml_alloc_tuple(2);
	Field(result, 0) = Val_int(left);
	Field(result, 1) = Val_int(top);
	Field(result, 2) = Val_int(right);
	Field(result, 3) = Val_int(bottom);
	CAMLreturn(result);
}

CAMLprim value mlterminal_d_position(value out)
{
	CAMLparam1(out);
	CAMLlocal1(result);
	int x, y;
#ifdef __WINNT__
	HANDLE f = handle_of_descr(out);
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(f, &info);
	x = info.dwCursorPosition.X;
	y = info.dwCursorPosition.Y;
#else
	if(!isatty(2)){
		failwith("mlterminal_d_position(stdin is not associated to terminal)");
	}
	int f = handle_of_descr(out);
	struct termios old_settings, new_settings;
	tcgetattr(2, &old_settings);
	new_settings = old_settings;
	new_settings.c_lflag &= ~(ECHO | ICANON);
	new_settings.c_cc[VMIN] = 1;
	new_settings.c_cc[VTIME] = 0;
	tcsetattr(2, TCSAFLUSH, &new_settings);
	write(f, "\x1b[6n", 4);
	char buf[256];
	int i = 0;
	while(read(2, &buf[i], 1) == 1){
		if(i == 0){
			if(buf[i] == '\x1b'){
				++i;
			}
		}else{
			char c = buf[i];
			++i;
			if(c == 'R') break;
		}
	}
	tcsetattr(2, TCSANOW, &old_settings);
	if(sscanf(buf, "\x1b[%d;%dR", &x, &y) != 2){
		failwith("mlterminal_d_position");
	}
	--x;
	--y;
#endif
	result = caml_alloc_tuple(2);
	Field(result, 0) = Val_int(x);
	Field(result, 1) = Val_int(y);
	CAMLreturn(result);
}

CAMLprim value mlterminal_d_set_position(
	value out,
	value x,
	value y)
{
	CAMLparam3(out, x, y);
#ifdef __WINNT__
	HANDLE f = handle_of_descr(out);
	SetConsoleCursorPosition(f, (COORD){
		.X = Int_val(x),
		.Y = Int_val(y)});
#else
	int f = handle_of_descr(out);
	int abs_x = Int_val(x) + 1;
	int abs_y = Int_val(y) + 1;
	char buf[256];
	int len = snprintf(buf, 256, "\x1b[%d;%dH", abs_y, abs_x);
	write(f, buf, len);
#endif
	CAMLreturn(Val_unit);
}

CAMLprim value mlterminal_d_move(
	value out,
	value x,
	value y)
{
	CAMLparam3(out, x, y);
#ifdef __WINNT__
	HANDLE f = handle_of_descr(out);
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(f, &info);
	SetConsoleCursorPosition(f, (COORD){
		.X = info.dwCursorPosition.X + Int_val(x),
		.Y = info.dwCursorPosition.Y + Int_val(y)});
#else
	int f = handle_of_descr(out);
	int rel_x = Int_val(x);
	int rel_y = Int_val(y);
	char buf[256];
	int len;
	if(rel_y < 0){
		len = snprintf(buf, 256, "\x1b[%dA", -rel_y);
		write(f, buf, len);
	}else if(rel_y > 0){
		len = snprintf(buf, 256, "\x1b[%dB", rel_y);
		write(f, buf, len);
	}
	if(rel_x > 0){
		len = snprintf(buf, 256, "\x1b[%dC", rel_x);
		write(f, buf, len);
	}else if(rel_x < 0){
		len = snprintf(buf, 256, "\x1b[%dD", -rel_x);
		write(f, buf, len);
	}
#endif
	CAMLreturn(Val_unit);
}

CAMLprim value mlterminal_d_move_to_backward(value out, value unit)
{
	CAMLparam2(out, unit);
#ifdef __WINNT__
	HANDLE f = handle_of_descr(out);
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(f, &info);
	SetConsoleCursorPosition(f, (COORD){
		.X = 0,
		.Y = info.dwCursorPosition.Y});
#else
	int f = handle_of_descr(out);
	write(f, "\r", 1);
#endif
	CAMLreturn(Val_unit);
}

CAMLprim value mlterminal_d_color(
	value out,
	value reset,
	value bold,
	value underscore,
	value blink,
	value reverse,
	value concealed,
	value foreground,
	value background,
	value unit)
{
	CAMLparam5(out, reset, bold, underscore, blink);
	CAMLxparam5(reverse, concealed, foreground, background, unit);
#ifdef __WINNT__
	HANDLE f = handle_of_descr(out);
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(f, &info);
	WORD attributes = info.wAttributes;
	if(Is_block(reset) && Int_val(Field(reset, 0))){
		attributes = FOREGROUND_BLUE | FOREGROUND_GREEN | FOREGROUND_RED
			| FOREGROUND_INTENSITY;
	}
	if(Is_block(foreground)){
		attributes &= ~0x0f;
		attributes |= code_of_color(Field(foreground, 0));
	}
	if(Is_block(background)){
		attributes &= ~0xf0;
		attributes |= code_of_color(Field(background, 0)) << 4;
	}
	if(Is_block(reverse) && Int_val(Field(reverse, 0))){
		attributes = ((attributes & 0x0f) << 4) | ((attributes & 0xf0) >> 4);
	}
	if(Is_block(concealed) && Int_val(Field(concealed, 0))){
		attributes &= ~0x0f;
		attributes |= (attributes & 0xf0) >> 4;
	}
	SetConsoleTextAttribute(f, attributes);
#else
	int f = handle_of_descr(out);
	char buf[256];
	int i = 0;
	buf[i++] = '\x1b';
	buf[i++] = '[';
	if(Is_block(reset) && Int_val(Field(reset, 0))){
		buf[i++] = '0';
	}
	if(Is_block(bold) && Int_val(Field(bold, 0))){
		if(i > 2) buf[i++] = ';';
		buf[i++] = '1';
	}
	if(Is_block(underscore) && Int_val(Field(underscore, 0))){
		if(i > 2) buf[i++] = ';';
		buf[i++] = '4';
	}
	if(Is_block(blink) && Int_val(Field(blink, 0))){
		if(i > 2) buf[i++] = ';';
		buf[i++] = '5';
	}
	if(Is_block(reverse) && Int_val(Field(reverse, 0))){
		if(i > 2) buf[i++] = ';';
		buf[i++] = '7';
	}
	if(Is_block(concealed) && Int_val(Field(concealed, 0))){
		if(i > 2) buf[i++] = ';';
		buf[i++] = '8';
	}
	if(Is_block(foreground)){
		if(i > 2) buf[i++] = ';';
		buf[i++] = '3';
		buf[i++] = '0' + code_of_color(Field(foreground, 0));
	}
	if(Is_block(background)){
		if(i > 2) buf[i++] = ';';
		buf[i++] = '4';
		buf[i++] = '0' + code_of_color(Field(background, 0));
	}
	if(i > 2){
		buf[i++] = 'm';
		write(f, buf, i);
	}
#endif
	CAMLreturn(Val_unit);
}

CAMLprim value mlterminal_d_color_byte(
	value *argv,
	__attribute__((unused)) int n)
{
	return mlterminal_d_color(
		argv[0],
		argv[1],
		argv[2],
		argv[3],
		argv[4],
		argv[5],
		argv[6],
		argv[7],
		argv[8],
		argv[9]);
}

CAMLprim value mlterminal_d_save(value out, value callback)
{
	CAMLparam2(out, callback);
	CAMLlocal1(result);
#ifdef __WINNT__
	HANDLE f = handle_of_descr(out);
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(f, &info);
	result = caml_callback_exn(callback, Val_unit);
	SetConsoleCursorPosition(f, (COORD){
		.X = info.dwCursorPosition.X,
		.Y = info.dwCursorPosition.Y});
#else
	int f = handle_of_descr(out);
	/* write(f, "\x1b[s", 3); */
	write(f, "\x1b""7", 2);
	result = caml_callback_exn(callback, Val_unit);
	/* write(f, "\x1b[u", 3); */
	write(f, "\x1b""8", 2);
#endif
	CAMLreturn(result);
}

CAMLprim value mlterminal_d_clear_screen(value out, value unit)
{
	CAMLparam2(out, unit);
#ifdef __WINNT__
	HANDLE f = handle_of_descr(out);
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(f, &info);
	clear_rect(f, &(SMALL_RECT){
		.Left = 0,
		.Top = 0,
		.Right = info.dwSize.X - 1,
		.Bottom = info.dwSize.Y - 1});
#else
	int f = handle_of_descr(out);
	write(f, "\x1b[2J", 4);
#endif
	CAMLreturn(Val_unit);
}

CAMLprim value mlterminal_d_clear_forward(value out, value unit)
{
	CAMLparam2(out, unit);
#ifdef __WINNT__
	HANDLE f = handle_of_descr(out);
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(f, &info);
	clear_rect(f, &(SMALL_RECT){
		.Left = info.dwCursorPosition.X,
		.Top = info.dwCursorPosition.Y,
		.Right = info.dwSize.X - 1,
		.Bottom = info.dwCursorPosition.Y});
#else
	int f = handle_of_descr(out);
	write(f, "\x1b[K", 3);
#endif
	CAMLreturn(Val_unit);
}

CAMLprim value mlterminal_d_scroll(value out, value y)
{
	CAMLparam2(out, y);
#ifdef __WINNT__
	HANDLE f = handle_of_descr(out);
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(f, &info);
	CHAR_INFO fill;
	memset(&fill, 0, sizeof(CHAR_INFO));
	ScrollConsoleScreenBuffer(
		f,
		&info.srWindow,
		&info.srWindow,
		(COORD){.X = info.srWindow.Left, .Y = info.srWindow.Top - Int_val(y)},
		&fill);
#else
	int f = handle_of_descr(out);
	int off_y = Int_val(y);
	char buf[256];
	int len;
	if(off_y > 0){
		len = snprintf(buf, 256, "\x1b[%dS", off_y);
		write(f, buf, len);
	}else if(off_y < 0){
		len = snprintf(buf, 256, "\x1b[%dT", -off_y);
		write(f, buf, len);
	}
#endif
	CAMLreturn(Val_unit);
}

CAMLprim value mlterminal_d_show_cursor(value out, value visible)
{
	CAMLparam2(out, visible);
#ifdef __WINNT__
	HANDLE f = handle_of_descr(out);
	CONSOLE_CURSOR_INFO info;
	GetConsoleCursorInfo(f, &info);
	info.bVisible = Int_val(visible);
	SetConsoleCursorInfo(f, &info);
#else
	/* refer https://developer.apple.com/library/mac/#documentation/OpenSource/
	         Conceptual/ShellScripting/AdvancedTechniques/
	         AdvancedTechniques.html%23//apple_ref/doc/uid/
	         TP40004268-TP40003521-SW9 */
	int f = handle_of_descr(out);
	if(Int_val(visible)){
		/* write(f, "\x1b[>5l", 5); */
		write(f, "\x1b[?25h", 6);
	}else{
		/* write(f, "\x1b[>5h", 5); */
		write(f, "\x1b[?25l", 6);
	}
#endif
	CAMLreturn(Val_unit);
}

CAMLprim value mlterminal_d_set_input_mode(
	value in,
	value echo,
	value canonical,
	value unit)
{
	CAMLparam4(in, echo, canonical, unit);
#ifdef __WINNT__
	HANDLE f = handle_of_descr(in);
	DWORD mode;
	GetConsoleMode(f, &mode);
	if(Is_block(echo)){
		if(Int_val(Field(echo, 0))){
			mode |= ENABLE_ECHO_INPUT;
		}else{
			mode &= ~ENABLE_ECHO_INPUT;
		}
	}
	if(Is_block(canonical)){
		if(Int_val(Field(canonical, 0))){
			mode |= ENABLE_LINE_INPUT;
		}else{
			mode &= ~ENABLE_LINE_INPUT;
		}
	}
	SetConsoleMode(f, mode);
#else
	struct termios settings;
	tcgetattr(2, &settings);
	if(Is_block(echo)){
		if(Int_val(Field(echo, 0))){
			settings.c_lflag |= ECHO;
		}else{
			settings.c_lflag &= ~ECHO;
		}
	}
	if(Is_block(canonical)){
		if(Int_val(Field(canonical, 0))){
			settings.c_lflag |= ICANON;
		}else{
			settings.c_lflag &= ~ICANON;
			/* settings.c_cc[VMIN] = 1; */
			/* settings.c_cc[VTIME] = 0; */
		}
	}
	tcsetattr(2, TCSANOW, &settings);
#endif
	CAMLreturn(Val_unit);
}
