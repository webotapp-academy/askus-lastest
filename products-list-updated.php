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
    $where = "WHERE p.status = 'active'";
    
    if ($categoryId) {
        $where .= " AND p.category_id = $categoryId";
    }
    
    if ($search) {
        $where .= " AND (p.name LIKE '%$search%' OR p.description LIKE '%$search%')";
    }
    
    // Get products with subcategory information
    $query = "SELECT 
                p.id,
                p.uuid,
                p.vendor_id,
                u.store_name as vendor_name,
                p.category_id,
                c.name as category_name,
                p.subcategory_id,
                s.name as subcategory_name,
                p.name,
                p.slug,
                p.description,
                p.short_description,
                p.price,
                p.compare_price,
                p.stock_quantity as stock,
                p.sku,
                p.thumbnail,
                p.images,
                p.status,
                COALESCE(ROUND(AVG(r.rating), 1), 0) as rating,
                COUNT(DISTINCT r.id) as total_reviews,
                p.view_count,
                p.is_featured,
                p.created_at
              FROM products p
              LEFT JOIN users u ON p.vendor_id = u.id
              LEFT JOIN categories c ON p.category_id = c.id
              LEFT JOIN subcategories s ON p.subcategory_id = s.id
              LEFT JOIN reviews r ON p.id = r.item_id AND r.type = 'product' AND r.status = 'approved'
              $where
              GROUP BY p.id
              ORDER BY p.created_at DESC
              LIMIT $limit OFFSET $offset";
    
    $result = $conn->query($query);
    
    if (!$result) {
        throw new Exception("Query failed: " . $conn->error);
    }
    
    $products = [];
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
        
        // Price fields
        $row['mrp'] = $row['compare_price'];
        $row['selling_price'] = $row['price'];
        $row['rating'] = floatval($row['rating']);
        $row['total_ratings'] = intval($row['total_reviews']);
        $row['is_featured'] = intval($row['is_featured']);
        
        $products[] = $row;
    }
    
    // Get total count
    $countQuery = "SELECT COUNT(DISTINCT p.id) as total
                   FROM products p
                   LEFT JOIN users u ON p.vendor_id = u.id
                   LEFT JOIN categories c ON p.category_id = c.id
                   LEFT JOIN subcategories s ON p.subcategory_id = s.id
                   $where";
    
    $countResult = $conn->query($countQuery);
    $countRow = $countResult->fetch_assoc();
    $total = $countRow['total'];
    
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
