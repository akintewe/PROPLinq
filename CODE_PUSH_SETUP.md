# Code Push Setup Guide for Proplinq

This guide will help you set up **Firebase App Distribution** for over-the-air updates (Code Push) in your Flutter app.

## 🚀 What is Code Push?

Code Push allows you to push minor UI updates, bug fixes, and feature improvements to users without going through the App Store/Play Store review process. Perfect for:
- UI tweaks and styling changes
- Text updates and translations
- Minor bug fixes
- Feature flags and A/B testing
- Small feature additions

## 📋 Prerequisites

✅ Firebase CLI installed (v14.20.0) - **COMPLETED**
✅ Firebase App Distribution package added - **COMPLETED**
✅ Flutter project ready - **COMPLETED**

## 🔧 Setup Steps

### Step 1: Firebase Authentication
```bash
# Run this command in your terminal (outside of this environment)
firebase login
```
This will open a browser window for Google authentication.

### Step 2: Set Up Firebase Project (Manual Setup)

Since Firebase App Distribution is configured through the Firebase Console, let's set it up manually:

1. **Go to Firebase Console**: https://console.firebase.google.com
2. **Select your project** (or create a new one if needed)
3. **Navigate to App Distribution**:
   - In the left sidebar, click on "App Distribution"
   - If you don't see it, click on "Release & Monitor" → "App Distribution"

4. **Add your Android app**:
   - Click "Add app" → "Android"
   - Enter your package name (found in `android/app/build.gradle`)
   - Enter app nickname (e.g., "Proplinq Android")
   - Click "Register app"

5. **Add your iOS app** (if applicable):
   - Click "Add app" → "iOS"
   - Enter your bundle ID (found in `ios/Runner/Info.plist`)
   - Enter app nickname (e.g., "Proplinq iOS")
   - Click "Register app"

6. **Note down your App IDs** - you'll need these for distribution commands

### Step 3: Configure Firebase App Distribution
```bash
# Add App Distribution to your Firebase project
firebase appdistribution:distribute

# For Android APK
firebase appdistribution:distribute android/app/build/outputs/apk/release/app-release.apk \
  --app YOUR_ANDROID_APP_ID \
  --groups "testers" \
  --release-notes "Bug fixes and UI improvements"

# For iOS IPA
firebase appdistribution:distribute ios/build/ios/ipa/proplinq.ipa \
  --app YOUR_IOS_APP_ID \
  --groups "testers" \
  --release-notes "Bug fixes and UI improvements"
```

### Step 4: Add Code to Your Flutter App

Add this to your `main.dart` or initialization code:

```dart
import 'package:firebase_app_distribution/firebase_app_distribution.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    try {
      // Check for app updates
      final updateAvailable = await FirebaseAppDistribution.instance.checkForUpdate();
      
      if (updateAvailable) {
        // Show update dialog
        _showUpdateDialog();
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Available'),
          content: Text('A new version of the app is available. Would you like to update?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseAppDistribution.instance.startUpdate();
              },
              child: Text('Update Now'),
            ),
          ],
        );
      },
    );
  }
}
```

### Step 5: Build and Distribute

#### For Development/Testing:
```bash
# Build debug APK
flutter build apk --debug

# Distribute to testers
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-debug.apk \
  --app YOUR_ANDROID_APP_ID \
  --groups "testers" \
  --release-notes "Development build with latest changes"
```

#### For Production Updates:
```bash
# Build release APK
flutter build apk --release

# Distribute to production testers
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_ANDROID_APP_ID \
  --groups "production-testers" \
  --release-notes "Production update with bug fixes and UI improvements"
```

## 🎯 Usage Workflow

### Daily Development:
1. Make your UI changes
2. Test locally
3. Build and distribute to testers:
   ```bash
   flutter build apk --debug
   firebase appdistribution:distribute build/app/outputs/flutter-apk/app-debug.apk \
     --app YOUR_ANDROID_APP_ID \
     --groups "testers" \
     --release-notes "Latest changes"
   ```

### Production Updates:
1. Make your changes
2. Test thoroughly
3. Build release version:
   ```bash
   flutter build apk --release
   firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
     --app YOUR_ANDROID_APP_ID \
     --groups "production-users" \
     --release-notes "Bug fixes and improvements"
   ```

## 📱 User Experience

- Users will receive notifications about updates
- They can choose to update immediately or later
- Updates are downloaded and installed seamlessly
- No need to go through app stores for minor updates

## 🔒 Security & Limitations

**What CAN be updated via Code Push:**
- UI changes and styling
- Text and translations
- Business logic
- API endpoints
- Feature flags
- Minor bug fixes

**What CANNOT be updated via Code Push:**
- Native code changes
- New permissions
- App store metadata changes
- Major architecture changes
- New native dependencies

## 🚀 Quick Start Commands

```bash
# 1. Login to Firebase
firebase login

# 2. Initialize project
firebase init appdistribution

# 3. Build your app
flutter build apk --release

# 4. Distribute update
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_ANDROID_APP_ID \
  --groups "testers" \
  --release-notes "Your update message"
```

## 📞 Support

For issues with Firebase App Distribution:
- Check Firebase Console: https://console.firebase.google.com
- Firebase Documentation: https://firebase.google.com/docs/app-distribution
- Flutter Firebase Plugin: https://pub.dev/packages/firebase_app_distribution

---

**Next Steps:**
1. Run `firebase login` in your terminal
2. Run `firebase init appdistribution`
3. Follow the setup prompts
4. Test with a simple UI change
5. Build and distribute your first update!

This setup will allow you to push updates instantly to your users without app store delays! 🎉
