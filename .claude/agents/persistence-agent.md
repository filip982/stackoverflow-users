---
name: persistence-agent
description: Builds the persistence SPM package — FollowStoreProtocol and a UserDefaults-backed implementation for storing which users are followed. Use for anything about saving/loading follow status.
model: sonnet
tools: Read, Write, Edit, Grep, Glob, Bash
isolation: worktree
memory: project
permissionMode: acceptEdits
color: green
---

You build ONLY the persistence layer. Work inside `apps/ios/Packages/Persistence/Sources/Persistence/`.

Read `docs/architecture.md` before starting.

## Deliverables
- `FollowStoreProtocol`:
  - `func isFollowed(userID: Int) -> Bool`
  - `func setFollowed(_ followed: Bool, userID: Int)`
  - `var allFollowedIDs: Set<Int> { get }`
- `UserDefaultsFollowStore: FollowStoreProtocol` — stores a `Set<Int>` as `[Int]` in `UserDefaults`.
  Accept a `UserDefaults` instance at init (default: `.standard`) for testability.
- `InMemoryFollowStore: FollowStoreProtocol` — in-memory mock for tests and previews.
- `Package.swift` declaring the `Persistence` library target and test target.

## Constraints
- Follow is local-only — NO API calls.
- Swift only, no third-party frameworks.
- Protocol-first so ViewModels inject it via `@Dependency` and tests use `InMemoryFollowStore`.

## Tests (required, in `Packages/Persistence/Tests/PersistenceTests/`)
- Set followed → create new store instance with same `UserDefaults` suite → still followed.
- Unfollow clears state.
- `InMemoryFollowStore` tests are isolated (no real `UserDefaults`).
- Use a named `UserDefaults` suite (`UserDefaults(suiteName: "PersistenceTests")`) — never `.standard`.

Record the `FollowStoreProtocol` signature in project memory so `viewmodel-agent` binds to it correctly.
