<?php
require_once __DIR__ . '/../config.php';

// Get optional authenticated user
$user = getAuthUser();

// Get query parameters
$type = $_GET['type'] ?? 'product'; // 'product', 'vendor'
$itemId = intval($_GET['item_id'] ?? 0);
$page = intval($_GET['page'] ?? 1);
$limit = intval($_GET['limit'] ?? 10);
$offset = ($page - 1) * $limit;

if ($itemId <= 0) {
    jsonResponse(['success' => false, 'message' => 'Item ID required'], 400);
}

$pdo = getDBConnection();

try {
    // Build query based on type
    $whereClause = '';
    $params = [];
    
    if ($type === 'product') {
        $whereClause = 'r.product_id = ? AND r.review_type = ?';
        $params = [$itemId, 'product'];
    } elseif ($type === 'vendor') {
        $whereClause = 'r.vendor_id = ? AND r.review_type = ?';
        $params = [$itemId, 'vendor'];
    } else {
        jsonResponse(['success' => false, 'message' => 'Invalid review type'], 400);
    }
    
    // Get reviews with user info
    $sql = "SELECT r.*, 
            u.name as user_name, 
            u.avatar as user_avatar,
            p.name as product_name,
            v.store_name as vendor_name
            FROM reviews r
            LEFT JOIN users u ON r.user_id = u.id
            LEFT JOIN products p ON r.product_id = p.id
            LEFT JOIN vendors v ON r.vendor_id = v.id
            WHERE $whereClause 
            AND r.is_approved = 1
            AND r.deleted_at IS NULL
            ORDER BY r.created_at DESC
            LIMIT ? OFFSET ?";
    
    $params[] = $limit;
    $params[] = $offset;
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $reviews = $stmt->fetchAll();
    
    // Get stats
    $statsParams = $type === 'product' 
        ? [$itemId, 'product'] 
        : [$itemId, 'vendor'];
    
    $statsWhereClause = $type === 'product'
        ? 'product_id = ? AND review_type = ?'
        : 'vendor_id = ? AND review_type = ?';
    
    $statsSql = "SELECT 
        AVG(rating) as average_rating,
        COUNT(*) as total_reviews,
        SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END) as five_star,
        SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END) as four_star,
        SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END) as three_star,
        SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END) as two_star,
        SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END) as one_star
        FROM reviews 
        WHERE $statsWhereClause 
        AND is_approved = 1 
        AND deleted_at IS NULL";
    
    $stmt = $pdo->prepare($statsSql);
    $stmt->execute($statsParams);
    $statsRow = $stmt->fetch();
    
    $stats = [
        'average_rating' => round(floatval($statsRow['average_rating'] ?? 0), 1),
        'total_reviews' => intval($statsRow['total_reviews'] ?? 0),
        'distribution' => [
            '5' => intval($statsRow['five_star'] ?? 0),
            '4' => intval($statsRow['four_star'] ?? 0),
            '3' => intval($statsRow['three_star'] ?? 0),
            '2' => intval($statsRow['two_star'] ?? 0),
            '1' => intval($statsRow['one_star'] ?? 0),
        ]
    ];
    
    jsonResponse([
        'success' => true,
        'reviews' => $reviews,
        'stats' => $stats,
        'page' => $page,
        'limit' => $limit,
        'has_more' => count($reviews) >= $limit
    ]);
    
} catch (Exception $e) {
    error_log("Reviews list error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Failed to load reviews'], 500);
}
?>