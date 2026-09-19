#!/usr/bin/env bash
# Record the result of a Mac-tier verification so tomorrow's cloud run can act on it.
#   ./scripts/record-mac.sh 03 pass
#   ./scripts/record-mac.sh 03 fail "MusicSearchViewModelTests: 2 failures, ViewState.empty never set"
set -euo pipefail
CH=$(printf '%02d' "$((10#${1:?usage: record-mac.sh <NN> pass|fail [note]}))")
RESULT="${2:?usage: record-mac.sh <NN> pass|fail [note]}"
NOTE="${3:-}"
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

python3 - "$ROOT" "$CH" "$RESULT" "$NOTE" <<'PY'
import json, sys, datetime, pathlib
root, ch, result, note = sys.argv[1:5]
p = pathlib.Path(root) / ".bookbot" / "state.json"
s = json.loads(p.read_text())
c = s["chapters"][ch]
if result == "pass":
    c.update(mac_green=True, status="done", last_failure=None)
else:
    c.update(mac_green=False, status="awaiting-mac",
             last_failure=note or "mac tier failed (no note given)")
s["last_run"] = datetime.date.today().isoformat()
p.write_text(json.dumps(s, indent=2) + "\n")
print(f"ch{ch}: {c['status']}" + (f" — {c['last_failure']}" if c["last_failure"] else ""))
PY
echo "Commit and push .bookbot/state.json so the next cloud run sees this."
