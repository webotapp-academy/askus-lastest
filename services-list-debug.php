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
    $search = isset($_GET['search']) ? trim($_GET['search']) : null;
    
    // Build WHERE clause
    $where = "WHERE sv.status = 'active'";
    $params = [];
    
    if ($categoryId > 0) {
        $where .= " AND sv.category_id = :categoryId";
        $params[':categoryId'] = $categoryId;
    }
    
    if (!empty($search)) {
        $where .= " AND (sv.name LIKE :search OR sv.description LIKE :search2)";
        $searchTerm = '%' . $search . '%';
        $params[':search'] = $searchTerm;
        $params[':search2'] = $searchTerm;
    }
    
    // Get total count
    $countQuery = "SELECT COUNT(DISTINCT sv.id) as total FROM services sv $where";
    $countStmt = $pdo->prepare($countQuery);
    if (!$countStmt->execute($params)) {
        throw new Exception("Count query failed: " . implode(", ", $countStmt->errorInfo()));
    }
    $total = intval($countStmt->fetchColumn());
    
    // Get services with subcategory information
    $query = "SELECT 
                sv.id,
                sv.uuid,
                sv.vendor_id,
                COALESCE(u.store_name, 'Unknown') as vendor_name,
                sv.category_id,
                COALESCE(c.name, '') as category_name,
                COALESCE(sv.subcategory_id, 0) as subcategory_id,
                COALESCE(s.name, NULL) as subcategory_name,
                sv.name,
                sv.slug,
                sv.description,
                sv.short_description,
                sv.price_type,
                COALESCE(sv.min_price, 0) as price,
                COALESCE(sv.max_price, 0) as compare_price,
                COALESCE(sv.duration_minutes, 0) as duration,
                sv.thumbnail,
                sv.images,
                sv.status,
                COALESCE(sv.view_count, 0) as view_count,
                COALESCE(sv.is_featured, 0) as is_featured,
                sv.created_at
              FROM services sv
              LEFT JOIN users u ON sv.vendor_id = u.id
              LEFT JOIN categories c ON sv.category_id = c.id
              LEFT JOIN subcategories s ON sv.subcategory_id = s.id
              $where
              ORDER BY sv.created_at DESC
              LIMIT :limit OFFSET :offset";
    
    $stmt = $pdo->prepare($query);
    
    // Bind all parameters
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    
    if (!$stmt->execute()) {
        throw new Exception("Query failed: " . implode(", ", $stmt->errorInfo()));
    }
    
    $services = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $formattedServices = [];
    foreach ($services as $service) {
        // Parse images
        $images = [];
        if (!empty($service['images'])) {
            $decoded = json_decode($service['images'], true);
            if (is_array($decoded)) {
                $images = array_map(function($img) {
                    return strpos($img, 'http') === 0 ? $img : BASE_URL . '/' . $img;
                }, $decoded);
            }
        }
        $service['images'] = $images;
        
        // Set thumbnail
        if (empty($service['thumbnail'])) {
            $service['thumbnail'] = !empty($images) ? $images[0] : null;
        } elseif (strpos($service['thumbnail'], 'http') !== 0) {
            $service['thumbnail'] = BASE_URL . '/' . $service['thumbnail'];
        }
        
        // Format price fields
        $service['selling_price'] = $service['compare_price'];
        $service['is_featured'] = intval($service['is_featured']);
        $service['subcategory_id'] = intval($service['subcategory_id']);
        
        $formattedServices[] = $service;
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
