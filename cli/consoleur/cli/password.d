/**
 * Consoleur: a package for interaction with character-oriented terminal emulators
 *
 * Copyright: Maxim Freck, 2017.
 * Authors:   Maxim Freck <maxim@freck.pp.ru>
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module consoleur.cli.password;

/**
 * Reads password from the user with echo
 *
 * Params:
 *  mask = Typed character mask
 *
 * Returns: Password
 */
string getPassword(string prompt, dchar mask = '•') @trusted
{
	import consoleur.cli.util: delchar, utf8length;
	import consoleur.core.termparam: setTermparam, Term;
	import consoleur.core: flushStdin;
	import consoleur.input.key: Command, getKeyPressed, KeyModifier, KeyType;
	import std.stdio: stdout, write;

	string ret;
	immutable tparam = setTermparam(Term.quiet|Term.raw);

	write(prompt);
	stdout.flush;

	while (true) {
		auto code = getKeyPressed();
		if (code.type == KeyType.ASCII || code.type == KeyType.UTF8) {
			ret ~= cast(string)(code);
			write(mask);
			stdout.flush;
		}

		if (code.type == KeyType.COMMAND && code.content.code == Command.del && ret.length > 0) {
			ret = ret.delchar;
			write("\b \b");
			stdout.flush;
		}
		if ( ( (code.type == KeyType.COMMAND && code.content.code == Command.escape ) ||
			(code.type == KeyType.COMMAND && code.content.code == Command.del && (code.modifier & KeyModifier.alt) ) )
			&& ret.length > 0
		) {
			foreach (_; 0 .. ret.utf8length) write("\b \b");
			stdout.flush;
			ret.length = 0;
		}

		if (code.type == KeyType.COMMAND && code.content.code == Command.lineFeed) break;
	}

	flushStdin();
	return ret;
}
