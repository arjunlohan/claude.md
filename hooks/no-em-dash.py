#!/usr/bin/env python3
"""PostToolUse hook: warn Claude when text it just wrote contains an em dash.

Exit code 2 sends stderr to Claude as feedback. The write has already happened,
so Claude fixes the file. Writes made through Bash are not covered.
"""
import json
import sys

EM_DASH = chr(0x2014)


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return 0
    ti = data.get("tool_input") or {}
    texts = [ti.get("content"), ti.get("new_string")]
    texts += [e.get("new_string") for e in (ti.get("edits") or []) if isinstance(e, dict)]
    if any(isinstance(t, str) and EM_DASH in t for t in texts):
        path = ti.get("file_path", "this file")
        print(
            f"{path}: the text you wrote contains an em dash (U+2014). Replace each one "
            "with a comma, colon, period, or parentheses (a middot in UI labels) unless "
            "the file is a deliberate exemption.",
            file=sys.stderr,
        )
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
