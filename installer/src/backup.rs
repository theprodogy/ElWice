use crate::{Res, elrice_dir};
use std::fs;
use std::path::{Path, PathBuf};
use winreg::RegKey;
use winreg::enums::{HKEY_CURRENT_USER, KEY_SET_VALUE};

#[derive(Debug, PartialEq)]
pub struct Entry {
    pub kind: String,
    pub target: String,
    pub name: String,
    pub value: String,
}

impl Entry {
    pub fn new(kind: &str, target: &str, name: &str, value: &str) -> Self {
        Self {
            kind: kind.into(),
            target: target.into(),
            name: name.into(),
            value: value.into(),
        }
    }

    pub fn to_line(&self) -> String {
        format!("{}\t{}\t{}\t{}", self.kind, self.target, self.name, self.value)
    }

    pub fn from_line(line: &str) -> Option<Self> {
        let mut p = line.splitn(4, '\t');
        Some(Self::new(p.next()?, p.next()?, p.next()?, p.next()?))
    }
}

fn file() -> Res<PathBuf> {
    Ok(elrice_dir()?.join("backup.txt"))
}

pub fn exists() -> Res<bool> {
    Ok(file()?.is_file())
}

pub fn write(entries: &[Entry]) -> Res<()> {
    fs::create_dir_all(elrice_dir()?)?;
    let text: String = entries.iter().map(|e| e.to_line() + "\n").collect();
    fs::write(file()?, text)?;
    Ok(())
}

pub fn read() -> Res<Vec<Entry>> {
    Ok(fs::read_to_string(file()?)?.lines().filter_map(Entry::from_line).collect())
}

fn hkcu() -> RegKey {
    RegKey::predef(HKEY_CURRENT_USER)
}

pub fn reg(key: &str, name: &str) -> Entry {
    if let Ok(k) = hkcu().open_subkey(key) {
        if let Ok(v) = k.get_value::<u32, _>(name) {
            return Entry::new("dword", key, name, &v.to_string());
        }
        if let Ok(v) = k.get_value::<String, _>(name) {
            return Entry::new("sz", key, name, &v);
        }
    }
    Entry::new("none", key, name, "")
}

pub fn set_dword(key: &str, name: &str, value: u32) -> Res<()> {
    hkcu().create_subkey(key)?.0.set_value(name, &value)?;
    Ok(())
}

pub fn set_sz(key: &str, name: &str, value: &str) -> Res<()> {
    hkcu().create_subkey(key)?.0.set_value(name, &value)?;
    Ok(())
}

pub fn delete_value(key: &str, name: &str) {
    if let Ok(k) = hkcu().open_subkey_with_flags(key, KEY_SET_VALUE) {
        let _ = k.delete_value(name);
    }
}

pub fn file_entry(cfg: &Path, bak: &Path) -> Res<Entry> {
    let mut saved = String::new();
    if cfg.is_file() {
        fs::create_dir_all(elrice_dir()?)?;
        fs::copy(cfg, bak)?;
        saved = bak.to_string_lossy().into_owned();
    }
    Ok(Entry::new("file", &cfg.to_string_lossy(), "", &saved))
}

pub fn restore(e: &Entry) -> Res<()> {
    match e.kind.as_str() {
        "dword" => set_dword(&e.target, &e.name, e.value.parse()?),
        "sz" => set_sz(&e.target, &e.name, &e.value),
        "none" => {
            delete_value(&e.target, &e.name);
            Ok(())
        }
        "wallpaper" => crate::wallpaper::set(&e.value),
        "autohide" => crate::appearance::set_autohide(e.value == "1"),
        "file" => {
            if e.value.is_empty() {
                let _ = fs::remove_file(&e.target);
            } else {
                fs::copy(&e.value, &e.target)?;
            }
            Ok(())
        }
        other => Err(format!("unknown backup kind {other}").into()),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn line_round_trip() {
        let cases = [
            Entry::new("dword", r"Software\X", "AppsUseLightTheme", "0"),
            Entry::new("none", r"Software\X", "", ""),
            Entry::new("wallpaper", "", "", r"C:\Users\a b\wall.jpg"),
        ];
        for e in cases {
            assert_eq!(Entry::from_line(&e.to_line()), Some(e));
        }
        assert_eq!(Entry::from_line("broken"), None);
    }
}
