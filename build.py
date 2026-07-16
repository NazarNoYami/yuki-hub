import os

ROOT = os.path.dirname(os.path.abspath(__file__))
FEATURES = os.path.join(ROOT, 'features')

ORDER = [
    '_init.lua',
    'main.lua',
    'visuals.lua',
    'esp.lua',
    'aimbot.lua',
    'misc.lua',
    'hud.lua',
    'credits.lua',
]

def build():
    chunks = []
    for name in ORDER:
        path = os.path.join(FEATURES, name)
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        chunks.append(f'-- [[ FILE: {name} ]]')
        chunks.append(content.rstrip())
        chunks.append('')

    output = '\n'.join(chunks)
    outpath = os.path.join(ROOT, 'build.lua')
    with open(outpath, 'w', encoding='utf-8') as f:
        f.write(output)
    print(f'OK build.lua ({len(output)} bytes, {len(chunks)} files)')

if __name__ == '__main__':
    build()

