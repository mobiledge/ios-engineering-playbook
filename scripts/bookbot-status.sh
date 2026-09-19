#!/usr/bin/env bash
# Show the pipeline at a glance.
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
python3 - "$ROOT" <<'PY'
import json, sys, pathlib
root = pathlib.Path(sys.argv[1])
s = json.loads((root / ".bookbot" / "state.json").read_text())
mark = {"done":"✅","awaiting-mac":"🔶","in-progress":"🔄","pending":"⬜","blocked":"❌"}
print(f"part: {s['part']}   last run: {s['last_run'] or 'never'}")
if s["halted"]:
    print(f"\n⛔ HALTED — {s['halt_reason']}\n   resume: set halted=false in .bookbot/state.json, commit, push\n")
for ch, c in sorted(s["chapters"].items()):
    plan = next(iter(sorted((root/"plans"/s["part"]).glob(f"ch{ch}-*.md"))), None)
    title = plan.stem[5:].replace("-", " ") if plan else "?"
    line = f"  {mark.get(c['status'],'?')} ch{ch}  {title:<28} {c['status']}"
    if c["attempts"]: line += f"  (attempt {c['attempts']})"
    print(line)
    if c["last_failure"]: print(f"        ↳ {c['last_failure'][:100]}")
pend = [c for c,v in s["chapters"].items() if v["status"] == "awaiting-mac"]
if pend:
    print(f"\nqueued for your Mac: {', '.join('ch'+c for c in pend)}")
    print(f"  ./scripts/verify.sh --tier mac {pend[0]}  &&  ./scripts/record-mac.sh {pend[0]} pass")
PY
