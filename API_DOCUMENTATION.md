# AskUs API Documentation

This document describes the API endpoints available for the AskUs application.

## Base Configuration

All API endpoints are located in the `api/` directory and use the shared `config.php` file for database connections and utilities.

### Database Configuration

Update the database configuration in `config.php`:

```php
define('DB_HOST', 'localhost');
define('DB_NAME', 'askus');
define('DB_USER', 'root');
define('DB_PASS', '');
```

## Services API

### 1. List Services

**Endpoint:** `GET /api/services/list.php`

**Description:** Retrieve a paginated list of services with filtering and sorting options.

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | integer | 1 | Page number for pagination |
| `limit` | integer | 20 | Number of services per page (max: 100) |
| `category_id` | integer | - | Filter by category ID |
| `subcategory_id` | integer | - | Filter by subcategory ID |
| `vendor_id` | integer | - | Filter by vendor ID |
| `search` | string | - | Search in name, description, and short_description |
| `featured` | boolean | - | Filter featured services (true/false) |
| `price_min` | float | - | Minimum price filter |
| `price_max` | float | - | Maximum price filter |
| `sort_by` | string | 'created_at' | Sort field (created_at, name, min_price, rating, total_reviews) |
| `sort_order` | string | 'desc' | Sort order (asc/desc) |

**Example Request:**
```
GET /api/services/list.php?page=1&limit=10&category_id=1&featured=true&sort_by=rating&sort_order=desc
```

**Response:**
```json
{
    "success": true,
    "message": "Services retrieved successfully",
    "data": [
        {
            "id": 1,
            "uuid": "123e4567-e89b-12d3-a456-426614174000",
            "vendor_id": 10,
            "vendor_name": "John's Services",
            "vendor_phone": "+1234567890",
            "category_id": 1,
            "category_name": "Home Cleaning",
            "subcategory_id": 1,
            "subcategory_name": "Deep Cleaning",
            "name": "Professional House Cleaning",
            "slug": "professional-house-cleaning",
            "description": "Complete house cleaning service...",
            "short_description": "Professional cleaning service",
            "price_type": "fixed",
            "price": 50.00,
            "min_price": 50.00,
            "max_price": 100.00,
            "compare_price": 100.00,
            "selling_price": 50.00,
            "duration": 120,
            "duration_minutes": 120,
            "service_area": "City Center",
            "availability": "Mon-Fri 9AM-6PM",
            "rating": 4.5,
            "total_reviews": 25,
            "total_ratings": 25,
            "is_featured": 1,
            "status": "active",
            "thumbnail": null,
            "images": [],
            "created_at": "2024-01-15 10:30:00",
            "updated_at": "2024-01-15 10:30:00"
        }
    ],
    "pagination": {
        "page": 1,
        "limit": 10,
        "total": 50,
        "pages": 5,
        "has_more": true
    },
    "filters": {
        "category_id": 1,
        "subcategory_id": 0,
        "vendor_id": 0,
        "search": "",
        "featured": true,
        "price_min": 0,
        "price_max": 0,
        "sort_by": "rating",
        "sort_order": "desc"
    }
}
```

### 2. Service Details

**Endpoint:** `GET /api/services/details.php`

**Description:** Get detailed information about a specific service including reviews and related services.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | Yes* | Service ID |
| `uuid` | string | Yes* | Service UUID |

*Either `id` or `uuid` is required.

**Example Request:**
```
GET /api/services/details.php?id=1
```

**Response:**
```json
{
    "success": true,
    "message": "Service details retrieved successfully",
    "data": {
        "id": 1,
        "uuid": "123e4567-e89b-12d3-a456-426614174000",
        "vendor": {
            "id": 10,
            "name": "John's Services",
            "phone": "+1234567890",
            "email": "john@example.com",
            "address": "123 Main St, City"
        },
        "category": {
            "id": 1,
            "name": "Home Cleaning",
            "slug": "home-cleaning"
        },
        "subcategory": {
            "id": 1,
            "name": "Deep Cleaning",
            "slug": "deep-cleaning"
        },
        "name": "Professional House Cleaning",
        "slug": "professional-house-cleaning",
        "description": "Complete house cleaning service...",
        "short_description": "Professional cleaning service",
        "pricing": {
            "type": "fixed",
            "min_price": 50.00,
            "max_price": 100.00,
            "price": 50.00,
            "compare_price": 100.00,
            "selling_price": 50.00
        },
        "duration_minutes": 120,
        "service_area": "City Center",
        "availability": "Mon-Fri 9AM-6PM",
        "rating": 4.5,
        "total_reviews": 25,
        "is_featured": 1,
        "status": "active",
        "reviews": [
            {
                "id": 1,
                "user_id": 5,
                "user_name": "Alice Johnson",
                "rating": 5.0,
                "comment": "Excellent service!",
                "created_at": "2024-01-10 14:30:00"
            }
        ],
        "related_services": [
            {
                "id": 2,
                "uuid": "456e7890-e89b-12d3-a456-426614174001",
                "name": "Office Cleaning",
                "min_price": 30.00,
                "rating": 4.2,
                "total_reviews": 15
            }
        ],
        "thumbnail": null,
        "images": [],
        "created_at": "2024-01-15 10:30:00",
        "updated_at": "2024-01-15 10:30:00"
    }
}
```

