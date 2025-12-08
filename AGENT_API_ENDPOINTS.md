# Agent API Endpoints Documentation

This document contains all agent-related API endpoints implemented in the Proplinq Flutter mobile app. Use this as a reference for building the web version.

## Base Configuration

- **Base URL**: `https://proapi.proplinq.com`
- **API Version**: `/api/v1`
- **Full Base URL**: `https://proapi.proplinq.com/api/v1`

## Authentication

All agent endpoints require authentication via Bearer token in the Authorization header:
```
Authorization: Bearer {token}
```

## Headers

All requests should include:
```
Accept: application/json
Content-Type: application/json
```
(Note: For multipart/form-data requests, remove the `Content-Type` header and let the browser set it automatically)

---

## 1. Agent KYC Status

**Endpoint**: `GET /api/v1/kyc/agent/status`

**Method**: `GET`

**Authentication**: Required

**Query Parameters**: None

**Request Body**: None

**Response Example**:
```json
{
  "success": true,
  "status_code": 200,
  "message": "KYC status retrieved successfully",
  "data": {
    "status": "pending|verified|rejected",
    "is_required": true,
    "message": "Status message"
  }
}
```

**Notes**:
- Returns `404` if KYC hasn't been submitted yet
- `status` can be: `pending`, `verified`, or `rejected`
- If `data` is `null`, it means KYC is not started or incomplete

---

## 2. Submit Agent KYC

**Endpoint**: `POST /api/v1/kyc/agent`

**Method**: `POST`

**Authentication**: Required

**Content-Type**: `multipart/form-data`

**Request Fields** (Form Data):

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| `bvn` | string | Yes | Bank Verification Number |
| `nin` | string | Yes | National Identification Number |
| `business_name` | string | Yes | Business/Company name |
| `tin` | string | Yes | Tax Identification Number |
| `employment_status` | string | Yes | Employment status |
| `occupation` | string | Yes | Occupation |
| `company_name` | string | Yes | Company name |

**Request Files** (Multipart Files):

| Field Name | File Type | Required | Description |
|------------|-----------|----------|-------------|
| `utility_bill` | File | Yes | Utility bill document (image/PDF) |
| `bank_statement` | File | Yes | Bank statement document (image/PDF) |
| `cac_doc` | File | Yes | CAC document (image/PDF) |

**Response Example**:
```json
{
  "success": true,
  "status_code": 200,
  "message": "KYC submitted successfully",
  "data": null
}
```

**Error Response Example**:
```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "errors": {
    "bvn": ["The bvn field is required."],
    "utility_bill": ["The utility bill field is required."]
  }
}
```

---

## 3. Get Agent's Properties

**Endpoint**: `GET /api/v1/agent/properties`

**Method**: `GET`

**Authentication**: Required

