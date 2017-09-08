/**
 * Consoleur: a package for interaction with character-oriented terminal emulators
 *
 * Copyright: Maxim Freck, 2017.
 * Authors:   Maxim Freck <maxim@freck.pp.ru>
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module consoleur.core.termparam;
version(Posix) {

import consoleur.core: STDIN_FILENO;

///Terminal parameters
enum Term: uint {
	quiet = 0b00000000_00000000_00000000_00000001,
	raw = 0b00000000_00000000_00000000_00000010,
	async = 0b00000000_00000000_00000000_00000100,
}

/*******
 * Structure with saved terminal parameters.
 * Restores parameters during destruction.
 */
struct SavedTermparam
{
	private import core.sys.posix.termios: TCSANOW, tcsetattr, termios;

	private termios tsave = {};
	private bool restore = false;

	///constructor
	this(bool r, termios s) @safe
	{
		tsave = s;
		restore = r;
	}

	~this() @safe
	{
		restoreBack();
	}

	/*******
	* Restores back previously saved terminal parameters
	*/
	void restoreBack() @trusted
	{
		if (restore) {
			tcsetattr(STDIN_FILENO, TCSANOW, &tsave);
			restore = false;
		}
	}
}

/*******
 * Sets new terminal parameters
 *
 * Returns: Structure with saved previous parameter set
 */
SavedTermparam setTermparam(uint flags = 0, ubyte delay = 0) @trusted
{
	import core.sys.posix.termios: ECHO, ICANON, tcgetattr, TCSANOW, tcsetattr, termios, VMIN, VTIME;

	termios told;
	termios tnew;

	tcgetattr(STDIN_FILENO, &told);
	tnew = told;

	if (flags & Term.quiet) {
		tnew.c_lflag &= ~ECHO;
	} else {
		tnew.c_lflag |= ECHO;
	}

	if (flags & Term.raw) {
		tnew.c_lflag &= ~ICANON;
	} else {
		tnew.c_lflag |= ICANON;
	}

	if (flags & Term.async) {
		tnew.c_cc[VMIN] = 0;
		tnew.c_cc[VTIME] = delay;
	} else {
		tnew.c_cc[VMIN] = 1;
		tnew.c_cc[VTIME] = 0;
	}
	
	if (tnew != told) {
		tcsetattr(STDIN_FILENO, TCSANOW, &tnew);
		return SavedTermparam(true, told);
	}

	return SavedTermparam(false, told);
}

}