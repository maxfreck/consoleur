/**
 * Consoleur: a package for interaction with character-oriented terminal emulators
 *
 * Copyright: Maxim Freck, 2017.
 * Authors:   Maxim Freck <maxim@freck.pp.ru>
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module consoleur.input.types;

import consoleur.input.util;

/**
 * Pressed key type: ascii character, utf-8 characer, command or raw sequence
 */
enum KeyType
{
	ASCII,
	UTF8,
	COMMAND,
	RAW,
}


version(WithSuperKey) {
	/**
	 * Key modifiers
	 */
	enum KeyModifier
	{
		none    = 0b00000000_00000000_00000000_00000000,
		shift   = 0b00000000_00000000_00000000_00000001,
		alt     = 0b00000000_00000000_00000000_00000010,
		control = 0b00000000_00000000_00000000_00000100,
		meta    = 0b00000000_00000000_00000000_00001000,
		supr    = 0b00000000_00000000_00000000_00010000,
	}
} else {
	/**
	 * Key modifiers
	 */
	enum KeyModifier
	{
		none    = 0b00000000_00000000_00000000_00000000,
		shift   = 0b00000000_00000000_00000000_00000001,
		alt     = 0b00000000_00000000_00000000_00000010,
		control = 0b00000000_00000000_00000000_00000100,
		meta    = 0b00000000_00000000_00000000_00001000,
	}
}


/**
 * Availabe commands
 */
enum Command: int
{
	empty = -255,
	unknown = -1,

	nothing = 0x00,
	startOfHeading = 0x01,
	startOfText = 0x02,
	endOfText = 0x03,
	endOfTransmission = 0x04,
	enquiry = 0x05,
	acknowledge = 0x06,
	bell = 0x07,
	backspace = 0x08,
	horizontalTabulation = 0x09,
	lineFeed = 0x0a,
	lineTabulation = 0x0b,
	formFeed = 0x0c,
	carriageReturn = 0x0d,
	shiftOu = 0x0e,
	shiftIn = 0x0f,
	dataLinkEscape = 0x10,
	deviceControlOne = 0x11,
	deviceControlTwo = 0x12,
	deviceControlThree = 0x13,
	deviceControlFour = 0x14,
	negativeAcknowledge = 0x15,
	synchronousIdle = 0x16,
	endOfTransmissionBlock = 0x17,
	cancel = 0x18,
	endOfMedium = 0x19,
	substitute  = 0x1a,
	escape  = 0x1b,
	fileSeparator = 0x1c,
	groupSeparator = 0x1d,
	recordSeparator = 0x1e,
	unitSeparator = 0x1f,
	del = 0x7f,

	keyUp = 0x5b41,
	keyDown = 0x5b42,
	keyRight = 0x5b43,
	keyLeft = 0x5b44,
	keyB2 = 0x5b45,

	keyInsert = 0xfe01,
	keyDelete = 0xfe02,
	keyHome = 0xfe03,
	keyEnd = 0xfe04,
	keyPageUp = 0xfe05,
	keyPageDown = 0xfe06,

	keyF1 = 0xff01,
	keyF2 = 0xff02,
	keyF3 = 0xff03,
	keyF4 = 0xff04,
	keyF5 = 0xff05,
	keyF6 = 0xff06,
	keyF7 = 0xff07,
	keyF8 = 0xff08,
	keyF9 = 0xff09,
	keyF10 = 0xff0a,
	keyF11 = 0xff0b,
	keyF12 = 0xff0c,

	pasteStart = 0xfffffd,
	pasteEnd = 0xfffffe,

	winch = 0xffffff
}


/**
 * Key value
 */
union KeyValue
{
	///ASCII Character
	char c;
	///UTF-8 sequence 2…6 bytes
	ubyte[6] utf;
	///Console command
	Command code;
	///Raw input usualy CSI or SS3 sequence
	string raw;

	///constructor
	this(Command code) @safe { this.code = code; }
	///ditto
	this(char c) @safe { this.c = c; }
	///ditto
	this(ubyte[6] symbol) @safe { this.utf = symbol; }
	///ditto
	this(string raw) @trusted { this.raw = raw; }
}


/**
 * Pressed key
 */
struct Key
{
	///Type
	KeyType type;
	///Value depending on type
	KeyValue content;
	///Key modifier
	uint modifier;

	///constructor
	this(KeyType type, KeyValue content, uint modifier = KeyModifier.none) @safe
	{
		this.type = type;
		this.content = content;
		this.modifier = modifier;
	}

	/*******
	* Returns: string representation of the current key
	*
	*/
	string opCast() @trusted
	{
		import std.conv: to;
		string ret;

		if (modifier & KeyModifier.shift) ret ~= "Shift+";
		if (modifier & KeyModifier.alt) ret ~= "Alt+";
		if (modifier & KeyModifier.control) ret ~= "Ctrl+";
		if (modifier & KeyModifier.meta) ret ~= "Meta+";
		version(WithSuperKey) if (modifier & KeyModifier.supr) ret ~= "Super+";

		with (KeyType) final switch(this.type) {
			case COMMAND:
				ret ~=  to!string(content.code);
				break;
			case ASCII:
				ret ~=  cast(string)[content.c];
				break;
			case UTF8:
				ret ~=  cast(string)content.utf[0 .. content.utf[0].codepointLength];
				break;
			case RAW:
				ret ~= content.raw.escapeString;
				break;
		}

		return ret;
	}
}

