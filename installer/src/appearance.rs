use crate::Res;
use crate::backup::{Entry, reg, set_dword};
use crate::wallpaper::wide;
use std::mem::{size_of, zeroed};
use std::ptr::{null, null_mut};
use windows_sys::Win32::UI::Shell::{ABM_GETSTATE, ABM_SETSTATE, ABS_AUTOHIDE, APPBARDATA, SHAppBarMessage};
use windows_sys::Win32::UI::WindowsAndMessaging::{
    FindWindowExW, FindWindowW, HWND_BROADCAST, SMTO_ABORTIFHUNG, SW_SHOW, SendMessageTimeoutW, ShowWindow,
    WM_SETTINGCHANGE,
};

const KEY: &str = r"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize";
const VALUES: [&str; 3] = ["AppsUseLightTheme", "SystemUsesLightTheme", "EnableTransparency"];

fn bar() -> APPBARDATA {
    let mut d: APPBARDATA = unsafe { zeroed() };
    d.cbSize = size_of::<APPBARDATA>() as u32;
    d.hWnd = unsafe { FindWindowW(wide("Shell_TrayWnd").as_ptr(), null()) };
    d
}

fn state() -> usize {
    let mut d = bar();
    unsafe { SHAppBarMessage(ABM_GETSTATE, &mut d) }
}

pub fn set_autohide(on: bool) -> Res<()> {
    let mut d = bar();
    let flag = ABS_AUTOHIDE as usize;
    d.lParam = ((state() & !flag) | if on { flag } else { 0 }) as isize;
    unsafe { SHAppBarMessage(ABM_SETSTATE, &mut d) };
    Ok(())
}

pub fn show_taskbar() {
    for class in ["Shell_TrayWnd", "Shell_SecondaryTrayWnd"] {
        let class = wide(class);
        let mut h = null_mut();
        loop {
            h = unsafe { FindWindowExW(null_mut(), h, class.as_ptr(), null()) };
            if h.is_null() {
                break;
            }
            unsafe { ShowWindow(h, SW_SHOW) };
        }
    }
}

pub fn snapshot() -> Res<Vec<Entry>> {
    let mut entries: Vec<Entry> = VALUES.iter().map(|n| reg(KEY, n)).collect();
    let hidden = state() & ABS_AUTOHIDE as usize != 0;
    entries.push(Entry::new("autohide", "", "", if hidden { "1" } else { "0" }));
    Ok(entries)
}

pub fn apply() -> Res<()> {
    for name in VALUES {
        set_dword(KEY, name, if name == "EnableTransparency" { 1 } else { 0 })?;
    }
    let mut result = 0usize;
    unsafe {
        SendMessageTimeoutW(
            HWND_BROADCAST,
            WM_SETTINGCHANGE,
            0,
            wide("ImmersiveColorSet").as_ptr() as isize,
            SMTO_ABORTIFHUNG,
            5000,
            &mut result,
        );
    }
    set_autohide(true)
}
