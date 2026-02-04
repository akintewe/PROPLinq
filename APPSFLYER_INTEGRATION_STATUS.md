# AppsFlyer Integration Status & Testing Guide

## ✅ Integration Complete

### SDK Configuration
- **Dev Key**: `TBCWz6fvHsJ2xegPPzHGJH` ✓
- **iOS App ID**: `6755110033` ✓
- **Android Package Name**: `com.proplinq.app` ✓
- **SDK Version**: `appsflyer_sdk ^6.17.7+1` ✓

### Implemented Features

#### 1. ✅ SDK Initialization
**Location**: `lib/main.dart` (lines 36-42)
- Initializes on app startup
- Debug mode enabled for development builds
- Production ready configuration

#### 2. ✅ Deep Linking & Deferred Deep Linking
**Location**: `lib/core/services/deep_linking_service.dart`
- **Standard Deep Links**: `proplinq://listing/{propertyId}`, `proplinq://shortlet/{propertyId}`, `proplinq://hotel/{propertyId}`
- **AppsFlyer OneLinks**: Full support for install attribution and deep link data
- **Deferred Deep Linking**: Handles links clicked before app installation
- **Custom URL Schemes**: Uses app_links for Android App Links and iOS Universal Links

**Deep Link Handlers**:
- `onInstallConversionData`: Captures deferred deep links
- `onDeepLinking`: Handles deep links when app is already installed
- `uriLinkStream`: Listens for custom URL scheme links

#### 3. ✅ Customer User ID (Attribution)
**Location**: `lib/features/auth/views/login_view.dart` (line 115)
- Automatically sets user ID after successful login
- Links user actions to their AppsFlyer profile
- Enables cross-device attribution

#### 4. ✅ Event Logging
**Location**: `lib/core/services/deep_linking_service.dart` (line 285)
- `logEvent(eventName, eventValues)` method available
- Ready for custom event tracking

**Recommended Events to Track**:
```dart
// Property Views
DeepLinkingService().logEvent('property_view', {
  'property_id': propertyId,
  'property_type': propertyType,
});

// Bookings
DeepLinkingService().logEvent('booking_initiated', {
  'property_id': propertyId,
  'price': price,
});

// Search
DeepLinkingService().logEvent('search', {
  'location': location,
  'property_type': propertyType,
});
```

---

## 🧪 Testing Instructions

### 1. SDK Integration Test

#### Test 1: Verify SDK Initialization
1. Run the app in debug mode
2. Check console logs for:
   ```
   🔵 [DeepLinkingService] Initializing AppsFlyer SDK...
   ✅ [DeepLinkingService] AppsFlyer SDK initialized successfully
   ```
3. ✅ If you see these logs, SDK is initialized correctly

#### Test 2: Verify Device Registration
1. Open AppsFlyer Dashboard
2. Navigate to: **Dashboard > Reports > Raw Data Report**
3. Filter by App ID: `com.proplinq.app`
4. Look for your device's install event (may take 5-10 minutes)

### 2. Deep Link Testing

#### Android Testing

**Method 1: ADB Command**
```bash
# Test listing deep link
adb shell am start -W -a android.intent.action.VIEW \
  -d "proplinq://listing/123" com.proplinq.app

# Test shortlet deep link
adb shell am start -W -a android.intent.action.VIEW \
  -d "proplinq://shortlet/456" com.proplinq.app

# Test hotel deep link
adb shell am start -W -a android.intent.action.VIEW \
  -d "proplinq://hotel/789" com.proplinq.app
```

**Method 2: Test Script**
```bash
# Use the existing test script
./test_deeplink_android.sh listing 123
./test_deeplink_android.sh shortlet 456
./test_deeplink_android.sh hotel 789
```

#### iOS Testing

**Method 1: Safari**
1. Open Safari on iOS device/simulator
2. Type in address bar: `proplinq://listing/123`
3. Tap "Go"
4. Select "Open in PropLinq"

**Method 2: Notes App**
1. Create a note with: `proplinq://listing/123`
2. Tap the link
3. App should open to that property

#### Verify Deep Link Success
- Check console for deep link logs
- Verify app navigates to correct property detail page
- Property ID should match the one in the deep link

### 3. AppsFlyer OneLink Testing

#### Create OneLink (If not already done)
1. Go to AppsFlyer Dashboard > OneLink
2. Create new OneLink with:
   - **Deep Link Template**: `proplinq://listing/{property_id}`
   - **Android App**: `com.proplinq.app`
   - **iOS App**: `6755110033`

#### Test OneLink
```bash
# Example OneLink URL (replace with your actual OneLink domain)
https://proplinq.onelink.me/XXXX/property?property_id=123&property_type=listing

# Test via ADB (Android)
adb shell am start -W -a android.intent.action.VIEW \
  -d "https://proplinq.onelink.me/XXXX/property?property_id=123" \
  com.proplinq.app
```

