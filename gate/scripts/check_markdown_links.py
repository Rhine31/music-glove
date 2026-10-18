from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote


LINK = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
FENCE = re.compile(r"^\s*```", re.MULTILINE)


def main() -> int:
    repository = Path(__file__).resolve().parents[2]
    failures: list[str] = []

    for document in sorted(repository.rglob("*.md")):
        if any(part.startswith(".") for part in document.relative_to(repository).parts):
            continue
        text = document.read_text(encoding="utf-8")
        if len(FENCE.findall(text)) % 2:
            failures.append(f"{document.relative_to(repository)}: 代码围栏未成对")

        for raw_target in LINK.findall(text):
            target = raw_target.strip().strip("<>")
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            local_path = unquote(target.split("#", 1)[0])
            if not local_path:
                continue
            resolved = (document.parent / local_path).resolve()
            if not resolved.exists():
                failures.append(
                    f"{document.relative_to(repository)}: 缺少链接目标 {target}"
                )

    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print("Markdown links and code fences: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
