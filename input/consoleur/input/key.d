/**
 * Consoleur: a package for interaction with character-oriented terminal emulators
 *
 * Copyright: Maxim Freck, 2017.
 * Authors:   Maxim Freck <maxim@freck.pp.ru>
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module consoleur.input.key;
version(Posix) {

import consoleur.core;
import consoleur.core.termparam;
import consoleur.terminfo;

public import consoleur.input.types;
import consoleur.input.util;

/*******
 * Synchronously reads Key from STDIN.
 * Returns: Key structure
 *
 * Params:
 *  escDelay = The escape key detection delay. The default value is -1,
 *             this means that the function always waits for two \x1b
 *             characters from STDIN.
 */
Key getKeyPressed(int escDelay = -1) @safe
{
	immutable tparam = setTermparam(Term.quiet|Term.raw);
	return processKeyPressed(escDelay);
}

/*******
 * Asynchronously reads Key from STDIN.
 * Returns: Key structure or Command.empty if STDIN is empty
 *
 * Params:
 *  escDelay = The escape key detection delay. The default value is -1,
 *             this means that the function always waits for two \x1b
 *             characters from STDIN.
 */
Key peekKeyPressed(int escDelay = -1) @safe
{
	immutable tparam = setTermparam(Term.quiet|Term.raw|Term.async);
	return processKeyPressed(escDelay);
}

private Key processKeyPressed(int escDelay) @safe
{
	ubyte b;

	if (!popStdin(b)) {
		return Key(KeyType.COMMAND, KeyValue(Command.empty));
	}

	if (b == 0x1b) {
		if (escDelay == -1) {
			immutable tparam = setTermparam(Term.quiet|Term.raw);
			popStdin(b);
		} else {
			immutable tparam = setTermparam(Term.quiet|Term.raw|Term.async, cast(ubyte)(escDelay));
			if (!popStdin(b)) return Key(KeyType.COMMAND, KeyValue(Command.escape));
		}

		pushStdin(b);

		return readCommandSequence();
	}

	version(WithSuperKey) {
		if (b == 0x18) {
			return readSuperKey();
		}
	}

	if (b > 128) {
		return readUtf8Char(Key(KeyType.UTF8, KeyValue(cast(ubyte[6])[b,0,0,0,0,0])));
	}

	if (b < 0x20 || b == 0x7f) {
		return Key(KeyType.COMMAND, KeyValue(cast(Command)b));
	}

	return Key(KeyType.ASCII, KeyValue(cast(char)b));
}

private Key readCommandSequence() @safe
{
	ubyte b;
	popStdin(b);

	if (b == 0x1b) {
		auto tparam = setTermparam(Term.quiet|Term.raw|Term.async, 0);

		if (!popStdin(b)) { //C0
			return Key(KeyType.COMMAND, KeyValue(cast(Command)0x1b));
		}

		if (b == 0x5b) { //alt + CSI
			tparam.restoreBack();
			auto key = mapSequence(readCsiSequence());
			key.modifier |= KeyModifier.alt;
			return key;
		}

		if (b == 0x4f) { //alt + SS3
			tparam.restoreBack();
			auto key = mapSequence(readSs3Sequence());
			key.modifier |= KeyModifier.alt;
			return key;
		}

		pushStdin(b);
		return Key(KeyType.COMMAND, KeyValue(cast(Command)0x1b));
	}

	if (b == 0x5b) {
		return mapSequence(readCsiSequence());
	}

	if (b == 0x4f) {
		return mapSequence(readSs3Sequence());
	}

	if (b < 0x20 || b == 0x7f) {
		return Key(KeyType.COMMAND, KeyValue(cast(Command)b), KeyModifier.alt);
	}

	if (b < 128) {
		return Key(KeyType.ASCII, KeyValue(b), KeyModifier.alt);
	}

	if (b > 128) {
		return readUtf8Char(Key(KeyType.UTF8, KeyValue(cast(ubyte[6])[b,0,0,0,0,0]), KeyModifier.alt));
	}

	return Key(KeyType.COMMAND, KeyValue(cast(Command)-1));
}

private Key mapSequence(string sequence) @safe
{
	auto cmd = (sequence in keyMap);
	if (cmd is null) return Key(KeyType.RAW, KeyValue(sequence));
	return *cmd;
}

private string readCsiSequence() @safe
{
	string csi;
	ubyte b;

	while (popStdin(b)) {
		csi~=b;
		if (b == 0x24 || (b >= 0x40 && b <= 0x7e && b != 0x5b)) break;
	}

	return "\x1b["~csi;
}

private string readSs3Sequence() @safe
{
	string ss3;
	ubyte b;

	while (popStdin(b)) {
		ss3 ~= b;
		if (b < 0x30 || b > 0x39) break;
	}

	return "\x1bO"~ss3;
}

version(WithSuperKey) {
	private Key readSuperKey() @safe
	{
		immutable tparam = setTermparam(Term.quiet|Term.raw|Term.async, 0);
		int modifier = KeyModifier.supr;
		ubyte b1, b2, b3;

		if (!popStdin(b1)) return Key(KeyType.COMMAND, KeyValue(cast(Command)0x18));
		if (b1 != 0x40) {
			pushStdin(b1);
			return Key(KeyType.COMMAND, KeyValue(cast(Command)0x18));
		}

		if (!popStdin(b2)) {
			pushStdin(b1);
			return Key(KeyType.COMMAND, KeyValue(cast(Command)0x18));
		}
		if (b2 != 0x73) {
			pushStdin(b1);
			pushStdin(b2);
			return Key(KeyType.COMMAND, KeyValue(cast(Command)0x18));
		}

		if (!popStdin(b3)) {
			pushStdin(b1);
			pushStdin(b2);
			return Key(KeyType.COMMAND, KeyValue(cast(Command)0x18));
		}

		if (b3 == 0x1b) {
			if (!popStdin(b3)) return Key(KeyType.COMMAND, KeyValue(cast(Command)b3), modifier);
			modifier |= KeyModifier.alt;
		}

		if (b3 < 0x20 || b3 == 0x7f) {
			return Key(KeyType.COMMAND, KeyValue(cast(Command)b3), modifier);
		}

		if (b3 > 128) {
			return readUtf8Char(Key(KeyType.UTF8, KeyValue(cast(ubyte[6])[b3,0,0,0,0,0]), modifier));
		}

		return Key(KeyType.ASCII, KeyValue(cast(char)b3), modifier);
	}
}


