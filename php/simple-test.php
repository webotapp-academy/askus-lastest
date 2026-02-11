<?php
// Simple test to verify server setup
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$tests = [];

// Test 1: Basic PHP
$tests['php_version'] = phpversion();
$tests['current_time'] = date('Y-m-d H:i:s');

// Test 2: Check if config.php exists
$configPath = __DIR__ . '/config.php';
$tests['config_exists'] = file_exists($configPath);

if ($tests['config_exists']) {
    try {
        require_once $configPath;
        $tests['config_loaded'] = true;
        
        // Test 3: Check Razorpay constants
        $tests['razorpay_key_defined'] = defined('RAZORPAY_KEY_ID');
        if ($tests['razorpay_key_defined']) {
            $tests['razorpay_key'] = RAZORPAY_KEY_ID;
        }
        
        // Test 4: Database connection
        try {
            $pdo = getDBConnection();
            $tests['database_connected'] = true;
            
            // Test 5: Check payments table
            $stmt = $pdo->query("SHOW TABLES LIKE 'payments'");
            $tests['payments_table_exists'] = $stmt->rowCount() > 0;
            
            if ($tests['payments_table_exists']) {
                $stmt = $pdo->query("DESCRIBE payments");
                $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
                $tests['payments_columns'] = $columns;
            }
            
        } catch (Exception $e) {
            $tests['database_error'] = $e->getMessage();
        }
        
    } catch (Exception $e) {
        $tests['config_error'] = $e->getMessage();
    }
}

// Test 6: Check request data
$tests['request_method'] = $_SERVER['REQUEST_METHOD'];
$tests['request_headers'] = getallheaders();
$tests['raw_input'] = file_get_contents('php://input');

echo json_encode([
    'success' => true,
    'message' => 'Server test completed',
    'tests' => $tests,
    'recommendations' => [
        'config_exists' => $tests['config_exists'] ? '✅ Config file found' : '❌ Create config.php',
        'razorpay_key' => ($tests['razorpay_key_defined'] ?? false) ? '✅ Razorpay key configured' : '❌ Add RAZORPAY_KEY_ID to config.php',
        'database' => ($tests['database_connected'] ?? false) ? '✅ Database connected' : '❌ Check database credentials',
        'payments_table' => ($tests['payments_table_exists'] ?? false) ? '✅ Payments table exists' : '❌ Create payments table'
    ]
], JSON_PRETTY_PRINT);
?>