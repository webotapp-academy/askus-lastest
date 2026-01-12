<?php
/**
 * Razorpay Diagnostic Test
 * Run this to check if your Razorpay configuration is correct
 * 
 * Usage: php test-razorpay-diagnosis.php
 * Or access via browser: http://your-domain/test-razorpay-diagnosis.php
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "=== RAZORPAY CONFIGURATION DIAGNOSIS ===\n\n";

// Check if config.php exists
$configFile = __DIR__ . '/../config.php';
if (!file_exists($configFile)) {
    echo "❌ config.php not found at: $configFile\n";
    echo "   Please create config.php file\n";
    exit(1);
}

echo "✅ config.php found\n\n";

// Load config
require_once $configFile;

echo "--- Checking Razorpay Constants ---\n";

// Check RAZORPAY_KEY_ID
if (!defined('RAZORPAY_KEY_ID')) {
    echo "❌ RAZORPAY_KEY_ID is NOT defined\n";
    echo "   Add this to config.php:\n";
    echo "   define('RAZORPAY_KEY_ID', 'rzp_test_YOUR_KEY_HERE');\n\n";
    $keyDefined = false;
} else {
    echo "✅ RAZORPAY_KEY_ID is defined\n";
    $keyDefined = true;
}

if ($keyDefined) {
    $keyValue = RAZORPAY_KEY_ID;
    echo "   Value: $keyValue\n";
    
    // Validate key format
    if (empty($keyValue)) {
        echo "   ❌ RAZORPAY_KEY_ID is EMPTY\n";
    } elseif (strpos($keyValue, 'rzp_test_') === 0) {
        echo "   ✅ Valid TEST mode key\n";
    } elseif (strpos($keyValue, 'rzp_live_') === 0) {
        echo "   ✅ Valid LIVE mode key\n";
    } else {
        echo "   ⚠️  WARNING: Key format doesn't match rzp_test_xxx or rzp_live_xxx\n";
        echo "   This will cause 'Something went wrong' error in Razorpay\n";
    }
    echo "\n";
}

// Check RAZORPAY_KEY_SECRET
if (!defined('RAZORPAY_KEY_SECRET')) {
    echo "❌ RAZORPAY_KEY_SECRET is NOT defined\n";
    echo "   Add this to config.php:\n";
    echo "   define('RAZORPAY_KEY_SECRET', 'your_secret_key');\n\n";
    $secretDefined = false;
} else {
    echo "✅ RAZORPAY_KEY_SECRET is defined\n";
    $secretValue = RAZORPAY_KEY_SECRET;
    
    if (empty($secretValue)) {
        echo "   ❌ RAZORPAY_KEY_SECRET is EMPTY\n";
    } else {
        // Don't show full secret, just first few chars
        echo "   Value: " . substr($secretValue, 0, 8) . "...\n";
        echo "   ✅ Secret appears to be set\n";
    }
    echo "\n";
    $secretDefined = true;
}

// Check database connection
echo "--- Checking Database Connection ---\n";
try {
    if (function_exists('getDBConnection')) {
        $pdo = getDBConnection();
        echo "✅ Database connection successful\n\n";
        
        // Check payments table
        echo "--- Checking Payments Table ---\n";
        $stmt = $pdo->query("SHOW TABLES LIKE 'payments'");
        if ($stmt->rowCount() > 0) {
            echo "✅ Payments table exists\n";
            
            // Check table structure
            $stmt = $pdo->query("DESCRIBE payments");
            $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
            
            $requiredColumns = ['id', 'user_id', 'amount', 'razorpay_order_id', 'status'];
            foreach ($requiredColumns as $col) {
                if (in_array($col, $columns)) {
                    echo "   ✅ Column '$col' exists\n";
                } else {
                    echo "   ❌ Column '$col' is MISSING\n";
                }
            }
        } else {
            echo "❌ Payments table does NOT exist\n";
        }
        echo "\n";
        
        // Check vendors table
        echo "--- Checking Vendors Table ---\n";
        $stmt = $pdo->query("SHOW TABLES LIKE 'vendors'");
        if ($stmt->rowCount() > 0) {
            echo "✅ Vendors table exists\n";
            
            $stmt = $pdo->query("DESCRIBE vendors");
            $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
            
            $requiredColumns = ['id', 'owner_name', 'email', 'phone'];
            foreach ($requiredColumns as $col) {
                if (in_array($col, $columns)) {
                    echo "   ✅ Column '$col' exists\n";
                } else {
                    echo "   ❌ Column '$col' is MISSING\n";
                }
            }
        } else {
            echo "❌ Vendors table does NOT exist\n";
        }
        echo "\n";
        
    } else {
        echo "❌ getDBConnection() function not found\n";
        echo "   Check if config.php properly defines this function\n\n";
    }
} catch (Exception $e) {
    echo "❌ Database connection failed: " . $e->getMessage() . "\n\n";
}

// Test Razorpay API (if both key and secret are defined)
if ($keyDefined && $secretDefined && !empty(RAZORPAY_KEY_ID) && !empty(RAZORPAY_KEY_SECRET)) {
    echo "--- Testing Razorpay API ---\n";
    
    // Create a test order
    $testAmount = 100; // ₹1.00 in paise
    $orderId = 'test_' . time();
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://api.razorpay.com/v1/orders');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_USERPWD, RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
        'amount' => $testAmount,
        'currency' => 'INR',
        'receipt' => $orderId,
    ]));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($error) {
        echo "❌ CURL Error: $error\n";
    } elseif ($httpCode === 200 || $httpCode === 201) {
        echo "✅ Razorpay API is accessible\n";
        echo "✅ Test order created successfully\n";
        $data = json_decode($response, true);
        echo "   Order ID: " . ($data['id'] ?? 'N/A') . "\n";
    } elseif ($httpCode === 401) {
        echo "❌ Razorpay Authentication FAILED\n";
        echo "   HTTP Code: $httpCode\n";
        echo "   This means your RAZORPAY_KEY_ID or RAZORPAY_KEY_SECRET is incorrect\n";
        echo "   Response: $response\n";
    } else {
        echo "❌ Razorpay API Error\n";
        echo "   HTTP Code: $httpCode\n";
        echo "   Response: $response\n";
    }
    echo "\n";
}

echo "=== SUMMARY ===\n";

$allGood = true;

if (!$keyDefined || empty(RAZORPAY_KEY_ID)) {
    echo "❌ Fix RAZORPAY_KEY_ID in config.php\n";
    $allGood = false;
}

if (!$secretDefined || empty(RAZORPAY_KEY_SECRET)) {
    echo "❌ Fix RAZORPAY_KEY_SECRET in config.php\n";
    $allGood = false;
}

if ($allGood) {
    echo "✅ All checks passed! Configuration looks good.\n";
    echo "\nIf you're still getting 'Something went wrong' error:\n";
    echo "1. Check server logs for detailed error messages\n";
    echo "2. Verify your Razorpay account is activated\n";
    echo "3. Ensure test mode is enabled on Razorpay dashboard\n";
    echo "4. Check if your Razorpay account has any restrictions\n";
    echo "5. Try using Razorpay's test card: 4111 1111 1111 1111\n";
} else {
    echo "\n❌ Please fix the above issues before testing payments\n";
}

echo "\n=== END OF DIAGNOSIS ===\n";
?>
