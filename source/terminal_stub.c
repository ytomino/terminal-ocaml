#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/signals.h>
#include <caml/unixsupport.h>

#define CAML_INTERNALS
#include "caml/io.h"
#undef CAML_INTERNALS

#include <stdbool.h>
#include <string.h>

#ifdef __WINNT__

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

static PWSTR get_title(void)
{
	size_t max_length = 256;
	PWSTR result = malloc(max_length * sizeof(WCHAR));
	while(GetConsoleTitleW(result, max_length) > 0){
		max_length *= 2;
		PWSTR new_result = realloc(result, max_length * sizeof(WCHAR));
		if(new_result == NULL){
			free(result);
			caml_raise_out_of_memory();
		}
		result = new_result;
	}
	return result;
}

typedef HANDLE handlt_t;

static HANDLE handle_of_descr(value x)
{
	if(Descr_kind_val(x) != KIND_HANDLE){
		failwith("mlterminal(the channel is not a file handle)");
	}
	return Handle_val(x);
}

static void set_size(HANDLE new_f, int new_w, int new_h, HANDLE old_f)
{
	CONSOLE_SCREEN_BUFFER_INFO info, old_info;
	GetConsoleScreenBufferInfo(old_f, &old_info);
	int old_win_w = old_info.srWindow.Right - old_info.srWindow.Left + 1;
	int old_win_h = old_info.srWindow.Bottom - old_info.srWindow.Top + 1;
	if(new_w < old_win_w || new_h < old_win_h){
		SetConsoleWindowInfo(new_f, true, &(SMALL_RECT){
			.Left = 0,
			.Top = 0,
			.Right = min(new_w, old_win_w) - 1,
			.Bottom = min(new_h, old_win_h) - 1});
	}
	SetConsoleScreenBufferSize(new_f, (COORD){
		.X = new_w,
		.Y = new_h});
	GetConsoleScreenBufferInfo(new_f, &info);
	SetConsoleWindowInfo(new_f, true, &(SMALL_RECT){
		.Left = 0,
		.Top = 0,
		.Right = info.dwMaximumWindowSize.X - 1,
		.Bottom = info.dwMaximumWindowSize.Y - 1});
}

static bool window_input_installed = false;

static void install_window_input(void)
{
	if(!window_input_installed){
		HANDLE f = GetStdHandle(STD_INPUT_HANDLE);
		DWORD mode;
		window_input_installed = true;
		GetConsoleMode(f, &mode);
		mode |= ENABLE_WINDOW_INPUT;
		SetConsoleMode(f, mode);
	}
}

static WORD default_attributes;
static bool default_attributes_initialized = false;

static int system_16(int red, int green, int blue, int intensity)
{
	int result = 0;
	if(red)       result |= FOREGROUND_RED;
	if(green)     result |= FOREGROUND_GREEN;
	if(blue)      result |= FOREGROUND_BLUE;
	if(intensity) result |= FOREGROUND_INTENSITY;
	return result;
}

static void clear_rect(HANDLE f, SMALL_RECT *rect)
{
	COORD buf_size = {
		.X = rect->Right - rect->Left + 1,
		.Y = rect->Bottom - rect->Top + 1};
	size_t sizeof_buf = buf_size.X * buf_size.Y * sizeof(CHAR_INFO);
	CHAR_INFO *buf = malloc(sizeof_buf);
	if(buf == NULL) caml_raise_out_of_memory();
	memset(buf, 0, sizeof_buf);
	WriteConsoleOutput(f, buf, buf_size, (COORD){.X = 0, .Y = 0}, rect);
	free(buf);
}

static void set_cursor_visible(HANDLE f, bool flag)
{
	CONSOLE_CURSOR_INFO info;
	GetConsoleCursorInfo(f, &info);
	info.bVisible = flag;
	SetConsoleCursorInfo(f, &info);
}

static void set_wrap(HANDLE f, bool flag)
{
	DWORD mode;
	GetConsoleMode(f, &mode);
	if(flag){
		mode |= ENABLE_WRAP_AT_EOL_OUTPUT;
	}else{
		mode &= ~ENABLE_WRAP_AT_EOL_OUTPUT;
	}
	SetConsoleMode(f, mode);
}

static value key(value *var, int k, unsigned s, char c)
{
	if(*var == 0){
		char buf[256];
		if(k == 1 && s == 1){
			wsprintf(buf, "\x1b[%c", c);
		}else{
			wsprintf(buf, "\x1b[%d;%d%c", k, s, c);
		}
		caml_register_global_root(var);
		*var = caml_copy_string(buf);
	}
	return *var;
}

#define SS_MAX 8

static value vk_up[SS_MAX];
static value vk_down[SS_MAX];
static value vk_right[SS_MAX];
static value vk_left[SS_MAX];
static value vk_home[SS_MAX];
static value vk_end[SS_MAX];
static value vk_insert[SS_MAX];
static value vk_delete[SS_MAX];
static value vk_pageup[SS_MAX];
static value vk_pagedown[SS_MAX];
static value vk_f1[SS_MAX];
static value vk_f2[SS_MAX];
static value vk_f3[SS_MAX];
static value vk_f4[SS_MAX];
static value vk_f5[SS_MAX];
static value vk_f6[SS_MAX];
static value vk_f7[SS_MAX];
static value vk_f8[SS_MAX];
static value vk_f9[SS_MAX];
static value vk_f10[SS_MAX];
static value vk_f11[SS_MAX];
static value vk_f12[SS_MAX];

#else

#include <errno.h>
#include <math.h>
#include <stdio.h>
#include <signal.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/select.h>

#if defined(__gnu_linux__)

static void *reallocf(void *ptr, size_t size)
{
	void *result;
	result = realloc(ptr, size);
	if(result == NULL && size > 0){
		free(ptr);
	}
	return result;
}

#endif

#undef stdin
#undef stdout
#undef stderr
#define stdin 0
#define stdout 1
#define stderr 2

typedef int handle_t;

static int handle_of_descr(value x)
{
	return Int_val(x);
}

static bool sigwinch_installed = false;
static volatile bool resized = false;

static void sigwinch_handler(__attribute__((unused)) int sig)
{
	resized = true;
}

