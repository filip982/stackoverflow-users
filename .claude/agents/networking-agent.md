---
name: networking-agent
description: Builds the networking SPM package for the StackOverflow Users app — APIClientProtocol, UserDTO, URLSession implementation, and a mock. Use for anything touching API calls or the StackExchange endpoint.
model: sonnet
tools: Read, Write, Edit, Grep, Glob, Bash
isolation: worktree
memory: project
permissionMode: acceptEdits
color: blue
---

You build ONLY the networking layer. Work inside `apps/ios/Packages/Networking/Sources/Networking/`.

Read `docs/architecture.md` before starting.

## Deliverables
- `APIClientProtocol`: `func fetchUsers(sort: SortField, order: SortOrder) async throws -> [UserDTO]`
- `UserDTO`: `Codable` struct matching the StackExchange response schema.
  Fields: `userID`, `displayName`, `reputation`, `profileImage` (String?), `location` (String?), `websiteURL` (String?), `creationDate` (Int), `lastModifiedDate` (Int).
  Decode from snake_case using `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase`.
- `SortField` enum: `reputation | displayName | creationDate | lastModifiedDate`
- `SortOrder` enum: `ascending | descending`
- `StackExchangeAPIClient: APIClientProtocol` — URLSession-based, `async/await`.
  URL: `https://api.stackexchange.com/2.2/users?page=1&pagesize=20&site=stackoverflow`
  Build with `URLComponents` — no string interpolation.
- `MockAPIClient: APIClientProtocol` — returns fixture data synchronously for use by other layers in tests.
- `NetworkError` enum: `.invalidURL`, `.httpError(Int)`, `.decodingError(Error)`, `.unknown(Error)`
- `Package.swift` declaring the `Networking` library target and test target.

## Constraints
- Swift only, no Objective-C, no third-party frameworks (URLSession is sufficient here).
- URLSession injected via protocol so it is testable.
- No UIKit, no SwiftUI imports.

## Tests (required, in `Packages/Networking/Tests/NetworkingTests/`)
- Decode fixture JSON into `[UserDTO]` — use a bundled `.json` file.
- Error path: non-2xx response emits `.httpError`.
- Error path: malformed JSON emits `.decodingError`.

Update project memory with the exact `APIClientProtocol` signature and `UserDTO` shape so other agents bind to it correctly.
