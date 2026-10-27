"""Install pinned AdMob v5.1.0 / Godot 4.6.3 Android dependencies before import."""
import hashlib
import io
import json
from pathlib import Path
import urllib.request
import zipfile

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'tools/admob_dependencies.json').read_text())
for item in manifest:
    with urllib.request.urlopen(item['url'], timeout=180) as response:
        data = response.read()
    if hashlib.sha256(data).hexdigest() != item['sha256']:
        raise RuntimeError('Dependency checksum mismatch: ' + item['name'])
    destination = root / item['destination']
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        for entry in archive.infolist():
            name = entry.filename
            if item['strip_prefix']:
                if not name.startswith(item['strip_prefix']):
                    continue
                name = name[len(item['strip_prefix']):]
            target = (destination / name).resolve()
            if not target.is_relative_to(destination.resolve()):
                raise RuntimeError('Unsafe archive entry')
            if entry.is_dir():
                target.mkdir(parents=True, exist_ok=True)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.read(entry))
    print('Installed', item['name'])
