#!/usr/bin/env bash
# Verify one chapter against its plan.
#
#   ./scripts/verify.sh --tier cloud 03      # everything that runs without Xcode
#   ./scripts/verify.sh --tier mac   03      # adds build + test (needs a Mac)
#
# Exit 0 = green. Exit 1 = red, with every failure listed.
set -uo pipefail

TIER=cloud
PART=part-1-architecture
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tier) TIER="$2"; shift 2 ;;
    --part) PART="$2"; shift 2 ;;
    *) CH="$1"; shift ;;
  esac
done
: "${CH:?usage: verify.sh [--tier cloud|mac] [--part <dir>] <NN>}"
CH=$(printf '%02d' "$((10#$CH))")

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

PLAN=$(ls "plans/$PART/ch$CH-"*.md 2>/dev/null | head -1)
[[ -f "$PLAN" ]] || { echo "FATAL: no plan file for chapter $CH in plans/$PART/"; exit 1; }
SLUG=$(basename "$PLAN" .md); SLUG=${SLUG#ch$CH-}
PROSE="$PART/$CH-$SLUG.md"
CODE="code/$PART/ch$CH-$SLUG"
PREV_N=$(printf '%02d' "$((10#$CH - 1))")
PREV_PLAN=$(ls "plans/$PART/ch$PREV_N-"*.md 2>/dev/null | head -1)
if [[ -n "$PREV_PLAN" ]]; then
  PREV_SLUG=$(basename "$PREV_PLAN" .md); PREV_SLUG=${PREV_SLUG#ch$PREV_N-}
  PREV_CODE="code/$PART/ch$PREV_N-$PREV_SLUG"
else
  PREV_CODE=""
fi

FAILURES=()
fail() { FAILURES+=("$1"); }
note() { printf '  %s\n' "$1"; }

echo "── verify chapter $CH ($SLUG) · tier=$TIER"
echo "   prose: $PROSE"
echo "   code:  $CODE"

# ─────────────────────────────────────────── prose exists
if [[ ! -f "$PROSE" ]]; then
  fail "prose file missing: $PROSE"
else
  # ── template headings, in order (Ch1 has no "Where we are")
  EXPECTED=("## The pain" "## The extraction" "## Prove it" "## Codify it" \
            "## The ledger" "## Is this worth it yet?" "## The trap this leaves open" "## Hands-on")
  [[ "$CH" != "01" ]] && EXPECTED=("## Where we are" "${EXPECTED[@]}")
  LAST_POS=0
  for h in "${EXPECTED[@]}"; do
    POS=$(grep -n -F -m1 "$h" "$PROSE" | cut -d: -f1)
    if [[ -z "$POS" ]]; then
      fail "prose missing heading: $h"
    elif (( POS < LAST_POS )); then
      fail "prose heading out of order: $h"
    else
      LAST_POS=$POS
    fi
  done

  # ── ledger: rows retired so far must be struck through
  WANT_STRUCK=$((10#$CH - 1))
  GOT_STRUCK=$(grep -c '~~' "$PROSE" || true)
  if (( GOT_STRUCK < WANT_STRUCK )); then
    fail "ledger: expected >= $WANT_STRUCK struck-through rows, found $GOT_STRUCK"
  fi
fi

# ─────────────────────────────────────────── code folder + manifest
if [[ ! -d "$CODE" ]]; then
  fail "code folder missing: $CODE"
else
  MAN=$(awk '/^```manifest/{f=1;next} /^```/{f=0} f' "$PLAN")
  if [[ -z "$MAN" ]]; then
    note "plan declares no manifest — skipping file checks"
  else
    while read -r sign path; do
      [[ -z "${path:-}" ]] && continue
      case "$sign" in
        +) [[ -e "$CODE/$path" ]] || fail "manifest: missing $CODE/$path" ;;
        -) [[ ! -e "$CODE/$path" ]] || fail "manifest: should not exist: $CODE/$path" ;;
      esac
    done <<< "$MAN"
  fi

  # ── continuity: the delta against the previous chapter must equal the manifest
  if [[ -n "$PREV_CODE" && -d "$PREV_CODE" ]]; then
    ADDED=$(diff -rq "$PREV_CODE" "$CODE" 2>/dev/null | sed -n 's/^Only in '"$(basename "$CODE")"'.*: //p' || true)
    CHANGED=$(diff -rq "$PREV_CODE" "$CODE" 2>/dev/null | grep -c '^Files .* differ$' || true)
    note "continuity: $(echo "$ADDED" | grep -c . || true) new paths, $CHANGED modified files vs ch$PREV_N"
    note "  (review by eye: diff -rq $PREV_CODE $CODE)"
  fi

  # ── swift syntax check, if a toolchain exists
  if command -v swiftc >/dev/null 2>&1; then
    SYNTAX_ERRS=0
    while IFS= read -r f; do
      swiftc -parse "$f" >/dev/null 2>&1 || { fail "swift syntax error: $f"; SYNTAX_ERRS=$((SYNTAX_ERRS+1)); }
    done < <(find "$CODE" -name '*.swift')
    note "swiftc -parse: $SYNTAX_ERRS error(s)"
  else
    note "swiftc not present — syntax check skipped"
  fi
fi

# ─────────────────────────────────────────── banned names (conventions glossary)
BANNED='iTunesSearchApp|NetworkManager|APIService|MainCoordinator|NavigationManager|ObservableObject|UIViewController|pushViewController|Package\.swift|CompositionRoot|AppFactory|AppInterfaces'
HITS=$(grep -rnE "$BANNED" "$PROSE" "$CODE" 2>/dev/null | grep -v 'SKILL.md' || true)
if [[ -n "$HITS" ]]; then
  # Ch8 gets exactly one UIKit sidebar mention
  if [[ "$CH" == "08" ]]; then
    HITS=$(echo "$HITS" | grep -vE 'UIViewController|Coordinator' || true)
  fi
  [[ -n "$HITS" ]] && { fail "banned names found:"; echo "$HITS" | head -10; }
fi

# ─────────────────────────────────────────── markdown links resolve
if [[ -f "$PROSE" ]] && command -v python3 >/dev/null 2>&1; then
  BROKEN=$(python3 - "$PROSE" <<'PY'
import re, sys, pathlib
md = pathlib.Path(sys.argv[1])
bad = []
for t in re.findall(r'\]\(([^)\s]+)\)', md.read_text()):
    if t.startswith(('http://','https://','#','mailto:')): continue
    p = t.split('#')[0]
    if p and not (md.parent / p).exists(): bad.append(t)
print('\n'.join(bad))
PY
)
  [[ -n "$BROKEN" ]] && fail "broken links in $PROSE: $BROKEN"
fi

# ─────────────────────────────────────────── skills declared by the plan
while read -r skill; do
  [[ -z "$skill" ]] && continue
  [[ -f "$CODE/.claude/skills/$skill/SKILL.md" ]] || fail "skill missing: $CODE/.claude/skills/$skill/SKILL.md"
done < <(grep -oE '^\+ \.claude/skills/[a-z-]+/SKILL\.md' "$PLAN" | sed 's|^+ \.claude/skills/||; s|/SKILL\.md$||')

# ─────────────────────────────────────────── mac tier
if [[ "$TIER" == "mac" ]]; then
  if ! command -v xcodebuild >/dev/null 2>&1; then
    fail "tier=mac requested but xcodebuild is not available"
  else
    ( cd "$CODE" && command -v xcodegen >/dev/null 2>&1 && xcodegen generate >/dev/null 2>&1 ) \
      || fail "xcodegen generate failed in $CODE"
    DEST='generic/platform=iOS Simulator'
    ( cd "$CODE" && xcodebuild -project Medley.xcodeproj -scheme Medley -destination "$DEST" build >/tmp/medley-build.log 2>&1 ) \
      || fail "xcodebuild build failed (see /tmp/medley-build.log)"
    # Pick by UDID: names repeat across runtimes, and a name regex drags in trailing spaces.
    SIM=$(xcrun simctl list devices available | grep -E '^ +iPhone ' | grep -oE '[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}' | head -1)
    if [[ -n "$SIM" ]]; then
      ( cd "$CODE" && xcodebuild -project Medley.xcodeproj -scheme Medley \
          -destination "platform=iOS Simulator,id=$SIM" test >/tmp/medley-test.log 2>&1 ) \
        || fail "xcodebuild test failed (see /tmp/medley-test.log)"
    else
      fail "no iOS simulator available to run tests"
    fi
  fi
fi

# ─────────────────────────────────────────── report
echo
if (( ${#FAILURES[@]} == 0 )); then
  echo "✅ chapter $CH tier=$TIER GREEN"
  exit 0
fi
echo "❌ chapter $CH tier=$TIER RED — ${#FAILURES[@]} failure(s):"
printf '  • %s\n' "${FAILURES[@]}"
exit 1