static void install_sigwinch(void)
{
	if(!sigwinch_installed){
		struct sigaction sa;
		sigwinch_installed = true;
		sigemptyset(&sa.sa_mask);
		sa.sa_flags = SA_RESTART;
		sa.sa_handler = sigwinch_handler;
		sigaction(SIGWINCH, &sa, NULL);
	}
}

static void set_restart_on_sigwinch(bool restart)
{
	struct sigaction sa;
	sigemptyset(&sa.sa_mask);
	sa.sa_flags = restart ? SA_RESTART : 0;
	sa.sa_handler = sigwinch_handler;
	sigaction(SIGWINCH, &sa, NULL);
}

static void get_size(int fd, int *width, int *height)
{
	/* Have it to write (fd, "\x1b[18t", 5); and receive "\x1b[8;W;Ht" ? */
	bool failed;
	struct winsize win;
	failed = ioctl(fd, TIOCGWINSZ, &win) < 0;
	if(failed){
		failwith("mlterminal(ioctl, failed to get size)");
	}
	*width = win.ws_col;
	*height = win.ws_row;
}

static void set_size(int fd, int width, int height)
{
	char buf[256];
	int len;
	len = snprintf(buf, 256, "\x1b[8;%d;%dt", height, width);
	write(fd, buf, len); /* for Terminal.app, also xterm can accept this */
}

static int system_16(int red, int green, int blue, int intensity)
{
	int result = 0;
	if(red)       result |= 1;
	if(green)     result |= 2;
	if(blue)      result |= 4;
	if(intensity) result |= 8;
	return result;
}

static bool supports_256_result;
static bool supports_256_result_initialized = false;

static bool supports_256(void)
{
	if(!supports_256_result_initialized){
		char const *p = getenv("TERM");
		supports_256_result = p && strcmp(p, "xterm-256color") == 0;
		supports_256_result_initialized = true;
	}
	return supports_256_result;
}

static int rgb_scale(float s)
{
	/* These constants are derived from xterm. */
	double const t4 = 0xd7 / 255.0;
	double const t3 = 0xaf / 255.0;
	double const t2 = 0x87 / 255.0;
	double const t1 = 0x5f / 255.0;
	int result;
	if(s >= (t4 + 1.0) / 2.0){
		result = 5;
	}else if(s >= (t3 + t4) / 2.0){
		result = 4;
	}else if(s >= (t2 + t3) / 2.0){
		result = 3;
	}else if(s >= (t1 + t2) / 2.0){
		result = 2;
	}else if(s >= t1 / 2.0){
		result = 1;
	}else{
		result = 0;
	}
	return result;
}

static bool current_cursor_visible = true;

static void set_cursor_visible(int fd, bool flag)
{
	if(flag){
		/* write(f, "\x1b[>5l", 5); */
		write(fd, "\x1b[?25h", 6); /* for Terminal.app, xterm can accept this */
	}else{
		/* write(f, "\x1b[>5h", 5); */
		write(fd, "\x1b[?25l", 6);
	}
	current_cursor_visible = flag;
}

static bool current_wrap = true;

static void set_wrap(int fd, bool flag)
{
	if(flag){
		write(fd, "\x1b[7h", 4);
	}else{
		write(fd, "\x1b[7l", 4);
	}
	current_wrap = flag;
}

static bool is_empty(int fd)
{
	bool result;
	struct timeval zero_time = {.tv_sec = 0, .tv_usec = 0};
	fd_set fds_r, fds_w, fds_e;
	FD_ZERO(&fds_r);
	FD_SET(fd, &fds_r);
	FD_ZERO(&fds_w);
	FD_ZERO(&fds_e);
	if(select(fd + 1, &fds_r, &fds_w, &fds_e, &zero_time) < 0){
		failwith("mlterminal(select, failed to check for reading)");
	}else{
		result = !FD_ISSET(fd, &fds_r);
	}
	return result;
}

static bool current_mouse_mode = false;

static void set_mouse_mode(int fd, bool flag)
{
	if(flag){
		write(fd, "\x1b[?1000h", 8);
	}else{
		write(fd, "\x1b[?1000l", 8);
	}
	current_mouse_mode = flag;
}

#endif

static int system_16_of_rgb(double red, double green, double blue)
{
	double const t3 = 0.75;
	double const t2 = 0.5;
	double const t1 = 0.25;
	int result;
	if(red >= t3 || green >= t3 || blue >= t3){
		int r = red >= t3;
		int g = green >= t3;
		int b = blue >= t3;
		result = system_16(r, g, b, 1);
	}else if(red >= t2 || green >= t2 || blue >= t2){
		int r = red >= t2;
		int g = green >= t2;
		int b = blue >= t2;
		result = system_16(r, g, b, 0);
	}else{
		int i = red >= t1 && green >= t1 && blue >= t1;
		result = system_16(0, 0, 0, i);
	}
	return result;
}

CAMLprim value mlterminal_title(value title, value closure)
{
	CAMLparam2(title, closure);
	CAMLlocal1(result);
#ifdef __WINNT__
	/* save */
	PWSTR old_title = get_title();
	/* set */
	SetConsoleTitle(String_val(title));
	/* callback */
	result = caml_callback_exn(closure, Val_unit);
	/* restore */
	SetConsoleTitleW(old_title);
	free(old_title);
#else
	if(!isatty(stdout)){
		failwith("mlterminal_title(stdout is not associated to terminal)");
	}
	/* save */
	write(stdout, "\x1b[22;2t", 7);
	/* set */
	write(stdout, "\x1b]2;", 4);
	write(stdout, String_val(title), caml_string_length(title));
	write(stdout, "\x07", 1);
	/* callback */
	result = caml_callback_exn(closure, Val_unit);
	/* restore */
	write(stdout, "\x1b[23;2t", 7);
#endif
	if(Is_exception_result(result)){
		caml_raise(Extract_exception(result));
	}
	CAMLreturn(result);
}

