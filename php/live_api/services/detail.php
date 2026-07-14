<?php
require_once __DIR__ . '/../config.php';

$id = intval($_GET['id'] ?? 0);

if (!$id) {
    jsonResponse(['success' => false, 'message' => 'Service ID required'], 400);
}

try {
    $pdo = getDBConnection();
    
    $stmt = $pdo->prepare("
        SELECT s.*, 
               v.store_name as vendor_name, 
               v.rating as vendor_rating, 
               v.city as vendor_city,
               v.phone as vendor_phone,
               c.name as category_name
        FROM services s
        JOIN vendors v ON s.vendor_id = v.id
        LEFT JOIN categories c ON s.category_id = c.id
        WHERE s.id = ? AND s.deleted_at IS NULL
    ");
    $stmt->execute([$id]);
    $service = $stmt->fetch();
    
    if (!$service) {
        jsonResponse(['success' => false, 'message' => 'Service not found'], 404);
    }
    
    // Map database fields to Flutter expected fields
    $service['price'] = $service['min_price'] ?? 0;
    $service['compare_price'] = $service['max_price'] ?? null;
    $service['duration'] = isset($service['duration_minutes']) ? $service['duration_minutes'] . ' mins' : null;
    $service['total_ratings'] = $service['total_reviews'] ?? 0;
    
    // Get images
    try {
        $imgStmt = $pdo->prepare("SELECT image_url FROM service_images WHERE service_id = ? ORDER BY sort_order");
        $imgStmt->execute([$id]);
        $service['images'] = array_column($imgStmt->fetchAll(), 'image_url');
    } catch (Exception $e) {
        $service['images'] = [];
    }
    
    $service['thumbnail'] = $service['images'][0] ?? null;
    
    // Vendor info object for Flutter
    $service['vendor'] = [
        'id' => $service['vendor_id'],
        'name' => $service['vendor_name'],
        'rating' => $service['vendor_rating'],
        'city' => $service['vendor_city'],
        'phone' => $service['vendor_phone'] ?? null
    ];
    
    jsonResponse([
        'success' => true,
        'service' => $service
    ]);
    
} catch (Exception $e) {
    error_log("Service detail error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Error loading service'], 500);
}
