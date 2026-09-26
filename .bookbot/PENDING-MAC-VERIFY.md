# Chapters awaiting Mac verification

The cloud agent appends here when a chapter passes the cloud tier.
Run `./scripts/verify.sh --tier mac <NN>` then `./scripts/record-mac.sh <NN> pass|fail "<note>"`.

- **ch02 — Models** (2026-09-25): cloud green. `verify.sh --tier mac 02` build + test already green
  on the author's Mac (4 Swift Testing decoding tests, 6 ms); still to check by hand: run the app,
  search for an artist, confirm live results show the album name under the artist and a tapped song
  still opens in Apple Music. Then `./scripts/record-mac.sh 02 pass`.

- **ch03 — Networking** (2026-09-25): cloud green. `verify.sh --tier mac 03` build + test already
  green on the author's Mac (12 Swift Testing tests / 18 cases, no network); still to check by hand:
  run the app, search, confirm live results; set the simulator's region to the UK, relaunch, search
  again and confirm results still load (GB storefront). Then `./scripts/record-mac.sh 03 pass`.

- **ch04 — View Composition** (2026-09-25): cloud green. `verify.sh --tier mac 04` build + test
  already green on the author's Mac (12 tests, unchanged); still to check by hand: open
  `TrackRow.swift` and `ArtworkView.swift` and confirm every preview renders in the canvas (long
  title wraps to two lines, subtitles stay on one; missing artwork shows a music note); run the app
  and search. Then `./scripts/record-mac.sh 04 pass`.

- **ch05 — View Models** (2026-09-25): cloud green. `verify.sh --tier mac 05` build + test already
  green on the author's Mac (28 tests); Release build also checked. Still to check by hand: open
  `MusicSearchView.swift` and confirm all five state previews render; run the app, search, go
  offline, search, go back online, tap **Try Again** (spinner only, no error underneath); clear the
  search field (back to "Search for a Song"). Then `./scripts/record-mac.sh 05 pass`.
