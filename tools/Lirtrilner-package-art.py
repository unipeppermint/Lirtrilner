"""Package the selected imagegen art. No image creation or creative editing.
Original PNGs and full prompts remain in design/visual-v2.
"""
import json
import shutil
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'design/visual-v2/prompts/manifest.json').read_text())
exporter = Path('/private/tmp/Lirtrilner-import-art')
subprocess.run([
    'swiftc', '-module-cache-path', '/private/tmp/Lirtrilner-module-cache',
    str(root / 'tools/Lirtrilner-import-art.swift'), '-o', str(exporter)
], check=True)
for job in manifest:
    name = job['name']
    source = root / f'design/visual-v2/source/Lirtrilner-{name}-v2.png'
    if not source.exists():
        shutil.copy2(job['source'], source)
    if name == 'app-icon':
        folder = root / 'Lirtrilner/Assets.xcassets/AppIcon.appiconset'
        target = folder / 'Lirtrilner-icon-v2.png'
        kind = 'icon'
        description = {'filename': target.name, 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'}
    else:
        folder = root / f'Lirtrilner/Assets.xcassets/Lirtrilner-{name}-v2.imageset'
        folder.mkdir(exist_ok=True)
        extension = 'png' if job['alpha'] else 'jpg'
        target = folder / f'Lirtrilner-{name}-v2.{extension}'
        kind = 'background' if name == 'workshop' else 'toy'
        description = {'filename': target.name, 'idiom': 'universal'}
    subprocess.run([str(exporter), str(source), str(target), kind], check=True)
    (folder / 'Contents.json').write_text(json.dumps({
        'images': [description], 'info': {'author': 'xcode', 'version': 1}
    }, indent=2) + '\n')
print(f'Packaged {len(manifest)} selected assets.')
