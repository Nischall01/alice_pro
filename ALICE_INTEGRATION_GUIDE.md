# 🚀 Alice Pro Integration Guide
> **For Developers & AI Agents** — Complete guide to integrating the Alice Pro mobile capture SDK into any Flutter application for live inspection via the Alice Pro Desktop Workstation.

---

## 📖 Overview

**Alice Pro** consists of two components:
1. **Alice Desktop Workstation** — A 3-pane desktop application listening for HTTP traffic telemetry via WebSockets on port `4040`.
2. **Alice SDK (`packages/alice`)** — A lightweight Flutter SDK containing network interceptors for `http` and `Dio` that serializes HTTP traffic into `AliceHttpCall` transport packets and streams them over WebSocket to the Desktop Workstation.

---

## 🛠️ Step-by-Step Integration

### 1. Add Dependencies to `pubspec.yaml`

In your Flutter project's `pubspec.yaml`, add `alice` and `alice_transport`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Alice SDK Dependencies
  alice:
    path: /path/to/alice_pro/packages/alice
  alice_transport:
    path: /path/to/alice_pro/packages/alice_transport

  # Networking dependencies (use http, dio, or both)
  http: ^1.2.0
  dio: ^5.4.0
```

Run `flutter pub get`.

---

### 2. Network Connection Setup & Addresses

Choose the appropriate WebSocket URL based on target platform and environment:

| Platform / Device | WebSocket Connection URL | Notes |
| :--- | :--- | :--- |
| **Android Emulator** | `ws://10.0.2.2:4040/` | `10.0.2.2` maps to workstation `localhost` |
| **iOS Simulator** | `ws://localhost:4040/` or `ws://127.0.0.1:4040/` | Direct local connection |
| **Physical Device (USB)** | `ws://localhost:4040/` | Requires ADB port forward: `adb forward tcp:4040 tcp:4040` |
| **Physical Device (Wi-Fi)**| `ws://<YOUR_COMPUTER_IP>:4040/` | Ensure computer & device are on same Wi-Fi network |

---

### 3. Initialize Alice Core

Initialize the global `Alice` instance early in your application lifecycle (e.g. `main.dart`):

```dart
import 'package:flutter/material.dart';
import 'package:alice/alice.dart';

// Create a top-level or DI-managed Alice instance
final alice = Alice(
  configuration: const AliceConfiguration(
    appName: 'My App',
    // Set desktopCompanionUrl to stream packets live to Alice Desktop Workstation
    desktopCompanionUrl: 'ws://10.0.2.2:4040/', // Adjust URL per table above
    maxCallsCount: 1000,
  ),
);

void main() {
  runApp(const MyApp());
}
```

---

### 4. Wire Interceptors to Networking Clients

#### **Option A: `http` Package**
Wrap standard `http.Client()` calls with `AliceHttpClient`:

```dart
import 'package:http/http.dart' as http;
import 'package:alice/alice.dart';

final client = AliceHttpClient(
  http.Client(),
  alice: alice,
);

// Use 'client' everywhere in place of http.Client()
Future<void> fetchUserData() async {
  final response = await client.get(Uri.parse('https://api.example.com/v1/users'));
  print('Status: ${response.statusCode}');
}
```

#### **Option B: `Dio` Package**
Add `AliceDioInterceptor` to your `Dio` instance:

```dart
import 'package:dio/dio.dart';
import 'package:alice/alice.dart';

final dio = Dio(
  BaseOptions(
    baseUrl: 'https://api.example.com/v1',
    connectTimeout: const Duration(seconds: 10),
  ),
);

void setupDioInterceptors() {
  dio.interceptors.add(AliceDioInterceptor(alice: alice));
}

Future<void> loginUser(String email, String password) async {
  final response = await dio.post('/login', data: {
    'email': email,
    'password': password,
  });
}
```

---

## 🤖 Instructions for AI Coding Agents

If you are an AI coding agent tasked with enabling Alice Pro in a Flutter project, follow these steps:

```markdown
1. Inspect `pubspec.yaml` for existing network libraries (`http` or `dio`).
2. Add dependencies `alice` and `alice_transport`.
3. Locate app entrypoint (e.g. `lib/main.dart` or dependency injection module).
4. Instantiate `Alice(configuration: AliceConfiguration(desktopCompanionUrl: 'ws://10.0.2.2:4040/'))`.
5. Locate HTTP client instances (`http.Client` or `Dio`) and wrap/intercept them using `AliceHttpClient` or `AliceDioInterceptor`.
6. Run `flutter analyze` to confirm zero compilation errors.
```

---

## 🧪 Verifying Integration

1. Launch **Alice Pro Desktop App**:
   ```bash
   flutter run -d windows  # or macos / linux
   ```
2. Launch your Flutter mobile app on an emulator/device.
3. Trigger API requests inside your app.
4. Verify HTTP traffic appears immediately in the Alice Pro Desktop Workstation.
