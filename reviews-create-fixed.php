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
    
    // Handle foreign key constraint - we need a valid order_id or create a dummy order
    $finalOrderId = null;
    if ($orderId) {
        // Verify the order exists and belongs to the user
        $orderCheckSql = "SELECT id FROM orders WHERE id = ? AND user_id = ?";
        $stmt = $pdo->prepare($orderCheckSql);
        $stmt->execute([$orderId, $user['id']]);
        if ($stmt->fetch()) {
            $finalOrderId = $orderId;
        }
    }
    
    // If no valid order_id, create a dummy order for the review
    if (!$finalOrderId) {
        $dummyOrderSql = "INSERT INTO orders (user_id, vendor_id, total_amount, status, created_at, updated_at) 
                          VALUES (?, ?, 0, 'review_only', NOW(), NOW())";
        $stmt = $pdo->prepare($dummyOrderSql);
        $stmt->execute([$user['id'], $vendorId]);
        $finalOrderId = $pdo->lastInsertId();
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
    
    // Insert review with valid order_id
    $sql = "INSERT INTO reviews (
        user_id, order_id, product_id, vendor_id, review_type, 
        rating, title, comment, is_verified_purchase, is_approved, 
        created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())";
    
    $stmt = $pdo->prepare($sql);
    $result = $stmt->execute([
        $user['id'],
        $finalOrderId,
        $productId,
        $vendorId,
        $reviewType,
        $rating,
        $title ?: null,
        $comment ?: null,
        0, // is_verified_purchase (0 = false)
        1  // is_approved (1 = true)
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
    
    // Update product rating if it's a product review
    if ($reviewType === 'product' && $productId) {
        try {
            $avgSql = "SELECT AVG(rating) as avg_rating FROM reviews 
                       WHERE product_id = ? AND review_type = 'product' 
                       AND is_approved = 1 AND deleted_at IS NULL";
            $stmt = $pdo->prepare($avgSql);
            $stmt->execute([$productId]);
            $avgResult = $stmt->fetch();
            
            if ($avgResult && $avgResult['avg_rating']) {
                $updateSql = "UPDATE products SET rating = ? WHERE id = ?";
                $stmt = $pdo->prepare($updateSql);
                $stmt->execute([round($avgResult['avg_rating'], 1), $productId]);
            }
        } catch (Exception $e) {
            // Don't fail the review creation if rating update fails
            error_log("Failed to update product rating: " . $e->getMessage());
        }
    }
    
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