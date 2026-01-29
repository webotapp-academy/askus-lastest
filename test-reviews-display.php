<?php
// Simple test to check if reviews are being fetched correctly
require_once __DIR__ . '/config.php';

header('Content-Type: application/json');

try {
    $pdo = getDBConnection();
    
    // Get some sample reviews
    $sql = "SELECT r.*, u.name as user_name 
            FROM reviews r 
            LEFT JOIN users u ON r.user_id = u.id 
            WHERE r.deleted_at IS NULL 
            ORDER BY r.created_at DESC 
            LIMIT 5";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute();
    $reviews = $stmt->fetchAll();
    
    // Get review stats for a product (assuming product_id = 49 from your test)
    $statsSql = "SELECT 
        AVG(rating) as average_rating,
        COUNT(*) as total_reviews,
        SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END) as five_star,
        SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END) as four_star,
        SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END) as three_star,
        SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END) as two_star,
        SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END) as one_star
        FROM reviews 
        WHERE product_id = 49 AND review_type = 'product'
        AND is_approved = 1 AND deleted_at IS NULL";
    
    $stmt = $pdo->prepare($statsSql);
    $stmt->execute();
    $stats = $stmt->fetch();
    
    echo json_encode([
        'success' => true,
        'recent_reviews' => $reviews,
        'product_49_stats' => [
            'average_rating' => round(floatval($stats['average_rating'] ?? 0), 1),
            'total_reviews' => intval($stats['total_reviews'] ?? 0),
            'distribution' => [
                '5' => intval($stats['five_star'] ?? 0),
                '4' => intval($stats['four_star'] ?? 0),
                '3' => intval($stats['three_star'] ?? 0),
                '2' => intval($stats['two_star'] ?? 0),
                '1' => intval($stats['one_star'] ?? 0),
            ]
        ]
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>