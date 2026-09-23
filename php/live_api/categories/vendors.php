<?php
require_once __DIR__ . '/../config.php';

try {
    $categoryId = intval($_GET['category_id'] ?? 0);
    $subcategoryId = intval($_GET['subcategory_id'] ?? 0);

    if ($categoryId <= 0 && $subcategoryId <= 0) {
        jsonResponse(['success' => false, 'message' => 'category_id or subcategory_id is required'], 400);
    }

    $pdo = getDBConnection();

    if ($subcategoryId > 0) {
        $stmt = $pdo->prepare("
            SELECT DISTINCT v.* 
            FROM vendors v
            LEFT JOIN vendor_categories vc ON v.id = vc.vendor_id
            WHERE v.status IN ('approved', 'active') AND v.deleted_at IS NULL
            AND (vc.subcategory_id = ? OR v.category_id = ?)
            ORDER BY v.rating DESC, v.created_at DESC
        ");
        $stmt->execute([$subcategoryId, $categoryId]);
    } else {
        $stmt = $pdo->prepare("
            SELECT DISTINCT v.* 
            FROM vendors v
            LEFT JOIN vendor_categories vc ON v.id = vc.vendor_id
            WHERE v.status IN ('approved', 'active') AND v.deleted_at IS NULL
            AND (v.category_id = ? OR vc.category_id = ?)
            ORDER BY v.rating DESC, v.created_at DESC
        ");
        $stmt->execute([$categoryId, $categoryId]);
    }

    $vendors = $stmt->fetchAll();

    jsonResponse([
        'success' => true,
        'count' => count($vendors),
        'vendors' => $vendors
    ]);

} catch (Exception $e) {
    error_log("Error in categories/vendors.php: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Failed to fetch vendors for category'], 500);
}
