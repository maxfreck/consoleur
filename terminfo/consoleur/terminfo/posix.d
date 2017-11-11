/**
 * Consoleur: a package for interaction with character-oriented terminal emulators
 *
 * Copyright: Maxim Freck, 2017.
 * Authors:   Maxim Freck <maxim@freck.pp.ru>
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module consoleur.terminfo.posix;
version(Posix) {

import consoleur.terminfo.io;

/// Terminfo boolean capabilities
enum CapFlag: size_t
{
	autoLeftMargin = 0, //Cub1 wraps from column 0 to last column 
	autoRightMargin = 1, //Terminal has automatic margins 
	noEscCtlc = 2, //Beehive (f1=escape, f2=ctrl C) 
	ceolStandoutGlitch = 3, //Standout not erased by overwriting (hp)
	eatNewlineGlitch = 4, //Newline ignored after 80 columns (Concept)
	eraseOverstrike = 5, //Can erase overstrikes with a blank
	genericType = 6, //Generic line type (e.g., dialup, switch)
	hardCopy = 7, //Hardcopy terminal 
	hasMetaKey = 8, //Has a meta key (shift, sets parity bit)
	hasStatusLine = 9, //Has extra "status line" 
	insertNullGlitch = 10, //Insert mode distinguishes nulls
	memoryAbove = 11, //Display may be retained above the screen
	memoryBelow = 12, //Display may be retained below the screen
	moveInsertMode = 13, //Safe to move while in insert mode
	moveStandoutMode = 14, //Safe to move in standout modes
	overStrike = 15, //Terminal overstrikes on hard-copy terminal
	statusLineEscOk = 16, //Escape can be used on the status line
	destTabsMagicSmso = 17, //Destructive tabs, magic smso char (t1061)
	tildeGlitch = 18, //Hazeltine; can't print tilde (~)
	transparentUnderline = 19, //Underline character overstrikes
	xonXoff = 20, //Terminal uses xon/xoff handshaking
	needsXonXoff = 21, //Padding won't work, xon/xoff required
	prtrSilent = 22, //Printer won't echo on screen
	hardCursor = 23, //Cursor is hard to see
	nonRevRmcup = 24, //smcup does not reverse rmcup
	noPadChar = 25, //Pad character doesn't exist
	nonDestScrollRegion = 26, //Scrolling region is nondestructive
	canChange = 27, //Terminal can re-define existing colour
	backColorErase = 28, //Screen erased with background colour
	hueLightnessSaturation = 29, //Terminal uses only HLS colour notation (Tektronix)
	colAddrGlitch = 30, //Only positive motion for hpa/mhpa caps
	crCancelsMicroMode = 31, //Using cr turns off micro mode
	hasPrintWheel = 32, //Printer needs operator to change character set
	rowAddrGlitch = 33, //Only positive motion for vpa/mvpa caps
	semiAutoRightMargin = 34, //Printing in last column causes cr
	cpiChangesRes = 35, //Changing character pitch changes resolution
	lpiChangesRes = 36, //Changing line pitch changes resolution

	backspacesWithBs = 37,
	crtNoScrolling = 38,
	noCorrectlyWorkingCr = 39,
	gnuHasMetaKey = 40,
	linefeedIsNewline = 41,
	hasHardwareTabs = 42,
	returnDoesClrEol = 43,
}

/// Terminfo short capabilities
enum CapShort: size_t
{
	columns = 0, //Number of columns in a line
	initTabs = 1, //Tabs initially every # spaces
	lines = 2, //Number of lines on a screen or a page
	linesOfMemory = 3, //Lines of memory if > lines; 0 means varies
	magicCookieGlitch = 4, //Number of blank characters left by smso or rmso
	paddingBaudRate = 5, //Lowest baud rate where padding needed
	virtualTerminal = 6, //Virtual terminal number
	widthStatusLine = 7, //Number of columns in status line
	numLabels = 8, //Number of labels on screen (start at 1)
	labelHeight = 9, //Number of rows in each label
	labelWidth = 10, //Number of columns in each label
	maxAttributes = 11, //Maximum combined video attributes terminal can display
	maximumWindows = 12, //Maximum number of definable windows
	maxColors = 13, //Maximum number of colours on the screen
	maxPairs = 14, //Maximum number of colour-pairs on the screen
	noColorVideo = 15, //Video attributes that can't be used with colours
	bufferCapacity = 16, //Number of bytes buffered before printing
	dotVertSpacing = 17, //Spacing of pins vertically in pins per inch
	dotHorzSpacing = 18, //Spacing of dots horizontally in dots per inch
	maxMicroAddress = 19, //Maximum value in micro_..._address
	maxMicroJump = 20, //Maximum value in parm_..._micro
	microColSize = 21, //Character step size when in micro mode
	microLineSize = 22, //Line step size when in micro mode
	numberOfPins = 23, //Number of pins in print-head
	outputResChar = 24, //Horizontal resolution in units per character
	outputResLine = 25, //Vertical resolution in units per line
	outputResHorzInch = 26, //Horizontal resolution in units per inch
	outputResVertInch = 27, //Vertical resolution in units per inch
	printRate = 28, //Print rate in characters per second
	wideCharSize = 29, //Character step size when in double-wide mode
	buttons = 30, //Number of buttons on the mouse
	bitImageEntwining = 31, //Number of passes for each bit-map row
	bitImageType = 32, //Type of bit image device

	magicCookieGlitchUl = 33,
	carriageReturnDelay = 34,
	newLineDelay = 35,
	backspaceDelay = 36,
	horizontalTabDelay = 37,
	numberOfFunctionKeys = 38,
}

/// Terminfo string capabilities
enum CapString: size_t
{
	backTab = 0,
	bell = 1,
	carriageReturn = 2,
	changeScrollRegion = 3,
	clearAllTabs = 4,
	clearScreen = 5,
	clrEol = 6,
	clrEos = 7,
	columnAddress = 8,
	commandCharacter = 9,
	cursorAddress = 10,
	cursorDown = 11,
	cursorHome = 12,
	cursorInvisible = 13,
	cursorLeft = 14,
	cursorMemAddress = 15,
	cursorNormal = 16,
	cursorRight = 17,
	cursorToLl = 18,
	cursorUp = 19,
	cursorVisible = 20,
	deleteCharacter = 21,
	deleteLine = 22,
	disStatusLine = 23,
	downHalfLine = 24,
	enterAltCharsetMode = 25,
	enterBlinkMode = 26,
	enterBoldMode = 27,
	enterCaMode = 28,
	enterDeleteMode = 29,
	enterDimMode = 30,
	enterInsertMode = 31,
	enterSecureMode = 32,
	enterProtectedMode = 33,
	enterReverseMode = 34,
	enterStandoutMode = 35,
	enterUnderlineMode = 36,
	eraseChars = 37,
	exitAltCharsetMode = 38,
	exitAttributeMode = 39,
	exitCaMode = 40,
	exitDeleteMode = 41,
	exitInsertMode = 42,
	exitStandoutMode = 43,
	exitUnderlineMode = 44,
	flashScreen = 45,
	formFeed = 46,
	fromStatusLine = 47,
	init1string = 48,
	init2string = 49,
	init3string = 50,
	initFile = 51,
	insertCharacter = 52,
	insertLine = 53,
	insertPadding = 54,
	keyBackspace = 55,
	keyCatab = 56,
	keyClear = 57,
	keyCtab = 58,
	keyDc = 59,
	keyDl = 60,
	keyDown = 61,
	keyEic = 62,
	keyEol = 63,
	keyEos = 64,
	keyF0 = 65,
	keyF1 = 66,
	keyF10 = 67,
	keyF2 = 68,
	keyF3 = 69,
	keyF4 = 70,
	keyF5 = 71,
	keyF6 = 72,
	keyF7 = 73,
	keyF8 = 74,
	keyF9 = 75,
	keyHome = 76,
	keyIc = 77,
	keyIl = 78,
	keyLeft = 79,
	keyLl = 80,
	keyNpage = 81,
	keyPpage = 82,
	keyRight = 83,
	keySf = 84,
	keySr = 85,
	keyStab = 86,
	keyUp = 87,
	keypadLocal = 88,
	keypadXmit = 89,
	labF0 = 90,
	labF1 = 91,
	labF10 = 92,
	labF2 = 93,
	labF3 = 94,
	labF4 = 95,
	labF5 = 96,
	labF6 = 97,
	labF7 = 98,
	labF8 = 99,
	labF9 = 100,
	metaOff = 101,
	metaOn = 102,
	newline = 103,
	padChar = 104,
	parmDch = 105,
	parmDeleteLine = 106,
	parmDownCursor = 107,
	parmIch = 108,
	parmIndex = 109,
	parmInsertLine = 110,
	parmLeftCursor = 111,
	parmRightCursor = 112,
	parmRindex = 113,
	parmUpCursor = 114,
	pkeyKey = 115,
	pkeyLocal = 116,
	pkeyXmit = 117,
	printScreen = 118,
	prtrOff = 119,
	prtrOn = 120,
	repeatChar = 121,
	reset1string = 122,
	reset2string = 123,
	reset3string = 124,
	resetFile = 125,
	restoreCursor = 126,
	rowAddress = 127,
	saveCursor = 128,
	scrollForward = 129,
	scrollReverse = 130,
	setAttributes = 131,
	setTab = 132,
	setWindow = 133,
	tab = 134,
	toStatusLine = 135,
	underlineChar = 136,
	upHalfLine = 137,
	initProg = 138,
	keyA1 = 139,
	keyA3 = 140,
	keyB2 = 141,
	keyC1 = 142,
	keyC3 = 143,
	prtrNon = 144,
	charPadding = 145,
	acsChars = 146,
	plabNorm = 147,
	keyBtab = 148,
	enterXonMode = 149,
	exitXonMode = 150,
	enterAmMode = 151,
	exitAmMode = 152,
	xonCharacter = 153,
	xoffCharacter = 154,
	enaAcs = 155,
	labelOn = 156,
	labelOff = 157,
	keyBeg = 158,
	keyCancel = 159,
	keyClose = 160,
	keyCommand = 161,
	keyCopy = 162,
	keyCreate = 163,
	keyEnd = 164,
	keyEnter = 165,
	keyExit = 166,
	keyFind = 167,
	keyHelp = 168,
	keyMark = 169,
	keyMessage = 170,
	keyMove = 171,
	keyNext = 172,
	keyOpen = 173,
	keyOptions = 174,
	keyPrevious = 175,
	keyPrint = 176,
	keyRedo = 177,
	keyReference = 178,
	keyRefresh = 179,
	keyReplace = 180,
	keyRestart = 181,
	keyResume = 182,
	keySave = 183,
	keySuspend = 184,
	keyUndo = 185,
	keySbeg = 186,
	keyScancel = 187,
	keyScommand = 188,
	keyScopy = 189,
	keyScreate = 190,
	keySdc = 191,
	keySdl = 192,
	keySelect = 193,
	keySend = 194,
	keySeol = 195,
	keySexit = 196,
	keySfind = 197,
	keyShelp = 198,
	keyShome = 199,
	keySic = 200,
	keySleft = 201,
	keySmessage = 202,
	keySmove = 203,
	keySnext = 204,
	keySoptions = 205,
	keySprevious = 206,
	keySprint = 207,
	keySredo = 208,
	keySreplace = 209,
	keySright = 210,
	keySrsume = 211,
	keySsave = 212,
	keySsuspend = 213,
	keySundo = 214,
	reqForInput = 215,
	keyF11 = 216,
	keyF12 = 217,
	keyF13 = 218,
	keyF14 = 219,
	keyF15 = 220,
	keyF16 = 221,
	keyF17 = 222,
	keyF18 = 223,
	keyF19 = 224,
	keyF20 = 225,
	keyF21 = 226,
	keyF22 = 227,
	keyF23 = 228,
	keyF24 = 229,
	keyF25 = 230,
	keyF26 = 231,
	keyF27 = 232,
	keyF28 = 233,
	keyF29 = 234,
	keyF30 = 235,
	keyF31 = 236,
	keyF32 = 237,
	keyF33 = 238,
	keyF34 = 239,
	keyF35 = 240,
	keyF36 = 241,
	keyF37 = 242,
	keyF38 = 243,
	keyF39 = 244,
	keyF40 = 245,
	keyF41 = 246,
	keyF42 = 247,
	keyF43 = 248,
	keyF44 = 249,
	keyF45 = 250,
	keyF46 = 251,
	keyF47 = 252,
	keyF48 = 253,
	keyF49 = 254,
	keyF50 = 255,
	keyF51 = 256,
	keyF52 = 257,
	keyF53 = 258,
	keyF54 = 259,
	keyF55 = 260,
	keyF56 = 261,
	keyF57 = 262,
	keyF58 = 263,
	keyF59 = 264,
	keyF60 = 265,
	keyF61 = 266,
	keyF62 = 267,
	keyF63 = 268,
	clrBol = 269,
	clearMargins = 270,
	setLeftMargin = 271,
	setRightMargin = 272,
	labelFormat = 273,
	setClock = 274,
	displayClock = 275,
	removeClock = 276,
	createWindow = 277,
	gotoWindow = 278,
	hangup = 279,
	dialPhone = 280,
	quickDial = 281,
	tone = 282,
	pulse = 283,
	flashHook = 284,
	fixedPause = 285,
	waitTone = 286,
	user0 = 287,
	user1 = 288,
	user2 = 289,
	user3 = 290,
	user4 = 291,
	user5 = 292,
	user6 = 293,
	user7 = 294,
	user8 = 295,
	user9 = 296,
	origPair = 297,
	origColors = 298,
	initializeColor = 299,
	initializePair = 300,
	setColorPair = 301,
	setForeground = 302,
	setBackground = 303,
	changeCharPitch = 304,
	changeLinePitch = 305,
	changeResHorz = 306,
	changeResVert = 307,
	defineChar = 308,
	enterDoublewideMode = 309,
	enterDraftQuality = 310,
	enterItalicsMode = 311,
	enterLeftwardMode = 312,
	enterMicroMode = 313,
	enterNearLetterQuality = 314,
	enterNormalQuality = 315,
	enterShadowMode = 316,
	enterSubscriptMode = 317,
	enterSuperscriptMode = 318,
	enterUpwardMode = 319,
	exitDoublewideMode = 320,
	exitItalicsMode = 321,
	exitLeftwardMode = 322,
	exitMicroMode = 323,
	exitShadowMode = 324,
	exitSubscriptMode = 325,
	exitSuperscriptMode = 326,
	exitUpwardMode = 327,
	microColumnAddress = 328,
	microDown = 329,
	microLeft = 330,
	microRight = 331,
	microRowAddress = 332,
	microUp = 333,
	orderOfPins = 334,
	parmDownMicro = 335,
	parmLeftMicro = 336,
	parmRightMicro = 337,
	parmUpMicro = 338,
	selectCharSet = 339,
	setBottomMargin = 340,
	setBottomMarginParm = 341,
	setLeftMarginParm = 342,
	setRightMarginParm = 343,
	setTopMargin = 344,
	setTopMarginParm = 345,
	startBitImage = 346,
	startCharSetDef = 347,
	stopBitImage = 348,
	stopCharSetDef = 349,
	subscriptCharacters = 350,
	superscriptCharacters = 351,
	theseCauseCr = 352,
	zeroMotion = 353,
	charSetNames = 354,
	keyMouse = 355,
	mouseInfo = 356,
	reqMousePos = 357,
	getMouse = 358,
	setAForeground = 359,
	setABackground = 360,
	pkeyPlab = 361,
	deviceType = 362,
	codeSetInit = 363,
	set0DesSeq = 364,
	set1DesSeq = 365,
	set2DesSeq = 366,
	set3DesSeq = 367,
	setLrMargin = 368,
	setTbMargin = 369,
	bitImageRepeat = 370,
	bitImageNewline = 371,
	bitImageCarriageReturn = 372,
	colorNames = 373,
	defineBitImageRegion = 374,
	endBitImageRegion = 375,
	setColorBand = 376,
	setPageLength = 377,
	displayPcChar = 378,
	enterPcCharsetMode = 379,
	exitPcCharsetMode = 380,
	enterScancodeMode = 381,
	exitScancodeMode = 382,
	pcTermOptions = 383,
	scancodeEscape = 384,
	altScancodeEsc = 385,
	enterHorizontalHlMode = 386,
	enterLeftHlMode = 387,
	enterLowHlMode = 388,
	enterRightHlMode = 389,
	enterTopHlMode = 390,
	enterVerticalHlMode = 391,
	setAAttributes = 392,
	setPglenInch = 393,
	termcapInit2 = 394,
	termcapReset = 395,
	linefeedIfNotLf = 396,
	backspaceIfNotBs = 397,
	otherNonFunctionKeys = 398,
	arrowKeyMap = 399,
	acsUlcorner = 400,
	acsLlcorner = 401,
	acsUrcorner = 402,
	acsLrcorner = 403,
	acsLtee = 404,
	acsRtee = 405,
	acsBtee = 406,
	acsTtee = 407,
	acsHline = 408,
	acsVline = 409,
	acsPlus = 410,
	memoryLock = 411,
	memoryUnlock = 412,
	boxChars1 = 413,
}

/// Terminfo load status
enum TerminfoStatus: ubyte {
	notLoaded = 0,
	invalidFile,
	headerLoaded,
	namesLoaded,
	flagsLoaded,
	shortsLoaded,
	stringsLoaded,

	loaded = 255,
}

/*******
 * Terminfo file reader
 */