CAMLprim value mlterminal_title_utf8(value title, value closure)
{
	CAMLparam2(title, closure);
	CAMLlocal1(result);
#ifdef __WINNT__
	/* save */
	PWSTR old_title = get_title();
	/* set */
	size_t length = caml_string_length(title);
	PWSTR wide_title = malloc((length + 1) * sizeof(WCHAR));
	if(wide_title == NULL) caml_raise_out_of_memory();
	size_t wide_length = MultiByteToWideChar(
		CP_UTF8,
		0,
		String_val(title),
		length,
		wide_title,
		length);
	wide_title[wide_length] = L'\0';
	SetConsoleTitleW(wide_title);
	free(wide_title);
	/* callback */
	result = caml_callback_exn(closure, Val_unit);
	/* restore */
	SetConsoleTitleW(old_title);
	free(old_title);
#else
	result = mlterminal_title(title, closure);
#endif
	if(Is_exception_result(result)){
		caml_raise(Extract_exception(result));
	}
	CAMLreturn(result);
}

CAMLprim value mlterminal_system_16(
	value red,
	value green,
	value blue,
	value intensity)
{
	CAMLparam4(red, green, blue, intensity);
	int result =
		system_16(Int_val(red), Int_val(green), Int_val(blue), Int_val(intensity));
	CAMLreturn(Val_int(result));
}

CAMLprim value mlterminal_supports_256(value unit)
{
	CAMLparam1(unit);
	bool result;
#ifdef __WINNT__
	result = false;
#else
	result = supports_256();
#endif
	CAMLreturn(Val_bool(result));
}

CAMLprim value mlterminal_rgb(value red, value green, value blue)
{
	CAMLparam3(red, green, blue);
	int result;
	double r = Double_val(red);
	double g = Double_val(green);
	double b = Double_val(blue);
#ifdef __WINNT__
	result = system_16_of_rgb(r, g, b);
#else
	if(!supports_256()){
		result = system_16_of_rgb(r, g, b);
	}else{
		result = 16 + 36 * rgb_scale(r) + 6 * rgb_scale(g) + rgb_scale(b);
	}
#endif
	CAMLreturn(Val_int(result));
}

CAMLprim value mlterminal_grayscale(value scale)
{
	CAMLparam1(scale);
	int result;
	double s = Double_val(scale);
#ifdef __WINNT__
	result = system_16_of_rgb(s, s, s);
#else
	if(!supports_256()){
		result = system_16_of_rgb(s, s, s);
	}else{
		result = (int)floor(s * nextafter(250.0, 0.0) + 5.0) / 10 + 231;
		if(result < 232){
			result = 16; /* #000000 */
		}else if(result > 255){
			result = 231; /* #ffffff */
		}
	}
#endif
	CAMLreturn(Val_int(result));
}

CAMLprim value mlterminal_d_is_terminal(value out)
{
	CAMLparam1(out);
	CAMLlocal1(result);
	handle_t f = handle_of_descr(out);
#ifdef __WINNT__
	result = Val_bool(GetFileType(f) == FILE_TYPE_CHAR);
#else
	result = Val_bool(isatty(f));
#endif
	CAMLreturn(result);
}

CAMLprim value mlterminal_d_size(value out)
{
	CAMLparam1(out);
	CAMLlocal1(result);
	int w, h;
	handle_t f = handle_of_descr(out);
#ifdef __WINNT__
	install_window_input();
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(f, &info);
	w = info.dwSize.X;
	h = info.dwSize.Y;
#else
	install_sigwinch();
	get_size(f, &w, &h);
#endif
	result = caml_alloc_tuple(2);
	Field(result, 0) = Val_int(w);
	Field(result, 1) = Val_int(h);
	CAMLreturn(result);
}

CAMLprim value mlterminal_d_set_size(value out, value w, value h)
{
	CAMLparam3(out, w, h);
	handle_t f = handle_of_descr(out);
	int new_w, new_h;
	new_w = Int_val(w);
	new_h = Int_val(h);
#ifdef __WINNT__
	install_window_input();
	set_size(f, new_w, new_h, f);
#else
	install_sigwinch();
	set_size(f, new_w, new_h);
#endif
	CAMLreturn(Val_unit);
}

