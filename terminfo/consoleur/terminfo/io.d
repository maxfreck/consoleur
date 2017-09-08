/**
 * Consoleur: a package for interaction with character-oriented terminal emulators
 *
 * Copyright: Maxim Freck, 2017.
 * Authors:   Maxim Freck <maxim@freck.pp.ru>
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module consoleur.terminfo.io;
version(Posix) {

import std.stdio: File;
import std.traits: isScalarType;

/*******
 * Determines terminfo file name
 * Returns: the path to the file or an empty string if the file is not found
 */
string determineTermFile() @safe
{
	import std.process: environment, get;

	auto fname = environment.get("TERM", "unknown");
	fname = cast(char)(fname[0])~"/"~fname;

	auto home = getHomeDir() ~ "/.terminfo/" ~ fname;

	if (fileExists(home)) {
		return home;
	}

	if (fileExists("/etc/terminfo/"~fname)) {
		return "/etc/terminfo/"~fname;
	}

	if (fileExists("/lib/terminfo/"~fname)) {
		return "/lib/terminfo/"~fname;
	}

	return "";
}

private bool fileExists(string name) @trusted
{
	import core.sys.posix.sys.stat: stat, stat_t, S_ISREG;

	stat_t path_stat;
	stat((name~"\0").ptr, &path_stat);
	return S_ISREG(path_stat.st_mode);
}

private string getHomeDir() @trusted
{
	import core.sys.posix.pwd: getpwuid;
	import core.sys.posix.unistd: getuid;
	import std.conv: to;

	auto passwdEnt = *getpwuid(getuid());
	return to!string(passwdEnt.pw_dir);
}

/*******
 * Determines whether the system is big endian
 * Returns: true if the system is big endan, false otherwise
 */
pure nothrow immutable(bool) isBigEndian() @trusted @nogc
{
	union E {ushort s; ubyte[2] b; }
	E e = {s: 0xdead};
	return (e.b[0] == 0xad) ? false : true;
}

/*******
 * Performes inplace reverse of a static array
 */
private pure nothrow void reverse(T, size_t n)(ref T[n] a) @safe @nogc
{
	foreach (i; 0 .. n/2) {
		immutable temp = a[i];
		a[i] = a[n - 1 - i];
		a[n - 1 - i] = temp;
	}
}

/*******
 * Reads variable of type T from a file in the little endian format.
 * Returns: true if the system is big endan, false otherwise.
 */
auto get(T)(File f) @safe if (isScalarType!(T))
{
	static if (T.sizeof == 1) {
		T[1] b = [0];
		f.rawRead(b);
		return b[0];

	} else {

		union buffer {ubyte[T.sizeof] b; T v;}
		buffer buf;
		f.rawRead(buf.b);

		if(isBigEndian()) {
			reverse(buf.b);
		}

		return buf.v;
	}
}

/*******
 * Reads array of variables of type T from a file in the little endian format.
 * Returns: true if the system is big endan, false otherwise.
 */
T[] get(T)(File f, size_t size) @safe if (isScalarType!(T))
{
	if (size < 1) return [];

	auto buf = new T[size];
	f.rawRead(buf);

	if(isBigEndian()) {
		union item {ubyte[T.sizeof] b; T v;}
		foreach (ref i; buf) {
			item itm;
			itm.v = i;
			reverse(itm.b);
			i = itm.v;
		}
	}

	return buf;
}

}