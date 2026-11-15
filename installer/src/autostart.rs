use crate::Res;
use crate::backup::{Entry, delete_value, reg, set_sz};
use crate::quickshell;
use std::os::windows::process::CommandExt;
use std::process::{Command, Stdio};

const KEY: &str = r"Software\Microsoft\Windows\CurrentVersion\Run";
const NAME: &str = "ElRice";
const DETACHED_PROCESS: u32 = 0x0000_0008;
const CREATE_NEW_PROCESS_GROUP: u32 = 0x0000_0200;

pub fn snapshot() -> Res<Vec<Entry>> {
    Ok(vec![reg(KEY, NAME)])
}

pub fn stop() {
    let _ = Command::new("taskkill")
        .args(["/F", "/IM", "qs.exe", "/IM", "qsw.exe"])
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
    Command::new(qsw)
        .args(["-c", "elrice"])
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .creation_flags(DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP)
        .spawn()?;
    Ok(())
}
