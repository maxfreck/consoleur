/**
 * Consoleur: a package for interaction with character-oriented terminal emulators
 *
 * Copyright: Maxim Freck, 2017.
 * Authors:   Maxim Freck <maxim@freck.pp.ru>
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module consoleur.commands;

version (Posix) {
	public import consoleur.commands.posix;
}