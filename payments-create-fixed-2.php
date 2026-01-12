<?php
require_once __DIR__ . '/../config.php';

// Enable detailed error logging
error_log("=== PAYMENT CREATE START ===");

$input = getInput();
error_log("📥 Input received: " . json_encode($input));

$amount = floatval($input['amount'] ?? 1179); // Default vendor registration fee

error_log("💰 Amount: $amount");

if ($amount <= 0) {
    error_log("❌ Invalid amount: $amount");
    jsonResponse(['success' => false, 'message' => 'Invalid amount'], 400);
}

// ✅ FIXED: For vendor registration payment, don't require authentication
// The vendor will be created AFTER payment verification
$isVendorRegistration = ($amount == 1179 || $amount == 1); // Registration fee amounts

if ($isVendorRegistration) {
    error_log("🏪 Vendor registration payment - authentication not required");
    
    // Use temporary ID for vendor registration (shortened for receipt)
    $tempVendorId = 'V' . time();
    $vendorId = $tempVendorId;
    
    // Get vendor data from input for prefill
    $vendorEmail = $input['email'] ?? '';
    $vendorPhone = $input['phone'] ?? '';
    $vendorName = $input['name'] ?? 'Vendor';
    
    error_log("📧 Email: $vendorEmail");
    error_log("📱 Phone: $vendorPhone");
    error_log("👤 Name: $vendorName");
    
} else {
    // For other payments, require authentication
    try {
        $user = requireAuth();
        error_log("✅ User authenticated: ID=" . $user['id']);
        $vendorId = $user['id'];
        $vendorEmail = $user['email'] ?? '';
        $vendorPhone = $user['phone'] ?? '';
        $vendorName = $user['name'] ?? 'User';
    } catch (Exception $e) {
        error_log("❌ Auth failed: " . $e->getMessage());
        jsonResponse(['success' => false, 'message' => 'Authentication failed'], 401);
    }
}

