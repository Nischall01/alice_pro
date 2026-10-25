# Alice Architecture & Implementation Plan

This implementation plan outlines the steps to build the complete **Alice** ecosystem: a robust cross-platform network inspector and database query workstation comprising shared transport serialization (`alice_transport`), mobile interception & storage (`alice`), and the desktop companion app (`alice_desktop`).

## User Review Required

> [!IMPORTANT]
> **Monorepo Structure**: We will structure the project as a Flutter workspace (`pubspec.yaml` with `workspace: [...]`), organizing code into modular packages under `packages/` and desktop applications under `apps/`.

## Open Questions

None at this time. All design decisions (WebSocket transport, SQLite/Hive local storage, 3-pane desktop workstation) are aligned with the project goals.

## Proposed Changes

### Monorepo & Core Transport (`alice_transport`)
- Update root `pubspec.yaml` to define a Flutter workspace.
- Complete `alice_transport` package with `AliceHttpCall`, `AliceDbTable`, and `AliceDbQuery` serialization models and JSON round-trip unit tests.

### Mobile Package (`packages/alice`)
- Implement mobile interception layers for `http` and `Dio`.
- Implement local SQLite storage buffer for captured network traffic.
- Implement WebSocket client for live telemetry streaming to desktop.

### Desktop Companion App (`apps/alice_desktop`)
- Wire up the WebSocket server to receive live telemetry from mobile devices.
- Connect the 3-pane UI (`NetworkInspectorScreen`) to live captured calls and local DB query console.

## Verification Plan

### Automated Tests
- Run `flutter test` across all packages to verify serialization models, unit tests, and widget tests.

### Manual Verification
- Launch the desktop companion app and mobile client, trigger HTTP requests, and verify real-time packet capture and query console execution.
