use crate::{Res, elrice_dir, local};
use std::path::PathBuf;
use std::process::Command;

const SCRIPT: &str = "https://raw.githubusercontent.com/nunreasonable/quickshell-windows/bea44443712216a09a91748e03cbd789af1c05c8/windows/install.ps1";
const SCRIPT_SHA256: &str = "5eec776d75088207e9960bbecac88cccd13d1919e719991c2936dfdd0575c2de";
pub const SCRIPT_FILE: &str = "quickshell-install.ps1";
const VERSION: &str = "v0.3.2-win2";

pub fn dir() -> Res<PathBuf> {
    Ok(local()?.join("Programs").join("Quickshell"))
}

fn script_path() -> Res<PathBuf> {
    Ok(elrice_dir()?.join(SCRIPT_FILE))
}

fn fetch_script() -> Res<PathBuf> {
    let path = script_path()?;
    std::fs::create_dir_all(elrice_dir()?)?;
    let out = Command::new("powershell")
        .args(["-NoProfile", "-Command"])
        .arg(format!(
            "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -UseBasicParsing '{SCRIPT}' -OutFile '{p}'; (Get-FileHash -Algorithm SHA256 '{p}').Hash",
            p = path.display()
        ))
        .output()?;
    let hash = String::from_utf8_lossy(&out.stdout).trim().to_lowercase();
    if !out.status.success() || hash != SCRIPT_SHA256 {
        let _ = std::fs::remove_file(&path);
        return Err(format!("Quickshell install script hash mismatch (got '{hash}'), refusing to run it").into());
    }
    Ok(path)
}

pub fn ensure() -> Res<()> {
    if dir()?.join("qs.exe").is_file() {
        return Ok(());
    }
    println!("installing Quickshell {VERSION}");
    let script = fetch_script()?;
    let status = Command::new("powershell")
        .args(["-NoProfile", "-ExecutionPolicy", "Bypass", "-File"])
        .arg(&script)
        .args(["-Version", VERSION])
        .status()?;
    if !status.success() || !dir()?.join("qs.exe").is_file() {
        return Err("Quickshell install failed".into());
    }
    Ok(())
}

pub fn uninstall_command() -> Res<String> {
    let path = if script_path()?.is_file() { script_path()? } else { fetch_script()? };
    Ok(format!("powershell -NoProfile -ExecutionPolicy Bypass -File \"{}\" -Uninstall", path.display()))
}
