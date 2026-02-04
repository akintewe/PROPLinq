# OneSignal Player ID Update Implementation

## Overview
Implemented automatic player_id synchronization with the backend to fix in-app notifications. The player_id is now automatically sent to the backend whenever it becomes available.

## API Endpoint

**Endpoint**: `POST /api/v1/update-player-id`

**Request Body**:
```json
{
  "player_id": "dsfhgjkcvhbjknl"
}
```

**Authentication**: Required (Bearer token)

## Implementation Details

### 1. API Constant Added
**File**: `lib/core/constants/api_constants.dart`
- Added `updatePlayerId = '/update-player-id'` endpoint

### 2. OneSignal Service Updated
**File**: `lib/core/services/onesignal_service.dart`

#### New Features:

**A. Subscription Observer**
- Automatically listens for OneSignal subscription state changes
- Updates player_id on backend when subscription becomes available
- Triggers on subscription changes (permission granted, device registered, etc.)

**B. Automatic Player ID Update**
- `_updatePlayerIdIfAvailable()`: Checks for player_id and updates if available
- Called during initialization (with retry logic)
- Called when notification permission is granted
- Called when user logs in

**C. Manual Update Method**
- `updatePlayerId()`: Public method to manually trigger player_id update
- Can be called from anywhere in the app if needed

**D. Backend Sync Method**
- `_updatePlayerIdOnBackend()`: Sends player_id to backend API
- Includes error handling and logging
- Requires authentication

## How It Works

### Flow Diagram

```
App Starts
  ↓
OneSignal.initialize()
  ↓
_setupSubscriptionObserver() ← Listens for subscription changes
  ↓
_updatePlayerIdIfAvailable() ← Checks for player_id (with retry)
  ↓
User Logs In
  ↓
setExternalUserId() ← Sets user ID in OneSignal
  ↓
_updatePlayerIdIfAvailable() ← Updates player_id on backend
  ↓
Subscription State Changes
  ↓
Observer Triggers
  ↓
_updatePlayerIdOnBackend() ← Sends to API
```

### Automatic Triggers

The player_id is automatically updated in these scenarios:

1. **App Initialization**
   - After OneSignal initializes
   - Waits 2 seconds for OneSignal to be ready
   - Retries after 3 seconds if not available

2. **User Login**
   - When `setExternalUserId()` is called
   - Ensures player_id is synced when user authenticates

3. **Permission Granted**
   - When user grants notification permission
   - OneSignal generates player_id after permission

4. **Subscription Changes**
   - When subscription state changes (device registered, token refreshed, etc.)
   - Observer automatically triggers update

## Code Structure

### Key Methods

```dart
// Initialize OneSignal and set up observers
Future<void> initialize()

// Set up subscription observer
void _setupSubscriptionObserver()

// Check and update player_id if available
Future<void> _updatePlayerIdIfAvailable()

// Send player_id to backend
Future<void> _updatePlayerIdOnBackend(String playerId)

// Public method for manual update
Future<void> updatePlayerId()
```

### API Call

```dart
POST /api/v1/update-player-id
Headers:
  Authorization: Bearer {token}
  Content-Type: application/json
Body:
  {
    "player_id": "one_signal_player_id_here"
  }
```

## Console Logs

When working correctly, you'll see these logs:

**Initialization:**
```
🔔 [OneSignalService] Initializing OneSignal...
✅ [OneSignalService] OneSignal initialized successfully
```

**Player ID Available:**
```
🔔 [OneSignalService] Player ID available: abc123xyz
📤 [OneSignalService] Updating player_id on backend: abc123xyz
✅ [OneSignalService] Player ID updated successfully on backend
```

**Subscription Changes:**
```
🔔 [OneSignalService] Push subscription state changed
   - Subscription ID: abc123xyz
   - OptedIn: true
📤 [OneSignalService] Updating player_id on backend: abc123xyz
```

**User Login:**
```
🔔 [OneSignalService] Setting external user ID: 123
🔔 [OneSignalService] Player ID available: abc123xyz
📤 [OneSignalService] Updating player_id on backend: abc123xyz
```

## Testing

### Test 1: Initial Load
1. Fresh app install
2. Open app
3. Check console logs
4. **Expected**: Player ID should be sent to backend within 2-5 seconds

### Test 2: After Login
1. Login to the app
2. Check console logs
3. **Expected**: Player ID should be sent again after login

### Test 3: Permission Grant
1. Deny notification permission initially
2. Grant permission later
3. Check console logs
4. **Expected**: Player ID should be sent when permission is granted

### Test 4: Manual Update
```dart
// Call from anywhere in the app
OneSignalService().updatePlayerId();
```
**Expected**: Player ID should be sent to backend

## Error Handling

### Retry Logic
- If player_id not available immediately, retries after 3 seconds
- Subscription observer handles automatic retries on state changes

### Error Logging
- All errors are logged to console with `❌` prefix
- Failed API calls are logged with error details
- Non-critical errors don't crash the app

### Common Issues

**Issue**: Player ID not updating
- **Check**: Is user logged in? (requires auth)
- **Check**: Is OneSignal initialized?
- **Check**: Is notification permission granted?
- **Check**: Console logs for errors

**Issue**: API call failing
- **Check**: Authentication token is valid
- **Check**: Backend endpoint is correct
- **Check**: Network connectivity
- **Check**: Backend logs for errors

## Backend Requirements

The backend endpoint should:
1. Accept POST requests to `/api/v1/update-player-id`
2. Require authentication (Bearer token)
3. Accept JSON body with `player_id` field
4. Update the user's player_id in database
5. Return success/error response

**Expected Response:**
```json
{
  "success": true,
  "message": "Player ID updated successfully"
}
```

## Benefits

✅ **Automatic Sync**: No manual intervention needed
✅ **Multiple Triggers**: Updates on login, permission, subscription changes
✅ **Error Resilient**: Retries and error handling built-in
✅ **Logged**: All operations logged for debugging
✅ **Non-Blocking**: Doesn't block app functionality if update fails

## Future Enhancements

### Potential Improvements:
1. **Persistent Storage**: Cache player_id to avoid unnecessary API calls
2. **Batch Updates**: Queue updates if multiple happen quickly
3. **Retry Strategy**: Exponential backoff for failed API calls
4. **Analytics**: Track update success/failure rates
5. **User Preference**: Allow users to disable notifications

---

**Status**: ✅ Complete
**Endpoint**: `/api/v1/update-player-id`
**Method**: POST
**Authentication**: Required
**Implementation Date**: January 2026
