<?php
// Test payment creation with authentication
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/config.php';

echo "Testing payment creation endpoint...\n\n";

// Test 1: Check if we can get an authenticated user
echo "Step 1: Testing authentication...\n";
try {
    // You need to provide a valid auth token here
    // Get it from your Flutter app's secure storage or login response
    $_SERVER['HTTP_AUTHORIZATION'] = 'Bearer YOUR_AUTH_TOKEN_HERE'; // Replace with actual token
    
    $user = getAuthUser();
    if ($user) {
        echo "✅ User authenticated: ID=" . $user['id'] . ", Role=" . ($user['role'] ?? 'unknown') . "\n";
        
        // Test 2: Try to create payment
        echo "\nStep 2: Creating payment order...\n";
        
        $vendorId = $user['id'];
        $amount = 1179;
        
        echo "Vendor ID: $vendorId\n";
        echo "Amount: $amount\n";
        
        // Check Razorpay config
        if (!defined('RAZORPAY_KEY_ID')) {
            echo "❌ RAZORPAY_KEY_ID not defined\n";
            exit;
        }
        
        echo "✅ Razorpay Key: " . RAZORPAY_KEY_ID . "\n";
        
        // Try to create payment record
        $pdo = getDBConnection();
        $razorpayOrderId = 'test_vendor_reg_' . $vendorId . '_' . time();
        $uuid = generateUUID();
        
        echo "\nStep 3: Inserting payment record...\n";
        echo "UUID: $uuid\n";
        echo "Order ID: $razorpayOrderId\n";
        
        $stmt = $pdo->prepare("INSERT INTO payments 
            (uuid, user_id, amount, currency, payment_method, razorpay_order_id, status, created_at, updated_at) 
            VALUES (?, ?, ?, 'INR', 'razorpay', ?, 'pending', NOW(), NOW())");
        
        $result = $stmt->execute([$uuid, $vendorId, $amount, $razorpayOrderId]);
        
        if ($result) {
            $paymentId = $pdo->lastInsertId();
            echo "✅ Payment record created: ID=$paymentId\n";
            
            // Prepare response like the actual API
            $response = [
                'success' => true,
                'payment_id' => $paymentId,
                'order_id' => $razorpayOrderId,
                'razorpay_key' => RAZORPAY_KEY_ID,
                'amount' => $amount * 100,
                'currency' => 'INR',
                'prefill' => [
                    'name' => $user['name'] ?? $user['owner_name'] ?? 'Vendor',
                    'email' => $user['email'] ?? '',
                    'contact' => $user['phone'] ?? '',
                ]
            ];
            
            echo "\nStep 4: API Response:\n";
            echo json_encode($response, JSON_PRETTY_PRINT);
            
        } else {
            echo "❌ Failed to create payment record\n";
            print_r($stmt->errorInfo());
        }
        
    } else {
        echo "❌ Authentication failed - no user found\n";
        echo "Note: You need to provide a valid Bearer token in the Authorization header\n";
    }
    
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString();
}
?>