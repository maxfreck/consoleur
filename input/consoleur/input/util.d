/**
 * Consoleur: a package for interaction with character-oriented terminal emulators
 *
 * Copyright: Maxim Freck, 2017.
 * Authors:   Maxim Freck <maxim@freck.pp.ru>
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module consoleur.input.util;

import consoleur.core;
import consoleur.input.types;

/*******
 * Returns: UTF-8 codepoint length
 *
 * Params:
 *  src = The first byte of codepoint
 */
ubyte codepointLength(ubyte src) @safe
{
	if ((src & 0b11111100) == 0b11111100) return 6;
	if ((src & 0b11111000) == 0b11111000) return 5;
	if ((src & 0b11110000) == 0b11110000) return 4;
	if ((src & 0b11100000) == 0b11100000) return 3;
	if ((src & 0b11000000) == 0b11000000) return 2;
	if ((src & 0b10000000) == 0b10000000) return 1;
	return 0;
}

package Key readUtf8Char(Key ch) @safe
{
	foreach (size_t n; 1 .. ch.content.utf[0].codepointLength) {
		popStdin(ch.content.utf[n]);
	}
	return ch;
}

package string escapeString(string src) @trusted
{
	import std.format: format;
	string str;

	foreach (b; src) {
		if (b == 0x1b) {
			str ~= "⇇";
		} else if(b < 0x20) {
			str ~= cast(wchar)(b + 0x2400);
		} else if(b > 0x7e){
			str ~= format("\\x%x", b);
		} else {
			str ~= b;
		}
	}

	return str;
}
