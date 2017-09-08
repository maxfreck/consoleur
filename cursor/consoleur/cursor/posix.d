/**
 * Consoleur: a package for interaction with character-oriented terminal emulators
 *
 * Copyright: Maxim Freck, 2017.
 * Authors:   Maxim Freck <maxim@freck.pp.ru>
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module consoleur.cursor.posix;
version(Posix) {

import consoleur.core;
import std.stdio: write;

/*******
 * Moves cursor to desired position
 *
 * Params:
 *  dest = Coordinates
 */
void moveCursorTo(Point dest) @safe
{
	import std.conv: to;
	write("\x1b["~to!string(dest.row)~';'~to!string(dest.col)~'f');
}

/*******
 * Moves cursor up by n rows
 *
 * Params:
 *  n = Number of rows to move
 */
void moveCursorUp(int n = 1)
{
	import std.conv: to;
	write("\x1b["~to!string(n)~"A");
}

/*******
 * Moves cursor down by n rows
 *
 * Params:
 *  n = Number of rows to move
 */
void moveCursorDown(int n = 1)
{
	import std.conv: to;
	write("\x1b["~to!string(n)~"B");
}

/*******
 * Moves cursor right by n columns
 *
 * Params:
 *  n = Number of columns to move
 */
void moveCursorRight(int n = 1)
{
	import std.conv: to;
	write("\x1b["~to!string(n)~"C");
}

/*******
 * Moves cursor left by n columns
 *
 * Params:
 *  n = Number of columns to move
 */
void moveCursorLeft(int n = 1)
{
	import std.conv: to;
	write("\x1b["~to!string(n)~"D");
}


/*******
 * Saves current cursor position
 *
 */
public bool saveCursorPosition()
{
	import consoleur.commands: invokeCommand, TermCommand;
	return invokeCommand(TermCommand.saveCursorPosition);
}

/*******
 * Restores previously saved cursor positon
 *
 */
public bool restoreCursorPosition()
{
	import consoleur.commands: invokeCommand, TermCommand;
	return invokeCommand(TermCommand.restoreCursorPosition);
}

/*******
 * Returns: current cursor positon
 *
 */
public Point getCursorPosition() @trusted
{
	import consoleur.core.termparam: setTermparam, Term;
	import std.array: split;
	import std.conv: to;

	immutable tparam = setTermparam(Term.quiet|Term.raw);

	write("\x1b[6n");

	auto csi = readEscapeSequence();
	if (csi.length <3 ) return Point(-1, -1);

	auto pos = csi[0..$-1].split(";");
	if (pos.length != 2 || pos[0].length == 0 || pos[1].length == 0) return Point(-1, -1);

	return Point(to!int(pos[0]), to!int(pos[1]));
}

private bool cursorHidden = false;

/*******
 * Hides cursor
 * Returns: false if cursor is already hidden, otherwise true
 */
bool hideCursor() @safe
{
	import consoleur.commands: invokeCommand, TermCommand;
	if (cursorHidden) return false;

	invokeCommand(TermCommand.cursorHide);

	cursorHidden = true;
	return true;
}

/*******
 * Shows cursor
 * Returns: false if cursor is already visible, otherwise true
 */
bool showCursor() @safe
{
	import consoleur.commands: invokeCommand, TermCommand;
	if (!cursorHidden) return false;

	invokeCommand(TermCommand.cursorShow);

	cursorHidden = false;
	return true;
}

}