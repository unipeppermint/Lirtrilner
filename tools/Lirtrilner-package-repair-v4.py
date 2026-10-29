"""Repackage the saved v4 parts without generating or creatively editing images."""
import json
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
exporter = Path('/private/tmp/Lirtrilner-import-art')
subprocess.run([
    'swiftc', '-module-cache-path', '/private/tmp/Lirtrilner-module-cache',
    str(root / 'tools/Lirtrilner-import-art.swift'), '-o', str(exporter)
], check=True)
for part in ('obstacle', 'delivery'):
    name = f'Lirtrilner-{part}-v4'
    source = root / 'design/repair-v4/source' / f'{name}.png'
    folder = root / 'Lirtrilner/Assets.xcassets' / f'{name}.imageset'
    folder.mkdir(exist_ok=True)
    subprocess.run([str(exporter), str(source), str(folder / f'{name}.png')], check=True)
    (folder / 'Contents.json').write_text(json.dumps({
        'images': [{'filename': f'{name}.png', 'idiom': 'universal'}],
        'info': {'author': 'xcode', 'version': 1}
    }, indent=2) + '\n')