private Key readUtf8Char(Key ch) @safe
{
	foreach (size_t n; 1 .. ch.content.utf[0].codepointLength) {
		popStdin(ch.content.utf[n]);
	}
	return ch;
}

// ubyte codepointLength(ubyte src) @safe
// {
// 	if ((src & 0b11111100) == 0b11111100) return 6;
// 	if ((src & 0b11111000) == 0b11111000) return 5;
// 	if ((src & 0b11110000) == 0b11110000) return 4;
// 	if ((src & 0b11100000) == 0b11100000) return 3;
// 	if ((src & 0b11000000) == 0b11000000) return 2;
// 	if ((src & 0b10000000) == 0b10000000) return 1;
// 	return 0;
// }


private static Key[string] keyMap;

shared static this()
{
	addCommonKeys();
	version (WithSuperKey) addSuperKeys();
}

private void addCommonKeys()
{
	import std.process: environment, get;

	// Relying on the terminfo database is dangerous: the environment variable $TERM can often be set incorrectly (e.g.
	// during PuTTY sessions), and many escape sequences are not listed in the database file. Therefore, we simply
	// collect all the most common sequences.
	keyMap = [
		"\x1b[[A": Key(KeyType.COMMAND, KeyValue(Command.keyF1), KeyModifier.none), //Linux
		"\x1b[[B": Key(KeyType.COMMAND, KeyValue(Command.keyF2), KeyModifier.none), //Linux
		"\x1b[[C": Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.none), //Linux
		"\x1b[[D": Key(KeyType.COMMAND, KeyValue(Command.keyF4), KeyModifier.none), //Linux
		"\x1b[[E": Key(KeyType.COMMAND, KeyValue(Command.keyF5), KeyModifier.none), //Linux
		"\x1b[1;2A": Key(KeyType.COMMAND, KeyValue(Command.keyUp), KeyModifier.shift), //Konsole
		"\x1b[1;2B": Key(KeyType.COMMAND, KeyValue(Command.keyDown), KeyModifier.shift), //Konsole
		"\x1b[1;2C": Key(KeyType.COMMAND, KeyValue(Command.keyRight), KeyModifier.shift), //Konsole, Xterm
		"\x1b[1;2D": Key(KeyType.COMMAND, KeyValue(Command.keyLeft), KeyModifier.shift), //Konsole, Xterm
		"\x1b[1;2F": Key(KeyType.COMMAND, KeyValue(Command.keyEnd), KeyModifier.shift), //Konsole, Xterm
		"\x1b[1;2H": Key(KeyType.COMMAND, KeyValue(Command.keyHome), KeyModifier.shift), //Konsole, Xterm
		"\x1b[1;2P": Key(KeyType.COMMAND, KeyValue(Command.keyF1), KeyModifier.shift), //Xterm
		"\x1b[1;2Q": Key(KeyType.COMMAND, KeyValue(Command.keyF2), KeyModifier.shift), //Xterm
		"\x1b[1;2R": Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.shift), //Xterm
		"\x1b[1;2S": Key(KeyType.COMMAND, KeyValue(Command.keyF4), KeyModifier.shift), //Xterm
		"\x1b[1;3A": Key(KeyType.COMMAND, KeyValue(Command.keyUp), KeyModifier.alt), //Konsole, Xterm
		"\x1b[1;3B": Key(KeyType.COMMAND, KeyValue(Command.keyDown), KeyModifier.alt), //Konsole, Xterm
		"\x1b[1;3C": Key(KeyType.COMMAND, KeyValue(Command.keyRight), KeyModifier.alt), //Konsole, Xterm
		"\x1b[1;3D": Key(KeyType.COMMAND, KeyValue(Command.keyLeft), KeyModifier.alt), //Konsole, Xterm
		"\x1b[1;3E": Key(KeyType.COMMAND, KeyValue(Command.keyB2), KeyModifier.alt), //Xterm
		"\x1b[1;3F": Key(KeyType.COMMAND, KeyValue(Command.keyEnd), KeyModifier.alt), //Konsole, Xterm
		"\x1b[1;3H": Key(KeyType.COMMAND, KeyValue(Command.keyHome), KeyModifier.alt), //Konsole, Xterm
		"\x1b[1;3P": Key(KeyType.COMMAND, KeyValue(Command.keyF1), KeyModifier.alt), //Xterm
		"\x1b[1;3Q": Key(KeyType.COMMAND, KeyValue(Command.keyF2), KeyModifier.alt), //Xterm
		"\x1b[1;3R": Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.alt), //Xterm
		"\x1b[1;3S": Key(KeyType.COMMAND, KeyValue(Command.keyF4), KeyModifier.alt), //Xterm
		"\x1b[1;4A": Key(KeyType.COMMAND, KeyValue(Command.keyUp), KeyModifier.shift|KeyModifier.alt), //Konsole, Xterm
		"\x1b[1;4B": Key(KeyType.COMMAND, KeyValue(Command.keyDown), KeyModifier.shift|KeyModifier.alt), //Konsole, Xterm
		"\x1b[1;4C": Key(KeyType.COMMAND, KeyValue(Command.keyRight), KeyModifier.shift|KeyModifier.alt), //Konsole, Xterm
		"\x1b[1;4D": Key(KeyType.COMMAND, KeyValue(Command.keyLeft), KeyModifier.shift|KeyModifier.alt), //Konsole, Xterm
		"\x1b[1;4E": Key(KeyType.COMMAND, KeyValue(Command.keyB2), KeyModifier.shift|KeyModifier.alt), //Xterm
		"\x1b[1;4F": Key(KeyType.COMMAND, KeyValue(Command.keyEnd), KeyModifier.shift|KeyModifier.alt), //Konsole, Xterm
		"\x1b[1;4H": Key(KeyType.COMMAND, KeyValue(Command.keyHome), KeyModifier.shift|KeyModifier.alt), //Konsole, Xterm
		"\x1b[1;4P": Key(KeyType.COMMAND, KeyValue(Command.keyF1), KeyModifier.shift|KeyModifier.alt), //Xterm
		"\x1b[1;4R": Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.shift|KeyModifier.alt), //Xterm
		"\x1b[1;4S": Key(KeyType.COMMAND, KeyValue(Command.keyF4), KeyModifier.shift|KeyModifier.alt), //Xterm
		"\x1b[1;5A": Key(KeyType.COMMAND, KeyValue(Command.keyUp), KeyModifier.control), //Konsole, Xterm
		"\x1b[1;5B": Key(KeyType.COMMAND, KeyValue(Command.keyDown), KeyModifier.control), //Konsole, Xterm
		"\x1b[1;5C": Key(KeyType.COMMAND, KeyValue(Command.keyRight), KeyModifier.control), //Konsole, Xterm
		"\x1b[1;5D": Key(KeyType.COMMAND, KeyValue(Command.keyLeft), KeyModifier.control), //Konsole, Xterm
		"\x1b[1;5E": Key(KeyType.COMMAND, KeyValue(Command.keyB2), KeyModifier.control), //Xterm
		"\x1b[1;5F": Key(KeyType.COMMAND, KeyValue(Command.keyEnd), KeyModifier.control), //Konsole, Xterm
		"\x1b[1;5H": Key(KeyType.COMMAND, KeyValue(Command.keyHome), KeyModifier.control), //Konsole, Xterm
		"\x1b[1;5P": Key(KeyType.COMMAND, KeyValue(Command.keyF1), KeyModifier.control), //Xterm
		"\x1b[1;5Q": Key(KeyType.COMMAND, KeyValue(Command.keyF2), KeyModifier.control), //Xterm
		"\x1b[1;5R": Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.control), //Xterm
		"\x1b[1;5S": Key(KeyType.COMMAND, KeyValue(Command.keyF4), KeyModifier.control), //Xterm
		"\x1b[1;6A": Key(KeyType.COMMAND, KeyValue(Command.keyUp), KeyModifier.shift|KeyModifier.control), //Konsole, Xterm
		"\x1b[1;6B": Key(KeyType.COMMAND, KeyValue(Command.keyDown), KeyModifier.shift|KeyModifier.control), //Konsole, Xterm
		"\x1b[1;6C": Key(KeyType.COMMAND, KeyValue(Command.keyRight), KeyModifier.shift|KeyModifier.control), //Xterm
		"\x1b[1;6D": Key(KeyType.COMMAND, KeyValue(Command.keyLeft), KeyModifier.shift|KeyModifier.control), //Xterm
		"\x1b[1;6E": Key(KeyType.COMMAND, KeyValue(Command.keyB2), KeyModifier.shift|KeyModifier.control), //Xterm
		"\x1b[1;6F": Key(KeyType.COMMAND, KeyValue(Command.keyEnd), KeyModifier.shift|KeyModifier.control), //Konsole, Xterm
		"\x1b[1;6H": Key(KeyType.COMMAND, KeyValue(Command.keyHome), KeyModifier.shift|KeyModifier.control), //Konsole, Xterm
		"\x1b[1;6P": Key(KeyType.COMMAND, KeyValue(Command.keyF1), KeyModifier.shift|KeyModifier.control), //Xterm
		"\x1b[1;6P": Key(KeyType.COMMAND, KeyValue(Command.keyF2), KeyModifier.shift|KeyModifier.control), //Xterm
		"\x1b[1;6R": Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.shift|KeyModifier.control), //Xterm
		"\x1b[1;6S": Key(KeyType.COMMAND, KeyValue(Command.keyF4), KeyModifier.shift|KeyModifier.control), //Xterm
		"\x1b[1;7A": Key(KeyType.COMMAND, KeyValue(Command.keyUp), KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[1;7B": Key(KeyType.COMMAND, KeyValue(Command.keyDown), KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[1;7C": Key(KeyType.COMMAND, KeyValue(Command.keyRight), KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[1;7D": Key(KeyType.COMMAND, KeyValue(Command.keyLeft), KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[1;7E": Key(KeyType.COMMAND, KeyValue(Command.keyB2), KeyModifier.alt|KeyModifier.control), //Xterm
		"\x1b[1;7F": Key(KeyType.COMMAND, KeyValue(Command.keyEnd), KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[1;7H": Key(KeyType.COMMAND, KeyValue(Command.keyHome), KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[1;8A": Key(KeyType.COMMAND, KeyValue(Command.keyUp), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[1;8B": Key(KeyType.COMMAND, KeyValue(Command.keyDown), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[1;8C": Key(KeyType.COMMAND, KeyValue(Command.keyRight), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[1;8D": Key(KeyType.COMMAND, KeyValue(Command.keyLeft), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[1;8F": Key(KeyType.COMMAND, KeyValue(Command.keyEnd), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[1;8H": Key(KeyType.COMMAND, KeyValue(Command.keyHome), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[1;8P": Key(KeyType.COMMAND, KeyValue(Command.keyF1), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Xterm
		"\x1b[1;8Q": Key(KeyType.COMMAND, KeyValue(Command.keyF2), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Xterm
		"\x1b[1;8R": Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Xterm
		"\x1b[1;8S": Key(KeyType.COMMAND, KeyValue(Command.keyF4), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Xterm
		"\x1b[1~": Key(KeyType.COMMAND, KeyValue(Command.keyHome), KeyModifier.none), //PuTTY, Linux
		"\x1b[11^": Key(KeyType.COMMAND, KeyValue(Command.keyF1), KeyModifier.control), //rxvt
		"\x1b[11~": Key(KeyType.COMMAND, KeyValue(Command.keyF1), KeyModifier.none), //PuTTY, rxvt
		"\x1b[12^": Key(KeyType.COMMAND, KeyValue(Command.keyF2), KeyModifier.control), //rxvt
		"\x1b[12~": Key(KeyType.COMMAND, KeyValue(Command.keyF2), KeyModifier.none), //PuTTY, rxvt
		"\x1b[13^": Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.control), //rxvt
		"\x1b[13~": Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.none), //PuTTY, rxvt
		"\x1b[14^": Key(KeyType.COMMAND, KeyValue(Command.keyF4), KeyModifier.control), //rxvt
		"\x1b[14~": Key(KeyType.COMMAND, KeyValue(Command.keyF4), KeyModifier.none), //PuTTY, rxvt
		"\x1b[15;2~": Key(KeyType.COMMAND, KeyValue(Command.keyF5), KeyModifier.shift), //Konsole, Xterm
		"\x1b[15;3": Key(KeyType.COMMAND, KeyValue(Command.keyF5), KeyModifier.alt), //Konsole, Xterm
		"\x1b[15;4~": Key(KeyType.COMMAND, KeyValue(Command.keyF5), KeyModifier.shift|KeyModifier.alt), //Konsole, Xterm
		"\x1b[15;5~": Key(KeyType.COMMAND, KeyValue(Command.keyF5), KeyModifier.control), //Konsole, Xterm
		"\x1b[15;6~": Key(KeyType.COMMAND, KeyValue(Command.keyF5), KeyModifier.shift|KeyModifier.control), //Konsole, Xterm
		"\x1b[15;8~": Key(KeyType.COMMAND, KeyValue(Command.keyF5), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[15^": Key(KeyType.COMMAND, KeyValue(Command.keyF5), KeyModifier.control), //rxvt
		"\x1b[15~": Key(KeyType.COMMAND, KeyValue(Command.keyF5), KeyModifier.none), //PuTTY, Konsole, Xterm, rxvt
		"\x1b[17;2~": Key(KeyType.COMMAND, KeyValue(Command.keyF6), KeyModifier.shift), //Konsole, Xterm
		"\x1b[17;3~": Key(KeyType.COMMAND, KeyValue(Command.keyF6), KeyModifier.alt), //Konsole, Xterm
		"\x1b[17;4~": Key(KeyType.COMMAND, KeyValue(Command.keyF6), KeyModifier.shift|KeyModifier.alt), //Konsole, Xterm
		"\x1b[17;5~": Key(KeyType.COMMAND, KeyValue(Command.keyF6), KeyModifier.control), //Konsole, Xterm
		"\x1b[17;6~": Key(KeyType.COMMAND, KeyValue(Command.keyF6), KeyModifier.shift|KeyModifier.control), //Konsole, Xterm
		"\x1b[17;8~": Key(KeyType.COMMAND, KeyValue(Command.keyF6), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[17^": Key(KeyType.COMMAND, KeyValue(Command.keyF6), KeyModifier.control), //rxvt
		"\x1b[17~": Key(KeyType.COMMAND, KeyValue(Command.keyF6), KeyModifier.none), //PuTTY, Konsole, Xterm, rxvt, Linux
		"\x1b[18;2~": Key(KeyType.COMMAND, KeyValue(Command.keyF7), KeyModifier.shift), //Konsole, Xterm
		"\x1b[18;3~": Key(KeyType.COMMAND, KeyValue(Command.keyF7), KeyModifier.alt), //Konsole, Xterm
		"\x1b[18;4~": Key(KeyType.COMMAND, KeyValue(Command.keyF7), KeyModifier.shift|KeyModifier.alt), //Konsole, Xterm
		"\x1b[18;5~": Key(KeyType.COMMAND, KeyValue(Command.keyF7), KeyModifier.control), //Konsole
		"\x1b[18;6~": Key(KeyType.COMMAND, KeyValue(Command.keyF7), KeyModifier.shift|KeyModifier.control), //Konsole, Xterm
		"\x1b[18;8~": Key(KeyType.COMMAND, KeyValue(Command.keyF7), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[18^": Key(KeyType.COMMAND, KeyValue(Command.keyF7), KeyModifier.control), //rxvt
		"\x1b[18~": Key(KeyType.COMMAND, KeyValue(Command.keyF7), KeyModifier.none), //PuTTY, Konsole, Xterm, rxvt, Linux
		"\x1b[19;2~": Key(KeyType.COMMAND, KeyValue(Command.keyF8), KeyModifier.shift), //Konsole, Xterm
		"\x1b[19;3~": Key(KeyType.COMMAND, KeyValue(Command.keyF8), KeyModifier.alt), //Konsole, Xterm
		"\x1b[19;4~": Key(KeyType.COMMAND, KeyValue(Command.keyF8), KeyModifier.shift|KeyModifier.alt), //Konsole, Xterm
		"\x1b[19;5~": Key(KeyType.COMMAND, KeyValue(Command.keyF8), KeyModifier.control), //Konsole
		"\x1b[19;6~": Key(KeyType.COMMAND, KeyValue(Command.keyF8), KeyModifier.shift|KeyModifier.control), //Konsole, Xterm
		"\x1b[19;8~": Key(KeyType.COMMAND, KeyValue(Command.keyF8), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[19^": Key(KeyType.COMMAND, KeyValue(Command.keyF8), KeyModifier.control), //rxvt
		"\x1b[19~": Key(KeyType.COMMAND, KeyValue(Command.keyF8), KeyModifier.none), //PuTTY, Konsole, Xterm, rxvt, Linux
		"\x1b[2;3~": Key(KeyType.COMMAND, KeyValue(Command.keyInsert), KeyModifier.alt), //Konsole, Xterm
		"\x1b[2;4~": Key(KeyType.COMMAND, KeyValue(Command.keyInsert), KeyModifier.shift|KeyModifier.alt), //Konsole
		"\x1b[2;5~": Key(KeyType.COMMAND, KeyValue(Command.keyInsert), KeyModifier.control), //Konsole, Xterm
		"\x1b[2;7~": Key(KeyType.COMMAND, KeyValue(Command.keyInsert), KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[2;8~": Key(KeyType.COMMAND, KeyValue(Command.keyInsert), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Konsole
		"\x1b[2@": Key(KeyType.COMMAND, KeyValue(Command.keyInsert), KeyModifier.shift|KeyModifier.control), //rxvt
		"\x1b[2^": Key(KeyType.COMMAND, KeyValue(Command.keyInsert), KeyModifier.control), //rxvt
		"\x1b[2~": Key(KeyType.COMMAND, KeyValue(Command.keyInsert), KeyModifier.none), //PuTTY, Konsole, Xterm, rxvt, Linux
		"\x1b[20;2~": Key(KeyType.COMMAND, KeyValue(Command.keyF9), KeyModifier.shift), //Konsole, Xterm
		"\x1b[20;3~": Key(KeyType.COMMAND, KeyValue(Command.keyF9), KeyModifier.alt), //Konsole, Xterm
		"\x1b[20;4~": Key(KeyType.COMMAND, KeyValue(Command.keyF9), KeyModifier.shift|KeyModifier.alt), //Konsole, Xterm
		"\x1b[20;5~": Key(KeyType.COMMAND, KeyValue(Command.keyF9), KeyModifier.control), //Konsole
		"\x1b[20;6~": Key(KeyType.COMMAND, KeyValue(Command.keyF9), KeyModifier.shift|KeyModifier.control), //Konsole, Xterm
		"\x1b[20;8~": Key(KeyType.COMMAND, KeyValue(Command.keyF9), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[20^": Key(KeyType.COMMAND, KeyValue(Command.keyF9), KeyModifier.control), //rxvt
		"\x1b[20~": Key(KeyType.COMMAND, KeyValue(Command.keyF9), KeyModifier.none), //PuTTY, Konsole, Xterm, rxvt, Linux
		"\x1b[21;2~": Key(KeyType.COMMAND, KeyValue(Command.keyF10), KeyModifier.shift), //Konsole, Xterm
		"\x1b[21;3~": Key(KeyType.COMMAND, KeyValue(Command.keyF10), KeyModifier.alt), //Konsole, Xterm
		"\x1b[21;4~": Key(KeyType.COMMAND, KeyValue(Command.keyF10), KeyModifier.shift|KeyModifier.alt), //Konsole, Xterm
		"\x1b[21;5~": Key(KeyType.COMMAND, KeyValue(Command.keyF10), KeyModifier.control), //Konsole
		"\x1b[21;6~": Key(KeyType.COMMAND, KeyValue(Command.keyF10), KeyModifier.shift|KeyModifier.control), //Konsole, Xterm
		"\x1b[21;8~": Key(KeyType.COMMAND, KeyValue(Command.keyF10), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[21^": Key(KeyType.COMMAND, KeyValue(Command.keyF10), KeyModifier.control), //rxvt
		"\x1b[21~": Key(KeyType.COMMAND, KeyValue(Command.keyF10), KeyModifier.none), //PuTTY, Konsole, Xterm, rxvt, Linux
		"\x1b[23;2~": Key(KeyType.COMMAND, KeyValue(Command.keyF11), KeyModifier.shift), //Konsole, Xterm
		"\x1b[23;3~": Key(KeyType.COMMAND, KeyValue(Command.keyF11), KeyModifier.alt), //Konsole, Xterm
		"\x1b[23;4~": Key(KeyType.COMMAND, KeyValue(Command.keyF11), KeyModifier.shift|KeyModifier.alt), //Konsole, Xterm
		"\x1b[23;5~": Key(KeyType.COMMAND, KeyValue(Command.keyF11), KeyModifier.control), //Konsole, Xterm
		"\x1b[23;6~": Key(KeyType.COMMAND, KeyValue(Command.keyF11), KeyModifier.shift|KeyModifier.control), //Konsole, Xterm
		"\x1b[23;8~": Key(KeyType.COMMAND, KeyValue(Command.keyF11), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[23@": Key(KeyType.COMMAND, KeyValue(Command.keyF11), KeyModifier.shift|KeyModifier.control), //rxvt
		"\x1b[23^": Key(KeyType.COMMAND, KeyValue(Command.keyF11), KeyModifier.control), //rxvt
		"\x1b[23~": Key(KeyType.COMMAND, KeyValue(Command.keyF11), KeyModifier.none), //PuTTY, Konsole, Xterm, rxvt, Linux
		"\x1b[23$": Key(KeyType.COMMAND, KeyValue(Command.keyF11), KeyModifier.shift), //rxvt
		"\x1b[24;2~": Key(KeyType.COMMAND, KeyValue(Command.keyF12), KeyModifier.shift), //Konsole, Xterm
		"\x1b[24;3~": Key(KeyType.COMMAND, KeyValue(Command.keyF12), KeyModifier.alt), //Konsole, Xterm
		"\x1b[24;6~": Key(KeyType.COMMAND, KeyValue(Command.keyF12), KeyModifier.shift|KeyModifier.control), //Konsole, Xterm
		"\x1b[24;8~": Key(KeyType.COMMAND, KeyValue(Command.keyF12), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[24@": Key(KeyType.COMMAND, KeyValue(Command.keyF12), KeyModifier.shift|KeyModifier.control), //rxvt
		"\x1b[24^": Key(KeyType.COMMAND, KeyValue(Command.keyF12), KeyModifier.control), //rxvt
		"\x1b[24~": Key(KeyType.COMMAND, KeyValue(Command.keyF12), KeyModifier.none), //PuTTY, Konsole, Xterm, rxvt, Linux
		"\x1b[24$": Key(KeyType.COMMAND, KeyValue(Command.keyF12), KeyModifier.shift), //rxvt
		"\x1b[25^": Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.shift|KeyModifier.control), //rxvt
		"\x1b[26^": Key(KeyType.COMMAND, KeyValue(Command.keyF4), KeyModifier.shift|KeyModifier.control), //rxvt
		"\x1b[28^": Key(KeyType.COMMAND, KeyValue(Command.keyF5), KeyModifier.shift|KeyModifier.control), //rxvt
		"\x1b[29^": Key(KeyType.COMMAND, KeyValue(Command.keyF6), KeyModifier.shift|KeyModifier.control), //rxvt
		"\x1b[3;2~": Key(KeyType.COMMAND, KeyValue(Command.keyDelete), KeyModifier.shift), //Konsole, Xterm
		"\x1b[3;3~": Key(KeyType.COMMAND, KeyValue(Command.keyDelete), KeyModifier.alt), //Konsole, Xterm
		"\x1b[3;4~": Key(KeyType.COMMAND, KeyValue(Command.keyDelete), KeyModifier.shift|KeyModifier.alt), //Konsole, Xterm
		"\x1b[3;5~": Key(KeyType.COMMAND, KeyValue(Command.keyDelete), KeyModifier.control), //Konsole, Xterm
		"\x1b[3;6~": Key(KeyType.COMMAND, KeyValue(Command.keyDelete), KeyModifier.shift|KeyModifier.control), //Konsole, Xterm
		"\x1b[3@": Key(KeyType.COMMAND, KeyValue(Command.keyDelete), KeyModifier.shift|KeyModifier.control), //rxvt
		"\x1b[3^": Key(KeyType.COMMAND, KeyValue(Command.keyDelete), KeyModifier.control), //rxvt
		"\x1b[3~": Key(KeyType.COMMAND, KeyValue(Command.keyDelete), KeyModifier.none), //PuTTY, Konsole, Xterm, rxvt, Linux
		"\x1b[3$": Key(KeyType.COMMAND, KeyValue(Command.keyDelete), KeyModifier.shift), //rxvt
		"\x1b[31^": Key(KeyType.COMMAND, KeyValue(Command.keyF7), KeyModifier.shift|KeyModifier.control), //rxvt
		"\x1b[32^": Key(KeyType.COMMAND, KeyValue(Command.keyF8), KeyModifier.shift|KeyModifier.control), //rxvt
		"\x1b[33^": Key(KeyType.COMMAND, KeyValue(Command.keyF9), KeyModifier.shift|KeyModifier.control), //rxvt
		"\x1b[34^": Key(KeyType.COMMAND, KeyValue(Command.keyF10), KeyModifier.shift|KeyModifier.control), //rxvt
		"\x1b[4~": Key(KeyType.COMMAND, KeyValue(Command.keyEnd), KeyModifier.none), //PuTTY, Linux
		"\x1b[5;3~": Key(KeyType.COMMAND, KeyValue(Command.keyPageUp), KeyModifier.alt), //Konsole, Xterm
		"\x1b[5;5~": Key(KeyType.COMMAND, KeyValue(Command.keyPageUp), KeyModifier.control), //Konsole, Xterm
		"\x1b[5;7~": Key(KeyType.COMMAND, KeyValue(Command.keyPageUp), KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[5@": Key(KeyType.COMMAND, KeyValue(Command.keyPageUp), KeyModifier.shift|KeyModifier.control), //rxvt
		"\x1b[5^": Key(KeyType.COMMAND, KeyValue(Command.keyPageUp), KeyModifier.control), //rxvt
		"\x1b[5~": Key(KeyType.COMMAND, KeyValue(Command.keyPageUp), KeyModifier.none), //PuTTY, Konsole, Xterm, rxvt, Linux
		"\x1b[6;3~": Key(KeyType.COMMAND, KeyValue(Command.keyPageDown), KeyModifier.alt), //Konsole, Xterm
		"\x1b[6;5~": Key(KeyType.COMMAND, KeyValue(Command.keyPageDown), KeyModifier.control), //Konsole, Xterm
		"\x1b[6;7~": Key(KeyType.COMMAND, KeyValue(Command.keyPageDown), KeyModifier.alt|KeyModifier.control), //Konsole, Xterm
		"\x1b[6@": Key(KeyType.COMMAND, KeyValue(Command.keyPageDown), KeyModifier.shift|KeyModifier.control), //rxvt
		"\x1b[6^": Key(KeyType.COMMAND, KeyValue(Command.keyPageDown), KeyModifier.control), //rxvt
		"\x1b[6~": Key(KeyType.COMMAND, KeyValue(Command.keyPageDown), KeyModifier.none), //PuTTY, Konsole, Xterm, rxvt, Linux
		"\x1b[7@": Key(KeyType.COMMAND, KeyValue(Command.keyHome), KeyModifier.shift|KeyModifier.control), //rxvt
		"\x1b[7^": Key(KeyType.COMMAND, KeyValue(Command.keyHome), KeyModifier.control), //rxvt
		"\x1b[7~": Key(KeyType.COMMAND, KeyValue(Command.keyHome), KeyModifier.none), //rxvt
		"\x1b[7$": Key(KeyType.COMMAND, KeyValue(Command.keyHome), KeyModifier.shift), //rxvt
		"\x1b[8@": Key(KeyType.COMMAND, KeyValue(Command.keyEnd), KeyModifier.shift|KeyModifier.control), //rxvt
		"\x1b[8^": Key(KeyType.COMMAND, KeyValue(Command.keyEnd), KeyModifier.control), //rxvt
		"\x1b[8~": Key(KeyType.COMMAND, KeyValue(Command.keyEnd), KeyModifier.none), //rxvt
		"\x1b[8$": Key(KeyType.COMMAND, KeyValue(Command.keyEnd), KeyModifier.shift), //rxvt
		"\x1b[A": Key(KeyType.COMMAND, KeyValue(Command.keyUp), KeyModifier.none), //PuTTY, Konsole, Xterm, rxvt, Linux
		"\x1b[a": Key(KeyType.COMMAND, KeyValue(Command.keyUp), KeyModifier.shift), //rxvt
		"\x1b[B": Key(KeyType.COMMAND, KeyValue(Command.keyDown), KeyModifier.none), //PuTTY, Konsole, Xterm, rxvt, Linux
		"\x1b[b": Key(KeyType.COMMAND, KeyValue(Command.keyDown), KeyModifier.shift), //rxvt
		"\x1b[C": Key(KeyType.COMMAND, KeyValue(Command.keyRight), KeyModifier.none), //PuTTY, Konsole, Xterm, rxvt, Linux
		"\x1b[c": Key(KeyType.COMMAND, KeyValue(Command.keyRight), KeyModifier.shift), //rxvt
		"\x1b[D": Key(KeyType.COMMAND, KeyValue(Command.keyLeft), KeyModifier.none), //PuTTY, Konsole, Xterm, rxvt, Linux
		"\x1b[d": Key(KeyType.COMMAND, KeyValue(Command.keyLeft), KeyModifier.shift), //rxvt
		"\x1b[E": Key(KeyType.COMMAND, KeyValue(Command.keyB2), KeyModifier.none), //Xterm
		"\x1b[F": Key(KeyType.COMMAND, KeyValue(Command.keyEnd), KeyModifier.none), //Konsole, Xterm
		"\x1b[G": Key(KeyType.COMMAND, KeyValue(Command.keyB2), KeyModifier.none), //PuTTY, Linux
		"\x1b[H": Key(KeyType.COMMAND, KeyValue(Command.keyHome), KeyModifier.none), //Konsole, Xterm
		"\x1b[Z": Key(KeyType.COMMAND, KeyValue(Command.horizontalTabulation), KeyModifier.shift), //PuTTY, Konsole, Xterm, rxvt
		"\x1bO2P": Key(KeyType.COMMAND, KeyValue(Command.keyF1), KeyModifier.shift), //Konsole
		"\x1bO2Q": Key(KeyType.COMMAND, KeyValue(Command.keyF2), KeyModifier.shift), //Konsole
		"\x1bO2R": Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.shift), //Konsole
		"\x1bO2S": Key(KeyType.COMMAND, KeyValue(Command.keyF4), KeyModifier.shift), //Konsole
		"\x1bO3P": Key(KeyType.COMMAND, KeyValue(Command.keyF1), KeyModifier.alt), //Konsole
		"\x1bO3Q": Key(KeyType.COMMAND, KeyValue(Command.keyF2), KeyModifier.alt), //Konsole
		"\x1bO3R": Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.alt), //Konsole
		"\x1bO4P": Key(KeyType.COMMAND, KeyValue(Command.keyF1), KeyModifier.shift|KeyModifier.alt), //Konsole
		"\x1bO4Q": Key(KeyType.COMMAND, KeyValue(Command.keyF2), KeyModifier.shift|KeyModifier.alt), //Konsole
		"\x1bO4R": Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.shift|KeyModifier.alt), //Konsole
		"\x1bO4S": Key(KeyType.COMMAND, KeyValue(Command.keyF4), KeyModifier.shift|KeyModifier.alt), //Konsole
		"\x1bO5P": Key(KeyType.COMMAND, KeyValue(Command.keyF1), KeyModifier.control), //Konsole
		"\x1bO5Q": Key(KeyType.COMMAND, KeyValue(Command.keyF2), KeyModifier.control), //Konsole
		"\x1bO5R": Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.control), //Konsole
		"\x1bO5R": Key(KeyType.COMMAND, KeyValue(Command.keyF4), KeyModifier.control), //Konsole
		"\x1bO6P": Key(KeyType.COMMAND, KeyValue(Command.keyF1), KeyModifier.shift|KeyModifier.control), //Konsole
		"\x1bO6Q": Key(KeyType.COMMAND, KeyValue(Command.keyF2), KeyModifier.shift|KeyModifier.control), //Konsole
		"\x1bO6R": Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.shift|KeyModifier.control), //Konsole
		"\x1bO6S": Key(KeyType.COMMAND, KeyValue(Command.keyF4), KeyModifier.shift|KeyModifier.control), //Konsole
		"\x1bO8P": Key(KeyType.COMMAND, KeyValue(Command.keyF1), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Konsole
		"\x1bO8Q": Key(KeyType.COMMAND, KeyValue(Command.keyF2), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Konsole
		"\x1bO8R": Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Konsole
		"\x1bO8S": Key(KeyType.COMMAND, KeyValue(Command.keyF4), KeyModifier.shift|KeyModifier.alt|KeyModifier.control), //Konsole
		"\x1bOA": Key(KeyType.COMMAND, KeyValue(Command.keyUp), KeyModifier.shift), //PuTTY
		"\x1bOa": Key(KeyType.COMMAND, KeyValue(Command.keyUp), KeyModifier.control), //rxvt
		"\x1bOB": Key(KeyType.COMMAND, KeyValue(Command.keyDown), KeyModifier.shift), //PuTTY
		"\x1bOb": Key(KeyType.COMMAND, KeyValue(Command.keyDown), KeyModifier.control), //rxvt
		"\x1bOC": Key(KeyType.COMMAND, KeyValue(Command.keyRight), KeyModifier.shift), //PuTTY
		"\x1bOc": Key(KeyType.COMMAND, KeyValue(Command.keyRight), KeyModifier.control), //rxvt
		"\x1bOD": Key(KeyType.COMMAND, KeyValue(Command.keyLeft), KeyModifier.shift), //PuTTY
		"\x1bOd": Key(KeyType.COMMAND, KeyValue(Command.keyLeft), KeyModifier.control), //rxvt
		"\x1bOG": Key(KeyType.COMMAND, KeyValue(Command.keyB2), KeyModifier.shift), //PuTTY
		"\x1bOP": Key(KeyType.COMMAND, KeyValue(Command.keyF1), KeyModifier.none), //Konsole, Xterm
		"\x1bOQ": Key(KeyType.COMMAND, KeyValue(Command.keyF2), KeyModifier.none), //Konsole, Xterm
		"\x1bOR": Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.none), //Konsole, Xterm
		"\x1bOS": Key(KeyType.COMMAND, KeyValue(Command.keyF4), KeyModifier.none), //Konsole, Xterm
		"\x1bOu": Key(KeyType.COMMAND, KeyValue(Command.keyB2), KeyModifier.shift), //rxvt
	];

	//rxvt and Linux terminal assign the same escape sequences to different keyboard shortcuts
	immutable term = environment.get("TERM", "unknown");
	if (term == "linux" || term == "screen") {
		keyMap["\x1b[25~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF1), KeyModifier.shift);
		keyMap["\x1b[26~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF2), KeyModifier.shift);
		keyMap["\x1b[28~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.shift);
		keyMap["\x1b[29~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF4), KeyModifier.shift);
		keyMap["\x1b[31~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF5), KeyModifier.shift);
		keyMap["\x1b[32~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF6), KeyModifier.shift);
		keyMap["\x1b[33~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF7), KeyModifier.shift);
		keyMap["\x1b[34~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF8), KeyModifier.shift);
	} else {
		keyMap["\x1b[25~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.shift);
		keyMap["\x1b[26~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF4), KeyModifier.shift);
		keyMap["\x1b[28~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF5), KeyModifier.shift);
		keyMap["\x1b[29~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF6), KeyModifier.shift);
		keyMap["\x1b[31~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF7), KeyModifier.shift);
		keyMap["\x1b[32~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF8), KeyModifier.shift);
		keyMap["\x1b[33~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF9), KeyModifier.shift);
		keyMap["\x1b[34~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF10), KeyModifier.shift);
	}

	//Some service escape sequences
	//During terminal resize Consoleur generates this sequence
	keyMap["\x1b[480w"] = Key(KeyType.COMMAND, KeyValue(Command.winch), KeyModifier.none);
	//Bracketed Pasting
	keyMap["\x1b[200~"] = Key(KeyType.COMMAND, KeyValue(Command.pasteStart), KeyModifier.none);
	keyMap["\x1b[201~"] = Key(KeyType.COMMAND, KeyValue(Command.pasteEnd), KeyModifier.none);
}

version (WithSuperKey) {
	private void addSuperKeys()
	{
		keyMap["\x1b[1;1A"] = Key(KeyType.COMMAND, KeyValue(Command.keyUp), KeyModifier.supr);
		keyMap["\x1b[1;1B"] = Key(KeyType.COMMAND, KeyValue(Command.keyDown), KeyModifier.supr);
		keyMap["\x1b[1;1C"] = Key(KeyType.COMMAND, KeyValue(Command.keyRight), KeyModifier.supr);
		keyMap["\x1b[1;1D"] = Key(KeyType.COMMAND, KeyValue(Command.keyLeft), KeyModifier.supr);

		keyMap["\x1b[2;1~"] = Key(KeyType.COMMAND, KeyValue(Command.keyInsert), KeyModifier.supr);
		keyMap["\x1b[3;1~"] = Key(KeyType.COMMAND, KeyValue(Command.keyDelete), KeyModifier.supr);
		keyMap["\x1b[1;1F"] = Key(KeyType.COMMAND, KeyValue(Command.keyEnd), KeyModifier.supr);
		keyMap["\x1b[1;1H"] = Key(KeyType.COMMAND, KeyValue(Command.keyHome), KeyModifier.supr);
		keyMap["\x1b[5;1~"] = Key(KeyType.COMMAND, KeyValue(Command.keyPageUp), KeyModifier.supr);
		keyMap["\x1b[6;1~"] = Key(KeyType.COMMAND, KeyValue(Command.keyPageDown), KeyModifier.supr);

		keyMap["\x1bO1P"] = Key(KeyType.COMMAND, KeyValue(Command.keyF1), KeyModifier.supr);
		keyMap["\x1bO1Q"] = Key(KeyType.COMMAND, KeyValue(Command.keyF2), KeyModifier.supr);
		keyMap["\x1bO1R"] = Key(KeyType.COMMAND, KeyValue(Command.keyF3), KeyModifier.supr);
		keyMap["\x1bO1S"] = Key(KeyType.COMMAND, KeyValue(Command.keyF4), KeyModifier.supr);
		keyMap["\x1b[15;1~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF5), KeyModifier.supr);
		keyMap["\x1b[17;1~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF6), KeyModifier.supr);
		keyMap["\x1b[18;1~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF7), KeyModifier.supr);
		keyMap["\x1b[19;1~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF8), KeyModifier.supr);
		keyMap["\x1b[20;1~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF9), KeyModifier.supr);
		keyMap["\x1b[21;1~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF10), KeyModifier.supr);
		keyMap["\x1b[23;1~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF11), KeyModifier.supr);
		keyMap["\x1b[24;1~"] = Key(KeyType.COMMAND, KeyValue(Command.keyF12), KeyModifier.supr);
	}
}

}