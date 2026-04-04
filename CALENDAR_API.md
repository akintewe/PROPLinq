# Proplinq — Agent Calendar Management API

**Base URL:** `https://api.v2.proplinq.com/api/v1`  
**Authentication:** All agent endpoints require `Authorization: Bearer {token}` header.

---

## Overview

The calendar system is **room-based**. Every hotel or shortlet listing has one or more rooms. The agent manages availability per room, not per property. Guests see the resulting availability when choosing dates during booking.

### Date Status Types

| Status | Meaning | Who Sets It |
|--------|---------|-------------|
| `available` | Room is free to book | Default |
| `blocked` | Agent manually blocked it | Agent via calendar |
| `booked` | Guest has a confirmed booking | System automatically |

---

## Endpoints

### 1. Get Room Calendar (Agent View)

Fetches the full day-by-day status for a room over a date range. Used to render the calendar UI.

```
GET /agent/calendar/room/{room_id}?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
```

**Auth:** Required (Bearer Token — must own the property)

**Path Params:**

| Param | Type | Description |
|-------|------|-------------|
| `room_id` | integer | ID of the room |

**Query Params:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `start_date` | date | Yes | Start of range e.g. `2026-04-01` |
| `end_date` | date | Yes | End of range e.g. `2026-04-30` |

**Example Request:**

```http
GET /agent/calendar/room/12?start_date=2026-04-01&end_date=2026-04-30
Authorization: Bearer eyJ...
```

**Response (200):**

```json
{
  "status": true,
  "message": "Room calendar retrieved successfully.",
  "data": [
    {
      "date": "2026-04-01",
      "status": "available",
      "is_blocked": false,
      "metadata": []
    },
    {
      "date": "2026-04-10",
      "status": "blocked",
      "is_blocked": true,
      "uuid": "b3d2a1c0-4f2e-11ef-...",
      "metadata": {
        "reason": "Maintenance"
      }
    },
    {
      "date": "2026-04-15",
      "status": "booked",
      "is_blocked": true,
      "metadata": []
    }
  ]
}
```

> **Note:** Load one month at a time. When the agent navigates to the next/previous month, call this endpoint again with updated `start_date`/`end_date`. Store the `uuid` from blocked entries — you will need it to unblock.

---

### 2. Block Dates (Agent)

Blocks a date range for a room. No guest can book those dates while blocked.

```
POST /agent/calendar/room/{room_id}/block
```

**Auth:** Required (Bearer Token — must own the property)

**Path Params:**

| Param | Type | Description |
|-------|------|-------------|
| `room_id` | integer | ID of the room to block |

**Request Body (JSON):**

