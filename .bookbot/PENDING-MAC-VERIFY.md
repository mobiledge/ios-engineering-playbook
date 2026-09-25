# Chapters awaiting Mac verification

The cloud agent appends here when a chapter passes the cloud tier.
Run `./scripts/verify.sh --tier mac <NN>` then `./scripts/record-mac.sh <NN> pass|fail "<note>"`.

- **ch01 — The Prototype** (2026-09-25): cloud green. `verify.sh --tier mac 01` build + test already
  green on the author's Mac; still to check by hand: run the app, search for an artist, confirm live
  results appear and a tapped song opens in Apple Music. Then `./scripts/record-mac.sh 01 pass`.