**Query Parameters**: None (all agent's properties are returned)

**Request Body**: None

**Response Example**:
```json
{
  "success": true,
  "status_code": 200,
  "message": "Properties retrieved successfully",
  "data": {
    "data": [
      {
        "id": 1,
        "user_id": 123,
        "type": "apartment|hotel|shortlet|building",
        "title": "Property Title",
        "description": "Property Description",
        "price": "350000.00",
        "category": "for_rent|for_sale|hotel|shortlet",
        "location": "Full Address",
        "images": [
          {
            "id": 1,
            "url": "https://example.com/image.jpg",
            "path": "/storage/images/..."
          }
        ],
        "360": [
          {
            "id": 2,
            "url": "https://example.com/360.jpg",
            "path": "/storage/360/..."
          }
        ],
        "video": {
          "id": 3,
          "url": "https://example.com/video.mp4",
          "path": "/storage/videos/..."
        },
        "bedrooms": 3,
        "bathrooms": 2,
        "gated": 1,
        "parking": 1,
        "features": ["Feature 1", "Feature 2"],
        "user": {
          "id": 123,
          "full_name": "Agent Name",
          "email": "agent@example.com",
          "phone_number": "+234...",
          "location": "Lagos, Nigeria",
          "agency_name": "Agency Name",
          "agent_type": "real_estate_agent",
          "whatsapp_number": "+234...",
          "profile_image_full_url": "https://example.com/profile.jpg"
        }
      }
    ],
    "current_page": 1,
    "last_page": 1,
    "per_page": 15,
    "total": 1
  }
}
```

**Notes**:
- Returns paginated list of properties
- Properties are filtered automatically to only show the authenticated agent's properties
- `gated` and `parking` are returned as integers: `1` = Yes, `0` = No

---

## 4. Create Property

**Endpoint**: `POST /api/v1/properties`

**Method**: `POST`

**Authentication**: Required

**Content-Type**: `multipart/form-data`

**Request Fields** (Form Data):

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| `type` | string | Yes | Property type: `apartment`, `hotel`, `shortlet`, `building` (lowercase) |
| `title` | string | Yes | Property title |
| `description` | string | Yes | Property description |
| `price` | string | Yes | Price (numeric only, currency symbols removed) |
| `category` | string | Yes | `for_rent`, `for_sale`, `hotel`, `shortlet` |
| `location` | string | Yes | Full address/location |
| `bedrooms` | string | Yes | Number of bedrooms |
| `bathrooms` | string | Yes | Number of bathrooms |
| `gated` | string | Yes | `1` for Yes, `0` for No |
| `parking` | string | Yes | `1` for Yes, `0` for No |
| `features[0]` | string | No | Feature name (array indexed from 0) |
| `features[1]` | string | No | Feature name |
| `features[n]` | string | No | Additional features... |

**Request Files** (Multipart Files):

| Field Name | File Type | Required | Description |
|------------|-----------|----------|-------------|
| `images[0]` | File | Yes | Primary property image |
| `images[1]` | File | No | Additional property image |
| `images[n]` | File | No | More images... |
| `360[0]` | File | No | 360-degree image |
| `360[1]` | File | No | Additional 360 image |
| `360[n]` | File | No | More 360 images... |
| `video` | File | No | Property video |

**Example Request (cURL)**:
```bash
curl -X POST https://proapi.proplinq.com/api/v1/properties \
  -H "Authorization: Bearer {token}" \
  -F "type=apartment" \
  -F "title=Luxury Apartment" \
  -F "description=Beautiful apartment in prime location" \
  -F "price=350000" \
  -F "category=for_rent" \
  -F "location=Lagos, Nigeria" \
  -F "bedrooms=3" \
  -F "bathrooms=2" \
  -F "gated=1" \
  -F "parking=1" \
  -F "features[0]=Swimming Pool" \
  -F "features[1]=Gym" \
  -F "images[0]=@/path/to/image1.jpg" \
  -F "images[1]=@/path/to/image2.jpg" \
  -F "360[0]=@/path/to/360image.jpg" \
  -F "video=@/path/to/video.mp4"
```

**Response Example**:
```json
{
  "success": true,
  "status_code": 201,
  "message": "Property created successfully",
  "data": {
    "id": 123,
    "title": "Luxury Apartment",
    "location": "Lagos, Nigeria",
    ...
  }
}
```

**Notes**:
- At least one image is required (`images[0]`)
- Images are automatically resized to standard dimensions (800x600, 1200x800, etc.)
- Price should be numeric string only (no currency symbols or commas)
- Category mapping: UI shows "For Rent" → API expects "for_rent"

---

## 5. Update Property

**Endpoint**: `PUT /api/v1/properties/{id}`

**Method**: `PUT`

**Authentication**: Required

**Content-Type**: `application/json`

**URL Parameters**:
- `id` (integer): Property ID

**Request Body** (JSON):

```json
{
  "title": "Updated Property Title",
  "description": "Updated description",
  "price": 350000.0,
  "location": "Updated Location",
  "bedrooms": 3,
  "bathrooms": 2,
  "gated": true,
  "parking": true,
  "features": ["Feature 1", "Feature 2", "Feature 3"],
  "status": "available|rented|sold"
}
```

**Request Fields**:

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| `title` | string | Yes | Property title |
| `description` | string | Yes | Property description |
| `price` | number | Yes | Price (float) |
| `location` | string | Yes | Full address/location |
| `bedrooms` | integer | Yes | Number of bedrooms |
| `bathrooms` | integer | Yes | Number of bathrooms |
| `gated` | boolean | Yes | `true` or `false` |
| `parking` | boolean | Yes | `true` or `false` |
| `features` | array | Yes | Array of feature strings |
| `status` | string | Yes | `available`, `rented`, or `sold` |

**Response Example**:
```json
{
  "success": true,
  "status_code": 200,
  "message": "Property updated successfully",
  "data": {
    "id": 123,
    "title": "Updated Property Title",
    ...
  }
}
```

**Success Status Codes**: `200` or `204`

**Notes**:
- This endpoint only updates property details, not images/videos
- To update images, you may need to delete and recreate the property, or check if there's a separate endpoint for updating media

---

## 6. Delete Property

**Endpoint**: `DELETE /api/v1/properties/{id}`

**Method**: `DELETE`

**Authentication**: Required

**URL Parameters**:
- `id` (integer): Property ID

**Request Body**: None

**Response Example**:
```json
{
  "success": true,
  "status_code": 200,
  "message": "Property deleted successfully",
  "data": null
}
```

**Error Response Example**:
```json
{
  "success": false,
  "status_code": 404,
  "message": "Property not found"
}
```

**Notes**:
- Only the property owner (agent) can delete their property
- Returns `404` if property doesn't exist or user doesn't have permission

---

## 7. Get Property Details

**Endpoint**: `GET /api/v1/properties/{id}`

**Method**: `GET`

**Authentication**: Required

**URL Parameters**:
- `id` (integer): Property ID

**Query Parameters**: None

**Request Body**: None

**Response Example**:
```json
{
  "success": true,
  "status_code": 200,
  "message": "Property retrieved successfully",
  "data": {
    "id": 123,
    "user_id": 456,
    "type": "apartment",
    "title": "Luxury 3-Bedroom Apartment",
    "description": "Beautiful apartment...",
    "price": "350000.00",
    "category": "for_rent",
    "location": "Lagos, Nigeria",
    "images": [...],
    "360": [...],
    "video": {...},
    "bedrooms": 3,
    "bathrooms": 2,
    "gated": 1,
    "parking": 1,
    "features": ["Swimming Pool", "Gym"],
    "user": {
      "id": 456,
      "full_name": "Agent Name",
      "email": "agent@example.com",
      "phone_number": "+234...",
      "whatsapp_number": "+234...",
      "profile_image_full_url": "https://..."
    }
  }
}
```

**Alternative Response Format** (if wrapped in nested `data`):
```json
{
  "success": true,
  "status_code": 200,
  "message": "Property retrieved successfully",
  "data": {
    "data": {
      "id": 123,
      ...
    }
  }
}
```

**Notes**:
- Response structure may vary - check for nested `data` key
- Property details include full agent/user information
- Images are returned as array of objects with `id`, `url`, and `path`

---

## 8. List All Properties (Search/Filter)

**Endpoint**: `GET /api/v1/get-properties-list`

**Method**: `GET`

**Authentication**: Required

**Query Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `type` | string | No | Filter by type: `apartment`, `hotel`, `shortlet`, `building` |
| `location` | string | No | Filter by location |
| `price_min` | string | No | Minimum price |
| `price_max` | string | No | Maximum price |
| `category` | string | No | Filter by category: `for_rent`, `for_sale`, `hotel`, `shortlet` |
| `page` | integer | No | Page number for pagination (default: 1) |

**Request Body**: None

**Response Example**:
```json
{
  "success": true,
  "status_code": 200,
  "message": "Properties retrieved successfully",
  "data": {
    "data": [
      {
        "id": 1,
        "title": "Property 1",
        ...
      },
      {
        "id": 2,
        "title": "Property 2",
        ...
      }
    ],
    "current_page": 1,
    "last_page": 5,
    "per_page": 15,
    "total": 75
  }
}
```

**Notes**:
- Returns paginated results
- Default pagination: 15 items per page
- Use `page` parameter to fetch additional pages
- This endpoint returns ALL properties (not just agent's properties)
- For agent's own properties, use `/agent/properties` instead

---

## Common Error Responses

### 401 Unauthorized
```json
{
  "success": false,
  "status_code": 401,
  "message": "Unauthenticated"
}
```

### 403 Forbidden
```json
{
  "success": false,
  "status_code": 403,
  "message": "Forbidden"
}
```

### 404 Not Found
```json
{
  "success": false,
  "status_code": 404,
  "message": "Resource not found"
}
```

### 422 Validation Error
```json
{
  "success": false,
  "status_code": 422,
  "message": "Validation failed",
  "errors": {
    "field_name": ["Error message 1", "Error message 2"]
  }
}
```

### 500 Server Error
```json
{
  "success": false,
  "status_code": 500,
  "message": "Internal server error"
}
```

---

## Implementation Notes for Web Developers

### File Upload Handling

When uploading files via `multipart/form-data`:

1. **JavaScript/TypeScript (FormData)**:
```javascript
const formData = new FormData();
formData.append('bvn', bvnValue);
formData.append('utility_bill', fileInput.files[0]);

fetch('https://proapi.proplinq.com/api/v1/kyc/agent', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`
    // DO NOT set Content-Type - browser will set it automatically with boundary
  },
  body: formData
});
```

2. **Array Fields** (for features/images):
```javascript
features.forEach((feature, index) => {
  formData.append(`features[${index}]`, feature);
});

