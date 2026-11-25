use crate::{Res, autostart, local};
use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

pub fn dest() -> Res<PathBuf> {
    Ok(local()?.join("quickshell").join("elrice"))
}

fn copy_dir(from: &Path, to: &Path) -> Res<()> {
    fs::create_dir_all(to)?;
    for entry in fs::read_dir(from)? {
        let entry = entry?;
        let target = to.join(entry.file_name());
        if entry.file_type()?.is_dir() {
            copy_dir(&entry.path(), &target)?;
        } else {
            fs::copy(entry.path(), target)?;
        }
    }
    Ok(())
}

const HELPERS: [&str; 2] = ["altwatch.exe", "taskbar.exe"];

fn find_helper(root: &Path, name: &str) -> Res<PathBuf> {
    let beside = env::current_exe()?.with_file_name(name);
    let built = root.join("installer").join("target").join("release").join(name);
    [beside, built]
        .into_iter()
        .find(|p| p.is_file())
        .ok_or_else(|| format!("{name} not found (run cargo build --release in installer/)").into())
}

fn link_dir(from: &Path, to: &Path) -> Res<()> {
    let status = Command::new("cmd")
        .args(["/c", "mklink", "/J"])
        .arg(to)
        .arg(from)
        .stdout(Stdio::null())
        .status()?;
    if !status.success() {
        return Err(format!("could not link {} to {}", to.display(), from.display()).into());
    }
    Ok(())
}

pub fn apply(root: &Path, live: bool) -> Res<()> {
    let helpers = HELPERS.iter().map(|n| find_helper(root, n)).collect::<Res<Vec<_>>>()?;
    autostart::stop();
    let dest = dest()?;
    let standby = dest.join("standby.json");
    let kept = fs::read(&standby).ok();
    let _ = fs::remove_dir_all(&dest);
    if live {
        fs::create_dir_all(dest.parent().ok_or("bad shell dir")?)?;
        link_dir(&root.join("shell"), &dest)?;
    } else {
        copy_dir(&root.join("shell"), &dest)?;
    }
    for (name, helper) in HELPERS.iter().zip(helpers) {
        fs::copy(helper, dest.join(name))?;
    }
    match kept {
        Some(bytes) => fs::write(&standby, bytes)?,
        None if !standby.is_file() => {
            fs::copy(root.join("standby.json"), &standby)?;
        }
        None => {}
    }
    fs::copy(root.join("wallpaper").join("wallpaper.jpg"), dest.join("wallpaper.jpg"))?;
    Ok(())
}

pub fn remove() {
    if let Ok(d) = dest() {
        let _ = fs::remove_dir_all(d);
    }
}
