<?php
// Debug version of reviews create endpoint
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Log the request for debugging
error_log("Reviews Create Debug - Request received");
error_log("Request method: " . $_SERVER['REQUEST_METHOD']);
error_log("Request body: " . file_get_contents('php://input'));

try {
    // Check if config file exists
    $configPath = __DIR__ . '/../config.php';
    if (!file_exists($configPath)) {
        throw new Exception("Config file not found at: $configPath");
    }
    
    require_once $configPath;
    error_log("Config loaded successfully");
    
    // Test database connection
    $pdo = getDBConnection();
    error_log("Database connection successful");
    
    // Check if reviews table exists
    $stmt = $pdo->query("SHOW TABLES LIKE 'reviews'");
    if (!$stmt->fetch()) {
        throw new Exception("Reviews table does not exist");
    }
    error_log("Reviews table exists");
    
    // Test authentication
    $user = requireAuth();
    error_log("User authenticated: " . json_encode(['id' => $user['id'], 'role' => $user['role'] ?? 'user']));
    
    $input = getInput();
    error_log("Input received: " . json_encode($input));
    
    // Validate required fields
    $reviewType = $input['review_type'] ?? '';
    $rating = intval($input['rating'] ?? 0);
    $productId = isset($input['product_id']) ? intval($input['product_id']) : null;
    $vendorId = isset($input['vendor_id']) ? intval($input['vendor_id']) : null;
    $orderId = isset($input['order_id']) ? intval($input['order_id']) : null;
    $title = trim($input['title'] ?? '');
    $comment = trim($input['comment'] ?? '');
    
    error_log("Parsed data: type=$reviewType, rating=$rating, productId=$productId, vendorId=$vendorId");
    
    // Validate review type
    if (!in_array($reviewType, ['product', 'vendor', 'delivery'])) {
        throw new Exception("Invalid review type: $reviewType");
    }
    
    // Validate rating
    if ($rating < 1 || $rating > 5) {
        throw new Exception("Invalid rating: $rating");
    }
    
    // Validate required IDs based on type
    if ($reviewType === 'product' && !$productId) {
        throw new Exception("Product ID required for product review");
    }
    
    if (!$vendorId) {
        throw new Exception("Vendor ID required");
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
    
    $checkSql .= " AND deleted_at IS NULL";
    
    $stmt = $pdo->prepare($checkSql);
    $stmt->execute($checkParams);
    
    if ($stmt->fetch()) {
        throw new Exception("User has already reviewed this item");
    }
    
    error_log("Validation passed, inserting review");
    
    // Insert review
    $sql = "INSERT INTO reviews (
        user_id, order_id, product_id, vendor_id, review_type, 
        rating, title, comment, is_verified_purchase, is_approved, 
        created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, 1, NOW(), NOW())";
    
    $stmt = $pdo->prepare($sql);
    $result = $stmt->execute([
        $user['id'],
        $orderId,
        $productId,
        $vendorId,
        $reviewType,
        $rating,
        $title ?: null,
        $comment ?: null
    ]);
    
    if (!$result) {
        throw new Exception("Failed to insert review: " . implode(', ', $stmt->errorInfo()));
    }
    
    $reviewId = $pdo->lastInsertId();
    error_log("Review inserted with ID: $reviewId");
    
    // Fetch the created review
    $fetchSql = "SELECT r.*, u.name as user_name, u.avatar as user_avatar
                 FROM reviews r
                 LEFT JOIN users u ON r.user_id = u.id
                 WHERE r.id = ?";
    $stmt = $pdo->prepare($fetchSql);
    $stmt->execute([$reviewId]);
    $review = $stmt->fetch();
    
    error_log("Review created successfully");
    
    echo json_encode([
        'success' => true,
        'message' => 'Review submitted successfully',
        'review' => $review,
        'debug_info' => [
            'review_id' => $reviewId,
            'user_id' => $user['id'],
            'review_type' => $reviewType,
            'rating' => $rating
        ]
    ]);
    
} catch (Exception $e) {
    error_log("Reviews Create Error: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());
    
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to submit review',
        'debug_error' => $e->getMessage(),
        'debug_trace' => $e->getTraceAsString()
    ]);
}
?>