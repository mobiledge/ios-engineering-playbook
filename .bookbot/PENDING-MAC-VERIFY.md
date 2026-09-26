# Chapters awaiting Mac verification

The cloud agent appends here when a chapter passes the cloud tier.
Run `./scripts/verify.sh --tier mac <NN>` then `./scripts/record-mac.sh <NN> pass|fail "<note>"`.

- **ch02 — Models** (2026-09-25): cloud green. `verify.sh --tier mac 02` build + test already green
  on the author's Mac (4 Swift Testing decoding tests, 6 ms); still to check by hand: run the app,
  search for an artist, confirm live results show the album name under the artist and a tapped song
  still opens in Apple Music. Then `./scripts/record-mac.sh 02 pass`.
