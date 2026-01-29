<?php
require_once __DIR__ . '/../config.php';

// Require authentication
$user = requireAuth();

$input = getInput();

// Get input values
$reviewType = $input['review_type'] ?? '';
$rating = intval($input['rating'] ?? 0);
$productId = isset($input['product_id']) ? intval($input['product_id']) : null;
$vendorId = isset($input['vendor_id']) ? intval($input['vendor_id']) : null;
$title = trim($input['title'] ?? '');
$comment = trim($input['comment'] ?? '');

// Basic validation
if (!in_array($reviewType, ['product', 'vendor', 'delivery'])) {
    jsonResponse(['success' => false, 'message' => 'Invalid review type'], 400);
}

if ($rating < 1 || $rating > 5) {
    jsonResponse(['success' => false, 'message' => 'Rating must be between 1 and 5'], 400);
}

if ($reviewType === 'product' && !$productId) {
    jsonResponse(['success' => false, 'message' => 'Product ID required'], 400);
}

try {
    $pdo = getDBConnection();
    
    // COMPLETELY IGNORE order_id - don't include it in the INSERT at all
    // Only insert the fields we actually need
    $sql = "INSERT INTO reviews (user_id, product_id, vendor_id, review_type, rating, title, comment) 
            VALUES (?, ?, ?, ?, ?, ?, ?)";
    
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
        
        // Get the created review
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
        jsonResponse(['success' => false, 'message' => 'Database error: ' . $error[2]], 500);
    }
    
} catch (Exception $e) {
    jsonResponse(['success' => false, 'message' => 'Error: ' . $e->getMessage()], 500);
}
?>