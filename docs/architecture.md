# Architecture Guide

This document is the source of truth for all agents and contributors working in this monorepo.
Read it before making any structural or pattern decisions.

---

## Monorepo Structure

```
stackoverflow-users/
├── apps/
│   ├── ios/        ← Milestone 1: SwiftUI app
│   └── android/    ← Milestone 2: Jetpack Compose app
├── core/
│   └── rust/       ← Milestone 3: shared business logic (UniFFI bridge)
├── tests/
│   └── e2e/        ← Milestone 4: integration and end-to-end tests
└── docs/
    └── architecture.md  ← this file
```

---

## Universal Patterns (apply to ALL platforms)

### 1. Unidirectional Data Flow

Every screen follows the same flow regardless of platform:

```
Action → ViewModel.send(action) → mutates State → View re-renders
```

- `Action` is a sealed enum of everything the user or system can trigger
- `State` is a value type (struct) — the single source of truth for a screen
- ViewModels expose one entry point: `send(_ action: Action)`
- Views are pure rendering functions of State — zero business logic

### 2. Layer Boundaries

```
View  →  ViewModel  →  Service  →  [Data packages]  →  Network/Disk
```

- Views import only their ViewModel
- ViewModels import only Service protocols (never concrete data implementations)
- Services import data packages and implement domain protocols
- Data packages (Networking, Persistence, ImageLoading) have no knowledge of each other

### 3. Protocol-Based Dependency Injection

All cross-layer references are to protocols, never concrete types.
This makes every layer independently testable.

- iOS: PointFree `swift-dependencies` (`@Dependency` property wrapper)
- Android: Hilt
- Tests always inject fakes/mocks — no real network or disk in unit tests

### 4. Domain Layer

The domain layer contains:
- **Models**: plain value types, no framework imports
- **Repository protocols**: define what data operations exist, not how they work

The domain layer has zero dependencies on any platform framework or data package.
It is the extraction point for the future Rust core (milestone 3).

---

## iOS (Milestone 1)

- **Language**: Swift 6, strict concurrency
- **UI**: SwiftUI
- **Min deployment**: iOS 17
- **Architecture**: MVVM structured as MVI (Action/State/send pattern above)
- **Reactive**: `@Observable` + `@MainActor` — no Combine, no RxSwift
- **Project generation**: XcodeGen (`project.yml`) — `.xcodeproj` is gitignored
- **Module system**: SPM local packages for data layer

### iOS Layer Map

| Layer | Location | Rule |
|---|---|---|
| Models + protocols | `StackOverflowUsers/Domain/` | No UIKit, no SwiftUI, no framework imports |
| Data (networking) | `Packages/Networking/` | SPM package, protocol-typed outputs |
| Data (persistence) | `Packages/Persistence/` | SPM package, UserDefaults-backed |
| Data (images) | Kingfisher (3rd party SPM) | `KFImage` in views, `ImageLoaderProtocol` wraps it for testability |
| Service / glue | `StackOverflowUsers/Services/` | Composes data packages, conforms to domain protocols |
| Features | `StackOverflowUsers/Features/<Name>/` | `<Name>View.swift` + `<Name>ViewModel.swift` |

### iOS Libraries

| Purpose | Library |
|---|---|
| Image loading | [Kingfisher](https://github.com/onevcat/Kingfisher) |
| Dependency injection | [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) (PointFree) |
| Testing | XCTest (native) |

### iOS ViewModel Template

```swift
@Observable
@MainActor
final class ExampleViewModel {

    struct State {
        var isLoading = false
        var items: [Item] = []
        var error: String? = nil
    }

    enum Action {
        case load
        case refresh
        case select(Item)
    }

    private(set) var state = State()

    @Dependency(\.exampleService) private var service

    func send(_ action: Action) {
        switch action {
        case .load: Task { await load() }
        case .refresh: Task { await load() }
        case .select(let item): handle(item)
        }
    }
}
```

---

## Android (Milestone 2)

- **Language**: Kotlin
- **UI**: Jetpack Compose
- **Architecture**: MVI (same Action/State/send mental model as iOS)
- **Module system**: Gradle multi-module (equivalent of iOS SPM packages)
- **DI**: Hilt

### Android Layer Map

| Layer | Gradle module | Rule |
|---|---|---|
| Models + protocols | `:domain` | Pure Kotlin, no Android framework |
| Networking | `:data:networking` | Retrofit + OkHttp |
| Persistence | `:data:persistence` | Room or DataStore |
| Image loading | Coil (in feature modules) | Compose-native |
| Features | `:feature:user-list`, `:feature:user-detail` | ViewModel + Composable |

### Android Libraries

| Purpose | Library |
|---|---|
| Networking | Retrofit + OkHttp |
| Image loading | Coil |
| DI | Hilt |
| Async | Kotlin Coroutines + Flow |
| Testing | JUnit5 + MockK |

### Android ViewModel Template

```kotlin
@HiltViewModel
class ExampleViewModel @Inject constructor(
    private val service: ExampleService
) : ViewModel() {

    sealed interface Action {
        data object Load : Action
        data class Select(val item: Item) : Action
    }

    data class State(
        val isLoading: Boolean = false,
        val items: List<Item> = emptyList(),
        val error: String? = null
    )

    private val _state = MutableStateFlow(State())
    val state: StateFlow<State> = _state.asStateFlow()

    fun send(action: Action) {
        when (action) {
            is Action.Load -> load()
            is Action.Select -> handle(action.item)
        }
    }
}
```

---

## Rust Core (Milestone 3)

- **Bridge**: Mozilla [UniFFI](https://github.com/mozilla/uniffi-rs)
- **Role**: shared business logic extracted from the domain layer (both iOS and Android domain layers are replaced by generated UniFFI bindings)
- **Location**: `core/rust/`

---

## Naming Conventions

| Context | Convention | Example |
|---|---|---|
| Swift files | PascalCase, suffix = role | `UserListViewModel.swift` |
| Swift protocols | Name + `Protocol` | `UserRepositoryProtocol` |
| Swift DI keys | camelCase | `\.userRepository` |
| Swift mocks (tests) | `Mock` prefix | `MockUserRepository` |
| Kotlin files | PascalCase | `UserListViewModel.kt` |
| Kotlin interfaces | Name + `Repository` / `Service` | `UserRepository` |
| JSON fields | snake_case decoded via `CodingKeys` (iOS) / Moshi/Gson (Android) | `display_name` → `displayName` |
| Feature folders | PascalCase on iOS, kebab-case module on Android | `UserList/` / `:feature:user-list` |

---

## What Agents Must NOT Do

- Import networking or persistence packages directly in a ViewModel or View
- Use singletons in production code (use DI instead)
- Add business logic to Views/Composables
- Introduce 3rd party libraries not listed above without updating this document
- Commit `.xcodeproj` (it is gitignored; run `xcodegen generate` locally)
- Use Objective-C, storyboards, or XIBs on iOS
- Use blocking/synchronous network calls
