/**
 * Consoleur: a package for interaction with character-oriented terminal emulators
 *
 * Copyright: Maxim Freck, 2017.
 * Authors:   Maxim Freck <maxim@freck.pp.ru>
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module consoleur.style.posix;
version(Posix) {

/// Color list
enum Color: uint
{
	//default 8 colors
	black = 0,
	maroon,
	green,
	olive,
	navy,
	purple,
	teal,
	silver,

	//light 8 colors
	grey = 8,
	red,
	lime,
	yellow,
	blue,
	fuchsia,
	aqua,
	white,

	grayscale1 = 232,
	grayscale2,
	grayscale3,
	grayscale4,
	grayscale5,
	grayscale6,
	grayscale7,
	grayscale8,
	grayscale9,
	grayscale10,
	grayscale11,
	grayscale12,
	grayscale13,
	grayscale14,
	grayscale15,
	grayscale16,
	grayscale17,
	grayscale18,
	grayscale19,
	grayscale20,
	grayscale21,
	grayscale22,
	grayscale23,
	grayscale24
}

/// Font styles
enum Style: uint {
	none        = 0,
	bold        = 0b00000000_00000000_00000000_00000001,
	italic      = 0b00000000_00000000_00000000_00000010,
	underline   = 0b00000000_00000000_00000000_00000100,
	blink       = 0b00000000_00000000_00000000_00001000,
	inverted    = 0b00000000_00000000_00000000_00010000,
	linethrough = 0b00000000_00000000_00000000_00100000,
}


private Style style;
private uint fgColor = Color.white;
private uint bgColor = Color.black;

/*******
 * Sets default colors
 */
void setDefaultColors() @safe
{
	import std.stdio: write;
	write("\x1b[39m\x1b[49m");
}

/*******
 * Sets foreground color
 * Returns: true in case of success, otherwise false
 *
 * Params:
 *  c = The color (0-7 — default colors, 8-15 — bright colors)
 */
bool setFg(Color c) @safe
{
	import std.stdio: writef;

	if (c > 15) return false;
	fgColor = c;

	if (c > 7) {
		writef("\033[%u;1m", c+30-8);
	} else {
		writef("\033[%um", c+30);
	}

	return true;
}

/*******
 * Sets background color
 * Returns: true in case of success, otherwise false
 *
 * Params:
 *  c = The color (0-7 — default colors, 8-15 — bright colors)
 */
bool setBg(Color c) @safe
{
	import std.stdio: writef;

	if (c > 15) return false;
	bgColor = c;

	if (c > 7) {
		writef("\x1b[%u;1m", c+40-8);
	} else {
		writef("\x1b[%um", c+40);
	}

	return true;
}

/*******
 * Sets terminal colors
 * Returns: true in case of success, otherwise false
 *
 * Params:
 *  fgC = The foreground color
 *  bgC = The background color
 */
bool setColors(Color fgC, Color bgC) @safe
{
	return (setFg(fgC) && setBg(bgC));
}


/*******
 * Sets foreground color in a 256 color mode
 * Returns: true in case of success, otherwise false
 *
 * Params:
 *  c = The color
 */
bool setFg256(uint c) @safe
{
	import std.stdio: writef;

	if (c > 255) return false;

	fgColor = c;
	writef("\x1b[38;05;%um", c);

	return true;
}

/*******
 * Sets background color in a 256 color mode
 * Returns: true in case of success, otherwise false
 *
 * Params:
 *  c = The color
 */
bool setBg256(uint c) @safe
{
	import std.stdio: writef;

	if (c > 255) return false;

	bgColor = c;
	writef("\x1b[48;05;%um", c);

	return true;
}

/*******
 * Sets colors in a 256 color mode
 * Returns: true in case of success, otherwise false
 *
 * Params:
 *  fgC = The foreground color
 *  bgC = The background color
 */
bool setColors256(int fgC, int bgC) @safe
{
	return (setFg256(fgC) && setBg256(bgC));
}

/*******
 * Sets foreground color in a TrueColor mode
 * Returns: true in case of success, otherwise false
 *
 * Params:
 *  c = The color
 */
bool setFg24bit(uint c) @safe
{
	import std.stdio: writef;

	fgColor = c;
	writef("\x1b[38;2;%u;%u;%um", c.r, c.g, c.b);

	return true;
}

/*******
 * Sets background color in a TrueColor mode
 * Returns: true in case of success, otherwise false
 *
 * Params:
 *  c = The color
 */
bool setBg24bit(uint c) @safe
{
	import std.stdio: writef;

	bgColor = c;
	writef("\x1b[48;2;%u;%u;%um", c.r, c.g, c.b);

	return true;
}

/*******
 * Sets colors in a TrueColor mode
 * Returns: true in case of success, otherwise false
 *
 * Params:
 *  fgC = The foreground color
 *  bgC = The background color
 */
void setColors24bit(int fgC, int bgC) @safe
{
	setFg24bit(fgC);
	setBg24bit(bgC);
}


/*******
 * Builds color code for a TrueColor functions
 * Returns: uint representing the color code
 *
 * Params:
 *  r = red component
 *  g = green component
 *  b = blue component
 */
pragma(inline) nothrow uint rgb(uint r, uint g, uint b) @safe @nogc
{
	return ((r & 0xff) << 24 | (g & 0xff) << 16 | (b & 0xff) << 8);
}

pragma(inline) private nothrow uint r(uint src) @safe @nogc
{
	return (src & 0xff000000) >> 24;
}

pragma(inline) private nothrow uint g(uint src) @safe @nogc
{
	return (src & 0x00ff0000) >> 16;
}

pragma(inline) private nothrow uint b(uint src) @safe @nogc
{
	return (src & 0x0000ff00) >> 8;
}


/*******
 * Sets text styles (see enum Style)
 *
 * Params:
 *  s = The style
 */
void setStyle(Style s)
{
	import std.stdio: write;
	string esc;

	if (s == style) return;

	esc.check(s, Style.bold, "\x1b[1m", "\x1b[22m");
	esc.check(s, Style.italic, "\x1b[3m", "\x1b[23m");
	esc.check(s, Style.underline, "\x1b[4m", "\x1b[24m");
	esc.check(s, Style.blink, "\x1b[5m", "\x1b[25m");
	esc.check(s, Style.inverted, "\x1b[7m", "\x1b[27m");
	esc.check(s, Style.linethrough, "\x1b[9m", "\x1b[29m");

	style = s;

	write(esc);
}

pragma(inline) private void check(ref string str, Style s, Style st, string on, string off) @safe
{
	if ( (s & st) && !(style & st)) {
		str ~= on;
		style |= st;
	} else if (!(s & st) && (style & st)) {
		str ~=off;
		style &= ~st;
	}
}

}