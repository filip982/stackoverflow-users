# Roadmap

This is the authoritative source for milestones, features, and sequencing.
Agents read this file to understand what exists, what comes next, and why.
Update this file when priorities change — do not hardcode roadmap knowledge into agents.

---

## Milestone 1 — iOS

**Goal:** Functional iOS app with user list, detail, sorting, and local follow state.  
**Stack:** SwiftUI, XcodeGen, SPM local packages, swift-dependencies, Kingfisher.  
**Status:** In progress

| # | Feature | Branch | Status |
|---|---------|--------|--------|
| 1 | User list screen + follow/unfollow | `feature/user-list` | In progress |
| 2 | User detail screen + follow/unfollow | `feature/user-detail` | Blocked on #1 |
| 3 | Sort order screen | `feature/sort-order` | Blocked on #2 |
| 4 | Advanced testing (integration + e2e) | `feature/advanced-testing` | Blocked on #3 |

**Sequencing rules:**
- Features must be implemented in order — each reuses networking and persistence built in feature 1
- Feature 2 may start only after feature 1 is merged to `develop`
- Feature 3 may start only after feature 2 is merged to `develop`
- Feature 4 may start only after feature 3 is merged to `develop`

---

## Milestone 2 — Android

**Goal:** Android app mirroring iOS Milestone 1 feature-for-feature.  
**Stack:** Jetpack Compose, Gradle multi-module, Hilt, Retrofit, Coil.  
**Status:** Not started — begins after Milestone 1 is merged to `main`

| # | Feature | Status |
|---|---------|--------|
| 1 | User list screen + follow/unfollow | Pending |
| 2 | User detail screen + follow/unfollow | Pending |
| 3 | Sort order screen | Pending |
| 4 | Advanced testing | Pending |

**Sequencing rules:**
- Android features mirror iOS feature order for the same dependency reasons
- Android Milestone 2 may not start until iOS Milestone 1 is tagged and merged to `main`

---

## Milestone 3 — Rust Core

**Goal:** Extract shared domain logic (models, repository protocols, business rules) into a Rust crate exposed via UniFFI bindings. Both iOS and Android replace their domain layers with generated bindings.  
**Stack:** Rust, Mozilla UniFFI, `core/rust/`  
**Status:** Not started — begins after both iOS and Android share a stable domain contract

**Sequencing rules:**
- Requires Milestone 1 and Milestone 2 to be complete and stable
- Domain layer on both platforms must be frozen before extraction begins

---

## Milestone 4 — Advanced Cross-Platform Testing

**Goal:** Integration and e2e tests that span iOS, Android, and the Rust core.  
**Stack:** `tests/e2e/`, tooling TBD  
**Status:** Not started — begins after Milestone 3

---

## Definition of done (per milestone)

- All features merged to `develop`
- All PRs have `VERDICT: APPROVED` from reviewer-agent
- Tagged release (`vX.Y.0`) triggers PR to `main`
- Human approves and merges to `main`
- `main` is always releasable
