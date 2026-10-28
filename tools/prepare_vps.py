"""Prepare a fresh Ubuntu VPS and verify the original game on loopback only.

Run as root: python3 tools/prepare_vps.py
Does not open ports, change SSH, or publish an Android release.
"""
import hashlib
import os
from pathlib import Path
import pwd
import shutil
import subprocess
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = "4.6.3"
CACHE = Path("/opt/cockro-tools")
BASE = f"https://github.com/godotengine/godot/releases/download/{VERSION}-stable"


def run(*args, **kwargs):
    subprocess.run(args, check=True, **kwargs)


def download(name):
    target = CACHE / name
    if not target.exists():
        print("Downloading", name, flush=True)
        temporary = target.with_suffix(target.suffix + ".partial")
        with urllib.request.urlopen(BASE + "/" + name, timeout=120) as response:
            with temporary.open("wb") as output:
                shutil.copyfileobj(response, output)
        temporary.replace(target)
    return target


def main():
    if os.geteuid() != 0:
        raise SystemExit("Run this preparation script as root.")
    if ROOT != Path("/opt/cockro-src"):
        raise SystemExit("Expected the staging checkout at /opt/cockro-src.")
    CACHE.mkdir(exist_ok=True)
    run("apt-get", "install", "-y", "libfontconfig1", "libx11-6", "libxcursor1",
        "libxinerama1", "libgl1", "libxi6", "libxrandr2", "libasound2t64")
    archive_name = f"Godot_v{VERSION}-stable_linux.x86_64.zip"
    checksums = download("SHA512-SUMS.txt").read_text()
    matches = [line.split()[0] for line in checksums.splitlines()
               if line.split() and line.split()[-1].lstrip("*") == archive_name]
    if len(matches) != 1:
        raise SystemExit("Official checksum entry missing; refusing to run download.")
    archive = download(archive_name)
    with archive.open("rb") as source:
        actual = hashlib.file_digest(source, "sha512").hexdigest()
    if actual != matches[0]:
        raise SystemExit("Godot checksum mismatch.")
    binary_name = archive_name.removesuffix(".zip")
    binary = CACHE / binary_name
    with zipfile.ZipFile(archive) as bundle:
        with bundle.open(binary_name) as source, binary.open("wb") as output:
            shutil.copyfileobj(source, output)
    binary.chmod(0o755)
    try:
        pwd.getpwnam("cockro-build")
    except KeyError:
        run("useradd", "--system", "--create-home", "--home-dir",
            "/var/lib/cockro-build", "--shell", "/usr/sbin/nologin", "cockro-build")
    run("chown", "-R", "cockro-build:cockro-build", str(ROOT))
    # A source checkout is a disposable staging/test environment. Published
    # servers must use an export, which excludes development accounts and DBs.
    prefix = ("runuser", "-u", "cockro-build", "--")
    env = {**os.environ, "HOME": "/var/lib/cockro-build"}
    with (CACHE / "import.log").open("w") as log:
        run(*prefix, str(binary), "--headless", "--path", str(ROOT),
            "--editor", "--import", stdout=log, stderr=subprocess.STDOUT, env=env)
    print("IMPORT_COMPLETE", flush=True)
    with (CACHE / "classic-test.log").open("w") as log:
        run(*prefix, "python3", str(ROOT / "tools/check_classic.py"),
            str(binary), stdout=log, stderr=subprocess.STDOUT, env=env)
    print("VPS_CLASSIC_TEST_PASS", flush=True)
    print("See /opt/cockro-tools/classic-test.log. No public game service yet.")


if __name__ == "__main__":
    main()
