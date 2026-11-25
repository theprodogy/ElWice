#![windows_subsystem = "windows"]

use std::io::{Read, stdin};
use std::ptr::{null, null_mut};
use std::thread;
use windows_sys::Win32::Foundation::HWND;
use windows_sys::Win32::System::Threading::GetCurrentThreadId;
use windows_sys::Win32::UI::Accessibility::{SetWinEventHook, UnhookWinEvent};
use windows_sys::Win32::UI::WindowsAndMessaging::{
    DispatchMessageW, EVENT_OBJECT_SHOW, FindWindowExW, GetClassNameW, GetMessageW, MSG, OBJID_WINDOW,
    PostThreadMessageW, SW_HIDE, SW_SHOW, ShowWindow, TranslateMessage, WINEVENT_OUTOFCONTEXT, WM_QUIT,
};

const MAIN: [u16; 15] = wide("Shell_TrayWnd");
const SECONDARY: [u16; 23] = wide("Shell_SecondaryTrayWnd");

const fn wide<const N: usize>(s: &str) -> [u16; N] {
    let b = s.as_bytes();
    let mut out = [0u16; N];
    let mut i = 0;
    while i < b.len() {
        out[i] = b[i] as u16;
        i += 1;
    }
    out
}

fn set_all(cmd: i32) {
    for class in [&MAIN[..], &SECONDARY[..]] {
        let mut h: HWND = null_mut();
        loop {
            h = unsafe { FindWindowExW(null_mut(), h, class.as_ptr(), null()) };
            if h.is_null() {
                break;
            }
            unsafe { ShowWindow(h, cmd) };
        }
    }
}

fn is_taskbar(hwnd: HWND) -> bool {
    let mut buf = [0u16; 32];
    let n = unsafe { GetClassNameW(hwnd, buf.as_mut_ptr(), 32) } as usize;
    [&MAIN[..], &SECONDARY[..]].iter().any(|c| c[..c.len() - 1] == buf[..n])
}

unsafe extern "system" fn on_show(_: *mut std::ffi::c_void, _: u32, hwnd: HWND, id: i32, _: i32, _: u32, _: u32) {
    if id == OBJID_WINDOW && !hwnd.is_null() && is_taskbar(hwnd) {
        unsafe { ShowWindow(hwnd, SW_HIDE) };
    }
}

fn main() {
    set_all(SW_HIDE);
    let hook = unsafe {
        SetWinEventHook(EVENT_OBJECT_SHOW, EVENT_OBJECT_SHOW, null_mut(), Some(on_show), 0, 0, WINEVENT_OUTOFCONTEXT)
    };
    let main_thread = unsafe { GetCurrentThreadId() };
    thread::spawn(move || {
        let mut buf = [0u8; 16];
        let mut input = stdin().lock();
        while matches!(input.read(&mut buf), Ok(n) if n > 0) {}
        unsafe { PostThreadMessageW(main_thread, WM_QUIT, 0, 0) };
    });
    let mut msg: MSG = unsafe { std::mem::zeroed() };
    while unsafe { GetMessageW(&mut msg, null_mut(), 0, 0) } > 0 {
        unsafe {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }
    if !hook.is_null() {
        unsafe { UnhookWinEvent(hook) };
    }
    set_all(SW_SHOW);
}