## Categories API

### List Categories

**Endpoint:** `GET /api/categories/list.php`

**Description:** Retrieve all categories with optional subcategories and service counts.

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `include_services` | boolean | false | Include service counts for each category |
| `include_subcategories` | boolean | true | Include subcategories for each category |
| `active_only` | boolean | true | Only return active categories |

**Example Request:**
```
GET /api/categories/list.php?include_services=true&include_subcategories=true
```

**Response:**
```json
{
    "success": true,
    "message": "Categories retrieved successfully",
    "data": [
        {
            "id": 1,
            "name": "Home Cleaning",
            "slug": "home-cleaning",
            "description": "Professional home cleaning services",
            "icon": "http://localhost/uploads/icons/cleaning.png",
            "image": "http://localhost/uploads/categories/cleaning.jpg",
            "sort_order": 1,
            "status": "active",
            "subcategories": [
                {
                    "id": 1,
                    "name": "Deep Cleaning",
                    "slug": "deep-cleaning",
                    "description": "Thorough deep cleaning",
                    "sort_order": 1,
                    "status": "active"
                }
            ],
            "subcategories_count": 3,
            "services_count": 15,
            "created_at": "2024-01-01 00:00:00",
            "updated_at": "2024-01-01 00:00:00"
        }
    ],
    "total": 5
}
```

## Error Handling

All API endpoints return consistent error responses:

```json
{
    "success": false,
    "message": "Error description",
    "error": "Detailed error information"
}
```

**Common HTTP Status Codes:**
- `200` - Success
- `400` - Bad Request (missing parameters, validation errors)
- `404` - Not Found (resource doesn't exist)
- `500` - Internal Server Error (database errors, system errors)

## CORS Support

All endpoints support CORS and include appropriate headers for cross-origin requests.

## Database Tables Required

The API expects the following database tables with the structure shown in your database screenshot:

### services
- `id` (bigint, primary key, auto_increment)
- `uuid` (varchar(36))
- `vendor_id` (bigint)
- `category_id` (bigint)
- `subcategory_id` (bigint, nullable)
- `name` (varchar(200))
- `slug` (varchar(220))
- `description` (text, nullable)
- `short_description` (varchar(500), nullable)
- `price_type` (enum: 'fixed', 'hourly', 'quote')
- `min_price` (decimal(10,2))
- `max_price` (decimal(10,2), nullable)
- `duration_minutes` (int, nullable)
- `service_area` (varchar(255), nullable)
- `availability` (varchar(255), nullable)
- `is_featured` (tinyint(1))
- `rating` (decimal(3,2))
- `total_reviews` (int)
- `status` (enum: 'active', 'inactive', 'pending')
- `is_approved` (tinyint(1))
- `approved_at` (timestamp, nullable)
- `approved_by` (bigint, nullable)
- `deleted_at` (timestamp, nullable)
- `created_at` (timestamp, default: CURRENT_TIMESTAMP)
- `updated_at` (timestamp, default: CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)

### Additional Tables
- `users` (for vendor information)
- `categories` (for service categories)
- `subcategories` (for service subcategories)
- `reviews` (for service reviews)

## Usage Examples

### Flutter/Dart Integration

```dart
// Example service for fetching services
class ServicesAPI {
  static const String baseUrl = 'http://your-domain.com/api';
  
  static Future<Map<String, dynamic>> getServices({
    int page = 1,
    int limit = 20,
    int? categoryId,
    String? search,
    bool? featured,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (categoryId != null) params['category_id'] = categoryId.toString();
    if (search != null) params['search'] = search;
    if (featured != null) params['featured'] = featured.toString();
    
    final uri = Uri.parse('$baseUrl/services/list.php').replace(queryParameters: params);
    final response = await http.get(uri);
    
    return json.decode(response.body);
  }
  
  static Future<Map<String, dynamic>> getServiceDetails(int serviceId) async {
    final uri = Uri.parse('$baseUrl/services/details.php').replace(
      queryParameters: {'id': serviceId.toString()}
    );
    final response = await http.get(uri);
    
    return json.decode(response.body);
  }
}
```

## Testing

You can test the API endpoints using tools like:
- Postman
- cURL
- Browser (for GET requests)
- Your Flutter application

Example cURL commands:
```bash
# List services
curl "http://localhost/api/services/list.php?page=1&limit=5"

# Get service details
curl "http://localhost/api/services/details.php?id=1"

# List categories
curl "http://localhost/api/categories/list.php?include_services=true"
```