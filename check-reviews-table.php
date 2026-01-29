<?php
require_once __DIR__ . '/config.php';

header('Content-Type: application/json');

try {
    $pdo = getDBConnection();
    
    // Check if reviews table exists
    $stmt = $pdo->query("SHOW TABLES LIKE 'reviews'");
    $tableExists = $stmt->fetch() ? true : false;
    
    $result = [
        'success' => true,
        'table_exists' => $tableExists,
        'database_info' => []
    ];
    
    if ($tableExists) {
        // Get table structure
        $stmt = $pdo->query("DESCRIBE reviews");
        $columns = $stmt->fetchAll();
        $result['table_structure'] = $columns;
        
        // Get row count
        $stmt = $pdo->query("SELECT COUNT(*) as count FROM reviews");
        $count = $stmt->fetch();
        $result['row_count'] = $count['count'];
    } else {
        // Provide CREATE TABLE statement
        $result['create_table_sql'] = "
CREATE TABLE reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    order_id INT NULL,
    product_id INT NULL,
    vendor_id INT NULL,
    delivery_agent_id INT NULL,
    review_type ENUM('product', 'vendor', 'delivery') NOT NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(255) NULL,
    comment TEXT NULL,
    images TEXT NULL,
    is_verified_purchase BOOLEAN DEFAULT FALSE,
    is_approved BOOLEAN DEFAULT TRUE,
    admin_reply TEXT NULL,
    replied_at TIMESTAMP NULL,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_product_id (product_id),
    INDEX idx_vendor_id (vendor_id),
    INDEX idx_review_type (review_type),
    INDEX idx_rating (rating),
    INDEX idx_created_at (created_at)
);";
    }
    
    echo json_encode($result, JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>