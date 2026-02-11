<?php
require_once __DIR__ . '/../config.php';

// Require authentication
$user = requireAuth();

$input = getInput();
$reviewId = intval($input['review_id'] ?? 0);

if (!$reviewId) {
    jsonResponse(['success' => false, 'message' => 'Review ID required'], 400);
}

$pdo = getDBConnection();

try {
    // Check if review exists and belongs to user
    $stmt = $pdo->prepare("SELECT * FROM reviews WHERE id = ? AND deleted_at IS NULL");
    $stmt->execute([$reviewId]);
    $review = $stmt->fetch();
    
    if (!$review) {
        jsonResponse(['success' => false, 'message' => 'Review not found'], 404);
    }
    
    // Only allow user to delete their own review
    if ($review['user_id'] != $user['id']) {
        jsonResponse(['success' => false, 'message' => 'You can only delete your own reviews'], 403);
    }
    
    // Soft delete the review
    $stmt = $pdo->prepare("UPDATE reviews SET deleted_at = NOW(), updated_at = NOW() WHERE id = ?");
    $stmt->execute([$reviewId]);
    
    // Update product/vendor average rating
    if ($review['review_type'] === 'product' && $review['product_id']) {
        $avgSql = "SELECT AVG(rating) as avg_rating FROM reviews 
                   WHERE product_id = ? AND review_type = 'product' 
                   AND is_approved = 1 AND deleted_at IS NULL";
        $stmt = $pdo->prepare($avgSql);
        $stmt->execute([$review['product_id']]);
        $avgResult = $stmt->fetch();
        
        $newRating = $avgResult && $avgResult['avg_rating'] ? round($avgResult['avg_rating'], 1) : 0;
        $pdo->prepare("UPDATE products SET rating = ? WHERE id = ?")
            ->execute([$newRating, $review['product_id']]);
    }
    
    jsonResponse([
        'success' => true,
        'message' => 'Review deleted successfully'
    ]);
    
} catch (Exception $e) {
    error_log("Review delete error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Failed to delete review'], 500);
}
?>
