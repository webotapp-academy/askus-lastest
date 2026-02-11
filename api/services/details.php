<?php
require_once __DIR__ . '/../../config.php';

try {
    $pdo = getDBConnection();
    
    // Get service ID from URL parameters
    $serviceId = intval($_GET['id'] ?? 0);
    $serviceUuid = $_GET['uuid'] ?? '';
    
    if (empty($serviceId) && empty($serviceUuid)) {
        jsonResponse([
            'success' => false,
            'message' => 'Service ID or UUID is required'
        ], 400);
    }
    
    // Build query based on provided parameter
    if (!empty($serviceUuid)) {
        $whereClause = "sv.uuid = :identifier";
        $identifier = $serviceUuid;
    } else {
        $whereClause = "sv.id = :identifier";
        $identifier = $serviceId;
    }
    
    // Get service details with all related information
    $query = "SELECT 
                sv.id,
                sv.uuid,
                sv.vendor_id,
                u.store_name as vendor_name,
                u.phone as vendor_phone,
                u.email as vendor_email,
                u.address as vendor_address,
                sv.category_id,
                c.name as category_name,
                c.slug as category_slug,
                sv.subcategory_id,
                s.name as subcategory_name,
                s.slug as subcategory_slug,
                sv.name,
                sv.slug,
                sv.description,
                sv.short_description,
                sv.price_type,
                sv.min_price,
                sv.max_price,
                sv.duration_minutes,
                sv.service_area,
                sv.availability,
                sv.rating,
                sv.total_reviews,
                sv.is_featured,
                sv.status,
                sv.created_at,
                sv.updated_at
              FROM services sv
              LEFT JOIN users u ON sv.vendor_id = u.id
              LEFT JOIN categories c ON sv.category_id = c.id
              LEFT JOIN subcategories s ON sv.subcategory_id = s.id
              WHERE $whereClause 
                AND sv.status = 'active' 
                AND sv.deleted_at IS NULL";
    
    $stmt = $pdo->prepare($query);
    $stmt->bindValue(':identifier', $identifier);
    $stmt->execute();
    $service = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$service) {
        jsonResponse([
            'success' => false,
            'message' => 'Service not found'
        ], 404);
    }
    
    // Get service reviews (last 10)
    $reviewsQuery = "SELECT 
                        r.id,
                        r.user_id,
                        ur.name as user_name,
                        r.rating,
                        r.comment,
                        r.created_at
                     FROM reviews r
                     LEFT JOIN users ur ON r.user_id = ur.id
                     WHERE r.item_type = 'service' 
                       AND r.item_id = :serviceId
                       AND r.status = 'approved'
                     ORDER BY r.created_at DESC
                     LIMIT 10";
    
    $reviewsStmt = $pdo->prepare($reviewsQuery);
    $reviewsStmt->bindValue(':serviceId', $service['id'], PDO::PARAM_INT);
    $reviewsStmt->execute();
    $reviews = $reviewsStmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Format reviews
    $formattedReviews = [];
    foreach ($reviews as $review) {
        $formattedReviews[] = [
            'id' => intval($review['id']),
            'user_id' => intval($review['user_id']),
            'user_name' => $review['user_name'] ?? 'Anonymous',
            'rating' => floatval($review['rating']),
            'comment' => $review['comment'],
            'created_at' => $review['created_at']
        ];
    }
    
    // Get related services (same category)
    $relatedQuery = "SELECT 
                        sv.id,
                        sv.uuid,
                        sv.name,
                        sv.min_price,
                        sv.rating,
                        sv.total_reviews
                     FROM services sv
                     WHERE sv.category_id = :categoryId 
                       AND sv.id != :serviceId
                       AND sv.status = 'active'
                       AND sv.deleted_at IS NULL
                     ORDER BY sv.rating DESC, sv.total_reviews DESC
                     LIMIT 5";
    
    $relatedStmt = $pdo->prepare($relatedQuery);
    $relatedStmt->bindValue(':categoryId', $service['category_id'], PDO::PARAM_INT);
    $relatedStmt->bindValue(':serviceId', $service['id'], PDO::PARAM_INT);
    $relatedStmt->execute();
    $relatedServices = $relatedStmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Format related services
    $formattedRelated = [];
    foreach ($relatedServices as $related) {
        $formattedRelated[] = [
            'id' => intval($related['id']),
            'uuid' => $related['uuid'],
            'name' => $related['name'],
            'min_price' => floatval($related['min_price']),
            'rating' => floatval($related['rating']),
            'total_reviews' => intval($related['total_reviews'])
        ];
    }
    
    // Format main service data
    $formattedService = [
        'id' => intval($service['id']),
        'uuid' => $service['uuid'],
        'vendor' => [
            'id' => intval($service['vendor_id']),
            'name' => $service['vendor_name'],
            'phone' => $service['vendor_phone'],
            'email' => $service['vendor_email'],
            'address' => $service['vendor_address']
        ],
        'category' => [
            'id' => intval($service['category_id']),
            'name' => $service['category_name'],
            'slug' => $service['category_slug']
        ],
        'subcategory' => $service['subcategory_id'] ? [
            'id' => intval($service['subcategory_id']),
            'name' => $service['subcategory_name'],
            'slug' => $service['subcategory_slug']
        ] : null,
        'name' => $service['name'],
        'slug' => $service['slug'],
        'description' => $service['description'],
        'short_description' => $service['short_description'],
        'pricing' => [
            'type' => $service['price_type'],
            'min_price' => floatval($service['min_price']),
            'max_price' => floatval($service['max_price']),
            'price' => floatval($service['min_price']),
            'compare_price' => floatval($service['max_price']),
            'selling_price' => floatval($service['min_price'])
        ],
        'duration_minutes' => intval($service['duration_minutes']),
        'service_area' => $service['service_area'],
        'availability' => $service['availability'],
        'rating' => floatval($service['rating']),
        'total_reviews' => intval($service['total_reviews']),
        'is_featured' => intval($service['is_featured']),
        'status' => $service['status'],
        'reviews' => $formattedReviews,
        'related_services' => $formattedRelated,
        'thumbnail' => null, // TODO: Add thumbnail logic if needed
        'images' => [], // TODO: Add images logic if needed
        'created_at' => $service['created_at'],
        'updated_at' => $service['updated_at']
    ];
    
    jsonResponse([
        'success' => true,
        'message' => 'Service details retrieved successfully',
        'data' => $formattedService,
        'service' => $formattedService // Backward compatibility
    ]);
    
} catch (PDOException $e) {
    logError("Service Details DB Error: " . $e->getMessage(), ['service_id' => $serviceId ?? null, 'uuid' => $serviceUuid ?? null]);
    jsonResponse([
        'success' => false,
        'message' => 'Database error occurred',
        'error' => 'Failed to fetch service details'
    ], 500);
} catch (Exception $e) {
    logError("Service Details Error: " . $e->getMessage(), ['service_id' => $serviceId ?? null, 'uuid' => $serviceUuid ?? null]);
    jsonResponse([
        'success' => false,
        'message' => 'An error occurred while fetching service details',
        'error' => $e->getMessage()
    ], 500);
}
?>