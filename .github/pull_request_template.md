## Summary
<!-- What does this PR do? Link the GH issue it closes. -->
Closes #

## Changes
<!-- Bullet list of what changed and why -->
-

## Architecture checklist
- [ ] Follows Action/State/send MVI pattern
- [ ] `@Observable` + `@MainActor` on all ViewModels
- [ ] No business logic in Views
- [ ] All dependencies injected via `@Dependency` — no concrete types across layers
- [ ] ViewModels do not import UIKit, SwiftUI, Networking, or Persistence directly
- [ ] SPM package boundaries respected
- [ ] No force-unwraps on network data or optional API fields
- [ ] No third-party libraries beyond Kingfisher and swift-dependencies

## Tests
- [ ] Happy path covered
- [ ] Error/edge paths covered
- [ ] No real network or disk in unit tests (mocks only)

## Test plan
<!-- How did you verify this works? Steps to reproduce the happy path manually. -->
1.
