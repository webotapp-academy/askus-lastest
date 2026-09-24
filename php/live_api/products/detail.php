<?php
require_once __DIR__ . '/../config.php';

$id = intval($_GET['id'] ?? 0);
if (!$id) {
    jsonResponse(['success' => false, 'message' => 'Product ID required'], 400);
}

try {
    $pdo = getDBConnection();

    $stmt = $pdo->prepare("
        SELECT p.*, 
               COALESCE(v.store_name, u.name, 'AskUs Vendor') as vendor_name, 
               COALESCE(v.rating, 0) as vendor_rating, 
               COALESCE(v.city, '') as vendor_city,
               COALESCE(v.phone, u.phone, '') as vendor_phone,
               c.name as category_name,
               (SELECT pi.image_url FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.is_primary DESC, pi.sort_order ASC LIMIT 1) as thumbnail
        FROM products p
        LEFT JOIN vendors v ON p.vendor_id = v.id
        LEFT JOIN users u ON p.vendor_id = u.id
        LEFT JOIN categories c ON p.category_id = c.id
        WHERE p.id = ?
    ");
    $stmt->execute([$id]);
    $product = $stmt->fetch();

    if (!$product) {
        jsonResponse(['success' => false, 'message' => 'Product not found'], 404);
    }

    if (!isset($product['price'])) {
        $product['price'] = $product['selling_price'] ?? 0;
    }
    if (!isset($product['compare_price'])) {
        $product['compare_price'] = $product['mrp'] ?? null;
    }
    if (!isset($product['stock'])) {
        $product['stock'] = $product['stock_quantity'] ?? 0;
    }
    if (!isset($product['total_ratings'])) {
        $product['total_ratings'] = $product['total_reviews'] ?? 0;
    }

    $imgStmt = $pdo->prepare("SELECT image_url FROM product_images WHERE product_id = ? ORDER BY is_primary DESC, sort_order ASC");
    $imgStmt->execute([$id]);
    $product['images'] = array_column($imgStmt->fetchAll(), 'image_url');
    
    if (empty($product['thumbnail']) && !empty($product['images'])) {
        $product['thumbnail'] = $product['images'][0];
    }

    $product['vendor'] = [
        'id' => $product['vendor_id'] ?? 0,
        'name' => $product['vendor_name'] ?? 'AskUs Vendor',
        'rating' => $product['vendor_rating'] ?? 0,
        'city' => $product['vendor_city'] ?? '',
        'phone' => $product['vendor_phone'] ?? '',
    ];

    try {
        $pdo->prepare("UPDATE products SET view_count = COALESCE(view_count, 0) + 1 WHERE id = ?")->execute([$id]);
    } catch (Exception $e) {}

    jsonResponse([
        'success' => true,
        'product' => $product
    ]);

} catch (Exception $e) {
    error_log("Product detail error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Failed to load product'], 500);
}
