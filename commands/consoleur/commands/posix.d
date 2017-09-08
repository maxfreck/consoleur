/**
 * Consoleur: a package for interaction with character-oriented terminal emulators
 *
 * Copyright: Maxim Freck, 2017.
 * Authors:   Maxim Freck <maxim@freck.pp.ru>
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module consoleur.commands.posix;
version(Posix) {

/**
 * Invocable commands
 */
enum TermCommand: size_t {
	clearScreen = 0,

	keypadLocal,
	keypadXmit,

	enterCa,
	exitCa,

	cursorHide,
	cursorShow,

	saveCursorPosition,
	restoreCursorPosition
}

private string[TermCommand.max+1] commands;

/*******
 * Invokes special terminal command if available
 *
 * Params:
 *  cmd = Terminal command
 *
 * Return: true if a command is available, false otherwise
 */
pragma(inline):
bool invokeCommand(TermCommand cmd) @safe
{
	import std.stdio: write;

	if (cmd >= commands.length || commands[cmd].length == 0) return false;

	write(commands[cmd]);
	return true;
}

private shared static this() @safe
{
	import consoleur.terminfo: CapString, Terminfo, TerminfoStatus;

	auto termInfo = Terminfo.getActual();
	bool loaded = false;

	if (termInfo.getStatus() >= TerminfoStatus.stringsLoaded) loaded = true;

	void setCommand(TermCommand cmd, CapString cap, string dflt) {
		if (!loaded) {
			commands[cmd] = dflt;
			return;
		}

		immutable str = termInfo.get(cap);
		commands[cmd] = (str.length == 0) ? dflt : str;
	}

	setCommand(TermCommand.clearScreen, CapString.clearScreen, "\x1b[2J");

	setCommand(TermCommand.keypadLocal, CapString.keypadLocal, "\x1b[?1l\x1b>");
	setCommand(TermCommand.keypadXmit, CapString.keypadXmit, "\x1b[?1h\x1b=");

	setCommand(TermCommand.enterCa, CapString.enterCaMode, "\x1b[?1049h");
	setCommand(TermCommand.exitCa, CapString.exitCaMode, "\x1b[?1049l");

	setCommand(TermCommand.cursorHide, CapString.cursorInvisible, "\x1b[?25l");
	setCommand(TermCommand.cursorShow, CapString.cursorNormal, "\x1b[?25h");

	setCommand(TermCommand.cursorHide, CapString.cursorInvisible, "\x1b[?25l");
	setCommand(TermCommand.cursorShow, CapString.cursorNormal, "\x1b[?25h");

	setCommand(TermCommand.saveCursorPosition, CapString.saveCursor, "\x1b[s");
	setCommand(TermCommand.restoreCursorPosition, CapString.restoreCursor, "\x1b[u");
}

}