class Terminfo
{
	private string fileName;
	private TerminfoStatus fileStatus;

	private string[] termNames;

	private bool[CapFlag] flags;
	private short[CapShort] shorts;
	private string[CapString] strings;

	/// Constructor
	public this() @safe
	{
		this(determineTermFile());
	}

	///ditto
	public this(string fName) @safe
	{
		fileName = fName;
		fileStatus = TerminfoStatus.notLoaded;

		if (fileName.length > 0) loadTerminfo();
	}

	protected void loadTerminfo() @trusted
	{
		import std.array: split;
		import std.stdio: File, SEEK_CUR;

		auto f = File(fileName, "rb");

		if (f.get!ushort != 0x011a) {
			fileStatus = TerminfoStatus.invalidFile;
			return;
		}

		auto namesSize = f.get!ushort;
		auto booleanSize = f.get!ushort;
		auto shortsSize = f.get!ushort;
		auto stringOffsetsSize = f.get!ushort;
		auto stringTableSize = f.get!ushort;

		fileStatus = TerminfoStatus.headerLoaded;

		foreach (name; f.get!char(namesSize)[0..$-1].split("|")) termNames ~= cast(string)(name);
		fileStatus = TerminfoStatus.namesLoaded;

		auto flgs = f.get!bool(booleanSize);
		foreach(n; 0 .. flgs.length) {
			if (flgs[n]) flags[cast(CapFlag)n] = flgs[n];
		}
		fileStatus = TerminfoStatus.flagsLoaded;

		//Between the boolean section and the number section,
		//a null byte will be inserted, if necessary, to ensure
		//that the number section begins on an even byte.
		if (f.tell % 2) f.seek(1, SEEK_CUR);

		auto shrts = f.get!short(shortsSize);
		foreach(n; 0 .. shrts.length ) {
			if (shrts[n] > 0) shorts[cast(CapShort)n] = shrts[n];
		}

		fileStatus = TerminfoStatus.shortsLoaded;

		auto offsets = f.get!short(stringOffsetsSize);
		auto stringtable = f.get!ubyte(stringTableSize);
		parseStrings(offsets, stringtable);
		fileStatus = TerminfoStatus.stringsLoaded;

/+ <TODO>
		if (f.tell != f.size) {
			if (f.tell % 2) f.seek(1, SEEK_CUR);
			readExtendedData(f);
		}
</TODO> +/
		fileStatus = TerminfoStatus.loaded;
	}

