"""Stage HTTPS configuration without enabling public listeners or requesting certs."""
import os
from pathlib import Path
import subprocess
import time
import urllib.request

DOMAIN = 'game.guardscan.xyz'
ROUTES = '''
    handle /health {
        respond "Cockro internal test server" 200
    }
    handle /world {
        reverse_proxy 127.0.0.1:8087
    }
    handle /v1/* {
        reverse_proxy 127.0.0.1:8088
    }
    handle {
        respond "Not found" 404
    }
'''


def main():
    if os.geteuid() != 0:
        raise SystemExit('Run as root.')
    folder = Path('/etc/caddy')
    folder.mkdir(exist_ok=True)
    config = folder / 'Caddyfile'
    if config.exists():
        raise SystemExit('Existing Caddy configuration found; inspect it before proceeding.')
    config.write_text('http://127.0.0.1:8090 {' + ROUTES + '}\n')
    subprocess.run(['apt-get', '-o', 'Dpkg::Options::=--force-confold',
                    'install', '-y', 'caddy'], check=True,
                   env={**os.environ, 'DEBIAN_FRONTEND': 'noninteractive'})
    pending = folder / 'Caddyfile.pending'
    pending.write_text(DOMAIN + ' {\n'
        '    tls {\n        issuer acme {\n'
        '            ca https://acme-v02.api.letsencrypt.org/directory\n'
        '        }\n    }\n' + ROUTES + '}\n')
    subprocess.run(['caddy', 'validate', '--adapter', 'caddyfile', '--config', str(pending)], check=True)
    subprocess.run(['systemctl', 'restart', 'caddy'], check=True)
    response = b''
    for _ in range(20):
        try:
            response = urllib.request.urlopen('http://127.0.0.1:8090/health', timeout=3).read()
            break
        except OSError:
            time.sleep(1)
    if response != b'Cockro internal test server':
        raise SystemExit('Local proxy health check failed.')
    world = Path('/etc/cockro/world.cfg')
    pending_world = Path('/etc/cockro/world.cfg.pending')
    pending_world.write_text(world.read_text().replace(
        'public_url="127.0.0.1"', 'public_url="wss://' + DOMAIN + '/world"'))
    print('HTTPS_CONFIG_READY_NOT_PUBLIC')
    print('Public listeners and certificate issuance have NOT been enabled.')


if __name__ == '__main__':
    main()
