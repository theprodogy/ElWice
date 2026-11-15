use crate::backup::{Entry, reg, set_sz};
use crate::{Res, elrice_dir};
use std::fs;
use std::path::Path;

const MAP: [(&str, &str); 5] = [
    ("WindowsLogon", "desktop-login"),
    ("WindowsLogoff", "desktop-logout"),
    ("SystemNotification", "message-new-instant"),
    ("Notification.Default", "message-new-instant"),
    ("SystemExclamation", "dialog-warning"),
];

fn key(event: &str) -> String {
    format!(r"AppEvents\Schemes\Apps\.Default\{event}\.Current")
}

pub fn snapshot() -> Res<Vec<Entry>> {
    Ok(MAP.iter().map(|(event, _)| reg(&key(event), "")).collect())
}

pub fn apply(root: &Path) -> Res<()> {
    let dest = elrice_dir()?.join("sounds");
    fs::create_dir_all(&dest)?;
    let src = root.join("share").join("sounds").join("macos-glass").join("stereo");
    for (event, sound) in MAP {
        let file = format!("{sound}.wav");
        let target = dest.join(&file);
        fs::copy(src.join(&file), &target)?;
        set_sz(&key(event), "", &target.to_string_lossy())?;
    }
    Ok(())
}
