<?php
// Test if config.php has Razorpay keys
header('Content-Type: application/json');

try {
    require_once __DIR__ . '/config.php';
    
    $result = [
        'config_loaded' => true,
        'razorpay_key_defined' => defined('RAZORPAY_KEY_ID'),
        'razorpay_secret_defined' => defined('RAZORPAY_KEY_SECRET'),
    ];
    
    if (defined('RAZORPAY_KEY_ID')) {
        $result['razorpay_key'] = RAZORPAY_KEY_ID;
    }
    
    // Test database connection
    try {
        $pdo = getDBConnection();
        $result['database_connected'] = true;
        
        // Test payments table
        $stmt = $pdo->query("SELECT COUNT(*) as count FROM payments");
        $count = $stmt->fetch();
        $result['payments_table_accessible'] = true;
        $result['payments_count'] = $count['count'];
        
    } catch (Exception $e) {
        $result['database_error'] = $e->getMessage();
    }
    
    echo json_encode($result, JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'error' => $e->getMessage(),
        'config_loaded' => false
    ], JSON_PRETTY_PRINT);
}
?>