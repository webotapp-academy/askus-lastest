<?php
require_once __DIR__ . '/../config.php';

$vendor = requireVendor();

$pdo = getDBConnection();

$stmt = $pdo->prepare("
    SELECT p.*, c.name as category_name,
           (SELECT pi.image_url FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.sort_order LIMIT 1) as thumbnail
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    WHERE p.vendor_id = ? AND p.deleted_at IS NULL
    ORDER BY p.created_at DESC
");
$stmt->execute([$vendor['id']]);
$products = $stmt->fetchAll();

foreach ($products as &$product) {
    $imgStmt = $pdo->prepare("SELECT image_url FROM product_images WHERE product_id = ? ORDER BY sort_order");
    $imgStmt->execute([$product['id']]);
    $product['images'] = array_column($imgStmt->fetchAll(), 'image_url');
}

jsonResponse([
    'success' => true,
    'products' => $products
]);
