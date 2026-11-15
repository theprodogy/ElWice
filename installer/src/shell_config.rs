use crate::{Res, local};
use std::fs;
use std::path::{Path, PathBuf};

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

pub fn apply(root: &Path) -> Res<()> {
    let dest = dest()?;
    let _ = fs::remove_dir_all(&dest);
    copy_dir(&root.join("shell"), &dest)?;
    fs::copy(root.join("standby.json"), dest.join("standby.json"))?;
    fs::copy(root.join("wallpaper").join("wallpaper.jpg"), dest.join("wallpaper.jpg"))?;
    Ok(())
}

pub fn remove() {
    if let Ok(d) = dest() {
        let _ = fs::remove_dir_all(d);
    }
}
