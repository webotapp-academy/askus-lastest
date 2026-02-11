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
    $where = "WHERE p.status = 'active' AND pi.id IS NOT NULL";
    $params = [];
    
    if ($categoryId > 0) {
        $where .= " AND p.category_id = :categoryId";
        $params[':categoryId'] = $categoryId;
    }
    
    if (!empty($search)) {
        $where .= " AND (p.name LIKE :search1 OR p.description LIKE :search2)";
        $params[':search1'] = '%' . $search . '%';
        $params[':search2'] = '%' . $search . '%';
    }
    
    // Get total count - count distinct products that have images
    $countStmt = $pdo->prepare("SELECT COUNT(DISTINCT p.id) FROM products p 
                                INNER JOIN product_images pi ON p.id = pi.product_id 
                                $where");
    $countStmt->execute($params);
    $total = intval($countStmt->fetchColumn());
    
    // Get products with images - only products that exist in product_images table
    $query = "SELECT DISTINCT
                p.id,
                p.uuid,
                p.vendor_id,
                p.category_id,
                p.subcategory_id,
                p.name,
                p.slug,
                p.description,
                p.short_description,
                p.mrp,
                p.selling_price,
                p.stock_quantity,
                p.sku,
                p.rating,
                p.total_reviews,
                p.is_featured,
                p.status,
                p.created_at
              FROM products p
              INNER JOIN product_images pi ON p.id = pi.product_id
              $where
              ORDER BY p.created_at DESC
              LIMIT :limit OFFSET :offset";
    
    $stmt = $pdo->prepare($query);
    $params[':limit'] = $limit;
    $params[':offset'] = $offset;
    $stmt->execute($params);
    $products = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get all images for the products
    $productIds = array_column($products, 'id');
    $images = [];
    if (!empty($productIds)) {
        $placeholders = implode(',', array_fill(0, count($productIds), '?'));
        $imgStmt = $pdo->prepare("SELECT id, product_id, image_url, alt_text, sort_order, is_primary 
                                  FROM product_images 
                                  WHERE product_id IN ($placeholders)
                                  ORDER BY sort_order ASC, is_primary DESC");
        $imgStmt->execute($productIds);
        $allImages = $imgStmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($allImages as $img) {
            if (!isset($images[$img['product_id']])) {
                $images[$img['product_id']] = [];
            }
            $images[$img['product_id']][] = $img;
        }
    }
    
    // Format products
    $formattedProducts = [];
    foreach ($products as $product) {
        $productImages = $images[$product['id']] ?? [];
        $thumbnail = null;
        if (!empty($productImages)) {
            $thumbnail = $productImages[0]['image_url'];
        }
        
        $formattedProducts[] = [
            'id' => intval($product['id']),
            'uuid' => $product['uuid'],
            'vendor_id' => intval($product['vendor_id']),
            'category_id' => intval($product['category_id']),
            'subcategory_id' => $product['subcategory_id'] ? intval($product['subcategory_id']) : null,
            'name' => $product['name'],
            'slug' => $product['slug'],
            'description' => $product['description'],
            'short_description' => $product['short_description'],
            'price' => floatval($product['selling_price']),
            'mrp' => floatval($product['mrp']),
            'selling_price' => floatval($product['selling_price']),
            'compare_price' => floatval($product['mrp']),
            'stock' => intval($product['stock_quantity']),
            'sku' => $product['sku'],
            'rating' => floatval($product['rating']),
            'total_reviews' => intval($product['total_reviews']),
            'total_ratings' => intval($product['total_reviews']),
            'is_featured' => intval($product['is_featured']),
            'status' => $product['status'],
            'thumbnail' => $thumbnail,
            'images' => $productImages,
            'created_at' => $product['created_at']
        ];
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
