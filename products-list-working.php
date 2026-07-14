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
    $where = "WHERE p.status = 'active' AND p.deleted_at IS NULL";
    $params = [];
    
    if ($categoryId > 0) {
        $where .= " AND p.category_id = ?";
        $params[] = $categoryId;
    }
    
    if ($search && !empty(trim($search))) {
        $where .= " AND (p.name LIKE ? OR p.description LIKE ?)";
        $searchTerm = '%' . $search . '%';
        $params[] = $searchTerm;
        $params[] = $searchTerm;
    }
    
    // Get total count
    $countStmt = $pdo->prepare("SELECT COUNT(DISTINCT p.id) as total FROM products p $where");
    $countStmt->execute($params);
    $total = $countStmt->fetchColumn();
    
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
                p.mrp as price,
                p.selling_price as compare_price,
                p.stock_quantity as stock,
                p.sku,
                p.thumbnail,
                p.images,
                p.status,
                p.view_count,
                p.is_featured,
                p.created_at
              FROM products p
              LEFT JOIN users u ON p.vendor_id = u.id
              LEFT JOIN vendors v ON p.vendor_id = v.id
              LEFT JOIN subscription_plans sp ON v.current_plan_id = sp.id AND (v.plan_expires_at IS NULL OR v.plan_expires_at > NOW())
              LEFT JOIN categories c ON p.category_id = c.id
              LEFT JOIN subcategories s ON p.subcategory_id = s.id
              $where
              ORDER BY sp.has_top_placement DESC, p.is_featured DESC, p.created_at DESC
              LIMIT ? OFFSET ?";
    
    $stmt = $pdo->prepare($query);
    
    // Bind all parameters
    $bindParams = array_merge($params, [$limit, $offset]);
    $types = str_repeat('s', count($params)) . 'ii';
    
    foreach ($bindParams as $key => $value) {
        if ($key < count($params)) {
            $stmt->bindValue($key + 1, $bindParams[$key]);
        } else {
            $stmt->bindValue($key + 1, $bindParams[$key], PDO::PARAM_INT);
        }
    }
    
    $stmt->execute($bindParams);
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
        $product['mrp'] = $product['price'];
        $product['selling_price'] = $product['compare_price'];
        $product['is_featured'] = (int)$product['is_featured'];
        $product['subcategory_id'] = (int)$product['subcategory_id'];
        
        $formattedProducts[] = $product;
    }
    
    jsonResponse([
        'success' => true,
        'products' => $formattedProducts,
        'pagination' => [
            'page' => $page,
            'limit' => $limit,
            'total' => (int)$total,
            'pages' => ceil($total / $limit)
        ]
    ]);
    
} catch (PDOException $e) {
    error_log("Products List DB Error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Database error'], 500);
} catch (Exception $e) {
    error_log("Products List Error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Error: ' . $e->getMessage()], 500);
}
?>
