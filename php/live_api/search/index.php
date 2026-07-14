<?php
require_once __DIR__ . '/../config.php';

try {
    $q = trim($_GET['q'] ?? '');
    $type = $_GET['type'] ?? 'all';

    if (strlen($q) < 2) {
        jsonResponse(['success' => true, 'products' => [], 'services' => []]);
    }

    $pdo = getDBConnection();

    $products = [];
    $services = [];

    if ($type === 'all' || $type === 'products') {
        try {
            $stmt = $pdo->prepare("
                SELECT p.*, v.store_name as vendor_name,
                       COALESCE(
                           (SELECT pi.image_url FROM product_images pi WHERE pi.product_id = p.id AND pi.is_primary = 1 ORDER BY pi.sort_order LIMIT 1),
                           (SELECT pi.image_url FROM product_images pi WHERE pi.product_id = p.id ORDER BY pi.sort_order LIMIT 1)
                       ) as thumbnail
                FROM products p
                JOIN vendors v ON p.vendor_id = v.id
                WHERE p.status = 'active' AND p.deleted_at IS NULL AND v.status = 'approved'
                AND (p.name LIKE ? OR p.description LIKE ?)
                ORDER BY p.is_featured DESC, p.created_at DESC
                LIMIT 20
            ");
            $stmt->execute(["%$q%", "%$q%"]);
            $products = $stmt->fetchAll();
            
            foreach ($products as &$product) {
                if (!isset($product['price'])) {
                    $product['price'] = $product['selling_price'] ?? 0;
                }
                if (!isset($product['compare_price'])) {
                    $product['compare_price'] = $product['mrp'] ?? null;
                }
            }
        } catch (Exception $e) {
            error_log("Search products error: " . $e->getMessage());
        }
    }

    if ($type === 'all' || $type === 'services') {
        try {
            $stmt = $pdo->prepare("
                SELECT s.*, 
                       v.store_name as vendor_name,
                       s.min_price as price,
                       (SELECT si.image_url FROM service_images si WHERE si.service_id = s.id ORDER BY si.sort_order LIMIT 1) as thumbnail
                FROM services s
                JOIN vendors v ON s.vendor_id = v.id
                WHERE s.status = 'active' AND s.deleted_at IS NULL AND v.status = 'approved'
                AND (s.name LIKE ? OR s.description LIKE ?)
                ORDER BY s.created_at DESC
                LIMIT 20
            ");
            $stmt->execute(["%$q%", "%$q%"]);
            $services = $stmt->fetchAll();
        } catch (Exception $e) {
            error_log("Search services error: " . $e->getMessage());
        }
    }

    jsonResponse([
        'success' => true,
        'products' => $products,
        'services' => $services
    ]);

} catch (Exception $e) {
    error_log("Search error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Search failed'], 500);
}