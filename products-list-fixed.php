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
    $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 20;
    $offset = ($page - 1) * $limit;
    
    $categoryId = isset($_GET['category_id']) ? intval($_GET['category_id']) : null;
    $search = isset($_GET['search']) ? $_GET['search'] : null;
    
    // Build the WHERE clause
    $where = "WHERE p.status = 'active'";
    $params = [];
    $types = '';
    
    if ($categoryId && $categoryId > 0) {
        $where .= " AND p.category_id = ?";
        $params[] = $categoryId;
        $types .= 'i';
    }
    
    if ($search && !empty(trim($search))) {
        $search = '%' . trim($search) . '%';
        $where .= " AND (p.name LIKE ? OR p.description LIKE ?)";
        $params[] = $search;
        $params[] = $search;
        $types .= 'ss';
    }
    
    // Get total count
    $countQuery = "SELECT COUNT(DISTINCT p.id) as total
                   FROM products p
                   LEFT JOIN users u ON p.vendor_id = u.id
                   LEFT JOIN categories c ON p.category_id = c.id
                   LEFT JOIN subcategories s ON p.subcategory_id = s.id
                   $where";
    
    $countStmt = $conn->prepare($countQuery);
    if (!empty($params)) {
        $countStmt->bind_param($types, ...$params);
    }
    $countStmt->execute();
    $countResult = $countStmt->get_result();
    $countRow = $countResult->fetch_assoc();
    $total = $countRow['total'];
    
    // Get products with subcategory information
    $query = "SELECT 
                p.id,
                p.uuid,
                p.vendor_id,
                COALESCE(u.store_name, 'Unknown') as vendor_name,
                p.category_id,
                c.name as category_name,
                COALESCE(p.subcategory_id, 0) as subcategory_id,
                s.name as subcategory_name,
                p.name,
                p.slug,
                p.description,
                p.short_description,
                p.price,
                p.compare_price,
                COALESCE(p.stock_quantity, 0) as stock,
                p.sku,
                p.thumbnail,
                p.images,
                p.status,
                COALESCE(p.rating, 0) as rating,
                COALESCE(p.total_reviews, 0) as total_reviews,
                COALESCE(p.view_count, 0) as view_count,
                COALESCE(p.is_featured, 0) as is_featured,
                p.created_at
              FROM products p
              LEFT JOIN users u ON p.vendor_id = u.id
              LEFT JOIN categories c ON p.category_id = c.id
              LEFT JOIN subcategories s ON p.subcategory_id = s.id
              $where
              ORDER BY p.created_at DESC
              LIMIT ? OFFSET ?";
    
    $stmt = $conn->prepare($query);
    if ($stmt === false) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    
    // Bind parameters
    $allParams = array_merge($params, [$limit, $offset]);
    $allTypes = $types . 'ii';
    
    if (!empty($allParams)) {
        $stmt->bind_param($allTypes, ...$allParams);
    }
    
    if (!$stmt->execute()) {
        throw new Exception("Execute failed: " . $stmt->error);
    }
    
    $result = $stmt->get_result();
    
    $products = [];
    while ($row = $result->fetch_assoc()) {
        // Parse images
        if (!empty($row['images'])) {
            $images = json_decode($row['images'], true);
            if (is_array($images)) {
                $row['images'] = array_map(function($img) {
                    return strpos($img, 'http') === 0 ? $img : BASE_URL . '/' . $img;
                }, $images);
            } else {
                $row['images'] = [];
            }
        } else {
            $row['images'] = [];
        }
        
        // Set thumbnail
        if (empty($row['thumbnail'])) {
            $row['thumbnail'] = !empty($row['images']) ? $row['images'][0] : null;
        } elseif (strpos($row['thumbnail'], 'http') !== 0) {
            $row['thumbnail'] = BASE_URL . '/' . $row['thumbnail'];
        }
        
        // Price fields for compatibility
        $row['mrp'] = $row['compare_price'];
        $row['selling_price'] = $row['price'];
        $row['total_ratings'] = intval($row['total_reviews']);
        $row['is_featured'] = intval($row['is_featured']);
        
        $products[] = $row;
    }
    
    echo json_encode([
        'success' => true,
        'products' => $products,
        'pagination' => [
            'page' => $page,
            'limit' => $limit,
            'total' => $total,
            'pages' => ceil($total / $limit)
        ]
    ]);
    
} catch (Exception $e) {
    error_log("Products list error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to fetch products',
        'error' => $e->getMessage()
    ]);
}

$conn->close();
?>
