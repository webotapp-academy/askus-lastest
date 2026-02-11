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
    
    // Find an existing order for this user
    $orderSql = "SELECT id FROM orders WHERE user_id = ? ORDER BY id DESC LIMIT 1";
    $stmt = $pdo->prepare($orderSql);
    $stmt->execute([$user['id']]);
    $existingOrder = $stmt->fetch();
    
    $finalOrderId = $existingOrder ? $existingOrder['id'] : 1;
    
    // If orderId was provided and exists, use it
    if ($orderId) {
        $orderCheckSql = "SELECT id FROM orders WHERE id = ?";
        $stmt = $pdo->prepare($orderCheckSql);
        $stmt->execute([$orderId]);
        if ($stmt->fetch()) {
            $finalOrderId = $orderId;
        }
    }
    
    // Check if user already reviewed this item
    $checkSql = "SELECT id FROM reviews WHERE user_id = ? AND review_type = ?";
    $checkParams = [$user['id'], $reviewType];
    
    if ($reviewType === 'product' && $productId) {
        $checkSql .= " AND product_id = ?";
        $checkParams[] = $productId;
    } elseif ($reviewType === 'vendor' && $vendorId) {
        $checkSql .= " AND vendor_id = ?";
        $checkParams[] = $vendorId;
    }
    
    $checkSql .= " AND (deleted_at IS NULL)";
    
    $stmt = $pdo->prepare($checkSql);
    $stmt->execute($checkParams);
    
    if ($stmt->fetch()) {
        jsonResponse(['success' => false, 'message' => 'You have already reviewed this item'], 400);
    }
    
    // Insert review - matching your exact table structure
    $sql = "INSERT INTO reviews (
        user_id, 
        order_id, 
        product_id, 
        vendor_id, 
        review_type, 
        rating, 
        title, 
        comment, 
        is_verified_purchase, 
        is_approved
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    $stmt = $pdo->prepare($sql);
    $result = $stmt->execute([
        $user['id'],           // user_id
        $finalOrderId,         // order_id
        $productId,            // product_id (can be NULL)
        $vendorId,             // vendor_id (can be NULL)
        $reviewType,           // review_type
        $rating,               // rating
        $title ?: null,        // title (can be NULL)
        $comment ?: null,      // comment (can be NULL)
        1,                     // is_verified_purchase (default 1)
        1                      // is_approved (default 1)
    ]);
    
    if (!$result) {
        $errorInfo = $stmt->errorInfo();
        throw new Exception("Database error: " . $errorInfo[2]);
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