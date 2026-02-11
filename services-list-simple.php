<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../config.php';

try {
    $pdo = getDBConnection();
    
    $page = intval($_GET['page'] ?? 1);
    $limit = intval($_GET['limit'] ?? 20);
    $offset = ($page - 1) * $limit;
    
    $categoryId = intval($_GET['category_id'] ?? 0);
    $search = isset($_GET['search']) ? trim($_GET['search']) : '';
    
    // Build WHERE clause
    $where = "WHERE sv.status = 'active' AND si.id IS NOT NULL";
    $params = [];
    
    if ($categoryId > 0) {
        $where .= " AND sv.category_id = :categoryId";
        $params[':categoryId'] = $categoryId;
    }
    
    if (!empty($search)) {
        $where .= " AND (sv.name LIKE :search1 OR sv.description LIKE :search2)";
        $params[':search1'] = '%' . $search . '%';
        $params[':search2'] = '%' . $search . '%';
    }
    
    // Get total count - count distinct services that have images
    $countStmt = $pdo->prepare("SELECT COUNT(DISTINCT sv.id) FROM services sv 
                                INNER JOIN service_images si ON sv.id = si.service_id 
                                $where");
    $countStmt->execute($params);
    $total = intval($countStmt->fetchColumn());
    
    // Get services with images - only services that exist in service_images table
    $query = "SELECT DISTINCT
                sv.id,
                sv.uuid,
                sv.vendor_id,
                sv.category_id,
                sv.subcategory_id,
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
                sv.created_at
              FROM services sv
              INNER JOIN service_images si ON sv.id = si.service_id
              $where
              ORDER BY sv.created_at DESC
              LIMIT :limit OFFSET :offset";
    
    $stmt = $pdo->prepare($query);
    $params[':limit'] = $limit;
    $params[':offset'] = $offset;
    $stmt->execute($params);
    $services = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get all images for the services
    $serviceIds = array_column($services, 'id');
    $images = [];
    if (!empty($serviceIds)) {
        $placeholders = implode(',', array_fill(0, count($serviceIds), '?'));
        $imgStmt = $pdo->prepare("SELECT id, service_id, image_url, sort_order, created_at 
                                  FROM service_images 
                                  WHERE service_id IN ($placeholders)
                                  ORDER BY sort_order ASC");
        $imgStmt->execute($serviceIds);
        $allImages = $imgStmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($allImages as $img) {
            if (!isset($images[$img['service_id']])) {
                $images[$img['service_id']] = [];
            }
            $images[$img['service_id']][] = $img;
        }
    }
    
    // Format services
    $formattedServices = [];
    foreach ($services as $service) {
        $serviceImages = $images[$service['id']] ?? [];
        $thumbnail = null;
        if (!empty($serviceImages)) {
            $thumbnail = $serviceImages[0]['image_url'];
        }
        
        $formattedServices[] = [
            'id' => intval($service['id']),
            'uuid' => $service['uuid'],
            'vendor_id' => intval($service['vendor_id']),
            'category_id' => intval($service['category_id']),
            'subcategory_id' => $service['subcategory_id'] ? intval($service['subcategory_id']) : null,
            'name' => $service['name'],
            'slug' => $service['slug'],
            'description' => $service['description'],
            'short_description' => $service['short_description'],
            'price_type' => $service['price_type'],
            'price' => floatval($service['min_price']),
            'min_price' => floatval($service['min_price']),
            'max_price' => floatval($service['max_price']),
            'compare_price' => floatval($service['max_price']),
            'selling_price' => floatval($service['min_price']),
            'duration' => intval($service['duration_minutes']),
            'service_area' => $service['service_area'],
            'availability' => $service['availability'],
            'rating' => floatval($service['rating']),
            'total_reviews' => intval($service['total_reviews']),
            'total_ratings' => intval($service['total_reviews']),
            'is_featured' => intval($service['is_featured']),
            'status' => $service['status'],
            'thumbnail' => $thumbnail,
            'images' => $serviceImages,
            'created_at' => $service['created_at']
        ];
    }
    
    jsonResponse([
        'success' => true,
        'services' => $formattedServices,
        'pagination' => [
            'page' => $page,
            'limit' => $limit,
            'total' => $total,
            'pages' => ceil($total / $limit)
        ]
    ]);
    
} catch (Exception $e) {
    error_log("Services List Error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => $e->getMessage()], 500);
}
?>
