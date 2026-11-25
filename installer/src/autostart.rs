use crate::Res;
use crate::backup::{Entry, delete_value, reg, set_sz};
use crate::quickshell;
use crate::wallpaper::wide;
use std::ffi::c_void;
use std::mem::{size_of, zeroed};
use std::os::windows::process::CommandExt;
use std::path::Path;
use std::process::{Command, Stdio};
use std::ptr::{null, null_mut};
use windows_sys::Win32::Foundation::{CloseHandle, HANDLE};
use windows_sys::Win32::System::Threading::{
    CreateProcessW, DeleteProcThreadAttributeList, EXTENDED_STARTUPINFO_PRESENT, InitializeProcThreadAttributeList,
    LPPROC_THREAD_ATTRIBUTE_LIST, OpenProcess, PROC_THREAD_ATTRIBUTE_PARENT_PROCESS, PROCESS_CREATE_PROCESS,
    PROCESS_INFORMATION, STARTUPINFOEXW, UpdateProcThreadAttribute,
};
use windows_sys::Win32::UI::WindowsAndMessaging::{GetShellWindow, GetWindowThreadProcessId};

const KEY: &str = r"Software\Microsoft\Windows\CurrentVersion\Run";
const NAME: &str = "ElRice";
const DETACHED_PROCESS: u32 = 0x0000_0008;
const CREATE_NEW_PROCESS_GROUP: u32 = 0x0000_0200;

pub fn snapshot() -> Res<Vec<Entry>> {
    Ok(vec![reg(KEY, NAME)])
}

pub fn stop() {
    let _ = Command::new("taskkill")
        .args(["/F", "/IM", "qs.exe", "/IM", "qsw.exe", "/IM", "altwatch.exe", "/IM", "taskbar.exe"])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();
}

pub fn remove() {
    delete_value(KEY, NAME);
}

pub fn apply() -> Res<()> {
    let qsw = quickshell::dir()?.join("qsw.exe");
    set_sz(KEY, NAME, &format!("\"{}\" -c elrice", qsw.display()))?;
    stop();
    if spawn_as_shell_user(&qsw) {
        return Ok(());
    }
    Command::new(qsw)
        .args(["-c", "elrice"])
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .creation_flags(DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP)
        .spawn()?;
    Ok(())
}

fn spawn_as_shell_user(qsw: &Path) -> bool {
    let mut pid = 0u32;
    unsafe { GetWindowThreadProcessId(GetShellWindow(), &mut pid) };
    if pid == 0 {
        return false;
    }
    let parent = unsafe { OpenProcess(PROCESS_CREATE_PROCESS, 0, pid) };
    if parent.is_null() {
        return false;
    }
    let mut size = 0usize;
    unsafe { InitializeProcThreadAttributeList(null_mut(), 1, 0, &mut size) };
    let mut buf = vec![0u8; size];
    let list = buf.as_mut_ptr() as LPPROC_THREAD_ATTRIBUTE_LIST;
    let mut ok = unsafe { InitializeProcThreadAttributeList(list, 1, 0, &mut size) } != 0;
    ok = ok
        && unsafe {
            UpdateProcThreadAttribute(
                list,
                0,
                PROC_THREAD_ATTRIBUTE_PARENT_PROCESS as usize,
                &parent as *const HANDLE as *const c_void,
                size_of::<HANDLE>(),
                null_mut(),
                null(),
            )
        } != 0;
    if ok {
        let mut cmd = wide(&format!("\"{}\" -c elrice", qsw.display()));
        let mut si: STARTUPINFOEXW = unsafe { zeroed() };
        si.StartupInfo.cb = size_of::<STARTUPINFOEXW>() as u32;
        si.lpAttributeList = list;
        let mut pi: PROCESS_INFORMATION = unsafe { zeroed() };
        ok = unsafe {
            CreateProcessW(
                null(),
                cmd.as_mut_ptr(),
                null(),
                null(),
                0,
                EXTENDED_STARTUPINFO_PRESENT | DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP,
                null(),
                null(),
                &si.StartupInfo,
                &mut pi,
            )
        } != 0;
        if ok {
            unsafe {
                CloseHandle(pi.hProcess);
                CloseHandle(pi.hThread);
            }
        }
        unsafe { DeleteProcThreadAttributeList(list) };
    }
    unsafe { CloseHandle(parent) };
    ok
}
