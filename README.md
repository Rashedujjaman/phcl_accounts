# PHCL Accounts

A comprehensive Flutter-based financial management and accounting application designed for efficient transaction management, dashboard analytics, and user administration. Built with Firebase backend, clean architecture principles, and **full offline-first capability**.

## Table of Contents

- [Features](#features-)
- [Offline-First Architecture](#offline-first-architecture-)
- [Technology Stack](#technology-stack-)
- [Getting Started](#getting-started-)
- [Offline Functionality Guide](#offline-functionality-guide-)
- [Project Structure](#project-structure-)
- [Testing](#testing-)
- [Troubleshooting](#troubleshooting-)
- [Deployment](#deployment-)
- [Contributing](#contributing-)
- [License](#license-)

## Features

### Authentication & Authorization

- **User Registration & Login**: Secure authentication with Firebase Auth
- **Role-based Access Control**: Different access levels for users and administrators
- **Password Reset**: Firebase-powered password recovery

### Transaction Management

- **Income & Expense Tracking**: Comprehensive transaction recording
- **Category Management**: Organize transactions by custom categories
- **Client Management**: Track transactions by client relationships
- **Attachment Support**: Upload and manage transaction receipts/documents (works offline!)
- **Real-time Sync**: Cloud-based data synchronization across devices
- ** Offline-First**: Create transactions without internet connection
- ** Auto-Sync**: Automatic synchronization when connection restored
- ** Offline Attachments**: Upload photos/documents even when offline

### Dashboard & Analytics

- **Financial Overview**: Real-time balance calculations and summaries
- **Visual Charts**: Interactive pie charts and trend analysis using Syncfusion
- **Income/Expense Distribution**: Category-wise breakdown and analysis
- **Revenue Trends**: Historical data visualization
- **Date Range Filtering**: Custom time period analysis

### Admin Features

- **User Management**: Administrative control over user accounts
- **System Settings**: Configure application parameters
- **Data Export**: Generate reports and export financial data

### 📱 Cross-Platform Support

- **Android**: Native Android application
- **iOS**: Native iOS application
- **Web**: Progressive web application
- **Windows**: Desktop application support
- **macOS & Linux**: Cross-platform desktop compatibility

---

## Offline-First Architecture 🌐

### Overview

This application implements a **complete offline-first architecture** that allows users to:

- ✅ Create transactions without internet
- ✅ Upload attachments while offline
- ✅ View all data offline
- ✅ Automatic synchronization when online
- ✅ Retry logic for failed syncs
- ✅ No data loss guarantee

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    USER INTERFACE                            │
│              (add_transaction_page.dart)                     │
│  User creates transaction → Add Transaction button          │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                 PRESENTATION LAYER                           │
│                 (TransactionBloc)                            │
│  Receives event → Calls repository                          │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              OfflineFirstTransactionRepository               │
│                (Smart Router)                                │
│  ┌─────────────────────────────────────────────────┐       │
│  │ Check Connectivity                               │       │
│  └─────────────┬────────────────────────────────────┘       │
│                │                                              │
│    ┌───────────┴───────────┐                                │
│    │                       │                                │
│ ONLINE                 OFFLINE                              │
│    │                       │                                │
│    ▼                       ▼                                │
│ Firebase               SQLite DB                            │
│ (Direct)              (Pending)                             │
└─────────────────────────────────────────────────────────────┘
                        │
              [Connection Restored]
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                    SyncService                               │
│  • Auto-triggers on connectivity change                     │
│  • Uploads pending transactions                             │
│  • Uploads offline attachments                              │
│  • Retries up to 3 times                                    │
│  • Cleans up local storage                                  │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

#### 1. **ConnectivityService**

- Monitors network status using `connectivity_plus`
- Broadcasts connection changes via stream
- Single source of truth for connectivity

#### 2. **OfflineFirstTransactionRepository**

- Routes operations based on connectivity
- Handles online/offline fallback
- Manages local file storage for attachments

#### 3. **OfflineTransactionRepository**

- SQLite database operations
- Stores pending transactions
- Tracks sync status and retry count

#### 4. **SyncService**

- Automatic background synchronization
- Listens to connectivity changes
- Handles attachment uploads during sync
- Retry logic with max 3 attempts

#### 5. **LocalDatabase**

- SQLite schema with pending_transactions table
- Offline attachment path storage
- Sync queue management

### Database Schema

```sql
CREATE TABLE pending_transactions (
  local_id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  category TEXT NOT NULL,
  date INTEGER NOT NULL,
  amount REAL NOT NULL,
  client_id TEXT,
  contact_no TEXT,
  note TEXT,
  attachment_url TEXT,
  attachment_type TEXT,
  attachment_local_path TEXT,       -- Local file path for sync
  transact_by TEXT,
  created_by TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  sync_status TEXT DEFAULT 'pending',
  firebase_id TEXT,
  retry_count INTEGER DEFAULT 0,
  error_message TEXT,
  last_sync_attempt INTEGER
);
```

---

## Technology Stack 🛠️

### Frontend Framework

- **Flutter 3.27.1**: Cross-platform UI framework
- **Dart 3.6.0**: Programming language

### State Management

- **flutter_bloc (^8.1.6)**: BLoC pattern implementation
- **provider (^6.1.2)**: Dependency injection

### Backend & Cloud Services

- **Firebase Core (^3.9.0)**: Firebase SDK initialization
- **Firebase Auth (^5.3.4)**: User authentication
- **Cloud Firestore (^5.6.0)**: NoSQL cloud database
- **Firebase Storage (^12.3.8)**: File and media storage

### Local Storage & Offline

- **sqflite (^2.4.1)**: SQLite database for offline storage
- **shared_preferences (^2.3.4)**: Local key-value storage
- **path_provider (^2.1.5)**: Access to file system directories
- **connectivity_plus (^6.1.1)**: Network connectivity monitoring

### UI Components & Visualization

- **syncfusion_flutter_charts (^27.2.5)**: Interactive charts and graphs
- **fl_chart (^0.69.2)**: Alternative charting library
- **shimmer (^3.0.0)**: Skeleton loading animations
- **cached_network_image (^3.4.1)**: Image caching and loading
- **lottie (^3.2.0)**: Vector animations

### File & Media Handling

- **image_picker (^1.1.3)**: Camera and gallery access
- **file_picker (^8.1.6)**: Document selection
- **pdfx (^2.8.0)**: PDF viewing and rendering
- **printing (^5.14.1)**: Document printing
- **file_saver (^0.2.15)**: Save files to device

### Utilities

- **intl (^0.20.1)**: Internationalization and formatting
- **uuid (^4.5.1)**: Unique identifier generation
- **fluttertoast (^8.2.8)**: Toast notifications
- **url_launcher (^6.3.1)**: External URL handling

### Development Tools

- **flutter_lints (^5.0.0)**: Static analysis and linting

---

## Getting Started 🚀

### Prerequisites

- Flutter SDK (3.27.1 or higher)
- Dart SDK (3.6.0 or higher)
- Android Studio or VS Code with Flutter extensions
- Firebase project with configured services
- Git

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/Rashedujjaman/phcl_accounts.git
   cd phcl_accounts
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication, Firestore Database, and Storage
   - Download and place configuration files:
     - `google-services.json` → `android/app/`
     - `GoogleService-Info.plist` → `ios/Runner/`
   - Run Firebase CLI setup:
     ```bash
     flutterfire configure
     ```

4. **Set up Firestore Collections**

   Create the following collections in Firestore:

   - `users` - User profiles and roles
   - `transactions` - Income and expense records
   - `clients` - Client information
   - `categories` - Transaction categories

5. **Configure Firebase Security Rules**

   Apply the security rules (see Firebase Setup section below)

6. **Run the application**
   ```bash
   flutter run
   ```

### Firebase Setup

#### Required Firebase Services

1. **Authentication**

   - Enable Email/Password sign-in method
   - Configure authorized domains for web deployment

2. **Cloud Firestore**

   - Create database in your preferred region
   - Set up security rules (see below)

3. **Firebase Storage**
   - Create default storage bucket
   - Configure CORS and security rules (see below)

#### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }

    // Helper function to check if user is admin
    function isAdmin() {
      return isAuthenticated() &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && (request.auth.uid == userId || isAdmin());
    }

    // Transactions collection
    match /transactions/{transactionId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() &&
                            (resource.data.createdBy == request.auth.uid || isAdmin());
    }

    // Clients collection
    match /clients/{clientId} {
      allow read, write: if isAuthenticated();
    }

    // Categories collection
    match /categories/{categoryId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
  }
}
```

#### Firebase Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Helper function to check authentication
    function isAuthenticated() {
      return request.auth != null;
    }

    // Attachment storage
    match /attachments/{userId}/{allPaths=**} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && request.auth.uid == userId;
      allow delete: if isAuthenticated() && request.auth.uid == userId;
    }

    // Profile images
    match /profiles/{userId}/{allPaths=**} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }
  }
}
```

---

## Offline Functionality Guide 📴

### How Offline Mode Works

#### Creating Transactions Offline

1. **User Action**: User creates transaction without internet
2. **Detection**: `ConnectivityService` detects no connection
3. **Local Save**: Transaction saved to SQLite with `local_id`
4. **User Feedback**: UI shows "Saved offline" message
5. **Sync Queue**: Transaction marked as pending for sync

#### Offline Attachment Upload

1. **File Selection**: User picks image/PDF from device
2. **Local Storage**: File copied to `app_flutter/offline_attachments/`
3. **Path Storage**: Local file path stored in database
4. **Sync Queue**: Attachment marked for upload when online

#### Automatic Synchronization

```
Connection Restored
        ↓
SyncService Triggered
        ↓
Query Pending Transactions
        ↓
Has Attachment? ──YES→ Upload to Firebase Storage
        │                      ↓
        NO                Get Download URL
        │                      ↓
        └──────────→ Sync to Firestore
                           ↓
                    Delete from SQLite
                           ↓
                    Delete Local Files
```

### Testing Offline Features

#### Manual Testing Checklist

- [ ] **Basic Offline Creation**

  - Turn off WiFi and mobile data
  - Create a transaction
  - Verify "Saved offline" message appears
  - Check transaction appears in list

- [ ] **Offline with Attachment**

  - Stay offline
  - Create transaction with image/PDF
  - Verify file displays locally
  - Check attachment preview works

- [ ] **Auto-Sync**

  - Keep app open
  - Turn on internet connection
  - Observe sync activity in logs
  - Verify transaction appears in Firebase Console

- [ ] **View Offline Data**
  - Create multiple transactions offline
  - View transaction list
  - Open transaction details
  - Verify all data displays correctly

---

## Project Structure 📁

```
lib/
├── core/                           # Core utilities and shared code
│   ├── errors/                     # Error handling
│   │   ├── failures.dart
│   │   ├── exceptions.dart
│   │   └── firebase_failure.dart
│   ├── services/                   # Core services
│   │   ├── connectivity_service.dart
│   │   ├── local_database.dart
│   │   └── sync_service.dart
│   └── widgets/                    # Reusable UI components
│       ├── skeleton_widgets.dart
│       ├── custom_button.dart
│       └── attachment_viewer.dart
│
├── features/                       # Feature-based modules
│   ├── admin/                      # Admin management
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── auth/                       # Authentication
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       └── widgets/
│   │
│   ├── dashboard/                  # Analytics and dashboard
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       └── widgets/
│   │           └── dashboard_skeleton.dart
│   │
│   └── transactions/               # Transaction management
│       ├── data/
│       │   ├── models/
│       │   └── repositories/
│       │       ├── transaction_repository_impl.dart
│       │       ├── offline_transaction_repository.dart
│       │       └── offline_first_transaction_repository.dart
│       ├── domain/
│       │   ├── entities/
│       │   └── repositories/
│       └── presentation/
│           ├── bloc/
│           ├── pages/
│           └── widgets/
│
├── firebase_options.dart
└── main.dart
```

### Architecture Pattern

This project follows **Clean Architecture** with **Offline-First** principles:

- **Domain Layer**: Business logic and entities (pure Dart)
- **Data Layer**: Repository implementations and data sources
  - Online Repository (Firebase)
  - Offline Repository (SQLite)
  - Offline-First Repository (Smart Router)
- **Presentation Layer**: UI components and BLoC state management

---

## Testing 🧪

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/transactions/transaction_bloc_test.dart
```

### Test Coverage

- Unit tests for BLoC logic
- Widget tests for UI components
- Integration tests for offline sync
- Repository tests for data operations

---

## Troubleshooting 🔧

### Common Issues

#### **Sync not triggering when connection restored**

**Solution:**

1. Ensure `SyncService` has `lazy: false` in provider setup
2. Check connectivity service initialization in `main.dart`
3. Verify logs show provider instantiation

#### **Local attachments not displaying**

**Solution:**

1. Check if path starts with `/` in database
2. Verify file exists at the stored path
3. Ensure `AttachmentViewer` widget detects local files correctly

#### **"Requires internet connection" error offline**

**Solution:**

1. Verify `ConnectivityService.hasConnection` returns false
2. Check repository routes to offline implementation
3. Ensure SQLite database is initialized

#### **Firebase permission errors**

**Solution:**

1. Review Firestore security rules
2. Verify user authentication status
3. Check user role permissions in database

---

## Deployment 🚀

### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS

```bash
# Build for iOS
flutter build ios --release
```

### Web

```bash
# Build for web
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

### Windows

```bash
flutter build windows --release
```

---

## Contributing 🤝

We welcome contributions! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit your changes**
   ```bash
   git commit -m 'Add some amazing feature'
   ```
4. **Push to the branch**
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open a Pull Request**

### Code Style

- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex business logic
- Run `dart format` before committing
- Run `flutter analyze` to check for issues

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

---

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments 🙏

- Flutter team for the amazing framework
- Firebase team for backend services
- Syncfusion for charting components
- Open source community for various packages
- All contributors who helped improve this project

---

## Support & Contact 📧

If you encounter any issues or have questions:

1. Check existing [Issues](https://github.com/Rashedujjaman/phcl_accounts/issues)
2. Review the [Troubleshooting](#troubleshooting-) section
3. Create a new issue with:
   - Detailed description
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots/logs (if applicable)

---

**Made with ❤️ by [Rashedujjaman](https://github.com/Rashedujjaman)**

For more information, visit the [GitHub repository](https://github.com/Rashedujjaman/phcl_accounts).
