use crate::backup::{Entry, file_entry, reg, set_sz};
use crate::{Res, elrice_dir, local};
use std::fs;
use std::path::PathBuf;
use std::process::Command;

const URL: &str = "https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip";
const SHA256: &str = "9883fdd4a49d4fb66bd8177ba6625ef9a64aa45899767dde3d36aa425756b11e";
const KEY: &str = r"Software\Microsoft\Windows NT\CurrentVersion\Fonts";
const FONTS: [(&str, &str); 2] = [
    ("InterVariable.ttf", "Inter Variable (TrueType)"),
    ("InterVariable-Italic.ttf", "Inter Variable Italic (TrueType)"),
];

fn dest() -> Res<PathBuf> {
    Ok(local()?.join("Microsoft").join("Windows").join("Fonts"))
}

pub fn snapshot() -> Res<Vec<Entry>> {
    let mut entries = Vec::new();
    for (file, name) in FONTS {
        entries.push(reg(KEY, name));
        entries.push(file_entry(&dest()?.join(file), &elrice_dir()?.join(format!("font-{file}.bak")))?);
    }
    Ok(entries)
}

fn download() -> Res<()> {
    let tmp = elrice_dir()?.join("inter-download");
    let _ = fs::remove_dir_all(&tmp);
    fs::create_dir_all(&tmp)?;
    let zip = tmp.join("Inter.zip");
    let out = Command::new("powershell")
        .args(["-NoProfile", "-Command"])
        .arg(format!(
            "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -UseBasicParsing '{URL}' -OutFile '{z}'; (Get-FileHash -Algorithm SHA256 '{z}').Hash",
            z = zip.display()
        ))
        .output()?;
    let hash = String::from_utf8_lossy(&out.stdout).trim().to_lowercase();
    if !out.status.success() || hash != SHA256 {
        let _ = fs::remove_dir_all(&tmp);
        return Err(format!("Inter zip hash mismatch (got '{hash}'), refusing to use it").into());
    }
    let status = Command::new("powershell")
        .args(["-NoProfile", "-Command"])
        .arg(format!(
            "Expand-Archive -LiteralPath '{z}' -DestinationPath '{t}' -Force",
            z = zip.display(),
            t = tmp.display()
        ))
        .status()?;
    if !status.success() {
        let _ = fs::remove_dir_all(&tmp);
        return Err("could not extract the Inter zip".into());
    }
    fs::create_dir_all(dest()?)?;
    for (file, _) in FONTS {
        fs::copy(tmp.join(file), dest()?.join(file))?;
    }
    let _ = fs::remove_dir_all(&tmp);
    Ok(())
}

pub fn apply() -> Res<()> {
    if FONTS.iter().any(|(file, _)| dest().is_ok_and(|d| !d.join(file).is_file())) {
        println!("installing Inter");
        download()?;
    }
    for (file, name) in FONTS {
        set_sz(KEY, name, &dest()?.join(file).to_string_lossy())?;
    }
    Ok(())
}
