# ElRice

Created by [@infectedwarelol](https://github.com/infectedwarelol).

![The ElRice desktop with the StandBy clock and widgets](screenshots/desktop.png)

ElRice is a liquid glass desktop rice for Windows 11 that borrows the look of macOS and iOS without pretending to be either. Dark smoked glass all round: a top bar sits over your wallpaper, a StandBy-style clock and a few widgets live on the bare desktop, a glass dock sits at the bottom, and the terminal matches the rest. The icons are drawn SVGs, not emoji. It runs on the Windows port of [Quickshell](https://quickshell.org), and the installer sets that up for you.

The screenshots below are from the GNOME version of the rice, so details on Windows will differ.

| Terminal | Quick Settings | Overview |
| --- | --- | --- |
| ![Terminal on glass](screenshots/terminal.png) | ![Quick Settings](screenshots/quick-settings.png) | ![Overview](screenshots/overview.png) |

## Install

You need Windows 11 22H2 or newer, the Rust toolchain and winget. Clone the repo, build the installer and run it from the clone.

```powershell
git clone https://github.com/infectedwarelol/ElRice
cd ElRice\installer
cargo build --release
target\release\elrice.exe install
```

The installer pulls in [nunreasonable/quickshell-windows](https://github.com/nunreasonable/quickshell-windows) (v0.3.2-win2) to `%LOCALAPPDATA%\Programs\Quickshell` if it is not there yet, then sets up the rest.

## Use

The rice starts on its own at login. To start it by hand, run `qs -c elrice`.

## What it does

- **StandBy clock.** An analog clock and weather card on the desktop, behind your windows, with Calendar, Now Playing and Battery widgets underneath. Now Playing follows any app that shows up in Windows media controls.
- **Top bar.** Dark glass bar with a small logo, the name of the focused app and the clock.
- **Dock.** A glass dock at the bottom with the pinned apps from the `"dock"` list in `standby.json` plus your open windows.
- **Spotlight.** A centred glass search bar that finds installed apps, does quick maths and falls back to a web search. Open it with a tap of the Windows key (Ctrl+Esc still opens the Start menu), the dock's apps button or the bar logo, then use the arrow keys, Enter to launch and Esc to close.
- **Icons.** Weather, battery, media controls and the bar logo are line icons drawn as SVGs in `shell/icons/`.
- **Dark mode.** Windows switches to dark mode with transparency on.
- **Taskbar.** Auto-hidden, replaced by the dock, so the bar and the desktop stay clean.
- **Wallpaper.** The ElRice wallpaper is set for you.
- **Terminal.** A WezTerm config on acrylic glass, with the fastfetch Apple logo.
- **Sounds.** macOS-style sounds.

## Make it yours

| What | Where |
| --- | --- |
| Weather city and unit | `standby.json` |
| Dock apps | `standby.json` |
| Widgets | `shell/*.qml` |
| Glass and blur | `shell/layerrules.json` |
| Terminal | `~/.config/wezterm/wezterm.lua`, written by `installer/src/terminal.rs` |
| Terminal logo | `fastfetch/config.jsonc` |
| Wallpaper | `wallpaper/wallpaper.jpg` |

After you edit files in `shell/`, run `elrice.exe install` again or restart with `qs -c elrice`.

## Uninstall

```powershell
cd ElRice\installer
target\release\elrice.exe revert
```

This restores the registry values, wallpaper and taskbar, removes the autostart entry, the WezTerm config and `%LOCALAPPDATA%\quickshell\elrice`. Quickshell itself stays. To remove it too:

```powershell
& "$env:LOCALAPPDATA\Programs\Quickshell\install.ps1" -Uninstall
```

## If something looks off

- **The clock says "Weather unavailable".** The weather comes from wttr.in, so check that `curl https://wttr.in` works on your network.
- **No glass.** Blur needs the Windows 11 transparency effects switched on.
- **Nothing shows up.** Run `qs -c elrice` in a terminal to see the QML errors.

## Credits

Built on [Quickshell](https://quickshell.org) and its Windows port by [nunreasonable](https://github.com/nunreasonable/quickshell-windows), and [fastfetch](https://github.com/fastfetch-cli/fastfetch). Weather by [wttr.in](https://wttr.in). Dock icons from [WhiteSur-icon-theme](https://github.com/vinceliuice/WhiteSur-icon-theme) by vinceliuice (GPL-3.0, see `shell/icons/dock/`).
