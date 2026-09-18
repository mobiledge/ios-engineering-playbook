# Revision Plans — How to Execute

This directory contains the execution plan for restructuring the book into its 8-chapter arc
(see `00-conventions.md` for the full design). The work is split into **one plan file per
chapter** so each can be executed in its own session, in order, by a smaller model
(e.g. Sonnet) to conserve usage credits.

## Rules

1. **Execute strictly in order**: `ch01` → `ch02` → … → `ch08`. Each chapter's plan assumes
   every earlier plan is complete; each `code/part-2-modular/chNN` folder must start where `code/ch(N-1)`
   ended.
2. **One chapter per session.** Start a fresh session per chapter, e.g.:

   ```bash
   claude --model sonnet "Read plans/00-conventions.md, then execute plans/ch03-domain-and-infrastructure.md exactly. Do not touch anything its Out-of-scope section forbids."
   ```

3. **Always read `00-conventions.md` first.** It holds the canonical naming glossary, the
   banned names, the chapter prose template, the feature schedule, and the verification
   commands. Chapter plans inline the parts they need, but conventions win on any conflict.
4. **Check every acceptance criterion before finishing.** If a criterion fails, fix it in the
   same session. Do not start the next chapter's work.
5. **Commit at the end of each chapter session** with the message `chNN: <one-line summary>`.
6. **Stay in scope.** Each plan has an Out-of-scope section. A chapter session must never edit
   later chapters' code folders or prose files, except where the plan explicitly says so.

## Plan files

| Order | File | Prose target | Code target |
|---|---|---|---|
| 0 | `00-conventions.md` | — (shared reference) | — |
| 1 | `ch01-the-monolith.md` | `part-2-modular/01-the-monolith.md` | `code/part-2-modular/ch01-the-monolith` |
| 2 | `ch02-extracting-the-design-system.md` | `part-2-modular/02-extracting-design-system.md` | `code/part-2-modular/ch02-design-system` |
| 3 | `ch03-domain-and-infrastructure.md` | `part-2-modular/03-domain-and-infrastructure.md` | `code/part-2-modular/ch03-domain-infrastructure` |
| 4 | `ch04-vertical-slicing.md` | `part-2-modular/04-vertical-slicing.md` | `code/part-2-modular/ch04-vertical-slicing` |
| 5 | `ch05-dependency-inversion.md` | `part-2-modular/05-dependency-inversion.md` | `code/part-2-modular/ch05-dependency-inversion` |
| 6 | `ch06-the-composition-root.md` | `part-2-modular/06-composition-root.md` | `code/part-2-modular/ch06-composition-root` |
| 7 | `ch07-the-proof.md` | `part-2-modular/07-the-proof.md` (new) | `code/part-2-modular/ch07-the-proof` (new) |
| 8 | `ch08-advanced-granularity.md` | `part-2-modular/08-advanced-granularity.md` | `code/part-2-modular/ch08-advanced-granularity` |

Existing prose filenames are kept (URLs are stable); only chapter 7 adds a new file and the old
chapter 7 is renamed to chapter 8 (both renames happen inside the ch07 plan).
