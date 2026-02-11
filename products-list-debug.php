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
    $where = "WHERE p.status = 'active'";
    $params = [];
    
    if ($categoryId > 0) {
        $where .= " AND p.category_id = :categoryId";
        $params[':categoryId'] = $categoryId;
    }
    
    if (!empty($search)) {
        $where .= " AND (p.name LIKE :search OR p.description LIKE :search2)";
        $searchTerm = '%' . $search . '%';
        $params[':search'] = $searchTerm;
        $params[':search2'] = $searchTerm;
    }
    
    // Get total count
    $countQuery = "SELECT COUNT(DISTINCT p.id) as total FROM products p $where";
    $countStmt = $pdo->prepare($countQuery);
    if (!$countStmt->execute($params)) {
        throw new Exception("Count query failed: " . implode(", ", $countStmt->errorInfo()));
    }
    $total = intval($countStmt->fetchColumn());
    
    // Get products with subcategory information
    $query = "SELECT 
                p.id,
                p.uuid,
                p.vendor_id,
                COALESCE(u.store_name, 'Unknown') as vendor_name,
                p.category_id,
                COALESCE(c.name, '') as category_name,
                COALESCE(p.subcategory_id, 0) as subcategory_id,
                COALESCE(s.name, NULL) as subcategory_name,
                p.name,
                p.slug,
                p.description,
                p.short_description,
                COALESCE(p.price, 0) as price,
                COALESCE(p.compare_price, 0) as compare_price,
                COALESCE(p.stock_quantity, 0) as stock,
                p.sku,
                p.thumbnail,
                p.images,
                p.status,
                COALESCE(p.view_count, 0) as view_count,
                COALESCE(p.is_featured, 0) as is_featured,
                p.created_at
              FROM products p
              LEFT JOIN users u ON p.vendor_id = u.id
              LEFT JOIN categories c ON p.category_id = c.id
              LEFT JOIN subcategories s ON p.subcategory_id = s.id
              $where
              ORDER BY p.created_at DESC
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
    
    $products = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $formattedProducts = [];
    foreach ($products as $product) {
        // Parse images
        $images = [];
        if (!empty($product['images'])) {
            $decoded = json_decode($product['images'], true);
            if (is_array($decoded)) {
                $images = array_map(function($img) {
                    return strpos($img, 'http') === 0 ? $img : BASE_URL . '/' . $img;
                }, $decoded);
            }
        }
        $product['images'] = $images;
        
        // Set thumbnail
        if (empty($product['thumbnail'])) {
            $product['thumbnail'] = !empty($images) ? $images[0] : null;
        } elseif (strpos($product['thumbnail'], 'http') !== 0) {
            $product['thumbnail'] = BASE_URL . '/' . $product['thumbnail'];
        }
        
        // Format price fields
        $product['mrp'] = $product['compare_price'];
        $product['selling_price'] = $product['price'];
        $product['is_featured'] = intval($product['is_featured']);
        $product['subcategory_id'] = intval($product['subcategory_id']);
        
        $formattedProducts[] = $product;
    }
    
    jsonResponse([
        'success' => true,
        'products' => $formattedProducts,
        'pagination' => [
            'page' => $page,
            'limit' => $limit,
            'total' => $total,
            'pages' => ceil($total / $limit)
        ]
    ]);
    
} catch (Exception $e) {
    error_log("Products List Error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => $e->getMessage()], 500);
}
?>
