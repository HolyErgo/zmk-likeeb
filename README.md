# ZMK config for [Likeeb](https://github.com/HolyErgo/likeeb)

The keymap lives only in `config/likeeb.keymap`: ZMK Studio is off, because bindings saved by Studio override the file.

The language key sends F19 on the Base layer (Russian) and F18 on the RU layer (English) and toggles the RU layer. `macos/likeeb-english.swift` selects the matching macOS input source on F18 and F19 and selects English when the keyboard connects to the Mac: after sleep or reboot the keyboard starts on the Base layer. The agent needs no macOS permissions: Carbon global hotkeys and TISSelectInputSource work without them. Ctrl+Space is not used: after a programmatic selection the macOS switcher skips the next Ctrl+Space. Install:

```sh
app=~/Applications/likeeb-english.app
mkdir -p "$app/Contents/MacOS" && cp macos/Info.plist "$app/Contents/"
swiftc -O -o "$app/Contents/MacOS/likeeb-english" macos/likeeb-english.swift
cp macos/org.holyergo.likeeb-english.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.holyergo.likeeb-english.plist
```

Log: `~/Library/Logs/likeeb-english.log`.

You can fork of this repository and customize layout with [Keymap Editor](https://nickcoutsos.github.io/keymap-editor/).


![](./keymap/likeeb.svg)
