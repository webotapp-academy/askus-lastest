<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'config.php';

try {
    $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
    $limit = 20;
    $offset = ($page - 1) * $limit;
    
    $categoryId = isset($_GET['category_id']) ? intval($_GET['category_id']) : null;
    $search = isset($_GET['search']) ? $conn->real_escape_string($_GET['search']) : null;
    
    // Build the WHERE clause
    $where = "WHERE sv.status = 'active'";
    
    if ($categoryId) {
        $where .= " AND sv.category_id = $categoryId";
    }
    
    if ($search) {
        $where .= " AND (sv.name LIKE '%$search%' OR sv.description LIKE '%$search%')";
    }
    
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
                COALESCE(ROUND(AVG(r.rating), 1), 0) as rating,
                COUNT(DISTINCT r.id) as total_reviews,
                sv.view_count,
                sv.is_featured,
                sv.created_at
              FROM services sv
              LEFT JOIN users u ON sv.vendor_id = u.id
              LEFT JOIN categories c ON sv.category_id = c.id
              LEFT JOIN subcategories s ON sv.subcategory_id = s.id
              LEFT JOIN reviews r ON sv.id = r.item_id AND r.type = 'service' AND r.status = 'approved'
              $where
              GROUP BY sv.id
              ORDER BY sv.created_at DESC
              LIMIT $limit OFFSET $offset";
    
    $result = $conn->query($query);
    
    if (!$result) {
        throw new Exception("Query failed: " . $conn->error);
    }
    
    $services = [];
    while ($row = $result->fetch_assoc()) {
        // Parse images
        if (!empty($row['images'])) {
            $row['images'] = json_decode($row['images'], true) ?? [];
            // Convert relative paths to absolute URLs
            $row['images'] = array_map(function($img) {
                return strpos($img, 'http') === 0 ? $img : BASE_URL . '/' . $img;
            }, $row['images']);
        } else {
            $row['images'] = [];
        }
        
        // Set thumbnail
        if (empty($row['thumbnail']) && !empty($row['images'])) {
            $row['thumbnail'] = $row['images'][0];
        } elseif (!empty($row['thumbnail']) && strpos($row['thumbnail'], 'http') !== 0) {
            $row['thumbnail'] = BASE_URL . '/' . $row['thumbnail'];
        }
        
        $row['rating'] = floatval($row['rating']);
        $row['total_ratings'] = intval($row['total_reviews']);
        $row['is_featured'] = intval($row['is_featured']);
        
        $services[] = $row;
    }
    
    // Get total count
    $countQuery = "SELECT COUNT(DISTINCT sv.id) as total
                   FROM services sv
                   LEFT JOIN users u ON sv.vendor_id = u.id
                   LEFT JOIN categories c ON sv.category_id = c.id
                   LEFT JOIN subcategories s ON sv.subcategory_id = s.id
                   $where";
    
    $countResult = $conn->query($countQuery);
    $countRow = $countResult->fetch_assoc();
    $total = $countRow['total'];
    
    echo json_encode([
        'success' => true,
        'services' => $services,
        'pagination' => [
            'page' => $page,
            'limit' => $limit,
            'total' => $total,
            'pages' => ceil($total / $limit)
        ]
    ]);
    
} catch (Exception $e) {
    error_log("Services list error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to fetch services',
        'error' => $e->getMessage()
    ]);
}

$conn->close();
?>
