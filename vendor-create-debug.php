<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Enable error logging
ini_set('log_errors', 1);
error_log("=== VENDOR PAYMENT CREATE DEBUG ===");

try {
    // Step 1: Load config
    error_log("Step 1: Loading config...");
    require_once __DIR__ . '/../config.php';
    error_log("✅ Config loaded");

    // Step 2: Check Razorpay config
    error_log("Step 2: Checking Razorpay config...");
    if (!defined('RAZORPAY_KEY_ID')) {
        throw new Exception("RAZORPAY_KEY_ID not defined");
    }
    error_log("✅ Razorpay key: " . RAZORPAY_KEY_ID);

    // Step 3: Get input
    error_log("Step 3: Getting input...");
    $rawInput = file_get_contents('php://input');
    error_log("Raw input: " . $rawInput);
    
    $input = json_decode($rawInput, true);
    if (!$input) {
        $input = $_POST;
    }
    error_log("Parsed input: " . json_encode($input));

    // Step 4: Get user
    error_log("Step 4: Getting authenticated user...");
    $user = requireAuth();
    error_log("✅ User authenticated: ID=" . $user['id'] . ", Role=" . ($user['role'] ?? 'unknown'));

    // Step 5: Validate input
    error_log("Step 5: Validating input...");
    $vendorId = intval($input['vendor_id'] ?? $user['id']);
    $amount = floatval($input['amount'] ?? 1179);
    
    error_log("Vendor ID: " . $vendorId);
    error_log("Amount: " . $amount);

    if ($amount <= 0) {
        throw new Exception("Invalid amount: " . $amount);
    }

    // Step 6: Check authorization
    error_log("Step 6: Checking authorization...");
    if ($user['id'] != $vendorId && ($user['role'] ?? '') !== 'admin') {
        throw new Exception("Unauthorized: User ID " . $user['id'] . " cannot create payment for vendor " . $vendorId);
    }
    error_log("✅ Authorization passed");

    // Step 7: Database connection
    error_log("Step 7: Connecting to database...");
    $pdo = getDBConnection();
    error_log("✅ Database connected");

    // Step 8: Check existing payments
    error_log("Step 8: Checking existing payments...");
    $stmt = $pdo->prepare("SELECT * FROM payments WHERE user_id = ? AND amount = ? AND status IN ('pending', 'success')");
    $stmt->execute([$vendorId, $amount]);
    $existingPayment = $stmt->fetch();
    
    if ($existingPayment) {
        error_log("Found existing payment: " . json_encode($existingPayment));
        if ($existingPayment['status'] === 'success') {
            throw new Exception("Vendor registration fee already paid");
        }
    } else {
        error_log("No existing payment found");
    }

    // Step 9: Generate order ID
    error_log("Step 9: Generating order ID...");
    $razorpayOrderId = 'vendor_reg_' . $vendorId . '_' . time();
    $uuid = generateUUID();
    error_log("Order ID: " . $razorpayOrderId);
    error_log("UUID: " . $uuid);

    // Step 10: Create/Update payment
    error_log("Step 10: Creating/updating payment...");
    
    if ($existingPayment && $existingPayment['status'] === 'pending') {
        error_log("Updating existing pending payment...");
        $stmt = $pdo->prepare("UPDATE payments SET 
            amount = ?, 
            razorpay_order_id = ?, 
            updated_at = NOW() 
            WHERE id = ?");
        $stmt->execute([$amount, $razorpayOrderId, $existingPayment['id']]);
        $paymentId = $existingPayment['id'];
        error_log("✅ Updated payment ID: " . $paymentId);
    } else {
        error_log("Creating new payment...");
        $stmt = $pdo->prepare("INSERT INTO payments 
            (uuid, user_id, amount, currency, payment_method, razorpay_order_id, status, created_at, updated_at) 
            VALUES (?, ?, ?, 'INR', 'razorpay', ?, 'pending', NOW(), NOW())");
        $stmt->execute([$uuid, $vendorId, $amount, $razorpayOrderId]);
        $paymentId = $pdo->lastInsertId();
        error_log("✅ Created payment ID: " . $paymentId);
    }

    // Step 11: Get user details
    error_log("Step 11: Getting user details...");
    $userDetails = null;
    
    // Try vendors table first
    try {
        $stmt = $pdo->prepare("SELECT owner_name as name, email, phone FROM vendors WHERE id = ?");
        $stmt->execute([$vendorId]);
        $userDetails = $stmt->fetch();
        if ($userDetails) {
            error_log("Found user in vendors table: " . json_encode($userDetails));
        }
    } catch (Exception $e) {
        error_log("Vendors table query failed: " . $e->getMessage());
    }
    
    // Try users table if not found
    if (!$userDetails) {
        try {
            $stmt = $pdo->prepare("SELECT name, email, phone FROM users WHERE id = ?");
            $stmt->execute([$vendorId]);
            $userDetails = $stmt->fetch();
            if ($userDetails) {
                error_log("Found user in users table: " . json_encode($userDetails));
            }
        } catch (Exception $e) {
            error_log("Users table query failed: " . $e->getMessage());
        }
    }

    // Step 12: Prepare response
    error_log("Step 12: Preparing response...");
    $response = [
        'success' => true,
        'payment_id' => $paymentId,
        'order_id' => $razorpayOrderId,
        'razorpay_key' => RAZORPAY_KEY_ID,
        'amount' => $amount * 100, // Convert to paise
        'currency' => 'INR',
        'prefill' => [
            'name' => $userDetails['name'] ?? $user['name'] ?? $user['owner_name'] ?? 'Vendor',
            'email' => $userDetails['email'] ?? $user['email'] ?? '',
            'contact' => $userDetails['phone'] ?? $user['phone'] ?? '',
        ],
        'notes' => [
            'vendor_id' => $vendorId,
            'payment_type' => 'vendor_registration',
            'description' => 'Vendor Registration Fee'
        ]
    ];

    error_log("✅ Response prepared: " . json_encode($response));
    echo json_encode($response);

} catch (Exception $e) {
    error_log("❌ Error: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());
    
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => $e->getMessage(),
        'debug' => true
    ]);
}
?>