	protected void parseStrings(short[] offsets, ubyte[] stringtable)
	{
		foreach (n; 0..offsets.length) {
			if (offsets[n] < 0 ) continue;
			size_t start = offsets[n];
			size_t end = start;
			while (end < stringtable.length && stringtable[end]) end++;

			strings[cast(CapString)n] = cast(string)stringtable[start .. end];
		}
	}

/+ <TODO>
	protected void readExtendedData(File f)
	{
		import std.stdio;
		import std.array: split;

		auto f1 = File("namedump.txt", "wb");

		auto flagsSize = f.get!ushort;
		auto shortsSize = f.get!ushort;
		auto stringsSize = f.get!ushort;
		auto offsetCount = f.get!ushort;
		auto tableSize = f.get!ushort;

		writefln("Flags size...........%u", flagsSize);
		writefln("Shorts size..........%u", shortsSize);
		writefln("String offsets size..%u", stringsSize);
		writefln("String table size....%u", offsetCount);
		writefln("Last offset..........%u", tableSize);

		auto flgs = f.get!bool(flagsSize);
		if (flagsSize % 2) f.seek(1, SEEK_CUR);

		auto shrts = f.get!short(shortsSize);
		auto offsets = f.get!short(stringsSize);

		auto offsets1 = f.get!short(flagsSize + shortsSize + stringsSize);

		auto stringtable = f.get!char(tableSize);

		string[] stringTable;
		foreach (str; stringtable.split(0)) if (str.length > 0) stringTable ~= cast(string)str;

		size_t namesSize = flagsSize + shortsSize + stringsSize;
		auto strings = stringTable[0 .. $ - namesSize];
		auto names = stringTable[$ - namesSize .. $];

		f1.writeln("Strings");
		f1.writeln(strings);

		f1.writeln("\nNames");
		f1.writeln(names);

		size_t id = 0;
		foreach (b; flgs) {
			writefln("%s = %s", names[id++], b);
		}

		foreach (sh; shrts) {
			writefln("%s = %s", names[id++], sh);
		}

		foreach (str; strings) {
			writefln("%s = %s", names[id++], str);
		}
	}
</TODO> +/