```json
{
  "start_date": "2026-04-20",
  "end_date": "2026-04-22",
  "reason": "Maintenance"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `start_date` | date | Yes | First day to block. Must be today or later |
| `end_date` | date | Yes | Last day to block. Must be ≥ `start_date` |
| `reason` | string | Yes | Accepted values: `Maintenance`, `Personal Use`, `Offline Bookings` |

**Response (201):**

```json
{
  "status": true,
  "message": "Dates blocked successfully.",
  "data": {
    "uuid": "b3d2a1c0-4f2e-11ef-...",
    "room_id": 12,
    "start_date": "2026-04-20",
    "end_date": "2026-04-22",
    "reason": "Maintenance",
    "status": "blocked"
  }
}
```

> **Note:** After a successful block, refresh the calendar for the current month by calling endpoint #1 again.

**Error — Past Date (422):**

```json
{
  "status": false,
  "message": "start_date must be today or in the future."
}
```

**Error — Date Conflict (409):**

```json
{
  "status": false,
  "message": "One or more dates in this range are already booked by a guest and cannot be blocked."
}
```

---

### 3. Unblock Dates (Agent)

Removes a block on a date range. The `uuid` comes from the calendar GET response (endpoint #1).

```
DELETE /agent/calendar/unblock/{uuid}
```

**Auth:** Required (Bearer Token — must own the property)

**Path Params:**

| Param | Type | Description |
|-------|------|-------------|
| `uuid` | string | UUID of the block entry returned from the calendar or block response |

**Example Request:**

```http
DELETE /agent/calendar/unblock/b3d2a1c0-4f2e-11ef-...
Authorization: Bearer eyJ...
```

**Response (200):**

```json
{
  "status": true,
  "message": "Dates unblocked successfully."
}
```

**Error — Not Found (404):**

```json
{
  "status": false,
  "message": "Block entry not found or does not belong to you."
}
```

> **Note:** After unblocking, refresh the calendar for the current month by calling endpoint #1 again.

---

### 4. Public Room Availability (Guest View)

Guests call this before or during booking to see which dates are unavailable. No authentication required.

```
GET /rooms/{room_id}/availability?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
```

**Auth:** None

**Query Params:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `start_date` | date | Yes | Start of range |
| `end_date` | date | Yes | End of range |

**Example Request:**

```http
GET /rooms/12/availability?start_date=2026-04-01&end_date=2026-04-30
```

**Response (200):**

```json
{
  "success": true,
  "data": [
    {
      "date": "2026-04-01",
      "status": "available",
      "is_blocked": false
    },
    {
      "date": "2026-04-10",
      "status": "blocked",
      "is_blocked": true,
      "metadata": { "reason": "Maintenance" }
    },
    {
      "date": "2026-04-15",
      "status": "booked",
      "is_blocked": true
    }
  ]
}
```

> **Note:** Grey out and disable any date where `is_blocked: true`. Only allow the guest to select dates where `status: "available"`.

---

## Endpoint Summary

| # | Method | Endpoint | Auth | Description |
|---|--------|----------|------|-------------|
| 1 | `GET` | `/agent/calendar/room/{room_id}` | Bearer Token (Agent) | Get room calendar with day-by-day status |
| 2 | `POST` | `/agent/calendar/room/{room_id}/block` | Bearer Token (Agent) | Block a date range |
| 3 | `DELETE` | `/agent/calendar/unblock/{uuid}` | Bearer Token (Agent) | Remove a block by UUID |
| 4 | `GET` | `/rooms/{room_id}/availability` | None | Public availability check for guests |

---

## Full Calendar Flow (Agent)

```
1. Agent opens calendar for a room
         ↓
2. GET /agent/calendar/room/{room_id}?start_date=...&end_date=...
         ↓
3. Render calendar:
   ├── White  = available  → tappable, agent can select to block
   ├── Orange = blocked    → tappable, agent can tap to unblock
   └── Red    = booked     → read-only, cannot be modified
         ↓
4a. Agent selects a date range to block
         ↓
5a. POST /agent/calendar/room/{room_id}/block
         ↓
6a. On success → refresh calendar (go to step 2)

   OR

4b. Agent taps a blocked (orange) date
         ↓
5b. DELETE /agent/calendar/unblock/{uuid}
         ↓
6b. On success → refresh calendar (go to step 2)
```

---

## Implementation Notes

- **Room picker:** If a property has multiple rooms, show a picker first so the agent selects which room's calendar to manage. Each room has its own independent calendar.

- **UUID storage:** The `uuid` field only appears on `blocked` entries in the GET calendar response. Save it on the client — it is what you pass to the DELETE unblock endpoint.

- **Booked dates are read-only:** Dates with `status: "booked"` are set automatically by the booking system and cannot be blocked or unblocked by the agent.

- **Date format:** Always `YYYY-MM-DD` (ISO 8601). No times or timezones needed.

- **Month-by-month loading:** Recommended to fetch one calendar month at a time (e.g. `start_date=2026-04-01`, `end_date=2026-04-30`) and refetch when the agent navigates between months.

- **Block conflict rule:** You cannot block dates that already have a confirmed guest booking. The API returns a `409` in this case — show the agent an appropriate error message.

- **Past dates:** `start_date` must be today or in the future. The API returns `422` for past dates.
