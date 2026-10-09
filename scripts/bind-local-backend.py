"""Explicit loopback port bindings for Kin only; keep named data volumes intact."""
import http.client
import json
import socket
import subprocess
import time
import urllib.parse

stage = 'configuration'
backups = []
def docker(*args):
    return subprocess.check_output(['docker', *args], stderr=subprocess.DEVNULL)

class LocalDocker(http.client.HTTPConnection):
    def connect(self):
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.connect(socket_path)

def request(method, path, data=None):
    conn = LocalDocker('localhost', timeout=60)
    conn.request(method, path, body=None if data is None else json.dumps(data),
                 headers={'Content-Type': 'application/json'})
    response = conn.getresponse()
    body = response.read()
    conn.close()
    if response.status >= 300:
        raise RuntimeError('Docker operation failed; private response withheld.')
    return json.loads(body) if body else None

try:
    context = json.loads(docker('context', 'inspect'))[0]
    endpoint = context['Endpoints']['docker']['Host']
    if not endpoint.startswith('unix://'):
        raise RuntimeError('This helper requires a local Unix Docker socket.')
    socket_path = endpoint.removeprefix('unix://')
    names = ['supabase_db_kin', 'supabase_kong_kin', 'supabase_inbucket_kin']
    for name in names:
        stage = f'loopback binding for {name}'
        original = json.loads(docker('inspect', name))[0]
        host = original['HostConfig']
        bindings = host.get('PortBindings') or {}
        if all(p['HostIp'] == '127.0.0.1' for ports in bindings.values() for p in ports):
            old = name + '_unbound_backup'
            try:
                saved = json.loads(docker('inspect', old))[0]
                if not saved['State']['Running'] and saved['Config'].get('Labels', {}).get('com.supabase.cli.project') == 'kin':
                    backups.append(old)
            except subprocess.CalledProcessError:
                pass
            continue
        if original['Config'].get('Labels', {}).get('com.supabase.cli.project') != 'kin':
            raise RuntimeError('Unexpected project; refused to modify it.')
        # CLI containers use named mounts. Preserve their exact sources; never
        # replace a persistent mount with an anonymous volume on recreation.
        if any(m['Type'] == 'volume' and not m.get('Name') for m in original['Mounts']):
            raise RuntimeError('Unexpected mount configuration.')
        # Image-declared volumes may be absent from HostConfig.Mounts/Binds.
        # Reference their existing names explicitly instead of creating empties.
        mounts = host.setdefault('Mounts', [])
        targets = {m['Target'] for m in mounts}
        targets.update(b.split(':')[1] for b in (host.get('Binds') or []))
        for mount in original['Mounts']:
            if mount['Type'] == 'volume' and mount['Destination'] not in targets:
                mounts.append({'Type': 'volume', 'Source': mount['Name'],
                               'Target': mount['Destination'], 'ReadOnly': not mount['RW']})
        for ports in bindings.values():
            for port in ports:
                port['HostIp'] = '127.0.0.1'
        endpoints = {network: {'Aliases': info.get('Aliases', [])}
                     for network, info in original['NetworkSettings']['Networks'].items()}
        backup = name + '_unbound_backup'
        docker('stop', '--time', '30', name)
        docker('rename', name, backup)
        backups.append(backup)
        for network in endpoints:
            docker('network', 'disconnect', network, backup)
        # CLI writes generated gateway config into its writable layer. Snapshot
        # that layer locally as well as retaining mounts; never push this image.
        image = docker('commit', backup).decode().strip()
        payload = {**original['Config'], 'Image': image, 'HostConfig': host,
                   'NetworkingConfig': {'EndpointsConfig': endpoints}}
        created = request('POST', '/containers/create?name=' + urllib.parse.quote(name), payload)
        request('POST', '/containers/' + created['Id'] + '/start')
        for _ in range(45):
            current = json.loads(docker('inspect', name))[0]
            health = current['State'].get('Health', {}).get('Status')
            if current['State']['Running'] and health in (None, 'healthy'):
                break
            time.sleep(1)
        else:
            raise RuntimeError('Recreated service did not become healthy.')
        actual = current['NetworkSettings']['Ports']
        identity = lambda m: (m['Type'], m.get('Name', m['Source']), m['Destination'])
        if {identity(m) for m in original['Mounts']} != {identity(m) for m in current['Mounts']}:
            raise RuntimeError('Mount preservation verification failed.')
        if not all(p['HostIp'] == '127.0.0.1' for ports in actual.values() if ports for p in ports):
            raise RuntimeError('Loopback verification failed.')
        print(f'{name}: published ports bound to 127.0.0.1; existing mounts preserved.', flush=True)
    # Remove only stopped rollback containers after every replacement is healthy.
    # No -v flag: named data volumes remain in place.
    if backups:
        docker('rm', *backups)
except Exception:
    print(f'Local binding failed during {stage}. Private configuration withheld. '
          'Stopped rollback containers are preserved if replacements did not finish.', flush=True)
    raise SystemExit(1)
