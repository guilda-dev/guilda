# notes/

Work-in-progress notes for the GUILDA redesign on the integration branch
`refactor/design-alignment`.

These files are **not user documentation**. They record the state of the
work while it is in progress: what has changed, what still has to be
decided or fixed, and how to migrate scripts and models.

- [v4-migration.md](v4-migration.md) — migration guide for script authors
  and model authors, deprecated forms, planned API changes and the
  compatibility policy.
- [status.md](status.md) — current test results, known failures and open
  items.
- [opf-requirements.md](opf-requirements.md) — agreed OPF requirements,
  roadmap and open design questions.
- [get-sys-workflow.md](get-sys-workflow.md) — survey of the workflow, data, edits, arguments and working data around `get_sys`.
- [get-sys-linearization.md](get-sys-linearization.md) — survey of the numerics and internals of `get_sys`.
- [get-sys-improvements.md](get-sys-improvements.md) — improvement proposals for `get_sys`, with measurements, roadmap and open decisions.
- [simulate-review-workflow.md](simulate-review-workflow.md) — survey of the workflow, data, edits and side effects around `simulate`.
- [simulate-review-runtime.md](simulate-review-runtime.md) — survey of the arguments, events, phases and internals of `simulate`.
- [simulate-review-measurements.md](simulate-review-measurements.md) — measurements of the behavior and performance of `simulate`.
- [simulate-improvements.md](simulate-improvements.md) — improvement proposals for `simulate`, with prototypes, roadmap and open decisions.
- [model-building-workflow.md](model-building-workflow.md) — survey of how systems are assembled from existing classes: routes, edits, tags, validation and failures.
- [model-building-extension.md](model-building-extension.md) — survey of how new Component, controller, Branch and network classes are implemented.
- [model-building-improvements.md](model-building-improvements.md) — improvement proposals for model building, with prototypes, roadmap and open decisions.

Where other kinds of content go:

- `_GUILDAdoc/` HTML pages are timeless documentation for users and future
  developers. They describe how GUILDA works, never the progress of this
  work.
- User-facing announcements of new classes, features and fixes go into the
  Home tab's Update log, `_GUILDAdoc/database/list_UpdateLog.js`.

This folder is removed, or condensed into release notes and the
documentation, when the redesign is released.
