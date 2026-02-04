# Shortlet Phone Number Blur Feature

## Overview
Implemented privacy protection for shortlet agent contact details. Phone numbers and WhatsApp numbers are now blurred until a user successfully books the shortlet.

## Feature Details

### How It Works
1. **For Shortlets Only**: This feature only applies to properties with type containing "shortlet"
2. **Booking Check**: On property details page load, the app checks if the user has booked this specific shortlet
3. **Payment Verification**: The booking must have a successful payment status (`paid`, `successful`, or `completed`)
4. **Blur Logic**: 
   - ✅ **Show normally**: User has booked the shortlet with successful payment
   - 🔒 **Blur contacts**: User has NOT booked the shortlet

### What Gets Blurred
- **Phone Number** (blurred)
- **WhatsApp Number** (blurred)
- **Email** (NOT blurred - remains visible)

### Visual Indicators
1. **Info Banner**: Yellow informational banner appears above contact details
   - Message: "Book this shortlet to view agent contact details"
   - Icon: Info icon
   - Color: Warning yellow/orange theme

2. **Blur Effect**: Phone and WhatsApp numbers appear blurred with backdrop filter
   
3. **Lock Icon**: Lock icon appears instead of copy icon when blurred
   - Tooltip: "Book this shortlet to view contact details"

## Implementation Details

### Files Modified
- **File**: `lib/features/home/views/property_details_view.dart` - Property details with blur logic
- **File**: `lib/core/services/bookings_cache_service.dart` - New service for caching bookings
- **File**: `lib/features/home/views/tenant_home_view.dart` - Pre-loads bookings cache
- **File**: `lib/features/home/views/agent_home_view.dart` - Pre-loads bookings cache
- **File**: `lib/features/auth/services/auth_service.dart` - Clears cache on logout

### New Service Created
- **`BookingsCacheService`**: Singleton service that caches user's bookings
  - Caches for 2 minutes
  - Auto-refreshes in background
  - Clears on logout
  - Provides instant synchronous booking checks

### New Imports
```dart
import 'dart:ui'; // For ImageFilter.blur
import 'package:proplinq/core/services/bookings_cache_service.dart'; // For cached booking checks
```

### New State Variables
```dart
final BookingsCacheService _bookingsCacheService = BookingsCacheService();
late bool _hasBookedProperty; // Initialized synchronously in initState
```

### New Methods

#### 1. `_checkIfPropertyBookedSync()`
- **Purpose**: INSTANTLY checks if user has booked this property (synchronous, no delay)
- **Called**: In `initState()` - before any rendering
- **Logic**:
  1. Only runs for shortlet properties
  2. Checks **cached** bookings data (no API call)
  3. Searches for matching property ID
  4. Verifies payment status is successful
  5. Returns boolean immediately

#### 2. `_refreshBookingsCacheIfNeeded()`
- **Purpose**: Refreshes bookings cache in background if needed
- **Called**: In `initState()` after synchronous check
- **Logic**:
  1. Fetches latest bookings from API (in background)
  2. Updates cache
  3. Re-checks booking status
  4. Updates UI only if status changed

#### 3. `_buildBlurredText()`
- **Purpose**: Creates a blurred text widget using BackdropFilter
- **Returns**: Stacked widget with text and blur overlay
- **Effect**: Blur sigma 5.0 on both X and Y axes

#### 4. Updated `_buildContactRow()`
- **New Parameter**: `shouldBlur` (optional, defaults to false)
- **Changes**:
  - Conditionally shows blurred or normal text
  - Shows lock icon instead of copy icon when blurred
  - Adds tooltip on lock icon

## Bookings Cache Service

### How It Works
1. **Initial Load**: Fetches bookings when user reaches home screen
2. **Cache Duration**: Data cached for 2 minutes
3. **Automatic Refresh**: Background refresh if cache expires
4. **Instant Access**: Property details screen checks cache synchronously
5. **No Flash**: Blur state determined before first render

### Cache Management
- **Clear on Logout**: Prevents showing previous user's data
- **Update on Booking**: Can add new bookings to cache
- **Force Refresh**: Can manually trigger refresh

### Booking Check API

**Endpoint**: `GET /bookings`

**Response Handling** (supports multiple formats):
```json
// Format 1: Direct list
[{booking1}, {booking2}, ...]

// Format 2: Nested in data
{
  "data": [{booking1}, {booking2}, ...]
}

// Format 3: Nested in bookings
{
  "data": {
    "bookings": [{booking1}, {booking2}, ...]
  }
}
```

**Booking Match Criteria**:
- `booking.property_id` must match current property ID
- `booking.payment_status` must be one of: `"paid"`, `"successful"`, or `"completed"`

### UI Components

#### Info Banner
```dart
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Color(0xFFFFF4E6), // Light yellow
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: Color(0xFFFFB547), // Orange
      width: 1,
    ),
  ),
  child: Row(
    children: [
      Icon(Icons.info_outline),
      Text('Book this shortlet to view agent contact details'),
    ],
  ),
)
```

#### Blur Condition
```dart
shouldBlur: isShortlet && !_hasBookedProperty
```

### Initialization Flow
```
App starts
  ↓
User logs in
  ↓
Home screen loads
  ↓
Bookings cache loads (background, ~1-2 seconds)
  ↓
User opens shortlet details
  ↓
Check cache INSTANTLY (synchronous, 0ms delay)
  ↓
Render with correct blur state (NO FLASH!)
  ↓
Background: Refresh cache if > 2 minutes old
```