CAMLprim value mlterminal_d_view(value out)
{
	CAMLparam1(out);
	CAMLlocal1(result);
	int left, top, right, bottom;
	handle_t f = handle_of_descr(out);
#ifdef __WINNT__
	install_window_input();
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(f, &info);
	left = info.srWindow.Left;
	top = info.srWindow.Top;
	right = info.srWindow.Right;
	bottom = info.srWindow.Bottom;
#else
	install_sigwinch();
	int w, h;
	get_size(f, &w, &h);
	left = 0;
	top = 0;
	right = w - 1;
	bottom = h - 1;
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
	handle_t f = handle_of_descr(out);
#ifdef __WINNT__
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(f, &info);
	x = info.dwCursorPosition.X;
	y = info.dwCursorPosition.Y;
#else
	if(!isatty(stdin)){
		failwith("mlterminal_d_position(stdin is not associated to terminal)");
	}
	struct termios old_settings, new_settings;
	tcgetattr(stdin, &old_settings);
	new_settings = old_settings;
	new_settings.c_lflag &= ~(ECHO | ICANON);
	new_settings.c_cc[VMIN] = 1;
	new_settings.c_cc[VTIME] = 0;
	tcsetattr(stdin, TCSAFLUSH, &new_settings);
	write(f, "\x1b[6n", 4);
	char buf[256];
	int i = 0;
	while(read(stdin, &buf[i], 1) == 1){
		if(i == 0){
			if(buf[i] == '\x1b'){
				++i;
			}
		}else{
			if(i >= 255 || buf[i] == 'R') break;
			++i;
		}
	}
	tcsetattr(stdin, TCSANOW, &old_settings);
	if(sscanf(buf, "\x1b[%d;%dR", &y, &x) != 2){
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
	handle_t f = handle_of_descr(out);
#ifdef __WINNT__
	SetConsoleCursorPosition(f, (COORD){
		.X = Int_val(x),
		.Y = Int_val(y)});
#else
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
	handle_t f = handle_of_descr(out);
#ifdef __WINNT__
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(f, &info);
	SetConsoleCursorPosition(f, (COORD){
		.X = info.dwCursorPosition.X + Int_val(x),
		.Y = info.dwCursorPosition.Y + Int_val(y)});
#else
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

CAMLprim value mlterminal_d_move_to_bol(value out, value unit)
{
	CAMLparam2(out, unit);
	handle_t f = handle_of_descr(out);
#ifdef __WINNT__
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(f, &info);
	SetConsoleCursorPosition(f, (COORD){
		.X = 0,
		.Y = info.dwCursorPosition.Y});
#else
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
	handle_t f = handle_of_descr(out);
#ifdef __WINNT__
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(f, &info);
	WORD attributes = info.wAttributes;
	if(!default_attributes_initialized){
		default_attributes_initialized = true;
		default_attributes = attributes;
	}
	if(Is_block(reset) && Bool_val(Field(reset, 0))){
		attributes = default_attributes;
	}
	if(Is_block(foreground)){
		attributes &= ~0x0f;
		attributes |= Int_val(Field(foreground, 0));
	}
	if(Is_block(background)){
		attributes &= ~0xf0;
		attributes |= Int_val(Field(background, 0)) << 4;
	}
	if(Is_block(reverse) && Bool_val(Field(reverse, 0))){
		attributes = ((attributes & 0x0f) << 4) | ((attributes & 0xf0) >> 4);
	}
	if(Is_block(concealed) && Bool_val(Field(concealed, 0))){
		attributes &= ~0x0f;
		attributes |= (attributes & 0xf0) >> 4;
	}
	SetConsoleTextAttribute(f, attributes);
#else
	char buf[256];
	int i = 0;
	buf[i++] = '\x1b';
	buf[i++] = '[';
	if(Is_block(reset) && Bool_val(Field(reset, 0))){
		buf[i++] = '0';
	}
	if(Is_block(bold) && Bool_val(Field(bold, 0))){
		if(i > 2) buf[i++] = ';';
		buf[i++] = '1';
	}
	if(Is_block(underscore) && Bool_val(Field(underscore, 0))){
		if(i > 2) buf[i++] = ';';
		buf[i++] = '4';
	}
	if(Is_block(blink) && Bool_val(Field(blink, 0))){
		if(i > 2) buf[i++] = ';';
		buf[i++] = '5';
	}
	if(Is_block(reverse) && Bool_val(Field(reverse, 0))){
		if(i > 2) buf[i++] = ';';
		buf[i++] = '7';
	}
	if(Is_block(concealed) && Bool_val(Field(concealed, 0))){
		if(i > 2) buf[i++] = ';';
		buf[i++] = '8';
	}
	if(Is_block(foreground)){
		if(i > 2) buf[i++] = ';';
		int fg = Int_val(Field(foreground, 0));
		if(fg >= 16){
			/* 256 color */
			i += snprintf(buf + i, 256 - i, "38;5;%d", fg);
		}else{
			/* system color */
			if((fg & 8) == 0){
				buf[i++] = '3';
			}else{
				buf[i++] = '9';
			}
			buf[i++] = '0' + (fg & 7);
		}
	}
	if(Is_block(background)){
		if(i > 2) buf[i++] = ';';
		int bg = Int_val(Field(background, 0));
		if(bg >= 16){
			/* 256 color */
			i += snprintf(buf + i, 256 - i, "48;5;%d", bg);
		}else{
			/* system color */
			if((bg & 8) == 0){
				buf[i++] = '4';
			}else{
				buf[i++] = '1';
				buf[i++] = '0';
			}
			buf[i++] = '0' + (bg & 7);
		}
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

CAMLprim value mlterminal_d_save(value out, value closure)
{
	CAMLparam2(out, closure);
	CAMLlocal1(result);
	handle_t f = handle_of_descr(out);
#ifdef __WINNT__
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(f, &info);
	result = caml_callback_exn(closure, Val_unit);
	SetConsoleCursorPosition(f, (COORD){
		.X = info.dwCursorPosition.X,
		.Y = info.dwCursorPosition.Y});
	SetConsoleTextAttribute(f, info.wAttributes);
#else
	/* write(f, "\x1b[s", 3); */
	write(f, "\x1b""7", 2);
	result = caml_callback_exn(closure, Val_unit);
	/* write(f, "\x1b[u", 3); */
	write(f, "\x1b""8", 2);
#endif
	if(Is_exception_result(result)){
		caml_raise(Extract_exception(result));
	}
	CAMLreturn(result);
}

CAMLprim value mlterminal_d_clear_screen(value out, value unit)
{
	CAMLparam2(out, unit);
	handle_t f = handle_of_descr(out);
#ifdef __WINNT__
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(f, &info);
	clear_rect(f, &(SMALL_RECT){
		.Left = 0,
		.Top = 0,
		.Right = info.dwSize.X - 1,
		.Bottom = info.dwSize.Y - 1});
#else
	write(f, "\x1b[2J", 4);
#endif
	CAMLreturn(Val_unit);
}

CAMLprim value mlterminal_d_clear_eol(value out, value unit)
{
	CAMLparam2(out, unit);
	handle_t f = handle_of_descr(out);
#ifdef __WINNT__
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(f, &info);
	clear_rect(f, &(SMALL_RECT){
		.Left = info.dwCursorPosition.X,
		.Top = info.dwCursorPosition.Y,
		.Right = info.dwSize.X - 1,
		.Bottom = info.dwCursorPosition.Y});
#else
	write(f, "\x1b[K", 3);
#endif
	CAMLreturn(Val_unit);
}

CAMLprim value mlterminal_d_scroll(value out, value y)
{
	CAMLparam2(out, y);
	handle_t f = handle_of_descr(out);
#ifdef __WINNT__
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
	int off_y = Int_val(y);
	char buf[256];
	int len;
	if(off_y > 0){
#if defined(__APPLE__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ < 1070
		int i;
		int w, h;
		get_size(f, &w, &h);
		len = snprintf(buf, 256, "\x1b[%d;0H", h);
		write(f, buf, len);
		for(i = 0; i < off_y; ++i){
			write(f, "\x1b" "D", 2);
		}
#else
		len = snprintf(buf, 256, "\x1b[%dS", off_y);
		write(f, buf, len);
#endif
	}else if(off_y < 0){
#if defined(__APPLE__) && __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ < 1070
		int i;
		write(f, "\x1b[0;0H", 6);
		for(i = 0; i > off_y; --i){
			write(f, "\x1bM", 2);
		}
#else
		len = snprintf(buf, 256, "\x1b[%dT", -off_y);
		write(f, buf, len);
#endif
	}
#endif
	CAMLreturn(Val_unit);
}

CAMLprim value mlterminal_d_show_cursor(value out, value visible)
{
	CAMLparam2(out, visible);
	handle_t f = handle_of_descr(out);
	set_cursor_visible(f, Bool_val(visible));
	CAMLreturn(Val_unit);
}

CAMLprim value mlterminal_d_wrap(value out, value enabled)
{
	CAMLparam2(out, enabled);
	handle_t f = handle_of_descr(out);
	set_wrap(f, Bool_val(enabled));
	CAMLreturn(Val_unit);
}

CAMLprim value mlterminal_d_screen(
	value out,
	value size,
	value cursor,
	value wrap,
	value closure)
{
	CAMLparam5(out, size, cursor, wrap, closure);
	CAMLlocal2(result, new_out);
	handle_t f = handle_of_descr(out);
#ifdef __WINNT__
	HANDLE new_f = CreateConsoleScreenBuffer(
		GENERIC_READ | GENERIC_WRITE,
		0,
		NULL,
		CONSOLE_TEXTMODE_BUFFER,
		NULL);
	if(Is_block(size)){
		install_window_input();
		value s = Field(size, 0);
		int new_w = Int_val(Field(s, 0));
		int new_h = Int_val(Field(s, 1));
		set_size(new_f, new_w, new_h, f);
	}
	if(Is_block(cursor)){
		set_cursor_visible(new_f, Bool_val(Field(cursor, 0)));
	}
	if(Is_block(wrap)){
		set_wrap(new_f, Bool_val(Field(wrap, 0)));
	}
	SetConsoleActiveScreenBuffer(new_f);
	new_out = win_alloc_handle(new_f);
	result = caml_callback_exn(closure, new_out);
	SetConsoleActiveScreenBuffer(f);
	CloseHandle(new_f);
#else
	bool pred_cursor_visible = current_cursor_visible;
	bool pred_wrap = current_wrap;
	write(f, "\x1b""7\x1b[?47h", 8); /* enter_ca_mode */
	int old_w, old_h;
	if(Is_block(size)){
		install_sigwinch();
		value s = Field(size, 0);
		get_size(f, &old_w, &old_h);
		int new_w, new_h;
		new_w = Int_val(Field(s, 0));
		new_h = Int_val(Field(s, 1));
		set_size(f, new_w, new_h);
	}
	if(Is_block(cursor)){
		set_cursor_visible(f, Bool_val(Field(cursor, 0)));
	}
	if(Is_block(wrap)){
		set_wrap(f, Bool_val(Field(wrap, 0)));
	}
	new_out = out;
	result = caml_callback_exn(closure, new_out);
	if(current_wrap != pred_wrap){
		set_wrap(f, pred_wrap);
	}
	if(current_cursor_visible != pred_cursor_visible){
		set_cursor_visible(f, pred_cursor_visible);
	}
	if(Is_block(size)){
		set_size(f, old_w, old_h);
	}
	write(f, "\x1b""[2J\x1b[?47l\x1b""8", 12); /* exit_ca_mode */
#endif
	if(Is_exception_result(result)){
		caml_raise(Extract_exception(result));
	}
	CAMLreturn(result);
}

CAMLprim value mlterminal_d_output_substring_utf8(
	value out,
	value s,
	value pos,
	value len)
{
	CAMLparam4(out, s, pos, len);
	handle_t f = handle_of_descr(out);
#ifdef __WINNT__
	size_t length = Int_val(len);
	PWSTR wide_s = malloc((length + 1) * sizeof(WCHAR));
	if(wide_s == NULL) caml_raise_out_of_memory();
	char *p = String_val(s) + Int_val(pos);
	size_t wide_length = MultiByteToWideChar(
		CP_UTF8,
		0,
		p,
		length,
		wide_s,
		length);
	DWORD w;
	bool failed = !WriteConsoleW(f, wide_s, wide_length, &w, NULL);
	free(wide_s);
	if(failed){
		if(!WriteFile(f, p, length, &w, NULL) || w != length){
			failwith("mlterminal_d_output_utf8");
		}
	}
#else
	write(f, String_val(s) + Int_val(pos), Int_val(len));
#endif
	CAMLreturn(Val_unit);
}

CAMLprim value mlterminal_d_output_newline(value out, value unit)
{
	CAMLparam2(out, unit);
	handle_t f = handle_of_descr(out);
#ifdef __WINNT__
	DWORD w;
	if(!WriteFile(f, "\r\n", 2, &w, NULL) || w != 2){
		failwith("mlterminal_d_output_newline");
	}
#else
	write(f, "\n", 1);
#endif
	CAMLreturn(Val_unit);
}

CAMLprim value mlterminal_d_mode(
	value in,
	value echo,
	value canonical,
	value ctrl_c,
	value mouse,
	value closure)
{
	CAMLparam5(in, echo, canonical, ctrl_c, mouse);
	CAMLxparam1(closure);
	CAMLlocal1(result);
	handle_t f = handle_of_descr(in);
#ifdef __WINNT__
	DWORD old_mode, new_mode;
	if(!GetConsoleMode(f, &old_mode)){
		failwith("mlterminal_d_mode(GetConsoleMode)");
	}
	new_mode = old_mode;
	if(Is_block(echo)){
		if(Bool_val(Field(echo, 0))){
			new_mode |= ENABLE_ECHO_INPUT;
		}else{
			new_mode &= ~ENABLE_ECHO_INPUT;
		}
	}
	if(Is_block(canonical)){
		if(Bool_val(Field(canonical, 0))){
			new_mode |= ENABLE_LINE_INPUT;
		}else{
			new_mode &= ~ENABLE_LINE_INPUT;
		}
	}
	if(Is_block(ctrl_c)){
		if(Bool_val(Field(ctrl_c, 0))){
			new_mode |= ENABLE_PROCESSED_INPUT;
		}else{
			new_mode &= ~ENABLE_PROCESSED_INPUT;
		}
	}
	if(Is_block(mouse)){
		if(Bool_val(Field(mouse, 0))){
			new_mode |= ENABLE_MOUSE_INPUT;
		}else{
			new_mode &= ~ENABLE_MOUSE_INPUT;
		}
	}
	SetConsoleMode(f, new_mode);
	result = caml_callback_exn(closure, Val_unit);
	SetConsoleMode(f, old_mode);
#else
	bool pred_mouse_mode = current_mouse_mode;
	struct termios old_settings, new_settings;
	if(tcgetattr(f, &old_settings) < 0){
		failwith("mlterminal_d_mode(tcgetattr)");
	}
	new_settings = old_settings;
	if(Is_block(echo)){
		if(Bool_val(Field(echo, 0))){
			new_settings.c_lflag |= ECHO;
		}else{
			new_settings.c_lflag &= ~ECHO;
		}
	}
	if(Is_block(canonical)){
		if(Bool_val(Field(canonical, 0))){
			new_settings.c_lflag |= ICANON;
		}else{
			new_settings.c_lflag &= ~ICANON;
			/* new_settings.c_cc[VMIN] = 1; */
			/* new_settings.c_cc[VTIME] = 0; */
		}
	}
	if(Is_block(ctrl_c)){
		if(Bool_val(Field(ctrl_c, 0))){
			new_settings.c_lflag |= ISIG;
		}else{
			new_settings.c_lflag &= ~ISIG;
		}
	}
	tcsetattr(f, TCSAFLUSH, &new_settings);
	if(Is_block(mouse)){
		if(!isatty(stdout)){
			failwith("mlterminal_d_mode(stdout is not associated to terminal)");
		}
		set_mouse_mode(stdout, Bool_val(Field(mouse, 0)));
	}
	result = caml_callback_exn(closure, Val_unit);
	if(current_mouse_mode != pred_mouse_mode){
		set_mouse_mode(0, pred_mouse_mode);
	}
	tcsetattr(f, TCSANOW, &old_settings);
#endif
	if(Is_exception_result(result)){
		caml_raise(Extract_exception(result));
	}
	CAMLreturn(result);
}

CAMLprim value mlterminal_d_mode_byte(
	value *argv,
	__attribute__((unused)) int n)
{
	return mlterminal_d_mode(
		argv[0],
		argv[1],
		argv[2],
		argv[3],
		argv[4],
		argv[5]);
}

CAMLprim value mlterminal_d_input_line_utf8(value in)
{
	CAMLparam1(in);
	CAMLlocal1(result);
	handle_t f = handle_of_descr(in);
#ifdef __WINNT__
	size_t max_length;
	size_t length;
	char *buf;
	size_t wide_max_length = 256;
	size_t wide_length = 0;
	WCHAR *wide_buf = malloc(wide_max_length * sizeof(WCHAR));
	if(wide_buf == NULL) caml_raise_out_of_memory();
	for(;;){
		WCHAR *p = wide_buf + wide_length;
		DWORD r;
		caml_enter_blocking_section();
		bool succeeded = ReadConsoleW(f, p, 1, &r, NULL);
		caml_leave_blocking_section();
		if(!succeeded){
			free(wide_buf);
			if(wide_length == 0){
				/* redirected */
				max_length = 256;
				length = 0;
				buf = malloc(max_length);
				if(buf == NULL) caml_raise_out_of_memory();
				for(;;){
					char *p = buf + length;
					DWORD r;
					caml_enter_blocking_section();
					bool succeeded = ReadFile(f, p, 1, &r, NULL);
					caml_leave_blocking_section();
					if(!succeeded){
						free(buf);
						failwith("mlterminal_d_input_line_utf8");
					}
					if(r <= 0){
						free(buf);
						caml_raise_end_of_file();
					}else if(*p == '\n'){
						if(length > 0 && *(p - 1) == '\r') --length;
						break;
					}
					++ length;
					if(length >= max_length){
						max_length *= 2;
						char *new_buf = realloc(buf, max_length);
						if(new_buf == NULL){
							free(buf);
							caml_raise_out_of_memory();
						}
						buf = new_buf;
					}
				}
				break; /* for */
			}
			failwith("mlterminal_d_input_line_utf8");
		}
		if(r <= 0){
			free(wide_buf);
			caml_raise_end_of_file();
		}else if(*p == '\n'){
			if(wide_length > 0 && *(p - 1) == '\r') --wide_length;
			/* succeeded */
			max_length = wide_length * 6;
			buf = malloc(max_length + 1);
			length = WideCharToMultiByte(
				CP_UTF8,
				0,
				wide_buf,
				wide_length,
				buf,
				max_length,
				NULL,
				NULL);
			free(wide_buf);
			break; /* for */
		}
		++ wide_length;
		if(wide_length >= wide_max_length){
			wide_max_length *= 2;
			WCHAR *new_buf = realloc(wide_buf, wide_max_length * sizeof(WCHAR));
			if(new_buf == NULL){
				free(wide_buf);
				caml_raise_out_of_memory();
			}
			wide_buf = new_buf;
		}
	}
	result = caml_alloc_string(length);
	memcpy(String_val(result), buf, length);
	free(buf);
#else
	size_t max_length = 256;
	size_t length = 0;
	char *buf = malloc(max_length);
	if(buf == NULL) caml_raise_out_of_memory();
	for(;;){
		char *p = buf + length;
		caml_enter_blocking_section();
		ssize_t r = read(f, p, 1);
		caml_leave_blocking_section();
		if(r < 0){
			free(buf);
			failwith("mlterminal_d_input_line_utf8");
		}else if(r == 0){
			free(buf);
			caml_raise_end_of_file();
		}else if(*p == '\n'){
			break;
		}
		++ length;
		if(length >= max_length){
			max_length *= 2;
			buf = reallocf(buf, max_length);
			if(buf == NULL) caml_raise_out_of_memory();
		}
	}
	result = caml_alloc_string(length);
	memcpy(String_val(result), buf, length);
	free(buf);
#endif
	CAMLreturn(result);
}

CAMLprim value mlterminal_d_is_empty(value in)
{
	CAMLparam1(in);
	CAMLlocal1(result);
	handle_t f = handle_of_descr(in);
#ifdef __WINNT__
	INPUT_RECORD input_record;
	DWORD r;
	bool completed = false;
	do{
		if(!PeekConsoleInputW(f, &input_record, 1, &r)){
			failwith("mlterminal_d_is_empty(PeekConsoleInputW)");
		}else if(r == 0){
			result = Val_bool(true);
			completed = true;
		}else{
			switch(input_record.EventType){
			case KEY_EVENT:
				if(input_record.Event.KeyEvent.bKeyDown){
					result = Val_bool(false);
					completed = true;
				}
				break;
			case MOUSE_EVENT:
			case WINDOW_BUFFER_SIZE_EVENT:
				result = Val_bool(false);
				completed = true;
				break;
			default:
				; /* will skip */
			}
			if(!completed){
				/* skip */
				ReadConsoleInputW(f, &input_record, 1, &r);
			}
		}
	}while(!completed);
#else
	result = Val_bool(!resized && is_empty(f));
#endif
	CAMLreturn(result);
}

CAMLprim value mlterminal_d_input_event(value in)
{
	CAMLparam1(in);
	CAMLlocal1(result);
	handle_t f = handle_of_descr(in);
#ifdef __WINNT__
	INPUT_RECORD input_record;
	DWORD r;
	char buf[256];
	bool completed = false;
	do{
		caml_enter_blocking_section();
		bool succeeded = ReadConsoleInputW(f, &input_record, 1, &r);
		caml_leave_blocking_section();
		if(!succeeded){
			failwith("mlterminal_d_input_event(ReadConsoleInputW)");
		}else if(r == 0){
			caml_raise_end_of_file(); /* ??? */
		}else{
			PKEY_EVENT_RECORD k;
			PMOUSE_EVENT_RECORD m;
			PWINDOW_BUFFER_SIZE_RECORD w;
			switch(input_record.EventType){
			case KEY_EVENT:
				k = &input_record.Event.KeyEvent;
				if(k->bKeyDown){
					if(k->uChar.UnicodeChar != '\0'){
						char buf[7];
						int length = WideCharToMultiByte(
							CP_UTF8,
							0,
							&k->uChar.UnicodeChar,
							1,
							buf,
							7,
							NULL,
							NULL);
						buf[length] = '\0';
						result = caml_copy_string(buf);
					}else{
						int index = 0;
						unsigned s = 1; /* shift state */
						if(k->dwControlKeyState & SHIFT_PRESSED){
							index |= 1;
							s += 1;
						}
						if(k->dwControlKeyState
							& (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED))
						{
							index |= 2;
							s += 4;
						}
						if(k->dwControlKeyState
							& (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED))
						{
							index |= 4;
							s += 8;
						}
						if(k->dwControlKeyState & ENHANCED_KEY){
							/* enhanced key */
							switch(k->wVirtualKeyCode){
							case VK_UP:
								result = key(&vk_up[index], 1, s, 'A');
								break;
							case VK_DOWN:
								result = key(&vk_down[index], 1, s, 'B');
								break;
							case VK_RIGHT:
								result = key(&vk_right[index], 1, s, 'C');
								break;
							case VK_LEFT:
								result = key(&vk_left[index], 1, s, 'D');
								break;
							case VK_HOME:
								result = key(&vk_home[index], 1, s, 'H');
								break;
							case VK_END:
								result = key(&vk_end[index], 1, s, 'F');
								break;
							case VK_INSERT:
								result = key(&vk_insert[index], 2, s, '~');
								break;
							case VK_DELETE:
								result = key(&vk_delete[index], 3, s, '~');
								break;
							case VK_PRIOR:
								result = key(&vk_pageup[index], 5, s, '~');
								break;
							case VK_NEXT:
								result = key(&vk_pagedown[index], 6, s, '~');
								break;
							default:
								/* "\x1b[...Vk" is fictitious escape sequence */
								wsprintf(buf, "\x1b[%d;%dVk", k->wVirtualKeyCode,
									s + 0x100); /* ENHANCED_KEY = 0x100 */
								result = caml_copy_string(buf);
							}
						}else{
							switch(k->wVirtualKeyCode){
							case VK_F1:
								result = key(&vk_f1[index], 11, s, '~');
								break;
							case VK_F2:
								result = key(&vk_f2[index], 12, s, '~');
								break;
							case VK_F3:
								result = key(&vk_f3[index], 13, s, '~');
								break;
							case VK_F4:
								result = key(&vk_f4[index], 14, s, '~');
								break;
							case VK_F5:
								result = key(&vk_f5[index], 15, s, '~');
								break;
							case VK_F6:
								result = key(&vk_f6[index], 17, s, '~');
								break;
							case VK_F7:
								result = key(&vk_f7[index], 18, s, '~');
								break;
							case VK_F8:
								result = key(&vk_f8[index], 19, s, '~');
								break;
							case VK_F9:
								result = key(&vk_f9[index], 20, s, '~');
								break;
							case VK_F10:
								result = key(&vk_f10[index], 21, s, '~');
								break;
							case VK_F11:
								result = key(&vk_f11[index], 23, s, '~');
								break;
							case VK_F12:
								result = key(&vk_f12[index], 24, s, '~');
								break;
							default:
								/* "\x1b[...Vk" is fictitious escape sequence */
								wsprintf(buf, "\x1b[%d;%dVk", k->wVirtualKeyCode, s);
								result = caml_copy_string(buf);
							}
						}
					}
					completed = true;
				}
				break;
			case MOUSE_EVENT:
				m = &input_record.Event.MouseEvent;
				unsigned char s = 0x43; /* unknown */
				if(m->dwEventFlags == 0 || m->dwEventFlags == DOUBLE_CLICK){
					if(m->dwButtonState == 0){
						s = 0x03; /* released */
					}else if(m->dwButtonState & FROM_LEFT_1ST_BUTTON_PRESSED){
						s = 0x00;
					}else if(m->dwButtonState & RIGHTMOST_BUTTON_PRESSED){
						s = 0x01;
					}else if(m->dwButtonState & FROM_LEFT_2ND_BUTTON_PRESSED){
						s = 0x02;
					}
				}else if(m->dwEventFlags == MOUSE_WHEELED){
					if(m->dwButtonState & (1 << 31)){
						s = 0x40; /* up */
					}else{
						s = 0x41; /* down */
					}
				}
				if(m->dwControlKeyState & SHIFT_PRESSED){
					s |= 0x04;
				}
				if(m->dwControlKeyState
					& (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED))
				{
					s |= 0x10;
				}
				if(m->dwControlKeyState & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED)){
					s |= 0x08;
				}
				buf[0] = '\x1b';
				buf[1] = '[';
				buf[2] = 'M';
				buf[3] = s;
				buf[4] = m->dwMousePosition.X + 0x21;
				buf[5] = m->dwMousePosition.Y + 0x22;
				buf[6] = '\0';
				result = caml_copy_string(buf);
				completed = true;
				break;
			case WINDOW_BUFFER_SIZE_EVENT:
				w = &input_record.Event.WindowBufferSizeEvent;
				wsprintf(buf, "\x1b[8;%d;%dt", w->dwSize.Y, w->dwSize.X);
				result = caml_copy_string(buf);
				completed = true;
				break;
			default:
				; /* continue */
			}
		}
	}while(!completed);
#else
	char buf[256];
	int i = 0;
	bool handling_resized = resized;
	if(!handling_resized){
		enum {
			s_exit, s_init, s_escape, s_escape_param, s_escape_param_N,
			s_escape_mouse_1, s_escape_mouse_2, s_escape_mouse_3
		} state = s_init;
		do{
			bool break_on_sigwinch = i == 0 && sigwinch_installed;
			caml_enter_blocking_section();
			if(break_on_sigwinch) set_restart_on_sigwinch(false);
			ssize_t r = read(f, &buf[i], 1);
			if(break_on_sigwinch) set_restart_on_sigwinch(true);
			caml_leave_blocking_section();
			if(r < 0){
				if(errno == EINTR && break_on_sigwinch && resized){
					handling_resized = true;
					break; /* do */
				}
				failwith("mlterminal_d_input_event(read)");
			}else if(r == 0){
				if(state == s_init) caml_raise_end_of_file();
				state = s_exit;
			}else{
				char c = buf[i];
				++ i;
				switch(state){
				case s_init:
					switch(c){
					case '\x1b':
						if(is_empty(f)){
							state = s_exit; /* escape key */
						}else{
							state = s_escape;
						}
						break;
					default:
						state = s_exit;
					}
					break;
				case s_escape:
					switch(c){
					case 'O': case '[':
						state = s_escape_param;
						break;
					default:
						state = s_exit;
					}
					break;
				case s_escape_param:
					if(c == 'M'){
						state = s_escape_mouse_1;
						break;
					}
					state = s_escape_param_N; /* fall through */
				case s_escape_param_N:
					switch(c){
					case '0': case '1': case '2': case '3': case '4':
					case '5': case '6': case '7': case '8': case '9':
					case ';':
						/* keep state */
						if(i >= (ssize_t)(sizeof(buf) - 1)) state = s_exit;
						break;
					default:
						state = s_exit;
					}
					break;
				case s_escape_mouse_1:
				case s_escape_mouse_2:
					++ state;
					break;
				case s_escape_mouse_3:
				default:
					state = s_exit;
				}
			}
		}while(state != s_exit);
	}
	if(handling_resized){
		resized = false;
		if(!isatty(stdout)){
			failwith("mlterminal_d_input_event"
				"(stdout is not associated to terminal)");
		}
		int w, h;
		get_size(stdout, &w, &h);
		snprintf(buf, sizeof(buf), "\x1b[8;%d;%dt", h, w);
	}else{
		buf[i] = '\0';
	}
	result = caml_copy_string(buf);
#endif
	CAMLreturn(result);
}

CAMLprim value mlterminal_buffered_in(value ic)
{
	CAMLparam1(ic);
	struct channel *internal = Channel(ic);
	Lock(internal);
	size_t avail = internal->max - internal->curr;
	Unlock(internal);
	CAMLreturn(Val_long(avail));
}

CAMLprim value mlterminal_buffered_line_in(value ic)
{
	CAMLparam1(ic);
	struct channel *internal = Channel(ic);
	Lock(internal);
	size_t avail = Max_long; /* line is not terminated */
	char *p;
	for(p = internal->curr; p < internal->max; ++p){
		if(*p == '\n'){
			++p; /* including '\n' */
			avail = p - internal->curr;
			break;
		}
	}
	Unlock(internal);
	CAMLreturn(Val_long(avail));
}

CAMLprim value mlterminal_utf8_of_locale(value s)
{
	CAMLparam1(s);
	CAMLlocal1(result);
#ifdef __WINNT__
	char *mbcs_str = String_val(s);
	size_t mbcs_length = caml_string_length(s);
	size_t wide_max_length = mbcs_length; /* from DBCD to UTF-16 */
	PWSTR wide_str = malloc((wide_max_length + 1) * sizeof(WCHAR));
	if(wide_str == NULL) caml_raise_out_of_memory();
	size_t wide_length = MultiByteToWideChar(
		CP_ACP,
		0,
		mbcs_str,
		mbcs_length,
		wide_str,
		wide_max_length);
	size_t utf8_max_length = wide_length * 3; /* from UTF-16 to UTF-8 */
	char *utf8_str = malloc((utf8_max_length + 1));
	size_t utf8_length = WideCharToMultiByte(
		CP_UTF8,
		0,
		wide_str,
		wide_length,
		utf8_str,
		utf8_max_length,
		NULL,
		NULL);
	result = caml_alloc_string(utf8_length);
	memcpy(String_val(result), utf8_str, utf8_length);
	free(wide_str);
	free(utf8_str);
#else
	result = s;
#endif
	CAMLreturn(result);
}

CAMLprim value mlterminal_locale_of_utf8(value s)
{
	CAMLparam1(s);
	CAMLlocal1(result);
#ifdef __WINNT__
	char *utf8_str = String_val(s);
	size_t utf8_length = caml_string_length(s);
	size_t wide_max_length = utf8_length; /* from UTF-8 to UTF-16 */
	PWSTR wide_str = malloc((wide_max_length + 1) * sizeof(WCHAR));
	if(wide_str == NULL) caml_raise_out_of_memory();
	size_t wide_length = MultiByteToWideChar(
		CP_UTF8,
		0,
		utf8_str,
		utf8_length,
		wide_str,
		wide_max_length);
	size_t mbcs_max_length = wide_length * 2; /* from UTF-16 to DBCS */
	char *mbcs_str = malloc((mbcs_max_length + 1));
	size_t mbcs_length = WideCharToMultiByte(
		CP_ACP,
		0,
		wide_str,
		wide_length,
		mbcs_str,
		mbcs_max_length,
		NULL,
		NULL);
	result = caml_alloc_string(mbcs_length);
	memcpy(String_val(result), mbcs_str, mbcs_length);
	free(wide_str);
	free(mbcs_str);
#else
	result = s;
#endif
	CAMLreturn(result);
}