	/*******
	 * Returns: terminfo load status
	 */
	public nothrow TerminfoStatus getStatus() @safe @nogc
	{
		return fileStatus;
	}

	/*******
	 * Returns: terminfo file name
	 */
	public nothrow string getFileName() @safe @nogc
	{
		return fileName;
	}

	/*******
	 * Returns: list of terminal names
	 */
	public nothrow string[] getTermNames() @safe @nogc
	{
		return termNames;
	}

	/*******
	 * Returns: terminfo boolean capability
	 */
	public nothrow bool get(CapFlag f) @safe @nogc
	{
		auto flg = (f in flags);
		if (flg is null) return false;
		return *flg;
	}

	/*******
	 * Returns: terminfo int capability
	 */
	public nothrow short get(CapShort s) @safe @nogc
	{
		auto shrt = (s in shorts);
		if (shrt is null) return -1;
		return *shrt;
	}

	/*******
	 * Returns: terminfo string capability
	 */
	public nothrow string get(CapString s) @safe @nogc
	{
		auto str = (s in strings);
		if (str is null) return "";
		return *str;
	}

	private static Terminfo actual;

	/*******
	 * Returns: terminfo reader depending on $TERM env
	 */
	public static Terminfo getActual() @safe
	{
		if (actual is null) {
			actual = new Terminfo();
		}
		return actual;
	}
}

}