try {
    $pdo = getDBConnection();
    error_log("✅ Database connected");
} catch (Exception $e) {
    error_log("❌ Database connection failed: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Database connection failed'], 500);
}

// Check if RAZORPAY_KEY_ID is defined
if (!defined('RAZORPAY_KEY_ID')) {
    error_log("❌ RAZORPAY_KEY_ID not defined in config.php");
    jsonResponse(['success' => false, 'message' => 'Payment configuration error: Razorpay key not configured'], 500);
}

if (empty(RAZORPAY_KEY_ID)) {
    error_log("❌ RAZORPAY_KEY_ID is empty");
    jsonResponse(['success' => false, 'message' => 'Payment configuration error: Razorpay key is empty'], 500);
}

if (!defined('RAZORPAY_KEY_SECRET')) {
    error_log("❌ RAZORPAY_KEY_SECRET not defined in config.php");
    jsonResponse(['success' => false, 'message' => 'Payment configuration error: Razorpay secret not configured'], 500);
}

if (empty(RAZORPAY_KEY_SECRET)) {
    error_log("❌ RAZORPAY_KEY_SECRET is empty");
    jsonResponse(['success' => false, 'message' => 'Payment configuration error: Razorpay secret is empty'], 500);
}

error_log("✅ Razorpay Key ID found: " . substr(RAZORPAY_KEY_ID, 0, 10) . "...");
error_log("✅ Razorpay Key Secret found: " . substr(RAZORPAY_KEY_SECRET, 0, 5) . "...");

// 🚨 CRITICAL: Create order on Razorpay's servers FIRST
error_log("🌐 Creating order on Razorpay's servers...");

$razorpayOrderId = null;
try {
    // Use Razorpay API to create the order
    $curl = curl_init();
    
    $postFields = [
        'amount' => (int)($amount * 100), // Convert to paise
        'currency' => 'INR',
        'receipt' => 'rcpt_' . substr(md5($vendorId . time()), 0, 30), // Max 40 chars
    ];
    
    error_log("📤 Razorpay API Request: " . json_encode($postFields));
    
    curl_setopt_array($curl, [
        CURLOPT_URL => 'https://api.razorpay.com/v1/orders',
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => http_build_query($postFields),
        CURLOPT_USERPWD => RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/x-www-form-urlencoded',
        ],
        CURLOPT_TIMEOUT => 10,
        CURLOPT_SSL_VERIFYPEER => true,
    ]);
    
    $response = curl_exec($curl);
    $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
    $error = curl_error($curl);
    curl_close($curl);
    
    error_log("📨 Razorpay Response HTTP Code: $httpCode");
    error_log("📨 Razorpay Response: $response");
    
    if ($error) {
        error_log("❌ CURL Error: $error");
        jsonResponse(['success' => false, 'message' => 'Failed to communicate with Razorpay: ' . $error], 500);
    }
    
    if ($httpCode !== 200) {
        error_log("❌ Razorpay API Error - HTTP $httpCode: $response");
        
        if ($httpCode === 401) {
            error_log("❌ Authentication failed - check RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET");
            jsonResponse(['success' => false, 'message' => 'Razorpay authentication failed. Check configuration.'], 401);
        } elseif ($httpCode === 400) {
            error_log("❌ Bad request - invalid parameters");
            $responseData = json_decode($response, true);
            jsonResponse(['success' => false, 'message' => 'Invalid payment parameters: ' . ($responseData['error']['description'] ?? 'Unknown error')], 400);
        }
        
        jsonResponse(['success' => false, 'message' => 'Failed to create order on Razorpay'], 500);
    }
    
    $razorpayResponse = json_decode($response, true);
    
    if (!isset($razorpayResponse['id'])) {
        error_log("❌ No order ID in Razorpay response: $response");
        jsonResponse(['success' => false, 'message' => 'Razorpay response missing order ID'], 500);
    }
    
    $razorpayOrderId = $razorpayResponse['id'];
    error_log("✅ Order created on Razorpay: ID=$razorpayOrderId");
    error_log("📋 Full Razorpay response: " . json_encode($razorpayResponse));
    
} catch (Exception $e) {
    error_log("❌ Exception while creating Razorpay order: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Failed to create payment order: ' . $e->getMessage()], 500);
}

// Generate UUID
if (function_exists('generateUUID')) {
    $uuid = generateUUID();
} else {
    $uuid = sprintf(
        '%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
        mt_rand(0, 0xffff),
        mt_rand(0, 0xffff),
        mt_rand(0, 0xffff),
        mt_rand(0, 0x0fff) | 0x4000,
        mt_rand(0, 0x3fff) | 0x8000,
        mt_rand(0, 0xffff),
        mt_rand(0, 0xffff),
        mt_rand(0, 0xffff)
    );
}
error_log("🆔 Generated UUID: $uuid");

try {
    $pdo->beginTransaction();
    error_log("🔄 Transaction started");

    // For vendor registration, use temporary user_id 0 (will be updated after vendor creation)
    // For authenticated payments, use the actual user_id
    $userIdForPayment = $isVendorRegistration ? 0 : $vendorId;

    error_log("➕ Creating new payment record");
    error_log("👤 User ID: " . $userIdForPayment . ($isVendorRegistration ? ' (temporary - vendor registration)' : ''));
    
    $stmt = $pdo->prepare("INSERT INTO payments 
        (uuid, order_id, user_id, amount, currency, payment_method, razorpay_order_id, status, created_at, updated_at) 
        VALUES (?, NULL, ?, ?, 'INR', 'razorpay', ?, 'pending', NOW(), NOW())");
    $stmt->execute([$uuid, $userIdForPayment, $amount, $razorpayOrderId]);
    $paymentId = $pdo->lastInsertId();
    error_log("✅ Payment created: ID=$paymentId");

    $pdo->commit();
    error_log("✅ Transaction committed");

    $response = [
        'success' => true,
        'payment_id' => $paymentId,
        'order_id' => $razorpayOrderId,
        'razorpay_key' => RAZORPAY_KEY_ID,
        'amount' => $amount * 100, // Convert to paise for Razorpay
        'currency' => 'INR',
        'prefill' => [
            'name' => $vendorName,
            'email' => $vendorEmail,
            'contact' => $vendorPhone,
        ],
        'notes' => [
            'vendor_id' => $vendorId,
            'payment_type' => $isVendorRegistration ? 'vendor_registration' : 'general',
            'description' => $isVendorRegistration ? 'Vendor Registration Fee' : 'Payment'
        ]
    ];

    error_log("✅ Payment order created successfully");
    error_log("📤 Response: " . json_encode($response));
    jsonResponse($response);

} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
        error_log("🔄 Transaction rolled back");
    }
    error_log("❌ Payment creation error: " . $e->getMessage());
    error_log("📍 Stack trace: " . $e->getTraceAsString());
    jsonResponse(['success' => false, 'message' => 'Failed to create payment order: ' . $e->getMessage()], 500);
}

error_log("=== PAYMENT CREATE END ===");
?>
