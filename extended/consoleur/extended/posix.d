/**
 * Consoleur: a package for interaction with character-oriented terminal emulators
 *
 * Copyright: Maxim Freck, 2017.
 * Authors:   Maxim Freck <maxim@freck.pp.ru>
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module consoleur.extended.posix;
version(Posix) {

/*******
 * Enables keypad mode
 * Returns: false if option is not available, otherwise true
 */
bool enableKeypad() @safe
{
	import consoleur.commands: invokeCommand, TermCommand;
	return invokeCommand(TermCommand.keypadXmit);
}

/*******
 * Disables keypad mode
 * Returns: false if option is not available, otherwise true
 */
bool disableKeypad() @safe
{
	import consoleur.commands: invokeCommand, TermCommand;
	return invokeCommand(TermCommand.keypadLocal);
}

/*******
 * Sets console title
 *
 * Params:
 *  title = The title
 */
void setConsoleTitle(string title) @safe
{
	import consoleur.core: isAttyOut, rawStdout;
	if (isAttyOut()) {
		rawStdout("\033]0;"~title~"\007");
	} else {
		import std.stdio: writeln;
		writeln("**"~title~"**");
	}
}

}