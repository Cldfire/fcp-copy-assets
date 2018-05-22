# FCP Copy Assets

A tiny tool to copy FCP X assets to a selected folder.

![usage demo](usage_demo.gif)

## Details

This tool parses FCPXML input for `assets`, grabs the path to each asset (specified by the `src` attribute), and then attempts to copy each asset to a folder of your choice. Filenames are not changed; if an asset filename conflicts with a filename in your chosen folder, the asset will not be copied and you will be alerted that it has not been.

My use-case is copying all assets sharing a keyword to an external drive for transfer to another machine.

### Sandbox

I had to turn off sandboxing for this app since the asset filepaths are only indirectly provided by the user (through FCPXML input), not directly, and therefore do not get whitelisted. This doesn't really matter, though, since macOS's sandbox implementation is [pretty useless anyway](https://krausefx.com/blog/mac-privacy-sandboxed-mac-apps-can-take-screenshots).

The code is short, straightforward, documented, and mostly in a single file (DropView.swift). I would encourage you to read it if you are bothered by the lack of sandboxing.
