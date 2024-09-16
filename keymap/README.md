# Draw keymaps

Based on [@caksoylar](https://github.com/caksoylar/)'s [keymap-drawer](https://github.com/caksoylar/keymap-drawer).

Redraws keymap automatically after commit and stores SVG to reporsitory.

## Sources

`likeeb.json` - keys placement
`config.yaml` - drawer config

## Parse keymap

```
keymap parse -c 10 --config ./config.yaml -z ../config/likeeb.keymap >keymap.yaml
```

Parses zmk config and creates `keymap.yaml`. Replaces key codes with glyphs.

Russian layout is a copy of `keymap.yaml` stored in `keymap-ru.yaml` with some cutted layers and some combos.

## Draw keymap

```
keymap -c config.yaml draw keymap.yaml >keymap.svg

keymap -c config.yaml draw keymap-ru.yaml >keymap-ru.svg
```