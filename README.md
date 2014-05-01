#SMARTSign - Assistant Mac
The SMARTSign-Assistant Mac application. A menubar application that allows users to search for a word through Georgia Tech's Center for Accesible Technology in Sign's (CATS) text->ASL database and then play the resulting sign.

Note: the default hotkey (currently hardcoded) is `CTRL-F1`

## Current Issues
- first time the hotkey is issued the video isn't loaded
- Changing the hotkey from the preferences window doesn't work yet

## Todos
- redesign how the interface works when multiple videos are found
    - Show video list in a column on the right of the player section
- give option for configuring hotkey
    - currently using MASShortcut for this, but having issues with the keybinding not actually happening
- give option for Menubar/normal application

## Installation
- This applications requires the use of [CocoaPods](http://cocoapods.org/). After `pods` has been installed run `pod install` from the project root to install dependencies
- Open and compile with Xcode

This project is based off of the following project:

## [Popup](https://github.com/shpakovski/Popup)

Popup project is a demo with custom popover window appearing from the icon in the Mac OS X status bar.

## License

Popup is licensed under the BSD license.
