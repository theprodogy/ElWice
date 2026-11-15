use crate::backup::Entry;
use crate::{Res, elrice_dir};
use std::ffi::{OsStr, c_void};
use std::fs;
use std::io;
use std::os::windows::ffi::OsStrExt;
use std::path::Path;
use windows_sys::Win32::UI::WindowsAndMessaging::{
    SPI_GETDESKWALLPAPER, SPI_SETDESKWALLPAPER, SPIF_SENDCHANGE, SPIF_UPDATEINIFILE,
    SystemParametersInfoW,
};

pub fn wide(s: &str) -> Vec<u16> {
    OsStr::new(s).encode_wide().chain(Some(0)).collect()
}

fn current() -> String {
    let mut buf = [0u16; 520];
    unsafe {
        SystemParametersInfoW(SPI_GETDESKWALLPAPER, 520, buf.as_mut_ptr().cast(), 0);
    }
    let len = buf.iter().position(|&c| c == 0).unwrap_or(buf.len());
    String::from_utf16_lossy(&buf[..len])
}

pub fn set(path: &str) -> Res<()> {
    let mut w = wide(path);
    let ok = unsafe {
        SystemParametersInfoW(
            SPI_SETDESKWALLPAPER,
            0,
            w.as_mut_ptr().cast::<c_void>(),
            SPIF_UPDATEINIFILE | SPIF_SENDCHANGE,
        )
    };
    if ok == 0 {
        return Err(io::Error::last_os_error().into());
    }
    Ok(())
}

pub fn snapshot() -> Res<Vec<Entry>> {
    Ok(vec![Entry::new("wallpaper", "", "", &current())])
}

pub fn apply(root: &Path) -> Res<()> {
    let dir = elrice_dir()?;
    fs::create_dir_all(&dir)?;
    let dest = dir.join("wallpaper.jpg");
    fs::copy(root.join("wallpaper").join("wallpaper.jpg"), &dest)?;
    set(&dest.to_string_lossy())
}
