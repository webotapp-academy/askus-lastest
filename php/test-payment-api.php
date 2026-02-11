<?php
// Simple test script to debug payment API
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Log all incoming data
error_log("=== PAYMENT API TEST ===");
error_log("Method: " . $_SERVER['REQUEST_METHOD']);
error_log("Headers: " . json_encode(getallheaders()));
error_log("Raw input: " . file_get_contents('php://input'));
error_log("POST data: " . json_encode($_POST));

try {
    // Test 1: Check if config.php exists and loads
    if (!file_exists(__DIR__ . '/config.php')) {
        throw new Exception("config.php not found");
    }
    
    require_once __DIR__ . '/config.php';
    echo json_encode(['step' => 1, 'status' => 'Config loaded successfully']);
    
} catch (Exception $e) {
    error_log("Error: " . $e->getMessage());
    echo json_encode([
        'success' => false, 
        'error' => $e->getMessage(),
        'step' => 'config_load_failed'
    ]);
    exit;
}

try {
    // Test 2: Check Razorpay constants
    if (!defined('RAZORPAY_KEY_ID')) {
        throw new Exception("RAZORPAY_KEY_ID not defined in config.php");
    }
    
    echo json_encode([
        'step' => 2, 
        'status' => 'Razorpay key found',
        'key' => RAZORPAY_KEY_ID
    ]);
    
} catch (Exception $e) {
    error_log("Razorpay error: " . $e->getMessage());
    echo json_encode([
        'success' => false, 
        'error' => $e->getMessage(),
        'step' => 'razorpay_config_failed'
    ]);
    exit;
}

try {
    // Test 3: Check database connection
    $pdo = getDBConnection();
    echo json_encode(['step' => 3, 'status' => 'Database connected']);
    
} catch (Exception $e) {
    error_log("Database error: " . $e->getMessage());
    echo json_encode([
        'success' => false, 
        'error' => $e->getMessage(),
        'step' => 'database_failed'
    ]);
    exit;
}

try {
    // Test 4: Check authentication
    $user = getAuthUser();
    if (!$user) {
        throw new Exception("No authenticated user found");
    }
    
    echo json_encode([
        'step' => 4, 
        'status' => 'User authenticated',
        'user_id' => $user['id'],
        'role' => $user['role'] ?? 'unknown'
    ]);
    
} catch (Exception $e) {
    error_log("Auth error: " . $e->getMessage());
    echo json_encode([
        'success' => false, 
        'error' => $e->getMessage(),
        'step' => 'auth_failed',
        'note' => 'This is expected if no auth token provided'
    ]);
    exit;
}

// If we get here, everything is working
echo json_encode([
    'success' => true,
    'message' => 'All tests passed',
    'ready_for_payment' => true
]);
?>