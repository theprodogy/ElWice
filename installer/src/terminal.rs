use crate::backup::{Entry, file_entry};
use crate::{Res, elrice_dir, home, local};
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

const WEZTERM_CONFIG: &str = r##"local wezterm = require 'wezterm'

return {
  font = wezterm.font_with_fallback { 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Cascadia Code', 'Consolas' },
  font_size = 12.0,
  colors = {
    background = '#18181C',
    foreground = '#D8DCFF',
    cursor_bg = '#8AA4FF',
    cursor_border = '#8AA4FF',
    cursor_fg = '#18181C',
    selection_bg = '#3B3570',
    selection_fg = '#D8DCFF',
    ansi = { '#18181C', '#FF7A93', '#9ECE6A', '#E0AF68', '#8AA4FF', '#BB9AF7', '#7DCFFF', '#D8DCFF' },
    brights = { '#4A4D66', '#FF9DB0', '#B9E78A', '#F2C98A', '#A9BEFF', '#D0B8FF', '#A4E0FF', '#FFFFFF' },
  },
  window_background_opacity = 0.55,
  win32_system_backdrop = 'Acrylic',
  window_padding = { left = 18, right = 18, top = 14, bottom = 14 },
  initial_cols = 110,
  initial_rows = 30,
  enable_tab_bar = false,
  window_close_confirmation = 'NeverPrompt',
  default_prog = { 'powershell.exe', '-NoLogo', '-NoProfile', '-NoExit', '-Command', 'fastfetch' },
}
"##;

fn fragment_dir() -> Res<PathBuf> {
    Ok(local()?.join("Microsoft").join("Windows Terminal").join("Fragments").join("ElRice"))
}

fn wezterm_config() -> Res<PathBuf> {
    Ok(home()?.join(".config").join("wezterm").join("wezterm.lua"))
}

fn wezterm_backup() -> Res<PathBuf> {
    Ok(elrice_dir()?.join("wezterm-config.bak"))
}

fn has_wezterm() -> bool {
    Command::new("where").arg("wezterm").output().is_ok_and(|o| o.status.success())
        || Path::new(r"C:\Program Files\WezTerm\wezterm.exe").exists()
}

fn fastfetch_config() -> Res<PathBuf> {
    Ok(home()?.join(".config").join("fastfetch").join("config.jsonc"))
}

fn fastfetch_backup() -> Res<PathBuf> {
    Ok(elrice_dir()?.join("fastfetch-config.bak"))
}

fn has_fastfetch() -> bool {
    Command::new("where").arg("fastfetch").output().is_ok_and(|o| o.status.success())
}

fn winget_install(id: &str, name: &str) {
    let ok = Command::new("winget")
        .args(["install", "--id", id, "-e", "--accept-package-agreements", "--accept-source-agreements"])
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .status()
        .is_ok_and(|s| s.success());
    if !ok {
        eprintln!("warning: {name} install failed, install it manually");
    }
}

pub fn snapshot() -> Res<Vec<Entry>> {
    Ok(vec![
        file_entry(&fastfetch_config()?, &fastfetch_backup()?)?,
        file_entry(&wezterm_config()?, &wezterm_backup()?)?,
    ])
}

pub fn apply(root: &Path) -> Res<()> {
    if !has_wezterm() {
        winget_install("wez.wezterm", "WezTerm");
    }
    if !has_fastfetch() {
        winget_install("Fastfetch-cli.Fastfetch", "fastfetch");
    }
    let cfg = fastfetch_config()?;
    fs::create_dir_all(cfg.parent().ok_or("bad fastfetch path")?)?;
    fs::copy(root.join("fastfetch").join("config.jsonc"), cfg)?;
    let wez = wezterm_config()?;
    fs::create_dir_all(wez.parent().ok_or("bad wezterm path")?)?;
    fs::write(wez, WEZTERM_CONFIG)?;
    Ok(())
}

pub fn remove() {
    if let Ok(d) = fragment_dir() {
        let _ = fs::remove_dir_all(d);
    }
}
