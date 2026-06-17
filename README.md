# MedCenter — Medical Centre Management App

**Built by Mchector Dev | mchectordev.com**
Designed for GP clinics in South Africa & Zimbabwe.

---

## Overview

MedCenter is a fully offline, peer-to-peer Flutter application for GP clinic management.
- **No server required** — SQLite runs locally on every device
- **Peer-to-peer sync** — devices share data over clinic WiFi via UDP broadcast + built-in HTTP API
- **Fully offline first** — works without internet
- **Cross-platform** — Android tablet (Phase 1), Windows/macOS/Linux desktop (Phase 2)

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | Flutter 3.x (Dart) |
| Database | SQLite via `sqflite` |
| In-app API | `shelf` + `shelf_router` |
| Peer Discovery | UDP broadcast (`udp` package) |
| Sync Client | `dio` HTTP |
| State | Riverpod |
| Navigation | go_router |
| PDF | `pdf` + `printing` |
| Security | `crypto` + `flutter_secure_storage` |

---

## Project Structure

```
lib/
  main.dart                     # App entry point
  core/
    database/
      database_helper.dart      # SQLite init, CRUD helpers
      schema.dart               # All CREATE TABLE statements
    sync/
      sync_engine.dart          # 30s sync orchestrator
      peer_discovery.dart       # UDP broadcast + peer list
      conflict_resolver.dart    # Merge logic (version + timestamp)
      sync_queue.dart           # Local change queue
    api/
      api_server.dart           # shelf HTTP server (in-app, port 8080)
    security/
      auth_service.dart         # PIN login, sessions, role permissions
      key_generator.dart        # CLINIC KEY, DEVICE ID, UUID, PIN hash
      audit_logger.dart         # Write to audit_log table
    config/
      clinic_config.dart        # Clinic settings (key-value in SQLite)
  modules/
    setup/                      # Welcome, Create Clinic, Join Clinic
    staff/                      # Login screen, Staff list/form
    patients/                   # Patient list, form, detail (5 tabs)
    consultations/              # Consultation form + detail
    prescriptions/              # Prescription form + detail + PDF
    billing/                    # Invoice form + detail + payment
    appointments/               # Appointment list + form
    settings/                   # Clinic settings screen
  shared/
    models/                     # PatientModel, UserModel, etc.
    utils/
      number_generator.dart     # PAT-000001, INV-2026-0001, etc.
      date_formatter.dart       # "15 Jun 2026" formatting
    widgets/
      main_shell.dart           # Bottom nav scaffold
      loading_overlay.dart      # All shared widgets
    app_theme.dart              # Blue/white MedCenter theme
    app_router.dart             # go_router config with auth guards
```

---

## Getting Started

### Prerequisites
- Flutter 3.10+ installed (`flutter --version`)
- Android Studio or VS Code with Flutter plugin
- Android device or emulator (API 21+, Android 5+)

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Run on Android
```bash
flutter run
```

### 3. Build APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### 4. Build APK (split by ABI — smaller size)
```bash
flutter build apk --split-per-abi
```

---

## First-Time Clinic Setup

1. Install app on first tablet/device
2. Tap **"Create New Clinic"**
3. Enter clinic name, address, country (ZA or ZW), and admin PIN
4. App generates a **CLINIC KEY** (e.g. `8F3K-2X9P-LM4R-9QWZ`) — save it
5. Login with your admin PIN

### Adding More Devices
1. Install app on second device
2. Tap **"Join Existing Clinic"**
3. Enter the CLINIC KEY and your name/role/PIN
4. Both devices must be on the same WiFi
5. App auto-discovers the first device via UDP and copies the database

---

## Sync Architecture

```
Device A (Reception Tablet)          Device B (Doctor Tablet)
  SQLite (full copy)                   SQLite (full copy)
  API Server :8080          ←→         API Server :8080
  Sync Client (30s)                    Sync Client (30s)
  UDP broadcast                        UDP broadcast
```

- Every device **broadcasts on UDP port 9999** every 5 seconds
- Devices with the same CLINIC KEY auto-discover each other
- Sync runs every **30 seconds**: push local changes, pull peer changes
- **Conflict resolution**: higher `sync_version` wins; tie → newer `updated_at` wins
- Losing version saved to `sync_conflicts` table (recoverable by admin)

---

## Auto-Generated Numbers

| Type | Format | Example | Resets |
|------|--------|---------|--------|
| Patient | PAT-NNNNNN | PAT-000001 | Never |
| Appointment | APP-YYYY-NNNN | APP-2026-0001 | Yearly |
| Invoice | INV-YYYY-NNNN | INV-2026-0001 | Yearly |
| Receipt | REC-YYYY-NNNN | REC-2026-0001 | Yearly |
| Prescription | RX-YYYY-NNNN | RX-2026-0001 | Yearly |
| Lab Request | LAB-YYYY-NNNN | LAB-2026-0001 | Yearly |

---

## Role Permissions

| Action | Admin | Doctor | Nurse | Reception |
|--------|-------|--------|-------|-----------|
| Register patient | ✅ | — | — | ✅ |
| Create consultation | ✅ | ✅ | — | — |
| Enter vitals | ✅ | ✅ | ✅ | — |
| Create prescription | ✅ | ✅ | — | — |
| Create invoice | ✅ | — | — | ✅ |
| Process payment | ✅ | — | — | ✅ |
| Book appointment | ✅ | View | — | ✅ |
| Manage staff | ✅ | — | — | — |
| Delete records | ✅ | — | — | — |

---

## Phase Roadmap

| Phase | Modules | Timeline |
|-------|---------|----------|
| **Phase 1 (This build)** | Auth, Patients, Consultations, Prescriptions, Billing, Appointments | Complete |
| Phase 2 | Lab, Pharmacy, Documents, Reports, WhatsApp reminders | 6–8 weeks |
| Phase 3 | AI notes, Drug interactions, Medical aid claims | 6–8 weeks |
| Desktop | Windows / macOS / Linux builds (same codebase) | 2–3 weeks |

---

## Desktop Build (Phase 2)

Enable desktop targets:
```bash
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
flutter create --platforms=windows,macos,linux .
```

Key changes needed for desktop:
- Replace `sqflite` → `sqlite3` + `sqlite3_flutter_libs`
- Replace `workmanager` → `dart:isolate` + `Timer.periodic`
- Replace `camera` → `file_picker`
- Add `window_manager` for minimum window size
- `LayoutBuilder` detects width > 600px → switch to sidebar nav

---

## Security

- **CLINIC KEY** isolates clinics on shared WiFi — wrong key = rejected
- **PIN hashing** — PINs stored as SHA-256 hash, never plaintext
- **Audit trail** — every change logged with user, device, timestamp
- **Role-based access** — each role sees only permitted modules
- **Session timeout** — auto-logout after 30 minutes of inactivity

---

## Support

**Mchector Dev**
Website: [mchectordev.com](https://mchectordev.com)

---

*MedCenter Phase 1 — Confidential | Mchector Dev | 2026*
"# Medcenter-App"  
"# Medcenter-App-v2" 
