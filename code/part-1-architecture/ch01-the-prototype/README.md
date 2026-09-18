# Medley — Part I, Chapter 1: The Prototype

*Structure must earn its place.*

The starting point of the whole book: **Medley**, a media-discovery app built on Apple's keyless
iTunes Search API, as a solo founder's weekend prototype. One file, one target, no layers.

> **Skeleton.** This folder is the seed the chapter builds on — the chapter prose and its full
> prototype aren't written yet. See [Part I](../../../part-1-architecture/README.md).

## Run it

You need a Mac with Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen        # one time

cd code/part-1-architecture/ch01-the-prototype
xcodegen generate            # creates Medley.xcodeproj from project.yml
open Medley.xcodeproj
```

Pick an iOS Simulator and press **Run** (⌘R).

> The `.xcodeproj` is intentionally **not** committed — it's a generated artifact. Re-run
> `xcodegen generate` any time the source layout changes.
