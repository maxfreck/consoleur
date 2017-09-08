/**
 * Consoleur: a package for interaction with character-oriented terminal emulators
 *
 * Copyright: Maxim Freck, 2017.
 * Authors:   Maxim Freck <maxim@freck.pp.ru>
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module consoleur.cli.util;

/**
 * Removes last char from the utf-8 string
 *
 * Params:
 *  str = Source string
 *
 * Returns: string whithout last char
 */
string delchar(string str) @safe
{
	if (str[$-1] < 128) return str[0 .. $-1];

	foreach_reverse (n; 0 .. str.length) {
		if (str[n] < 0x80 || str[n] > 0xbf) return str[0 .. n];
	}

	return "";
}

/**
 * Params:
 *  str = string
 *
 * Returns: utf-8 string length in characters
 */
size_t utf8length(string str) @safe @nogc
{
	size_t len = 0;
	foreach(ubyte b; str) {
		if (b < 0x80 || b > 0xbf) len++;
	}
	return len;
}

/**
 * Repeats symbol `count` times
 *
 * Params:
 *  symbol = Symbol to repeat
 *  count  = Number of symbol repetitions
 *
 * Returns: a string containing `symbol` character a `count` times
 */
string repeat(wchar symbol, uint count) @safe
{
	string ret;
	foreach(_; 0..count) ret~=symbol;
	return ret;
}
