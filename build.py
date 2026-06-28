"""PyInstaller 打包脚本。"""

import subprocess
from pathlib import Path


def main():
    root = Path(__file__).parent

    subprocess.run(
        [
            "uv", "run", "pyinstaller",
            "--clean", "--noconfirm",
            str(root / "etalien-daily.spec"),
        ],
        check=True,
    )

    print("\n打包完成: dist/etalien-daily/")


if __name__ == "__main__":
    main()
