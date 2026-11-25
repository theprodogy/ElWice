#![windows_subsystem = "windows"]

use std::io::{Write, stdout};
use std::thread::sleep;
use std::time::Duration;
use windows_sys::Win32::UI::Input::KeyboardAndMouse::{GetAsyncKeyState, VK_MENU};

fn main() {
    let mut out = stdout().lock();
    let mut up = 0;
    while up < 2 {
        let down = unsafe { GetAsyncKeyState(VK_MENU as i32) } < 0;
        up = if down { 0 } else { up + 1 };
        if writeln!(out, "{}", u8::from(down)).and_then(|()| out.flush()).is_err() {
            break;
        }
        sleep(Duration::from_millis(30));
    }
}