images.forEach((image, index) => {
  formData.append(`images[${index}]`, image);
});
```

3. **File Validation**:
   - Images: Recommended max size 5MB
   - Supported formats: JPG, PNG, PDF
   - Images are automatically resized on the backend, but it's good practice to validate on frontend too

### Authentication Token

- Token is stored after login/registration
- Include token in `Authorization` header for all authenticated requests
- Token expires after a certain period (check with backend team)
- Handle token refresh if implemented

### Error Handling

- Always check `success` field in response
- Display `message` to user
- For 422 errors, display `errors` object fields
- Handle network errors gracefully

### Property Status Values

- `available`: Property is available for rent/sale
- `rented`: Property has been rented (agent-only status)
- `sold`: Property has been sold (for sale properties)

---

## Additional Endpoints (May be needed for web)

These endpoints are used in the app but may not be agent-specific:

- `GET /api/v1/user` - Get current user profile
- `PUT /api/v1/profile/update` - Update user profile
- `POST /api/v1/user/profile-image` - Upload profile image
- `GET /api/v1/get-user-chats` - Get chat conversations
- `POST /api/v1/chat/webhook` - Send chat message

Check the main API documentation for these endpoints.

---

## Testing

### Test with cURL

**Create Property Example**:
```bash
curl -X POST https://proapi.proplinq.com/api/v1/properties \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -F "type=apartment" \
  -F "title=Test Property" \
  -F "description=Test Description" \
  -F "price=100000" \
  -F "category=for_rent" \
  -F "location=Test Location" \
  -F "bedrooms=2" \
  -F "bathrooms=1" \
  -F "gated=1" \
  -F "parking=1" \
  -F "features[0]=Test Feature" \
  -F "images[0]=@/path/to/image.jpg"
```

**Update Property Example**:
```bash
curl -X PUT https://proapi.proplinq.com/api/v1/properties/123 \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Updated Title",
    "description": "Updated Description",
    "price": 200000.0,
    "location": "Updated Location",
    "bedrooms": 3,
    "bathrooms": 2,
    "gated": true,
    "parking": true,
    "features": ["Feature 1", "Feature 2"],
    "status": "available"
  }'
```

---

**Last Updated**: Based on Flutter app implementation as of current date
**Version**: 1.0

