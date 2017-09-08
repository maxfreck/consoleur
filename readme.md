# Consoleur
> Please use with caution. Consoleur in the active development, some interfaces and behavior may change in future releases.

A package for interaction with character-oriented terminal emulators.

## Features
* Output coloring and formatting.
* Cursor positioning.
* UTF-8 input with codepoint and CSI/SS3 sequences detection.
* Special keys recognition.
* Support for [Konsole](https://konsole.kde.org/) `super` key.
* CLI UI elements: password input and progress bar.

## Some restrictions
* It is assumed that the terminal operates in the UTF-8 encoding.
* Special keys detector assumes that a PC-compatible keyboard is used. I.e. keyboard has F1 — F12 function keys and Shift, Control and Alt modifier keys.

## To-Do
* Unit tests.
* Better documentation.
* Support for mouse input.
* Support for Windows cmd.exe.