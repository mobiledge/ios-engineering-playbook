# Part I · iOS Architecture, One Skill at a Time

**Where should this *code* live?** · 1 → 2 people

A solo founder refactors a one-file SwiftUI app into a tested MVVM-C monolith — one
Single-Responsibility extraction per chapter, each codified as a reusable AI skill.

This is **Part I** of a four-part book that follows one company, Medley, from a solo prototype to a
full product organization. For the whole arc, see the [Series Roadmap](../README.md).

> **Not written yet.** The chapter list below is the outline; the detailed beat-by-beat plan lives
> in [`PREQUEL-OUTLINE.md`](../PREQUEL-OUTLINE.md).

## Chapters in this part

1. **The Prototype** — *Structure must earn its place.*
2. **Models** — *Data becomes a type the moment it enters the app.*
3. **Networking** — *The network hides behind a contract.*
4. **View Composition** — *A view renders what it is given, and nothing else.*
5. **View Models** — *Raw data never reaches a view.*
6. **Duplication and Abstraction** — *Duplication is cheaper than the wrong abstraction.*
7. **Design Tokens** — *A value used twice is a token.*
8. **Coordinators** — *A screen never decides where to go next.*
9. **Cross-Cutting Services** — *Depend on what you need, not on who provides it.*
10. **Project Generation** — *If it isn't in a text file, it isn't under control.*

*Epilogue — The Limits of Convention: a rule the compiler can't see is a rule waiting to break.*

## Code

End states live in [`code/part-1-architecture/`](../code/part-1-architecture/). The app target is
named `Medley` from the first chapter.
