<?php
require_once __DIR__ . '/../config.php';

$user = requireAuth();
$input = getInput();

$reviewType = $input['review_type'] ?? '';
$rating = intval($input['rating'] ?? 0);
$productId = isset($input['product_id']) ? intval($input['product_id']) : null;
$vendorId = isset($input['vendor_id']) ? intval($input['vendor_id']) : null;
$title = trim($input['title'] ?? '');
$comment = trim($input['comment'] ?? '');

if (!in_array($reviewType, ['product', 'vendor', 'delivery'])) {
    jsonResponse(['success' => false, 'message' => 'Invalid review type'], 400);
}

if ($rating < 1 || $rating > 5) {
    jsonResponse(['success' => false, 'message' => 'Invalid rating'], 400);
}

try {
    $pdo = getDBConnection();
    
    // Create a dummy order just to satisfy the foreign key
    $pdo->prepare("INSERT IGNORE INTO orders (id, user_id, vendor_id, total_amount, status, created_at, updated_at) VALUES (0, ?, ?, 0, 'review_dummy', NOW(), NOW())")->execute([$user['id'], $vendorId ?: 1]);
    
    // Now insert the review with order_id = 0
    $sql = "INSERT INTO reviews (user_id, order_id, product_id, vendor_id, review_type, rating, title, comment) 
            VALUES (?, 0, ?, ?, ?, ?, ?, ?)";
    
    $stmt = $pdo->prepare($sql);
    $result = $stmt->execute([
        $user['id'],
        $productId,
        $vendorId,
        $reviewType,
        $rating,
        $title ?: null,
        $comment ?: null
    ]);
    
    if ($result) {
        $reviewId = $pdo->lastInsertId();
        $stmt = $pdo->prepare("SELECT * FROM reviews WHERE id = ?");
        $stmt->execute([$reviewId]);
        $review = $stmt->fetch();
        
        jsonResponse([
            'success' => true,
            'message' => 'Review submitted successfully',
            'review' => $review
        ]);
    } else {
        $error = $stmt->errorInfo();
        jsonResponse(['success' => false, 'message' => $error[2]], 500);
    }
    
} catch (Exception $e) {
    jsonResponse(['success' => false, 'message' => $e->getMessage()], 500);
}
?>