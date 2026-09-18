# Code — One Runnable Project Per Chapter

Every chapter of the book has exactly one folder here, and that folder is the **runnable end state
of that chapter**. Layout mirrors the prose:

```
code/
  part-1-architecture/ch01-the-prototype/ …
  part-2-modular/ch01-the-monolith/ … ch08-advanced-granularity/
```

Chapter numbering restarts per part, which is why the folders are nested by part — Part I's `ch01`
and Part II's `ch01` are different projects.

## The continuity contract

For every chapter N ≥ 2 within a part:

- `chNN`'s contents = `ch(N-1)`'s contents **plus exactly the delta that chapter teaches**.
  `diff -r` between the two folders must show that delta — no more, no less.
- The chapter's prose opens by restating the previous chapter's end state (module graph + feature
  set) before introducing new pain.
- No module, feature, protocol, or name appears in prose or code without having been introduced, or
  disappears without being explicitly retired.

```bash
# Verify a chapter's delta is exactly what its prose claims
diff -qr part-2-modular/ch03-domain-infrastructure part-2-modular/ch04-vertical-slicing | sort
```

## Building a chapter

Xcode projects are **generated**, not committed — [XcodeGen](https://github.com/yonaskolb/XcodeGen)
owns `project.yml` and `.xcodeproj` is gitignored. From any chapter folder:

```bash
xcodegen generate
xcodebuild -project <AppName>.xcodeproj -scheme <AppName> \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Package tests, where a chapter has them (no simulator needed)
swift test --package-path Packages/Domain
```

`brew install xcodegen` if you don't have it. Each chapter folder's own `README.md` names its
scheme and any chapter-specific steps.

## Scorecards

Part II chapters end with a scorecard diffed against the **Chapter 1 baseline**: clean build
~3m10s · change one color ~40s · Music logic tests ~1m+ (simulator-bound) · two devs on two features
= merge conflicts on shared files. Later chapters measure against those four numbers.

## Naming

New code (Part I onward) uses the `Medley` app target. Part II's carried-over chapters still use the
historical `iTunesSearchApp` name; the rename lands with the Part II revision. The canonical naming
glossary — and the list of banned legacy names — lives in
[`plans/part-2-modular/00-conventions.md`](../plans/part-2-modular/00-conventions.md).
