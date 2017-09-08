/**
 * Consoleur: a package for interaction with character-oriented terminal emulators
 *
 * Copyright: Maxim Freck, 2017.
 * Authors:   Maxim Freck <maxim@freck.pp.ru>
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module consoleur.core.posix;
version(Posix) {

///STDIN file descriptor
int STDIN_FILENO = 0;
///STDOUT file descriptor
enum STDOUT_FILENO = 1;
///STERR file descriptor
enum STDERR_FILENO = 2;

/*******
 * Console point: row and column
 */
struct Point {
	int row;
	int col;
}

/*******
 * Tests whether a STDOUT descriptor refers to a terminal
 * Returns: true on success, false in case of failure
 */
bool isAttyOut() @safe
{
	import core.sys.posix.unistd: isatty;
	return cast(bool)isatty(STDOUT_FILENO);
}

/*******
 * Tests whether a STDIN descriptor refers to a terminal
 * Returns: true on success, false in case of failure
 */
bool isAttyIn() @safe
{
	import core.sys.posix.unistd: isatty;
	return cast(bool)isatty(STDIN_FILENO);
}

/*******
 * Flushes STDOUT buffer
 */
bool flushStdout()
{
	import core.stdc.stdio: fflush;
	import std.stdio: stdout;
	return fflush(stdout.getFP) == 0;
}


/*******
 * Writes raw data to stdout without buffering
 *
 * Params:
 *  buffer = The buffer
 */
nothrow size_t rawStdout(string buffer) @trusted
{
	import core.sys.posix.unistd: write;
	return write(STDOUT_FILENO, buffer.ptr, buffer.length);
}

private auto buffer = new ubyte[MAX_STDIN_BUFFER_SIZE];
private ubyte[] stdinBuffer;
private size_t stdinPosition;
private enum MAX_STDIN_BUFFER_SIZE = 32;

/*******
 * Reads raw ubyte from stdin
 * Returns: true on success, false in case of failure
 *
 * Params:
 *  b = The variable to read byte into
 */
nothrow bool popStdin(ref ubyte b) @safe
{
	if (stdinBuffer.length == stdinPosition) fillStdinBuffer();

	if (stdinBuffer.length == stdinPosition) return false;
	b = stdinBuffer[stdinPosition++];

	return true;
}

private nothrow void fillStdinBuffer() @trusted
{
	import core.sys.posix.unistd: read;

	auto len = read(STDIN_FILENO, buffer.ptr, MAX_STDIN_BUFFER_SIZE);

	if (stdinPosition == stdinBuffer.length) {
		stdinPosition = 0;
		stdinBuffer = buffer[0 .. len];
	} else if (len > 0) {
		stdinBuffer = buffer[0 .. len] ~ stdinBuffer;
	}
}

/*******
 * Returns raw ubyte from stdin
 * Returns: ubyte on success, 0 in case of failure
 */
nothrow ubyte popStdin() @safe
{
	if (stdinBuffer.length == stdinPosition) fillStdinBuffer();

	if (stdinBuffer.length == stdinPosition) return 0;
	return stdinBuffer[stdinPosition++];
}

/*******
 * Puts back ubyte to STDIN buffer
 * Returns: true on success, false in case of failure
 *
 * Params:
 *  b = The ubyte to write
 */
nothrow bool pushStdin(immutable ubyte b) @safe
{
	if (stdinPosition == 0) {
		stdinBuffer = b ~ stdinBuffer;
	} else {
		stdinBuffer[--stdinPosition] = b;
	}

	return true;
}

/*******
 * Puts back string to STDIN buffer
 * Returns: true on success, false in case of failure
 *
 * Params:
 *  str = The string to write
 */
nothrow bool pushStdin(string str) @safe
{
	foreach_reverse(immutable ubyte b; str) if (!pushStdin(b)) return false;
	return true;
}

/*******
 * Flushes STDIN buffer
 */
void flushStdin() @trusted
{
	import consoleur.core.termparam: setTermparam, Term;

	immutable tparam = setTermparam(Term.quiet|Term.raw|Term.async, 0);
	while(true) {
		stdinBuffer.length = 0;
		stdinPosition = 0;
		fillStdinBuffer();
		if (stdinBuffer.length == 0) break;
	}
}


/*******
 * Reads escape sequence from STDIN
 * Returns: string, containing escape command without Control Sequence Introducer
 */
string readEscapeSequence() @safe
{
	ubyte b;
	ubyte b1;

	if (!popStdin(b)) return "";

	if (b != 0x1b && b != 0xc2) {
		pushStdin(b);
		return "";
	}

	if (!popStdin(b1)){
		pushStdin(b);
		return "";
	}

	if ( (b == 0x1b && b1 != 0x5b) || (b == 0xc2 && b1 != 0x9b)){
		pushStdin(b1);
		pushStdin(b);
		return "";
	}

	string csi;
	while (popStdin(b)) {
		csi~=b;
		if (b >= 0x40 && b <= 0x7e && b != 0x5b) break;
	}

	return csi;
}


shared static this()
{
	import core.sys.posix.fcntl: open, O_RDONLY;
	import core.sys.posix.unistd: isatty;

	if (!isatty(STDIN_FILENO)) {
		STDIN_FILENO = open("/dev/tty", O_RDONLY);
	}
}

}