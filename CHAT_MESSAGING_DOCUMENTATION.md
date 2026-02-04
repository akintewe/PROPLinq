# Chat and Messaging System Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [API Endpoints](#api-endpoints)
4. [Service Layer (ChatService)](#service-layer-chatservice)
5. [UI Components](#ui-components)
6. [Data Flow](#data-flow)
7. [Features](#features)
8. [Technical Implementation Details](#technical-implementation-details)

---

## Overview

The chat and messaging system allows users (home seekers and agents) to communicate about properties within the app. It includes real-time message polling, online status tracking, file attachments, and message read receipts.

### Key Features
- **In-app messaging**: Direct messaging between users about properties
- **File attachments**: Support for images, videos, and documents
- **Online status**: Real-time online/offline status tracking
- **Read receipts**: Track when messages are received/read
- **Unread counts**: Badge indicators for unread messages
- **Auto-refresh**: Periodic polling for new messages

---

## Architecture

### Component Structure

```
lib/features/home/
├── services/
│   └── chat_service.dart          # Core chat API service
├── views/
│   ├── messages_view.dart          # Conversation list view
│   └── in_app_chat_view.dart      # Individual chat screen
└── models/
    └── (ChatMessage model is defined inline)
```

### Key Dependencies
- **Dio**: HTTP client for API calls
- **AuthService**: User authentication
- **StorageService**: Token and data persistence

---

## API Endpoints

All endpoints are defined in `lib/core/constants/api_constants.dart` and use the base URL: `https://proapi.proplinq.com/api/v1`

### 1. Send Message

**Endpoint**: `POST /chat/webhook`

**Purpose**: Send a message (text or with file attachment)

**Authentication**: Required (Bearer token)

**Request Format**:

**For text-only messages (JSON)**:
```json
{
  "sender_id": 123,           // Integer - Current user's ID
  "receiver_id": 456,         // Integer - Recipient's ID
  "message": "Hello!",        // String - Message content
  "sent_at": "2026-01-08T12:00:00.000Z",  // ISO 8601 timestamp
  "property_id": 789          // Integer (optional) - Related property ID
}
```

**For messages with file attachments (FormData)**:
```
sender_id: "123"              // String - Current user's ID
receiver_id: "456"            // String - Recipient's ID
message: "Check this out!"    // String - Message content
sent_at: "2026-01-08T12:00:00.000Z"  // ISO 8601 timestamp
file: "/path/to/file.jpg"     // String - File path
property_id: "789"            // String (optional) - Related property ID
```

**Response**:
- `200` or `201`: Message sent successfully
- `401`: Unauthorized
- `400`: Bad request

**Implementation Notes**:
- Uses `FormData` when file is present, JSON otherwise
- File path is sent as string, not binary data
- Timestamp is generated client-side using `DateTime.now().toIso8601String()`

---

### 2. Get User Chats (Conversation List)

**Endpoint**: `GET /get-user-chats`

**Purpose**: Retrieve all conversations for the current user

**Authentication**: Required (Bearer token)

**Response Structure**:
```json
{
  "status": true,
  "message": "Success",
  "data": [
    {
      "id": 1,
      "sender_id": 123,
      "receiver_id": 456,
      "message": "Latest message text",
      "sent_at": "2026-01-08T12:00:00.000Z",
      "received_at": "2026-01-08T12:01:00.000Z",
      "property_id": 789,
      "sender": {
        "id": 123,
        "name": "John Doe",
        "email": "john@example.com",
        "phone_number": "+1234567890",
        "profile_image": "https://..."
      },
      "receiver": {
        "id": 456,
        "name": "Jane Smith",
        "email": "jane@example.com",
        "phone_number": "+0987654321",
        "profile_image": "https://..."
      },
      "property": {
        "id": 789,
        "title": "Property Title",
        "location": "Property Location"
      },
      "is_read": false
    }
  ]
}
```

**Alternative Response** (if API returns array directly):
```json
[
  {
    "id": 1,
    "sender_id": 123,
    ...
  }
]
```

**Implementation Notes**:
- Handles both nested `data.data` structure and direct array responses
- Conversations are grouped by `other_person_id` (sender or receiver depending on user role)
- Latest message is used as preview
- Unread status is determined by `is_read` field

---

### 3. Get Conversation with Specific User

**Endpoint**: `GET /chats/conversation/{receiver_id}`

**Purpose**: Retrieve full message history with a specific user

**Authentication**: Required (Bearer token)

**Path Parameters**:
- `receiver_id`: The ID of the user you're chatting with

**Response Structure**:
```json
{
  "status": true,
  "data": {
    "messages": [
      {
        "id": 1,
        "sender_id": 123,
        "receiver_id": 456,
        "message": "Message text",
        "sent_at": "2026-01-08T12:00:00.000Z",
        "updated_at": "2026-01-08T12:00:00.000Z",
        "created_at": "2026-01-08T12:00:00.000Z",
        "received_at": "2026-01-08T12:01:00.000Z",
        "file_url": "https://...",  // or "file" field
        "property_id": 789,
        "sender": {
          "id": 123,
          "name": "John Doe",
          "profile_image": "https://..."
        },
        "receiver": {
          "id": 456,
          "name": "Jane Smith",
          "profile_image": "https://..."
        }
      }
    ]
  }
}
```

**Alternative Response** (legacy format):
```json
{
  "data": [
    {
      "id": 1,
      "sender_id": 123,
      ...
    }
  ]
}
```

**Implementation Notes**:
- Handles multiple response formats (nested `data.data.messages`, `data.data` array, or direct array)
- Returns empty array `[]` if no conversation exists (404 is treated as normal)
- Messages can be filtered by `property_id` on client side if needed
- Uses `updated_at` for sorting if available, falls back to `sent_at` or `created_at`

---

### 4. Mark Message as Received/Read

**Endpoint**: `POST /chat/mark-received/{message_id}`

**Purpose**: Mark a message as received/read

**Authentication**: Required (Bearer token)

**Path Parameters**:
- `message_id`: The ID of the message to mark as read

**Response**:
- `200` or `204`: Successfully marked as received
- `401`: Unauthorized
- `404`: Message not found

**Implementation Notes**:
- Called automatically when chat screen is opened
- Updates `received_at` timestamp on server
- Used to determine read/unread status

---

### 5. Update Online Status

**Endpoint**: `POST /chat/update-online-status`

**Purpose**: Update current user's online status to "online"

**Authentication**: Required (Bearer token)

**Request Body**:
```json
{}
```

**Response**:
- `200` or `204`: Status updated successfully

**Implementation Notes**:
- Called periodically (every 30 seconds) to keep user marked as online
- Also called when entering chat screens
- Empty body is sent (server likely uses timestamp)

---

### 6. Check Online Status

**Endpoint**: `POST /chat/check-online-status`

**Purpose**: Check online status for multiple users

**Authentication**: Required (Bearer token)

**Request Body**:
```json
{
  "user_ids": [123, 456, 789]
}
```

**Response Structure** (multiple formats supported):

**Format 1 - List of objects**:
```json
{
  "data": [
    {
      "id": 123,
      "is_online": true
    },
    {
      "id": 456,
      "is_online": false
    }
  ]
}
```

**Format 2 - Map with nested objects**:
```json
{
  "data": {
    "123": {
      "is_online": true
    },
    "456": {
      "is_online": false
    }
  }
}
```

**Format 3 - Direct map**:
```json
{
  "123": true,
  "456": false
}
```

**Implementation Notes**:
- Handles multiple response formats for flexibility
- Returns `Map<String, bool>` with user ID as key and online status as value
- Called periodically (every 10 seconds) to update online statuses
- Status is cached in UI for performance

---

### 7. Get My Online Status

**Endpoint**: `GET /chat/my-online-status`

**Purpose**: Get current user's own online status

**Authentication**: Required (Bearer token)

**Response Structure**:
```json
{
  "status": true,
  "data": {
    "user_id": 123,
    "is_online": true,
    "last_seen": "2026-01-08T12:00:00.000Z"
  }
}
```

**Alternative Response**:
```json
{
  "user_id": 123,
  "is_online": true,
  "last_seen": "2026-01-08T12:00:00.000Z"
}
```

---

## Service Layer (ChatService)

Location: `lib/features/home/services/chat_service.dart`

### Class Overview

The `ChatService` class handles all chat-related API interactions. It uses Dio directly for most endpoints to handle array responses and various response formats.

### Key Methods

#### 1. `sendMessage()`

```dart
Future<bool> sendMessage({
  required String message,
  required String senderId,
  required String receiverId,
  required String propertyId,
  String? file,
})
```

**Purpose**: Send a message (text or with file)

**Logic**:
- If `file` is provided: Uses FormData with Dio
- If no file: Uses JSON with ApiService
- Converts IDs to appropriate types (string for FormData, int for JSON)
- Returns `true` if status code is 200 or 201

**Usage Example**:
```dart
final success = await chatService.sendMessage(
  message: "Hello!",
  senderId: "123",
  receiverId: "456",
  propertyId: "789",
  file: "/path/to/image.jpg",  // Optional
);
```

---

#### 2. `sendInAppMessage()`

```dart
Future<bool> sendInAppMessage({
  required String message,
  required String recipientId,
  required String propertyId,
  String? file,
})
```

**Purpose**: Convenience method that automatically gets current user ID

**Logic**:
- Gets current authenticated user
- Extracts user ID
- Calls `sendMessage()` with current user as sender

---

#### 3. `getUserChats()`

```dart
Future<List<Map<String, dynamic>>> getUserChats()
```

**Purpose**: Get all conversations for current user

**Returns**: List of chat objects (latest message per conversation)

**Response Handling**:
- Handles `data.data` (nested array)
- Handles direct array response
- Returns empty list on error

---

#### 4. `getConversation()`

```dart
Future<List<Map<String, dynamic>>> getConversation(String receiverId)
```

**Purpose**: Get full conversation history with a user

**Parameters**:
- `receiverId`: The user you're chatting with

**Response Handling**:
- Handles `data.data.messages` (nested structure)
- Handles `data.data` (array)
- Handles direct array
- Returns empty array for 404 (no conversation exists)

---

#### 5. `getChatHistory()`

```dart
Future<List<Map<String, dynamic>>> getChatHistory({
  required String agentId,
  required String propertyId,
})
```

**Purpose**: Get conversation filtered by property ID

**Logic**:
- Calls `getConversation(agentId)`
- Filters results by `property_id`
- Returns filtered list

---

#### 6. `markMessageAsRead()`

```dart
Future<bool> markMessageAsRead(String messageId)
```

**Purpose**: Mark a message as received/read

**Logic**:
- Parses message ID to integer
- Makes POST request to `/chat/mark-received/{message_id}`
- Returns true if status is 200 or 204

---

#### 7. `updateOnlineStatus()`

```dart
Future<bool> updateOnlineStatus()
```

**Purpose**: Update current user's online status

**Logic**:
- Sends POST to `/chat/update-online-status`
- Empty body
- Called periodically to keep user online

---

#### 8. `checkOnlineStatus()`

```dart
Future<Map<String, bool>> checkOnlineStatus(List<int> userIds)
```

**Purpose**: Check online status for multiple users

**Parameters**:
- `userIds`: List of user IDs to check

**Returns**: `Map<String, bool>` with user ID as key, online status as value

**Response Handling**:
- Handles list format: `[{id: 123, is_online: true}]`
- Handles nested map: `{data: {123: {is_online: true}}}`
- Handles direct map: `{123: true}`
- Converts boolean, int (1/0), or nested objects to boolean

---

#### 9. `getMyOnlineStatus()`

```dart
Future<Map<String, dynamic>?> getMyOnlineStatus()
```

**Purpose**: Get current user's online status

**Returns**: Map with user status info or `null` on error

---

#### 10. `getUnreadMessageCount()`

```dart
Future<int> getUnreadMessageCount()
```

**Purpose**: Count unread conversations

**Logic**:
- Calls `getUserChats()`
- Counts items where `is_read == false`
- Returns count

---

## UI Components

### 1. MessagesView

**Location**: `lib/features/home/views/messages_view.dart`

**Purpose**: Display list of all conversations

**Key Features**:
- Search/filter conversations
- Unread badge indicators
- Online status indicators
- Last message preview
- Property context

**State Management**:
- `_conversations`: All conversations
- `_filteredConversations`: Filtered/search results
- `_onlineStatusCache`: Cached online statuses
- `_unreadStatusCache`: Cached unread statuses

**Periodic Updates**:
- Conversations refresh: Every 3 seconds
- Online status check: Every 10 seconds
- Update own status: Every 30 seconds

**Data Flow**:
1. Load conversations via `getUserChats()`
2. Group by `other_person_id` (sender/receiver depending on current user)
3. Extract latest message per conversation
4. Update UI with conversation list

---

### 2. InAppChatView

**Location**: `lib/features/home/views/in_app_chat_view.dart`

**Purpose**: Individual chat screen with message thread

**Key Features**:
- Message bubbles (sent/received)
- File attachments (images, videos, documents)
- Typing indicators
- Online status display
- WhatsApp fallback banner (after 3 minutes)
- Auto-scroll to latest message
- Message read receipts

**State Management**:
- `_messages`: List of `ChatMessage` objects
- `_isAgentOnline`: Agent's online status
- `_selectedFilePath`: File selected for attachment
- `_isTypingVisible`: Typing indicator visibility

**Periodic Updates**:
- Message polling: Every 1 second (while chat is open)
- Online status check: Every 30 seconds
- Update own status: Every 30 seconds

**Data Flow**:
1. Load chat history via `getChatHistory(agentId, propertyId)`
2. Convert API response to `ChatMessage` objects
3. Sort by timestamp
4. Display in chat bubbles
5. Poll for new messages periodically
6. Auto-scroll when new messages arrive

**ChatMessage Model** (inline):
```dart
class ChatMessage {
  final String text;
  final bool isFromUser;
  final DateTime timestamp;
  final String? filePath;
  final String? fileType;  // 'image', 'video', 'document'
  final bool? isRead;
  final String? receivedAt;
  final String? messageId;
}
```

---

## Data Flow

### Sending a Message

```
User types message + optional file
    ↓
InAppChatView._sendMessage()
    ↓
Adds message to UI immediately (optimistic update)
    ↓
ChatService.sendInAppMessage()
    ↓
Gets current user ID
    ↓
ChatService.sendMessage()
    ↓
If file: FormData with Dio
If no file: JSON with ApiService
    ↓
POST /chat/webhook
    ↓
Returns success/failure
    ↓
Updates UI accordingly
```

---

### Receiving Messages

```
InAppChatView loads
    ↓
ChatService.getChatHistory()
    ↓
ChatService.getConversation()
    ↓
GET /chats/conversation/{receiver_id}
    ↓
Filters by property_id (if provided)
    ↓
Converts to ChatMessage objects
    ↓
Displays in UI
    ↓
Starts polling timer (1 second)
    ↓
Periodically calls getConversation()
    ↓
Checks for new messages (length comparison)
    ↓
Updates UI if new messages found
    ↓
Marks messages as read
    ↓
POST /chat/mark-received/{message_id}
```

---

### Online Status Flow

```
User opens MessagesView or InAppChatView
    ↓
Update own status immediately
    ↓
POST /chat/update-online-status
    ↓
Start periodic timer (30 seconds)
    ↓
Every 30 seconds: Update own status
    ↓
Every 10 seconds (MessagesView): Check others' status
    ↓
POST /chat/check-online-status with user IDs
    ↓
Update onlineStatusCache
    ↓
Display online indicators in UI
```

---

## Features

### 1. Real-time Message Polling

**Implementation**: Timer-based polling (not WebSockets)

**Frequency**:
- Chat screen open: Every 1 second
- Conversation list: Every 3 seconds

**Logic**:
- Compare message count with previous count
- If increased: New messages arrived
- Update UI and scroll to bottom
- Show typing indicator if appropriate

---

### 2. File Attachments

**Supported Types**:
- Images: `.jpg`, `.jpeg`, `.png`, `.gif`
- Videos: `.mp4`, `.mov`, `.avi`
- Documents: All other file types

**Implementation**:
- Uses `image_picker` and `file_picker` packages
- File path is sent as string to backend
- Backend handles file upload/storage
- `file_url` is returned in message response

**UI Display**:
- Images: Thumbnail preview
- Videos: Video player
- Documents: File icon with name

---

### 3. Online Status

**Implementation**:
- Server-side status tracking
- Client sends heartbeat every 30 seconds
- Status cached in UI for performance
- Green dot indicator in UI

**Status Check Flow**:
1. User IDs extracted from conversations
2. Batch request to check multiple users
3. Response cached in `_onlineStatusCache`
4. UI displays status indicators

---

### 4. Read Receipts

**Implementation**:
- `received_at` timestamp indicates message was read
- Messages marked as read when chat screen opens
- Visual indicator (checkmark) shows read status

**Marking as Read**:
```dart
// Called when chat screen opens
Future<void> _markMessagesAsRead() async {
  for (var message in _messages) {
    if (!message.isFromUser && message.receivedAt == null) {
      await _chatService.markMessageAsRead(message.messageId);
    }
  }
}
```

---

### 5. Unread Counts

**Implementation**:
- Calculated from `is_read` field in conversation list
- Badge displayed on Messages tab
- Updated on each conversation list refresh

**Calculation**:
```dart
int unreadCount = 0;
for (final chat in chats) {
  if (chat['is_read'] == false) {
    unreadCount++;
  }
}
```

---

### 6. WhatsApp Fallback

**Trigger**: After 3 minutes of no response in chat

**Display**: Banner suggesting WhatsApp contact

**Implementation**:
- Timer starts when chat opens
- Banner shows after 3 minutes
- User can tap to open WhatsApp
- Phone number extracted from agent data

---

## Technical Implementation Details

### Authentication

All endpoints require Bearer token authentication:

```dart
headers: {
  'Accept': 'application/json',
  'Authorization': 'Bearer $token',
}
```

Token is retrieved from `StorageService`:
```dart
final token = await _storageService.getToken();
```

---

### Error Handling

**Network Errors**:
- Returns empty array/list on error
- Logs errors for debugging
- User-friendly error messages

**404 Handling**:
- No conversation exists: Returns empty array (not an error)
- Message not found: Returns false

**Dio Exception Handling**:
```dart
catch (e) {
  if (e is DioException) {
    // Handle Dio-specific errors
  }
  return false; // or empty list
}
```

---

### Response Format Handling

The API can return data in multiple formats. The service handles:

1. **Nested structure**: `{data: {data: [...]}}`
2. **Single nested**: `{data: [...]}`
3. **Direct array**: `[...]`
4. **Map with nested objects**: `{data: {123: {is_online: true}}}`
5. **Direct map**: `{123: true}`

**Strategy**: Try-catch with type checking and fallback logic

---

### Polling vs WebSockets

**Current Implementation**: Polling (HTTP requests)

**Why Polling?**:
- Simpler implementation
- No WebSocket server required
- Works with standard HTTP/HTTPS
- Easier error handling

**Trade-offs**:
- Higher server load
- Slight delay (1-3 seconds)
- More battery usage

**Future Consideration**: WebSockets for real-time updates

---

### Data Models

**Chat Object** (from API):
```dart
{
  "id": int,
  "sender_id": int,
  "receiver_id": int,
  "message": String,
  "sent_at": String (ISO 8601),
  "received_at": String? (ISO 8601),
  "file_url": String?,
  "property_id": int?,
  "sender": UserObject,
  "receiver": UserObject,
  "property": PropertyObject?,
  "is_read": bool
}
```

**ChatMessage** (UI model):
```dart
class ChatMessage {
  final String text;
  final bool isFromUser;
  final DateTime timestamp;
  final String? filePath;
  final String? fileType;
  final bool? isRead;
  final String? receivedAt;
  final String? messageId;
}
```

---

### Timestamp Handling

**Format**: ISO 8601 strings (`"2026-01-08T12:00:00.000Z"`)

**Usage**:
- Sending: `DateTime.now().toIso8601String()`
- Receiving: `DateTime.tryParse(sentAt)`
- Sorting: Uses `updated_at` > `sent_at` > `created_at`

---

### File Handling

**File Selection**:
- Images: `ImagePicker` (camera or gallery)
- Other files: `FilePicker`

**Sending**:
- File path sent as string in FormData
- Backend handles actual file upload
- `file_url` returned in message response

**Display**:
- Images: Network image widget
- Videos: Video player
- Documents: File icon + download

---

### State Management

**Approach**: StatefulWidget with setState

**State Variables**:
- Messages list
- Loading states
- Online status cache
- Unread counts
- Timers for polling

**Performance**:
- Caching to reduce API calls
- Debouncing for rapid updates
- Conditional UI rebuilds

---

## Common Patterns

### Extracting User IDs

From agent data (multiple possible fields):
```dart
final user = widget.agentData['user'] as Map<String, dynamic>?;
final agentId = user?['id']?.toString() 
             ?? widget.agentData['id']?.toString() 
             ?? widget.agentData['user_id']?.toString();
```

### Determining Message Direction

```dart
final currentUser = await _authService.getCurrentUser();
final currentUserId = currentUser?.id.toString();
final isFromCurrentUser = senderId == currentUserId;
```

### Grouping Conversations

```dart
// Group by other person (sender or receiver)
final otherPersonId = chat['sender_id'] == currentUserId 
    ? chat['receiver_id'] 
    : chat['sender_id'];

// Keep latest message per conversation
if (!conversationMap.containsKey(otherPersonId) || 
    newTimestamp > existingTimestamp) {
  conversationMap[otherPersonId] = chat;
}
```

---

## Testing Considerations

### Endpoints to Test

1. **Send Message**:
   - Text only
   - With file attachment
   - Invalid user IDs
   - Missing property ID

2. **Get Conversations**:
   - Empty list
   - Single conversation
   - Multiple conversations
   - Different response formats

3. **Online Status**:
   - Single user
   - Multiple users
   - User goes offline
   - Network errors

4. **Read Receipts**:
   - Mark single message
   - Mark multiple messages
   - Invalid message ID

### Edge Cases

- No internet connection
- Slow network (timeout handling)
- Empty message text
- Very long messages
- Large file attachments
- Concurrent messages
- User logs out mid-chat

---

## Future Enhancements

Potential improvements:

1. **WebSocket Support**: Real-time bidirectional communication
2. **Push Notifications**: Notify users of new messages
3. **Message Reactions**: Emoji reactions to messages
4. **Message Editing**: Edit sent messages
5. **Message Deletion**: Delete messages
6. **Voice Messages**: Record and send audio
7. **Location Sharing**: Share location in chat
8. **Group Chats**: Multiple participants
9. **Message Search**: Search within conversations
10. **Message Forwarding**: Forward messages to other chats

---

## Troubleshooting

### Messages Not Sending

**Check**:
1. Token is valid
2. User IDs are correct (integer vs string)
3. Network connection
4. API endpoint is accessible
5. Request format matches API expectations

### Messages Not Receiving

**Check**:
1. Polling timer is running
2. Receiver ID is correct
3. Conversation endpoint returns data
4. Message count comparison logic
5. UI update after receiving messages

### Online Status Not Updating

**Check**:
1. Update status timer is running
2. Check status endpoint is called
3. Response format matches expected structure
4. Cache is updated correctly
5. UI reads from cache

---

## API Response Examples

### Get User Chats Response
```json
{
  "status": true,
  "message": "Success",
  "data": [
    {
      "id": 1,
      "sender_id": 123,
      "receiver_id": 456,
      "message": "Hi there!",
      "sent_at": "2026-01-08T12:00:00.000Z",
      "received_at": "2026-01-08T12:00:05.000Z",
      "property_id": 789,
      "is_read": true,
      "sender": {
        "id": 123,
        "name": "John Doe",
        "profile_image": "https://proapi.proplinq.com/storage/profile_images/..."
      },
      "receiver": {
        "id": 456,
        "name": "Jane Smith",
        "profile_image": "https://proapi.proplinq.com/storage/profile_images/..."
      }
    }
  ]
}
```

### Get Conversation Response
```json
{
  "status": true,
  "data": {
    "messages": [
      {
        "id": 1,
        "sender_id": 123,
        "receiver_id": 456,
        "message": "Hello!",
        "sent_at": "2026-01-08T12:00:00.000Z",
        "updated_at": "2026-01-08T12:00:00.000Z",
        "created_at": "2026-01-08T12:00:00.000Z",
        "received_at": "2026-01-08T12:00:05.000Z",
        "file_url": null,
        "property_id": 789
      },
      {
        "id": 2,
        "sender_id": 456,
        "receiver_id": 123,
        "message": "Hi there!",
        "sent_at": "2026-01-08T12:01:00.000Z",
        "updated_at": "2026-01-08T12:01:00.000Z",
        "created_at": "2026-01-08T12:01:00.000Z",
        "received_at": null,
        "file_url": "https://proapi.proplinq.com/storage/files/image.jpg",
        "property_id": 789
      }
    ]
  }
}
```

### Check Online Status Response
```json
{
  "status": true,
  "data": [
    {
      "id": 123,
      "is_online": true
    },
    {
      "id": 456,
      "is_online": false
    }
  ]
}
```

---

## Conclusion

This documentation covers the complete chat and messaging implementation. The system uses HTTP polling for real-time updates, supports file attachments, tracks online status, and provides read receipts. All endpoints are RESTful and require Bearer token authentication.

For questions or issues, refer to:
- `lib/features/home/services/chat_service.dart` - Service implementation
- `lib/features/home/views/messages_view.dart` - Conversation list UI
- `lib/features/home/views/in_app_chat_view.dart` - Chat screen UI
- `lib/core/constants/api_constants.dart` - Endpoint definitions
