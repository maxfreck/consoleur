/**
 * Consoleur: a package for interaction with character-oriented terminal emulators
 *
 * Copyright: Maxim Freck, 2017.
 * Authors:   Maxim Freck <maxim@freck.pp.ru>
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module consoleur.screen.posix;
version(Posix) {
	
import consoleur.core;

/*******
 * Returns: current screen rows and columns count
 */
Point getScreenSize() @trusted
{
	import core.sys.posix.sys.ioctl: ioctl, TIOCGWINSZ, winsize;
	winsize w;
	ioctl(STDOUT_FILENO, TIOCGWINSZ, &w);
	return Point(w.ws_row, w.ws_col);
}

/*******
 * Clears screen
 *
 * Returns: true on success, false otherwise
 */
bool clearScreen() @safe
{
	import consoleur.commands: invokeCommand, TermCommand;
	return invokeCommand(TermCommand.clearScreen);
}

/*******
 * Enters cup mode
 * Returns: false if option is not available, otherwise true
 */
bool enterFullscreen() @safe
{
	import consoleur.commands: invokeCommand, TermCommand;
	return invokeCommand(TermCommand.enterCa);
}

/*******
 * Leaves cup mode
 * Returns: false if option is not available, otherwise true
 */
bool exitFullscreen() @safe
{
	import consoleur.commands: invokeCommand, TermCommand;
	return invokeCommand(TermCommand.exitCa);
}



import core.sys.posix.signal;

private enum SIGWINCH = 28;

private sigaction_t oldSigWinch;

private extern(C) void resizeHandle(int sigNumber) @safe
{
	//pushStdin("w084[\x1b");
	pushStdin("\x1b[480w");
}

shared static this()
{
	sigaction_t n;
	n.sa_handler = &resizeHandle;
	n.sa_mask = cast(sigset_t) 0;
	n.sa_flags = 0;
	sigaction(SIGWINCH, &n, &oldSigWinch);
}

shared static ~this()
{
	sigaction(SIGWINCH, &oldSigWinch, null);
}

}