### 4. Deferred Deep Link Testing (Install Attribution)

**Testing Flow**:
1. **Uninstall the app** from test device
2. Click on a OneLink or deep link (e.g., shared via WhatsApp)
3. Get redirected to Play Store/App Store
4. **Install the app**
5. Open the app for the first time
6. ✅ App should automatically navigate to the property from the original link

**Verify in AppsFlyer Dashboard**:
- Navigate to: **Reports > Installs**
- Look for your test install
- Check "Media Source" should show the attribution source
- Check "Deep Link Data" should show the property details

### 5. Customer User ID Test

1. Login to the app with a test account
2. Check console logs for AppsFlyer customer ID being set
3. In AppsFlyer Dashboard:
   - Go to: **Reports > User Acquisition**
   - Find your user by email or device ID
   - Verify "Customer User ID" field is populated

### 6. Event Logging Test

Add test events to your code:
```dart
// After viewing a property
DeepLinkingService().logEvent('test_property_view', {
  'property_id': '123',
  'property_type': 'listing',
  'timestamp': DateTime.now().toIso8601String(),
});
```

Verify in Dashboard:
- Navigate to: **Reports > In-App Events**
- Filter by event name: `test_property_view`
- Should appear within 5-10 minutes

---

## 📱 Testing Checklist

- [ ] SDK initializes on app launch
- [ ] Device appears in AppsFlyer dashboard
- [ ] Deep links work (proplinq://)
- [ ] OneLinks redirect correctly
- [ ] Deferred deep links work after install
- [ ] Customer User ID is set after login
- [ ] Custom events appear in dashboard
- [ ] Attribution data is tracked correctly

---

## 🔧 Debugging

### Enable Debug Mode
Debug mode is already enabled in development builds (`kDebugMode`).

### Check Logs
**iOS**: Use Xcode Console
**Android**: Use Android Studio Logcat or:
```bash
adb logcat | grep -i appsflyer
```

### Common Issues

**Issue**: Deep links not working
- **Solution**: Check AndroidManifest.xml and Info.plist for proper intent filters
- Verify URL scheme is registered: `proplinq://`

**Issue**: OneLink not redirecting
- **Solution**: Verify OneLink configuration in AppsFlyer dashboard
- Check App ID and Package Name are correct

**Issue**: No data in dashboard
- **Solution**: Wait 5-10 minutes for data to appear
- Verify internet connection
- Check SDK initialization logs

**Issue**: Deferred deep links not working
- **Solution**: Ensure fresh install (uninstall completely first)
- Check `onInstallConversionData` callback in logs
- Verify "is_first_launch" flag is true

---

## 📊 AppsFlyer Dashboard Access

**Dashboard URL**: https://hq1.appsflyer.com/

**View Key Reports**:
1. **Overview Dashboard**: Real-time install and event stats
2. **Cohort Analysis**: User retention and LTV
3. **Fraud Protection**: Invalid install detection
4. **Attribution Analytics**: Campaign performance
5. **Deep Linking**: Deep link performance metrics

---

## 🚀 Production Readiness

### Before Going Live:
1. ✅ SDK initialized - **DONE**
2. ✅ Customer User ID set - **DONE**
3. ✅ Deep linking configured - **DONE**
4. ⚠️ Add key event tracking (property_view, booking_initiated, search, etc.)
5. ⚠️ Configure push notification campaigns in AppsFlyer
6. ⚠️ Set up attribution links for marketing campaigns
7. ⚠️ Test on multiple devices (iOS & Android)
8. ⚠️ Verify production OneLinks work correctly

### Recommended Next Steps:
1. Implement event tracking for key user actions
2. Create marketing OneLinks for campaigns
3. Set up cohort analysis for retention tracking
4. Configure fraud protection rules
5. Integrate with ad networks for attribution

---

## 📞 Support

**AppsFlyer Documentation**: https://dev.appsflyer.com/
**SDK Reference**: https://pub.dev/packages/appsflyer_sdk
**Flutter Integration Guide**: https://dev.appsflyer.com/hc/docs/flutter

**In-App Support**:
- Deep Linking Service: `lib/core/services/deep_linking_service.dart`
- Deep Link Router: `lib/core/services/deep_link_router.dart`

---

## ✅ Summary

**AppsFlyer is fully integrated and ready for testing!**

All core features are implemented:
- ✅ SDK initialization
- ✅ Deep linking (standard + deferred)
- ✅ Customer User ID tracking
- ✅ Event logging capability
- ✅ OneLink support

**Next Actions**:
1. Test deep links using the commands above
2. Test deferred deep linking with fresh install
3. Add custom event tracking for key user actions
4. Verify data appears in AppsFlyer dashboard within 10 minutes
