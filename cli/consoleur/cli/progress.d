/**
 * Consoleur: a package for interaction with character-oriented terminal emulators
 *
 * Copyright: Maxim Freck, 2017.
 * Authors:   Maxim Freck <maxim@freck.pp.ru>
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module consoleur.cli.progress;

class Progress
{
	import std.stdio: stderr, stdout, writef, writeln;
	import consoleur.core, consoleur.cursor, consoleur.screen, consoleur.cli.util;
public:

	/*******
	* Constructor
	*
	* Params:
	*  title = Progress bar title
	*/
	this(string title = "")
	{
		stdout.flush();
		savePosition();
		setTitle(title);
	}

	/*******
	* Sets new progress bar title
	*
	* Params:
	*  title = Progress bar title
	*/
	void setTitle(string title)
	{
		this.title = title;
	}

	/*******
	* Sets new progress bar percents
	*
	* Params:
	*  pct = Percent
	*/
	void setPercent(int pct)
	{
		if (isAttyOut()) {
			setPercentTty(pct);
		} else {
			setPercentRedirected(pct);
		}
	}

private:
	enum FILLED_PERCENT = 0;
	enum EMPTY_PERCENT = 1;
	enum OPEN_BAR = 2;
	enum CLOSE_BAR = 3;

	string title;
	ubyte filledColor = 0;
	int row;

	wchar[4] blocks = ['█', '░', '┨', '┠'];

	wchar[] spinner = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

	///Spinner examples
	//wchar[] spinner = ['▖','▘','▝','▗'];
	//wchar[] spinner = ['▌','▀','▐','▄'];
	//wchar[] spinner = ['▉','▊','▋','▌','▍','▎','▏','▎','▍','▌','▋','▊','▉'];
	//wchar[] spinner = ['▁','▃','▄','▅','▆','▇','█','▇','▆','▅','▄','▃'];
	//wchar[] spinner = ['☱','☲','☴'];
	//wchar[] spinner = ['⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏'];
	//wchar[] spinner = ['⠋','⠙','⠚','⠞','⠖','⠦','⠴','⠲','⠳','⠓'];
	//wchar[] spinner = ['⠄','⠆','⠇','⠋','⠙','⠸','⠰','⠠','⠰','⠸','⠙','⠋','⠇','⠆'];
	//wchar[] spinner = ['⠋','⠙','⠚','⠒','⠂','⠂','⠒','⠲','⠴','⠦','⠖','⠒','⠐','⠐','⠒','⠓','⠋'];
	//wchar[] spinner = ['⠁','⠉','⠙','⠚','⠒','⠂','⠂','⠒','⠲','⠴','⠤','⠄','⠄','⠤','⠴','⠲','⠒','⠂','⠂','⠒','⠚','⠙','⠉','⠁'];
	//wchar[] spinner = ['⠈','⠉','⠋','⠓','⠒','⠐','⠐','⠒','⠖','⠦','⠤','⠠','⠠','⠤','⠦','⠖','⠒','⠐','⠐','⠒','⠓','⠋','⠉','⠈'];
	//wchar[] spinner = ['⠁','⠁','⠉','⠙','⠚','⠒','⠂','⠂','⠒','⠲','⠴','⠤','⠄','⠄','⠤','⠠','⠠','⠤','⠦','⠖','⠒','⠐','⠐','⠒','⠓','⠋','⠉','⠈','⠈'];
	//wchar[] spinner = ['⢄','⢂','⢁','⡁','⡈','⡐','⡠'];
	//wchar[] spinner = ['⢹','⢺','⢼','⣸','⣇','⡧','⡗','⡏'];
	//wchar[] spinner = ['⣾','⣽','⣻','⢿','⡿','⣟','⣯','⣷'];
	//wchar[] spinner = ['⠁','⠂','⠄','⡀','⢀','⠠','⠐','⠈'];

	void setPercentTty(int pct)
	{
		if (pct < 0) pct = 0;
		if (pct > 100) pct  = 100;


		if (row > 0) {
			moveCursorTo(Point(row, 1));
		} else {
			saveCursorPosition();
		}

		uint width = cast(uint)(getScreenSize().col - 11 - title.length);
		uint done = cast(uint)((width*pct)/100);

		writef(" %s %c %c%s%s%c%3s%% ",
			title,
			progressSymbol(pct),
			blocks[OPEN_BAR],
			repeat(blocks[FILLED_PERCENT], done),
			repeat(blocks[EMPTY_PERCENT], width - done),
			blocks[CLOSE_BAR],
			pct,
		);
		stdout.flush();

		if (row <= 0) restoreCursorPosition();
	}

	void setPercentRedirected(int pct)
	{
		import std.conv: to;
		writeln(title~to!string(pct));
	}

	void savePosition()
	{
		if (!isAttyOut()) return;

		import std.stdio: writeln;

		immutable pos = getCursorPosition();
		row = pos.row;
		if (pos.col > 1) {
			auto window = getScreenSize();
			if(window.row == row) {
				writeln();
			} else {
				row+=1;
			}
		}
	}

	wchar progressSymbol(int percent)
	{
		return spinner[percent % spinner.length];
	}
}
