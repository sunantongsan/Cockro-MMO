"""Exercise HTTPS login and original world/movement over WSS.

Usage: python3 tools/check_remote.py GODOT [--resume]
Creates one test account; --resume checks its character after a server restart.
Test credentials stay in a mode-0600 file in the current user's home directory.
"""
import argparse
import json
import os
from pathlib import Path
import secrets
import subprocess
import tempfile
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
BASE = 'https://game.guardscan.xyz'
STATE = Path.home() / '.cockro-remote-test.json'
VERSION = next(line.split('"')[1] for line in (ROOT / 'project.godot').read_text().splitlines()
               if line.startswith('config/version='))


def request(endpoint, body):
    req = urllib.request.Request(BASE + '/v1/' + endpoint,
        data=json.dumps(body).encode(), headers={'Content-Type': 'application/json'})
    result = json.load(urllib.request.urlopen(req, timeout=20))
    if 'error' in result:
        raise RuntimeError(f'{endpoint}: {result.get("error")}')
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('godot')
    parser.add_argument('--resume', action='store_true')
    args = parser.parse_args()
    request('handshake', {'c-v': VERSION})
    worlds = request('worlds', {})['w']
    if args.resume:
        account = json.loads(STATE.read_text())
    else:
        if STATE.exists():
            raise SystemExit('Existing test account found. Use --resume.')
        account = {'a-u': 'qa' + secrets.token_hex(4), 'a-p': secrets.token_hex(16)}
        request('account/create', account)
        with os.fdopen(os.open(STATE, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), 'w') as output:
            json.dump(account, output)
    login = request('login', {**account, 'c-v': VERSION})
    context = {'t-id': login['session_id'], 'a-u': account['a-u'], 'w-id': int(next(iter(worlds)))}
    if args.resume:
        characters = request('world/characters', context)
        if account['a-u'] not in json.dumps(characters):
            raise RuntimeError('Persisted character missing after restart')
        print('REMOTE_PERSISTENCE_PASS: login and character survived restart', flush=True)
        return
    handoff = request('world/character/create',
        {**context, 'data': {'name': account['a-u'], 'skin': 1}})
    if handoff.get('address') != 'wss://game.guardscan.xyz/world':
        raise RuntimeError('World did not advertise the expected secure endpoint')
    with tempfile.TemporaryDirectory(prefix='cockro-remote-') as directory:
        path = Path(directory) / 'handoff.json'
        path.write_text(json.dumps(handoff))
        path.chmod(0o600)
        result = subprocess.run([str(Path(args.godot).resolve()), '--headless', '--path', str(ROOT),
            '--mode=client', 'res://tests/classic_world_smoke.tscn', '--handoff=' + str(path)],
            capture_output=True, text=True, timeout=90)
        if result.returncode or 'SCRIPT ERROR' in result.stderr or 'CLASSIC_SMOKE_PASS' not in result.stdout:
            print(result.stderr[-3000:])
            raise RuntimeError('Secure original-world movement test failed')
    print('REMOTE_GAME_PASS: HTTPS account/login and WSS original map/movement', flush=True)


if __name__ == '__main__':
    main()
