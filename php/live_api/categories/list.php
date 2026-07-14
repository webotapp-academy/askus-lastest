<?php
require_once __DIR__ . '/../config.php';

try {
    $pdo = getDBConnection();

    $stmt = $pdo->prepare("
        SELECT * FROM categories 
        WHERE status = 'active' AND deleted_at IS NULL 
        ORDER BY sort_order, name
    ");
    $stmt->execute();
    $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $formattedCategories = [];
    foreach ($categories as $category) {
        $categoryData = $category; // Start with all fields
        
        // Format specific fields
        $categoryData['id'] = intval($category['id']);
        $categoryData['icon'] = formatImageURL($category['icon']);
        $categoryData['image'] = formatImageURL($category['image']);
        $categoryData['gallery_images'] = formatImageURL($category['gallery_images']);
        $categoryData['sort_order'] = intval($category['sort_order']);
        
        $formattedCategories[] = $categoryData;
    }

    jsonResponse([
        'success' => true,
        'categories' => $formattedCategories
    ]);

} catch (Exception $e) {
    logError("Categories list error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Failed to load categories'], 500);
}
?>
