"""Run the original local server stack and verify account + character + world entry.
Usage: python tools/check_classic.py /path/to/godot
Creates a disposable test account in the LOCAL development database only.
"""
import json
import pathlib
import secrets
import subprocess
import sys
import tempfile
import time
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
GODOT = str(pathlib.Path(sys.argv[1]).resolve())
VERSION = next(line.split('"')[1] for line in (ROOT / 'project.godot').read_text().splitlines() if line.startswith('config/version='))

def request(endpoint, body):
    req = urllib.request.Request('http://127.0.0.1:8088/v1/' + endpoint,
        data=json.dumps(body).encode(), headers={'Content-Type': 'application/json'})
    result = json.load(urllib.request.urlopen(req, timeout=15))
    assert 'error' not in result, (endpoint, result)
    return result

processes = []
with tempfile.TemporaryDirectory(prefix='cockro-classic-') as temp:
    try:
        for role in ('master-server', 'gateway-server', 'world-server'):
            output = open(pathlib.Path(temp) / (role + '.log'), 'w')
            processes.append(subprocess.Popen([GODOT, '--headless', '--path', str(ROOT), '--mode=' + role], stdout=output, stderr=output))
            time.sleep(3)
        for attempt in range(30):
            assert all(p.poll() is None for p in processes), 'Server process exited'
            try:
                request('handshake', {'c-v': VERSION})
                worlds = request('worlds', {})['w']
                if worlds:
                    break
            except (OSError, AssertionError):
                pass
            time.sleep(1)
        else:
            raise AssertionError('Local server stack was not ready')
        username = 'qa' + secrets.token_hex(4)
        password = secrets.token_hex(16)
        request('account/create', {'a-u': username, 'a-p': password})
        login = request('login', {'a-u': username, 'a-p': password, 'c-v': VERSION})
        context = {'t-id': login['session_id'], 'a-u': username, 'w-id': int(next(iter(worlds)))}
        handoff = request('world/character/create', {**context, 'data': {'name': username, 'skin': 1}})
        handoff_path = pathlib.Path(temp) / 'handoff.json'
        handoff_path.write_text(json.dumps(handoff))
        handoff_path.chmod(0o600)
        run = subprocess.run([GODOT, '--headless', '--path', str(ROOT), '--mode=client', 'res://tests/classic_world_smoke.tscn', '--handoff=' + str(handoff_path)], timeout=60, capture_output=True, text=True)
        print(run.stdout)
        if run.returncode != 0 or 'SCRIPT ERROR' in run.stderr:
            print(run.stderr[-4000:])
        assert 'SCRIPT ERROR' not in run.stderr, 'Client emitted script errors'
        assert run.returncode == 0 and 'CLASSIC_SMOKE_PASS' in run.stdout, 'World client failed'
        login = request('login', {'a-u': username, 'a-p': password, 'c-v': VERSION})
        context['t-id'] = login['session_id']
        characters = request('world/characters', context)
        assert username in json.dumps(characters), 'Character missing after reconnect'
        print('PASS: signup, login, character creation, original world, movement, reconnect and character retrieval')
    finally:
        for p in processes:
            p.terminate()
        for p in processes:
            try:
                p.wait(timeout=10)
            except subprocess.TimeoutExpired:
                p.kill()
        if sys.exc_info()[0]:
            for log in pathlib.Path(temp).glob('*.log'):
                pathlib.Path('/tmp/classic-' + log.name).write_text(log.read_text())
                print(log.name, log.read_text()[-1800:])
