<?php
require_once __DIR__ . '/../config.php';

try {
    // Require authentication
    $user = requireAuth();
    
    $input = getInput();
    
    // Validate required fields
    $reviewType = $input['review_type'] ?? '';
    $rating = intval($input['rating'] ?? 0);
    $productId = isset($input['product_id']) ? intval($input['product_id']) : null;
    $vendorId = isset($input['vendor_id']) ? intval($input['vendor_id']) : null;
    $orderId = isset($input['order_id']) ? intval($input['order_id']) : null;
    $title = trim($input['title'] ?? '');
    $comment = trim($input['comment'] ?? '');
    
    // Validate review type
    if (!in_array($reviewType, ['product', 'vendor', 'delivery'])) {
        jsonResponse(['success' => false, 'message' => 'Invalid review type'], 400);
    }
    
    // Validate rating
    if ($rating < 1 || $rating > 5) {
        jsonResponse(['success' => false, 'message' => 'Rating must be between 1 and 5'], 400);
    }
    
    // Validate required IDs based on type
    if ($reviewType === 'product' && !$productId) {
        jsonResponse(['success' => false, 'message' => 'Product ID required for product review'], 400);
    }
    
    if (!$vendorId) {
        jsonResponse(['success' => false, 'message' => 'Vendor ID required'], 400);
    }
    
    $pdo = getDBConnection();
    
    // Check if reviews table exists, create if not
    $stmt = $pdo->query("SHOW TABLES LIKE 'reviews'");
    if (!$stmt->fetch()) {
        // Create reviews table
        $createTableSql = "
        CREATE TABLE reviews (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            order_id INT NULL,
            product_id INT NULL,
            vendor_id INT NULL,
            delivery_agent_id INT NULL,
            review_type ENUM('product', 'vendor', 'delivery') NOT NULL,
            rating INT NOT NULL,
            title VARCHAR(255) NULL,
            comment TEXT NULL,
            images TEXT NULL,
            is_verified_purchase BOOLEAN DEFAULT FALSE,
            is_approved BOOLEAN DEFAULT TRUE,
            admin_reply TEXT NULL,
            replied_at TIMESTAMP NULL,
            deleted_at TIMESTAMP NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )";
        $pdo->exec($createTableSql);
    }
    
    // Check if user already reviewed this item
    $checkSql = "SELECT id FROM reviews WHERE user_id = ? AND review_type = ?";
    $checkParams = [$user['id'], $reviewType];
    
    if ($reviewType === 'product') {
        $checkSql .= " AND product_id = ?";
        $checkParams[] = $productId;
    } else {
        $checkSql .= " AND vendor_id = ?";
        $checkParams[] = $vendorId;
    }
    
    $checkSql .= " AND (deleted_at IS NULL OR deleted_at = '')";
    
    $stmt = $pdo->prepare($checkSql);
    $stmt->execute($checkParams);
    
    if ($stmt->fetch()) {
        jsonResponse(['success' => false, 'message' => 'You have already reviewed this item'], 400);
    }
    
    // Handle order_id requirement - use 0 if not provided since it's NOT NULL
    $finalOrderId = $orderId ?: 0;
    
    // Insert review
    $sql = "INSERT INTO reviews (
        user_id, order_id, product_id, vendor_id, review_type, 
        rating, title, comment, is_verified_purchase, is_approved, 
        created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, 1, NOW(), NOW())";
    
    $stmt = $pdo->prepare($sql);
    $result = $stmt->execute([
        $user['id'],
        $finalOrderId,
        $productId,
        $vendorId,
        $reviewType,
        $rating,
        $title ?: null,
        $comment ?: null
    ]);
    
    if (!$result) {
        throw new Exception("Failed to insert review");
    }
    
    $reviewId = $pdo->lastInsertId();
    
    // Fetch the created review with user info
    $fetchSql = "SELECT r.*, u.name as user_name, u.avatar as user_avatar
                 FROM reviews r
                 LEFT JOIN users u ON r.user_id = u.id
                 WHERE r.id = ?";
    $stmt = $pdo->prepare($fetchSql);
    $stmt->execute([$reviewId]);
    $review = $stmt->fetch();
    
    jsonResponse([
        'success' => true,
        'message' => 'Review submitted successfully',
        'review' => $review
    ]);
    
} catch (Exception $e) {
    error_log("Review create error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Failed to submit review: ' . $e->getMessage()], 500);
}
?>