## User Experience Flow

### Scenario 1: User Has NOT Booked the Shortlet
1. Opens shortlet property details
2. Sees info banner: "Book this shortlet to view agent contact details"
3. Phone number appears blurred
4. WhatsApp number appears blurred
5. Email remains visible
6. Lock icons appear instead of copy icons
7. Hovering over lock shows tooltip

### Scenario 2: User HAS Booked the Shortlet (Payment Successful)
1. Opens shortlet property details
2. No info banner appears
3. Phone number is fully visible and readable
4. WhatsApp number is fully visible and readable
5. Email remains visible
6. Copy icons appear for all contact fields
7. Can copy contact details normally

### Scenario 3: User Views Non-Shortlet Property (Listing/Hotel)
1. Opens property details
2. All contact details are fully visible
3. No blurring or restrictions
4. Normal behavior maintained

## Testing Guide

### Test Case 1: View Unbooked Shortlet
**Steps**:
1. Login as a user who has NOT booked any shortlets
2. Navigate to a shortlet property detail page
3. Scroll to agent contact section

**Expected**:
- ✅ Info banner appears
- ✅ Phone number is blurred
- ✅ WhatsApp is blurred
- ✅ Email is visible
- ✅ Lock icons shown

### Test Case 2: View Booked Shortlet
**Steps**:
1. Login as a user who HAS successfully booked a shortlet
2. Navigate to THAT shortlet's property detail page
3. Scroll to agent contact section

**Expected**:
- ✅ NO info banner
- ✅ Phone number is clear and visible
- ✅ WhatsApp is clear and visible
- ✅ Email is visible
- ✅ Copy icons shown

### Test Case 3: View Non-Shortlet Property
**Steps**:
1. Login as any user
2. Navigate to a regular listing or hotel property
3. Scroll to agent contact section

**Expected**:
- ✅ All contacts visible normally
- ✅ No blur effect
- ✅ No info banner
- ✅ Copy icons shown

### Test Case 4: Booking with Pending Payment
**Steps**:
1. Create a booking for a shortlet
2. Do NOT complete payment (status = "pending")
3. View that shortlet's details

**Expected**:
- ✅ Contact details remain BLURRED
- ✅ Info banner still appears
- ✅ Only successful payments unlock contacts

## Edge Cases Handled

1. **No Bookings API Response**: Assumes no bookings, blur applied
2. **API Error**: Assumes no bookings, blur applied (fail-safe)
3. **Checking State**: While checking bookings, blur is applied
4. **Property ID Missing**: Blur applied by default
5. **Invalid Payment Status**: Only accepts: `paid`, `successful`, `completed`
6. **Case Sensitivity**: Payment status check is case-insensitive

## Security Considerations

1. **Backend Enforcement**: This is a UI-only protection. Backend should also restrict contact info in API responses
2. **API Security**: Bookings endpoint requires authentication
3. **Property Owner**: Property owners always see their own contact info (via `_isOwner` check)

## Future Enhancements

### Potential Improvements:
1. **Backend API Update**: Return a `contact_visible` flag from the API
2. **Blur Other Fields**: Consider blurring agent name or profile image
3. **Partial Reveal**: Show first few digits of phone number
4. **Analytics**: Track how many users book after seeing blurred contacts
5. **A/B Testing**: Test if blurring increases or decreases booking rates

### Related Features:
1. **Payment Integration**: Ensure payment status updates trigger contact reveal
2. **Booking Confirmation**: After successful booking, auto-refresh property details
3. **In-App Messaging**: Encourage using in-app chat instead of direct contact

## Configuration

### To Enable/Disable
Currently hardcoded to be enabled for all shortlets. To make it configurable:

```dart
// Add to app config or feature flags
static const bool ENABLE_SHORTLET_CONTACT_BLUR = true;

// Use in condition:
shouldBlur: ENABLE_SHORTLET_CONTACT_BLUR && 
           isShortlet && 
           !_hasBookedProperty && 
           !_isCheckingBooking
```

### To Change Which Fields Are Blurred
Modify the `shouldBlur` parameter in the `_buildContactRow` calls:

```dart
// Current: Phone and WhatsApp blurred
_buildContactRow('phone_icon', phone, shouldBlur: condition),
_buildContactRow('whatsapp_icon', whatsapp, shouldBlur: condition),
_buildContactRow('email_icon', email), // Not blurred

// To blur email too:
_buildContactRow('email_icon', email, shouldBlur: condition),
```

## Performance Impact

- **✅ Zero Delay**: Uses cached bookings data - NO API call on property details load
- **✅ Cached**: Bookings data fetched once on home screen and cached for 2 minutes
- **✅ Background Refresh**: Cache refreshes automatically in background
- **✅ No Flickering**: Phone numbers are blurred from first render (no flash)

## Accessibility

- **Tooltip**: Lock icon has descriptive tooltip for screen readers
- **Info Banner**: Uses semantic colors (warning/info theme)
- **Clear Messaging**: Explicit message about why contacts are hidden

---

**Implementation Date**: January 2026
**Status**: ✅ Complete and Ready for Testing
**Applies To**: Shortlet properties only
**User Impact**: Privacy protection for agents, encourages bookings
