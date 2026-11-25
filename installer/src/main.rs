mod appearance;
mod autostart;
mod backup;
mod fonts;
mod quickshell;
mod shell_config;
mod sounds;
mod terminal;
mod timeserver;
mod wallpaper;

use std::env;
use std::error::Error;
use std::path::{Path, PathBuf};
use std::process::ExitCode;

pub type Res<T> = Result<T, Box<dyn Error>>;

pub fn local() -> Res<PathBuf> {
    Ok(PathBuf::from(env::var_os("LOCALAPPDATA").ok_or("LOCALAPPDATA not set")?))
}

pub fn home() -> Res<PathBuf> {
    Ok(PathBuf::from(env::var_os("USERPROFILE").ok_or("USERPROFILE not set")?))
}

pub fn elrice_dir() -> Res<PathBuf> {
    Ok(local()?.join("ElRice"))
}

fn is_root(dir: &Path) -> bool {
    dir.join("shell").join("shell.qml").is_file() && dir.join("wallpaper").is_dir()
}

fn find_root() -> Res<PathBuf> {
    let starts = [env::current_dir().ok(), env::current_exe().ok()];
    starts
        .into_iter()
        .flatten()
        .flat_map(|p| p.ancestors().map(Path::to_path_buf).collect::<Vec<_>>())
        .find(|d| is_root(d))
        .ok_or_else(|| "repo root not found (need shell/shell.qml and wallpaper/ above the current dir or the exe)".into())
}

fn install(live: bool) -> Res<()> {
    let root = find_root()?;
    println!("repo: {}", root.display());
    quickshell::ensure()?;
    if !backup::exists()? {
        let mut entries = Vec::new();
        entries.extend(wallpaper::snapshot()?);
        entries.extend(appearance::snapshot()?);
        entries.extend(sounds::snapshot()?);
        entries.extend(fonts::snapshot()?);
        entries.extend(autostart::snapshot()?);
        entries.extend(terminal::snapshot()?);
        backup::write(&entries)?;
        println!("backup written");
    }
    shell_config::apply(&root, live)?;
    wallpaper::apply(&root)?;
    appearance::apply()?;
    sounds::apply(&root)?;
    fonts::apply()?;
    terminal::apply(&root)?;
    autostart::apply()?;
    println!("installed");
    Ok(())
}

fn clean_state() -> Res<()> {
    for entry in std::fs::read_dir(elrice_dir()?)? {
        let path = entry?.path();
        if path.file_name().is_some_and(|n| n == quickshell::SCRIPT_FILE) {
            continue;
        }
        if path.is_dir() {
            std::fs::remove_dir_all(path)?;
        } else {
            std::fs::remove_file(path)?;
        }
    }
    Ok(())
}

fn revert() -> Res<()> {
    autostart::stop();
    appearance::show_taskbar();
    autostart::remove();
    terminal::remove();
    timeserver::reset();
    shell_config::remove();
    let mut failed = false;
    if backup::exists()? {
        for entry in backup::read()? {
            if let Err(e) = backup::restore(&entry) {
                failed = true;
                eprintln!("restore failed for {}: {e}", entry.target);
            }
        }
    } else {
        eprintln!("no backup found, skipping registry, wallpaper and taskbar restore");
    }
    if failed {
        return Err(r"some settings could not be restored, backup kept in %LOCALAPPDATA%\ElRice".into());
    }
    if elrice_dir()?.is_dir() {
        clean_state()?;
    }
    println!("reverted");
    println!("Quickshell is still installed.");
    match quickshell::uninstall_command() {
        Ok(cmd) => println!("To remove it run: {cmd}"),
        Err(e) => println!("Could not prepare the uninstall command: {e}"),
    }
    Ok(())
}

fn main() -> ExitCode {
    let result = match env::args().nth(1).as_deref() {
        Some("install") => install(env::args().nth(2).as_deref() == Some("--live")),
        Some("revert") => revert(),
        _ => {
            eprintln!("usage: elrice <install [--live]|revert>");
            return ExitCode::from(2);
        }
    };
    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("error: {e}");
            ExitCode::FAILURE
        }
    }
}
