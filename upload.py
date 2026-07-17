import base64
import json
import os
import urllib.error
import urllib.request

REPO = "NazarNoYami/yuki-hub"
ROOT = os.path.dirname(os.path.abspath(__file__))
API = "https://api.github.com/repos"
FILES = [
    "build.lua", "button_detector.lua", "skill_utility.lua", "build.py", ".luacheckrc", ".github/workflows/lint.yml",
    "features/_init.lua", "features/_windui.lua", "features/main.lua",
    "features/visuals.lua", "features/esp.lua", "features/aimbot.lua",
    "features/misc.lua", "features/hud.lua", "features/credits.lua",
]


def request(path, method="GET", data=None):
    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        raise RuntimeError("Set GITHUB_TOKEN before running upload.py")
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    body = json.dumps(data).encode() if data is not None else None
    return urllib.request.urlopen(
        urllib.request.Request(f"{API}/{REPO}/contents/{path}", data=body, headers=headers, method=method),
        timeout=30,
    )


def get_sha(path):
    try:
        with request(path) as response:
            return json.loads(response.read()).get("sha")
    except urllib.error.HTTPError as error:
        if error.code == 404:
            return None
        raise


def upload(path):
    with open(os.path.join(ROOT, *path.split("/")), "rb") as source:
        data = {"message": f"update {path}", "content": base64.b64encode(source.read()).decode()}
    sha = get_sha(path)
    if sha:
        data["sha"] = sha
    with request(path, "PUT", data):
        print(f"OK: {path}")


def main():
    for path in FILES:
        upload(path)


if __name__ == "__main__":
    main()
