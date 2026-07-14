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
    $search = $_GET['search'] ?? null;
    
    // Build WHERE clause
    $where = "WHERE sv.status = 'active' AND sv.deleted_at IS NULL";
    $params = [];
    
    if ($categoryId > 0) {
        $where .= " AND sv.category_id = ?";
        $params[] = $categoryId;
    }
    
    if ($search && !empty(trim($search))) {
        $where .= " AND (sv.name LIKE ? OR sv.description LIKE ?)";
        $searchTerm = '%' . $search . '%';
        $params[] = $searchTerm;
        $params[] = $searchTerm;
    }
    
    // Get total count
    $countStmt = $pdo->prepare("SELECT COUNT(DISTINCT sv.id) as total FROM services sv $where");
    $countStmt->execute($params);
    $total = $countStmt->fetchColumn();
    
    // Get services with subcategory information
    $query = "SELECT 
                sv.id,
                sv.uuid,
                sv.vendor_id,
                u.store_name as vendor_name,
                sv.category_id,
                c.name as category_name,
                sv.subcategory_id,
                s.name as subcategory_name,
                sv.name,
                sv.slug,
                sv.description,
                sv.short_description,
                sv.price_type,
                sv.min_price as price,
                sv.max_price as compare_price,
                sv.duration_minutes as duration,
                sv.thumbnail,
                sv.images,
                sv.status,
                sv.view_count,
                sv.is_featured,
                sv.created_at
              FROM services sv
              LEFT JOIN users u ON sv.vendor_id = u.id
              LEFT JOIN vendors v ON sv.vendor_id = v.id
              LEFT JOIN subscription_plans sp ON v.current_plan_id = sp.id AND (v.plan_expires_at IS NULL OR v.plan_expires_at > NOW())
              LEFT JOIN categories c ON sv.category_id = c.id
              LEFT JOIN subcategories s ON sv.subcategory_id = s.id
              $where
              ORDER BY sp.has_top_placement DESC, sv.is_featured DESC, sv.created_at DESC
              LIMIT ? OFFSET ?";
    
    $stmt = $pdo->prepare($query);
    
    // Bind all parameters
    $bindParams = array_merge($params, [$limit, $offset]);
    
    foreach ($bindParams as $key => $value) {
        if ($key < count($params)) {
            $stmt->bindValue($key + 1, $bindParams[$key]);
        } else {
            $stmt->bindValue($key + 1, $bindParams[$key], PDO::PARAM_INT);
        }
    }
    
    $stmt->execute($bindParams);
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
        $service['is_featured'] = (int)$service['is_featured'];
        $service['subcategory_id'] = (int)$service['subcategory_id'];
        
        $formattedServices[] = $service;
    }
    
    jsonResponse([
        'success' => true,
        'services' => $formattedServices,
        'pagination' => [
            'page' => $page,
            'limit' => $limit,
            'total' => (int)$total,
            'pages' => ceil($total / $limit)
        ]
    ]);
    
} catch (PDOException $e) {
    error_log("Services List DB Error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Database error'], 500);
} catch (Exception $e) {
    error_log("Services List Error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Error: ' . $e->getMessage()], 500);
}
?>
