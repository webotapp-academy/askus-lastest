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
    
    $pdo = getDBConnection();
    
    // Get the exact column names from the table
    $stmt = $pdo->query("DESCRIBE reviews");
    $columns = $stmt->fetchAll();
    $columnNames = array_column($columns, 'Field');
    
    // Check which vendor column exists
    $vendorColumn = null;
    if (in_array('vendor_id', $columnNames)) {
        $vendorColumn = 'vendor_id';
    } elseif (in_array('vendorId', $columnNames)) {
        $vendorColumn = 'vendorId';
    } elseif (in_array('vendor', $columnNames)) {
        $vendorColumn = 'vendor';
    }
    
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
    } elseif ($reviewType === 'vendor' && $vendorId && $vendorColumn) {
        $checkSql .= " AND $vendorColumn = ?";
        $checkParams[] = $vendorId;
    }
    
    $checkSql .= " AND (deleted_at IS NULL)";
    
    $stmt = $pdo->prepare($checkSql);
    $stmt->execute($checkParams);
    
    if ($stmt->fetch()) {
        jsonResponse(['success' => false, 'message' => 'You have already reviewed this item'], 400);
    }
    
    // Build INSERT query based on available columns
    $insertColumns = ['user_id', 'order_id', 'review_type', 'rating', 'created_at', 'updated_at'];
    $insertValues = [$user['id'], $finalOrderId, $reviewType, $rating, 'NOW()', 'NOW()'];
    $insertPlaceholders = ['?', '?', '?', '?', 'NOW()', 'NOW()'];
    
    // Add optional columns if they exist
    if ($productId && in_array('product_id', $columnNames)) {
        $insertColumns[] = 'product_id';
        $insertValues[] = $productId;
        $insertPlaceholders[] = '?';
    }
    
    if ($vendorId && $vendorColumn) {
        $insertColumns[] = $vendorColumn;
        $insertValues[] = $vendorId;
        $insertPlaceholders[] = '?';
    }
    
    if ($title && in_array('title', $columnNames)) {
        $insertColumns[] = 'title';
        $insertValues[] = $title;
        $insertPlaceholders[] = '?';
    }
    
    if ($comment && in_array('comment', $columnNames)) {
        $insertColumns[] = 'comment';
        $insertValues[] = $comment;
        $insertPlaceholders[] = '?';
    }
    
    if (in_array('is_verified_purchase', $columnNames)) {
        $insertColumns[] = 'is_verified_purchase';
        $insertValues[] = 0;
        $insertPlaceholders[] = '?';
    }
    
    if (in_array('is_approved', $columnNames)) {
        $insertColumns[] = 'is_approved';
        $insertValues[] = 1;
        $insertPlaceholders[] = '?';
    }
    
    // Remove NOW() from values array and handle separately
    $finalValues = [];
    $finalPlaceholders = [];
    for ($i = 0; $i < count($insertPlaceholders); $i++) {
        if ($insertPlaceholders[$i] === 'NOW()') {
            $finalPlaceholders[] = 'NOW()';
        } else {
            $finalPlaceholders[] = '?';
            $finalValues[] = $insertValues[$i];
        }
    }
    
    $sql = "INSERT INTO reviews (" . implode(', ', $insertColumns) . ") VALUES (" . implode(', ', $finalPlaceholders) . ")";
    
    $stmt = $pdo->prepare($sql);
    $result = $stmt->execute($finalValues);
    
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
        'review' => $review,
        'debug_info' => [
            'columns_found' => $columnNames,
            'vendor_column' => $vendorColumn,
            'sql_used' => $sql
        ]
    ]);
    
} catch (Exception $e) {
    error_log("Review create error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Failed to submit review: ' . $e->getMessage()], 500);
}
?>