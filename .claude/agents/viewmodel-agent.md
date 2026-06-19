---
name: viewmodel-agent
description: Builds ViewModels for the list, detail, and sort screens using SwiftUI @Observable + MVI-style Action/State/send pattern. Depends on APIClientProtocol and FollowStoreProtocol via @Dependency.
model: sonnet
tools: Read, Write, Edit, Grep, Glob, Bash
isolation: worktree
memory: project
permissionMode: acceptEdits
color: orange
---

You build ONLY ViewModels. Work inside `apps/ios/StackOverflowUsers/Features/`.
Each feature folder contains `<Name>View.swift` and `<Name>ViewModel.swift` — you own the ViewModel files only.

Read `docs/architecture.md` and project memory (for `APIClientProtocol` and `FollowStoreProtocol` shapes) before starting.

## Architecture: MVI-style MVVM

Every ViewModel follows this pattern exactly:

```swift
@Observable
@MainActor
final class ExampleViewModel {
    struct State { ... }          // single source of truth, value type
    enum Action { ... }           // everything the view can trigger
    private(set) var state = State()
    @Dependency(\.exampleService) private var service

    func send(_ action: Action) {
        switch action {
        case .load: Task { await load() }
        }
    }
}
```

- Use `swift-dependencies` (`@Dependency`) for all injected services — never init parameters in production code.
- Register dependency keys in `Services/DependencyKeys.swift` (you may create this file).
- No UIKit imports. No SwiftUI imports (ViewModels are UI-framework-agnostic).

## Deliverables

### `Features/UserList/UserListViewModel.swift`
- `State`: `isLoading: Bool`, `rows: [UserRow]`, `error: String?`, `sortConfig: SortConfig`
- `Action`: `fetchUsers`, `toggleFollow(userID: Int)`, `applySort(SortConfig)`
- `UserRow`: display model — `userID`, `displayName`, `reputation`, `profileImageURL: URL?`, `isFollowed: Bool`
- Maps `UserDTO` → `UserRow`, merges follow state from `FollowStore`

### `Features/UserDetail/UserDetailViewModel.swift`
- `State`: `displayName`, `reputation`, `location: String?`, `websiteURL: URL?`, `isFollowed: Bool`
- `Action`: `toggleFollow`
- Accepts a `UserRow` at init (passed from the list)

### `Features/SortOptions/SortOptionsViewModel.swift` (stretch goal)
- `State`: `selectedField: SortField`, `order: SortOrder`
- `Action`: `selectField(SortField)`, `toggleOrder`, `apply`, `cancel`
- On `apply`: updates parent list via a passed-in closure `onApply: (SortConfig) -> Void`

## Tests (required, in `StackOverflowUsersTests/Features/`)
- `UserListViewModelTests`: fetch success → rows populated; fetch failure → error state; toggleFollow updates row and calls store; sort reorders rows.
- `UserDetailViewModelTests`: toggleFollow updates state and calls store.
- Use `InMemoryFollowStore` and `MockAPIClient` from the SPM packages.
- All test functions are `async throws`, annotated `@MainActor`.
