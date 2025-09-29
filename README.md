# PHCL Accounts 📊

A comprehensive Flutter-based financial management and accounting application designed for efficient transaction management, dashboard analytics, and user administration. Built with Firebase backend and clean architecture principles.

## Features ✨

### 🔐 Authentication & Authorization

- **User Registration & Login**: Secure authentication with Firebase Auth
- **Role-based Access Control**: Different access levels for users and administrators
- **Password Reset**: Firebase-powered password recovery

### 💰 Transaction Management

- **Income & Expense Tracking**: Comprehensive transaction recording
- **Category Management**: Organize transactions by custom categories
- **Client Management**: Track transactions by client relationships
- **Attachment Support**: Upload and manage transaction receipts/documents
- **Real-time Sync**: Cloud-based data synchronization across devices

### 📈 Dashboard & Analytics

- **Financial Overview**: Real-time balance calculations and summaries
- **Visual Charts**: Interactive pie charts and trend analysis using Syncfusion
- **Income/Expense Distribution**: Category-wise breakdown and analysis
- **Revenue Trends**: Historical data visualization
- **Date Range Filtering**: Custom time period analysis

### 👥 Admin Features

- **User Management**: Administrative control over user accounts
- **System Settings**: Configure application parameters
- **Data Export**: Generate reports and export financial data

### 📱 Cross-Platform Support

- **Android**: Native Android application
- **iOS**: Native iOS application
- **Web**: Progressive web application
- **Windows**: Desktop application support
- **macOS & Linux**: Cross-platform desktop compatibility

## Technology Stack 🛠️

### Frontend

- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language
- **BLoC Pattern**: State management with flutter_bloc
- **Provider**: Additional state management
- **Material Design**: UI/UX components

### Backend & Services

- **Firebase Core**: Backend-as-a-Service platform
- **Firebase Auth**: Authentication service
- **Cloud Firestore**: NoSQL document database
- **Firebase Storage**: File storage service

### Key Dependencies

- **syncfusion_flutter_charts**: Advanced charting and data visualization
- **image_picker**: Camera and gallery image selection
- **file_picker**: File selection from device storage
- **pdfx**: PDF viewing and manipulation
- **cached_network_image**: Optimized image loading and caching
- **permission_handler**: Device permissions management
- **url_launcher**: Launch external URLs and applications

## Getting Started 🚀

### Prerequisites

- Flutter SDK (3.8.0 or higher)
- Dart SDK
- Android Studio / Xcode for mobile development
- Firebase project setup
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

3. **Firebase Setup**

   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication, Firestore Database, and Storage
   - Download `google-services.json` for Android and `GoogleService-Info.plist` for iOS
   - Place configuration files in respective platform directories

4. **Configure Firebase**

   ```bash
   flutter packages pub run build_runner build
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

### Build for Production

#### Android APK

```bash
flutter build apk --release
```

#### iOS

```bash
flutter build ios --release
```

#### Web

```bash
flutter build web --release
```

## Project Structure 📁

```
lib/
├── core/                     # Core utilities and widgets
│   ├── errors/              # Error handling classes
│   └── widgets/             # Reusable UI components
├── features/                # Feature-based modules
│   ├── admin/               # Admin management functionality
│   ├── auth/                # Authentication features
│   ├── dashboard/           # Analytics and dashboard
│   ├── settings/            # Application settings
│   └── transactions/        # Transaction management
├── firebase_options.dart    # Firebase configuration
└── main.dart               # Application entry point
```

### Architecture Pattern

This project follows **Clean Architecture** principles with:

- **Domain Layer**: Business logic and entities
- **Data Layer**: Repository implementations and data sources
- **Presentation Layer**: UI components and state management

## Configuration ⚙️

### Firebase Security Rules

Ensure proper Firestore security rules are configured:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /transactions/{transactionId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.createdBy;
    }

    // Admin access rules
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.token.admin == true;
    }
  }
}
```

## Contributing 🤝

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex business logic
- Maintain consistent formatting with `dart format`

## Testing 🧪

Run tests with:

```bash
flutter test
```

## Deployment 🚀

### Android Play Store

1. Configure `android/app/build.gradle` with proper signing
2. Build release APK or AAB
3. Upload to Google Play Console

### iOS App Store

1. Configure Xcode project settings
2. Build for release
3. Upload via Xcode or Application Loader

### Web Hosting

Deploy to Firebase Hosting, Netlify, or any static hosting service:

```bash
flutter build web
firebase deploy --only hosting
```

## Support & Issues 🆘

If you encounter any issues or have questions:

1. Check existing [Issues](https://github.com/Rashedujjaman/phcl_accounts/issues)
2. Create a new issue with detailed description
3. Contact the development team

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments 🙏

- Flutter team for the amazing framework
- Firebase team for backend services
- Syncfusion for charting components
- Open source community for various packages

---

**Made with ❤️ by [Rashedujjaman](https://github.com/Rashedujjaman)**

For more information, visit our [GitHub repository](https://github.com/Rashedujjaman/phcl_accounts).
