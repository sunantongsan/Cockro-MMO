"""Build and install the original server as a loopback-only Ubuntu service.

Requires prepare_vps.py to have passed. Run as root from /opt/cockro-src.
This initial installer refuses to replace an existing installation.
"""
import hashlib
import json
import os
from pathlib import Path
import pwd
import shutil
import time
import urllib.request
import zipfile

from prepare_vps import CACHE, ROOT, VERSION, download, run

APP = Path('/opt/cockro')
DATA = Path('/var/lib/cockro')
CONFIG = Path('/etc/cockro')

SUPERVISOR = '''import json, os, signal, subprocess, time, urllib.request
from pathlib import Path
stopping = False
def stop(signum, frame):
    global stopping
    stopping = True
signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)
processes = []
try:
    for role in ('master', 'gateway', 'world'):
        processes.append(subprocess.Popen([
            '/opt/cockro/server.x86_64', '--headless',
            '--mode=' + role + '-server', '--config=/etc/cockro/' + role + '.cfg',
            '--log-file=/var/lib/cockro/logs/' + role + '.log']))
        time.sleep(3)
    while not stopping:
        if any(p.poll() is not None for p in processes):
            raise RuntimeError('A server process exited; restarting the stack.')
        time.sleep(1)
finally:
    try:
        req = urllib.request.Request('http://127.0.0.1:8080/v1/save_all',
            data=b'{}', headers={'Content-Type': 'application/json'})
        urllib.request.urlopen(req, timeout=10).read()
        time.sleep(3)
    except OSError as exc:
        print('Save before stop failed:', exc, flush=True)
    for p in reversed(processes):
        if p.poll() is None:
            p.terminate()
    for p in processes:
        try:
            p.wait(timeout=10)
        except subprocess.TimeoutExpired:
            p.kill()
'''

UNIT = '''[Unit]
Description=Cockro original MMO internal server stack
After=network.target
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Type=simple
User=cockro
Group=cockro
WorkingDirectory=/opt/cockro
Environment=HOME=/var/lib/cockro
Environment=XDG_DATA_HOME=/var/lib/cockro
ExecStart=/usr/bin/python3 /opt/cockro/supervisor.py
Restart=on-failure
RestartSec=10
KillMode=mixed
TimeoutStopSec=60
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=/var/lib/cockro
UMask=0077

[Install]
WantedBy=multi-user.target
'''


def main():
    if os.geteuid() != 0 or ROOT != Path('/opt/cockro-src'):
        raise SystemExit('Run as root in /opt/cockro-src.')
    if APP.exists() or Path('/etc/systemd/system/cockro.service').exists():
        raise SystemExit('Existing installation found. Use a reviewed upgrade with a backup.')
    if 'PASS: signup' not in (CACHE / 'classic-test.log').read_text():
        raise SystemExit('Complete prepare_vps.py successfully first.')
    template_name = f'Godot_v{VERSION}-stable_export_templates.tpz'
    archive = download(template_name)
    sums = (CACHE / 'SHA512-SUMS.txt').read_text().splitlines()
    expected = next(line.split()[0] for line in sums
                    if line.split()[-1].lstrip('*') == template_name)
    with archive.open('rb') as stream:
        if hashlib.file_digest(stream, 'sha512').hexdigest() != expected:
            raise SystemExit('Template checksum mismatch.')
    template_dir = Path('/var/lib/cockro-build/.local/share/godot/export_templates') / (VERSION + '.stable')
    template_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as bundle:
        for member in ('linux_release.x86_64', 'version.txt'):
            with bundle.open('templates/' + member) as source:
                (template_dir / member).write_bytes(source.read())
    run('chown', '-R', 'cockro-build:cockro-build', '/var/lib/cockro-build/.local')
    build = ROOT / 'exports/vps'
    build.mkdir(parents=True, exist_ok=True)
    run('chown', '-R', 'cockro-build:cockro-build', str(ROOT / 'exports'))
    with (CACHE / 'server-export.log').open('w') as log:
        run('runuser', '-u', 'cockro-build', '--',
            str(CACHE / f'Godot_v{VERSION}-stable_linux.x86_64'),
            '--headless', '--path', str(ROOT), '--export-release', 'ServerUbuntu',
            str(build / 'server.x86_64'),
            stdout=log, stderr=log, env={**os.environ, 'HOME': '/var/lib/cockro-build'})
    try:
        pwd.getpwnam('cockro')
    except KeyError:
        run('useradd', '--system', '--home-dir', str(DATA),
            '--shell', '/usr/sbin/nologin', 'cockro')
    shutil.copytree(build, APP)
    (APP / 'server.x86_64').chmod(0o755)
    (APP / 'supervisor.py').write_text(SUPERVISOR)
    CONFIG.mkdir(exist_ok=True)
    for role in ('master', 'gateway', 'world'):
        text = (ROOT / f'data/config/{role}_config.cfg').read_text()
        if role == 'world':
            text = text.replace('max_players=200', 'max_players=12')
        (CONFIG / (role + '.cfg')).write_text(text)
    user_dir = DATA / 'godot/app_userdata/Cockro MMO'
    user_dir.mkdir(parents=True, exist_ok=True)
    (DATA / 'logs').mkdir(exist_ok=True)
    (user_dir / 'server_admins.cfg').write_text('[admins]\n')
    run('chown', '-R', 'cockro:cockro', str(DATA))
    DATA.chmod(0o700)
    Path('/etc/systemd/system/cockro.service').write_text(UNIT)
    run('systemctl', 'daemon-reload')
    run('systemctl', 'enable', '--now', 'cockro.service')
    for attempt in range(60):
        try:
            req = urllib.request.Request('http://127.0.0.1:8088/v1/worlds',
                data=b'{}', headers={'Content-Type': 'application/json'})
            worlds = json.load(urllib.request.urlopen(req, timeout=3))
            if worlds.get('w'):
                print('VPS_SERVICE_READY_LOOPBACK_ONLY', flush=True)
                print('12-player internal world; no public endpoint configured.')
                return
        except OSError:
            pass
        time.sleep(2)
    raise SystemExit('Server not ready: inspect journalctl -u cockro and /var/lib/cockro/logs.')


if __name__ == '__main__':
    main()
