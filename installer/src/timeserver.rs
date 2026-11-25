use std::process::{Command, Stdio};

const COMMAND: &str = r#"w32tm /config /manualpeerlist:"time.windows.com,0x9" /syncfromflags:manual /update"#;

pub fn reset() {
    let ok = Command::new("w32tm")
        .args(["/config", "/manualpeerlist:time.windows.com,0x9", "/syncfromflags:manual", "/update"])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .is_ok_and(|s| s.success());
    if !ok {
        println!("Could not reset the time server (needs admin). Run this in an elevated prompt: {COMMAND}");
    }
}
