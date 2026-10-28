"""Launch the original game and its three local servers. No public hosting.
Usage: python tools/run_classic.py /path/to/godot
Close the game (or press Ctrl+C) to stop the local servers.
"""
import json
import pathlib
import subprocess
import sys
import time
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
GODOT = str(pathlib.Path(sys.argv[1]).resolve())
VERSION = next(line.split('"')[1] for line in (ROOT / 'project.godot').read_text().splitlines() if line.startswith('config/version='))
processes = []
try:
    for role in ('master-server', 'gateway-server', 'world-server'):
        processes.append(subprocess.Popen([GODOT, '--headless', '--path', str(ROOT), '--mode=' + role]))
        time.sleep(3)
    for attempt in range(45):
        if any(p.poll() is not None for p in processes):
            raise RuntimeError('A local server stopped; see its output above.')
        try:
            req = urllib.request.Request('http://127.0.0.1:8088/v1/handshake', data=json.dumps({'c-v': VERSION}).encode(), headers={'Content-Type': 'application/json'})
            handshake = json.load(urllib.request.urlopen(req, timeout=2))
            req = urllib.request.Request('http://127.0.0.1:8088/v1/worlds', data=b'{}', headers={'Content-Type': 'application/json'})
            worlds = json.load(urllib.request.urlopen(req, timeout=2))
            if handshake.get('ok') and worlds.get('w'):
                break
        except OSError:
            pass
        time.sleep(1)
    else:
        raise RuntimeError('The local world did not become ready.')
    client = subprocess.Popen([GODOT, '--path', str(ROOT), '--mode=client'])
    processes.append(client)
    client.wait()
finally:
    for p in reversed(processes):
        if p.poll() is None:
            p.terminate()
    for p in processes:
        try:
            p.wait(timeout=10)
        except subprocess.TimeoutExpired:
            p.kill()
