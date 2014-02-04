# ASL Popup
Version of my text->ASL app but in a status bar popup. This allows videos to pop up anywhere, including over fullscreen apps.

## Current Issues
- first time the hotkey is issued the video isn't loaded
- NSTextDidEndEditingNotification is fired when the video is opened via hotkey

## Todos
- Video/playlist looping
- Dynamically building a playlist for sentences. E.g.:
  - "The father loves the child." would queue the videos "FATHER", "LOVE", "CHILD" (as an SVO example)



# Popup

Popup project is a demo with custom popover window appearing from the icon in the Mac OS X status bar.

# License

Popup is licensed under the BSD license.
