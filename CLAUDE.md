```markdown
# Claude Custom Instructions

## 🎯 Core Principles
1.  **Accuracy First:** Prioritize syntactically correct and functional code over experimental or brief solutions.
2.  **Flutter Expert:** Assume all UI requests refer to Flutter/Dart unless specified otherwise.
3.  **Pixel-Perfect Fidelity:** When provided with a UI design or image description, replicate it exactly. Do not "improve," "modernize," or alter the design unless explicitly asked.
4.  **Cross-Platform (Mobile & Web):** All code must run without errors on both iOS/Android and Web. Avoid platform-specific dependencies (like `dart:io`) that crash on the web.

## 🖼️ UI & Design Rules (Image-to-Code)
* **Exact Reproduction:** Adhere strictly to the layout, spacing, fonts, and colors visible in reference images.
* **Asset Handling:** Use placeholders for images/icons if assets are not provided, but ensure the dimensions match the design exactly. Use `NetworkImage` or `AssetImage` (avoid `FileImage` to prevent Web crashes).
* **Responsive Strategy:**
    * **Mobile:** Use `SafeArea` and standard column/list layouts.
    * **Web:** Wrap main content in a `Center` widget with a `ConstrainedBox` (max-width: 1200px) to prevent the UI from stretching across large monitors.
    * **Text Scaling:** Use `MediaQuery.textScaleFactor` to ensure text remains readable on different screen densities.

## 🏗️ Code Architecture & Modularity
* **Componentization:** Never write monolithic widgets. Break down the UI into smaller, reusable widgets (e.g., `CustomButton`, `ProfileCard`, `HeaderSection`).
* **File Structure:**
    * Place reusable widgets in a `lib/widgets/` folder.
    * Place screens/pages in a `lib/screens/` folder.
    * Place data models in a `lib/models/` folder.
    * Place API service classes in a `lib/services/` folder.
    * Place all API response/request models in a `lib/models/` folder.
* **State Management:** Keep business logic separate from UI code. Avoid putting complex logic inside `build()` methods.

## 🌍 Web & Mobile Compatibility
* **Platform Checks:** Use `kIsWeb` (from `flutter/foundation`) for platform checks. Do **not** use `Platform.isAndroid` or `Platform.isIOS` in code that might run on the web.
* **Scrolling:** For horizontal lists, ensure `ScrollBehavior` is configured to support mouse dragging (for Web users).
* **Navigation:** Use named routes or a package like `go_router` to ensure URLs work correctly on the Web (handling deep links and browser history).

## 🧹 Code Style & Maintenance
* **Typed Code:** Always specify types for variables and return types for functions. Avoid `var` or `dynamic` unless absolutely necessary.
* **Comments:** Add brief comments explaining *why* a complex block of code exists, specifically for maintenance.
* **Constants:** Extract hardcoded colors, strings, and text styles into a separate `AppTheme` or `Constants` class to ensure consistency and easy updates.

## 🔌 Backend API Architecture

### Connection
* **Base URL:** The backend is a .NET Minimal API running at `http://localhost:5000` during development.
* **HTTP Client:** Use the `http` package. Create a single `ApiService` class in `lib/services/api_service.dart` that all other services extend or use. Never instantiate `http.Client` directly inside widgets.
* **Base URL Constant:** Store the base URL in a constants file:
```dart
// lib/constants/api_constants.dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:5000/api';
}
```

### Authentication
* **Login:** `POST /api/auth/login` with body `{ "email": "...", "password": "..." }`
* **Token Storage:** After a successful login, the response contains `{ "token": "...", "roleId": ... }`.
  Store the token securely using the `flutter_secure_storage` package. Never store it in `SharedPreferences`.
* **Sending the Token:** Every protected request must include the token in the Authorization header:
```dart
headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $token',
}
```
* **Session Handling:** If any API call returns a `401 Unauthorized`, immediately redirect the user to the login screen and clear the stored token.

### Service Structure
Each feature should have its own service file. Example structure:
```
lib/services/
  api_service.dart       # base HTTP logic (headers, error handling)
  auth_service.dart      # login, logout, token management
  meeting_service.dart   # meeting-related API calls
```

A base service example:
```dart
// lib/services/api_service.dart
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> getHeaders() async {
    final String? token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String endpoint) async {
    final Map<String, String> headers = await getHeaders();
    return http.get(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers,
    );
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final Map<String, String> headers = await getHeaders();
    return http.post(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }
}
```

### Error Handling
* **Always** check the response status code before parsing the body.
* Show user-friendly error messages using a `SnackBar` — never expose raw API error messages to the user.
* Wrap all API calls in `try/catch` to handle network failures gracefully:
```dart
try {
  final http.Response response = await _apiService.get('/meetings');
  if (response.statusCode == 200) {
    // parse and return data
  } else if (response.statusCode == 401) {
    // redirect to login
  } else {
    // show generic error snackbar
  }
} catch (e) {
  // handle no internet / timeout
}
```

### User Roles
The backend returns a `roleId` on login. Use it to control UI visibility:
* `roleId: 1` → Admin
* `roleId: 2` → Secretary
* `roleId: 3` → Department Head
* `roleId: 4` → Staff Member
* `roleId: 5` → Minute Taker

Store the `roleId` alongside the token and use it to show or hide UI elements per role. Never rely solely on hiding UI elements for security — the backend enforces access control.

---

## 📡 API Endpoints Reference

### Auth Endpoints — `/api/auth`
| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| POST | `/api/auth/login` | ❌ | Login with email & password. Returns `token` and `roleId` |
| POST | `/api/auth/logout` | ✅ | Invalidates the current session token |

**Login request body:**
```json
{
  "email": "user@example.com",
  "password": "yourpassword"
}
```
**Login response:**
```json
{
  "token": "...",
  "roleId": 1
}
```

---

### Meeting Endpoints — `/api/meetings`
| Method | Endpoint | Auth Required | Description |
|--------|----------|---------------|-------------|
| POST | `/api/meetings/` | ✅ | Create a new meeting |
| POST | `/api/meetings/signature/verify` | ✅ | Submit a digital signature for a meeting |

**Create meeting request body:**
```json
{
  "meetingDate": "2026-04-01T10:00:00",
  "agenda": "Discuss Q2 plans",
  "meetingContent": "Full meeting notes here...",
  "status": 0
}
```

**Signature verify — no request body needed.** The endpoint reads `UserId` and `MeetingId` from the JWT claims directly.

**Possible signature verify responses:**
* `200 OK` — Signature recorded successfully
* `401 Unauthorized` — No valid session
* `409 Conflict` — User has already signed, or meeting is in an invalid state for signing

---

### Important Notes for Flutter
* The `status` field in meetings is a numeric enum. Use constants to avoid magic numbers:
```dart
// lib/constants/api_constants.dart
class MeetingStatus {
  static const int draft = 0;
  static const int pendingApproval = 1;
  static const int finalized = 2;
}
```
* When calling `/api/meetings/signature/verify`, the backend reads user and meeting identity from the JWT token claims — do not send them in the request body.
* Always check for `409 Conflict` on the signature endpoint and show the user a message like "You have already signed this meeting."
```