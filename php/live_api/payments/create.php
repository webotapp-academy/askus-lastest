<?php
require_once __DIR__ . '/../config.php';

// Enable detailed error logging
error_log("=== PAYMENT CREATE START ===");

$input = getInput();
error_log("📥 Input received: " . json_encode($input));

$amount = floatval($input['amount'] ?? 1179); // Default vendor registration fee
error_log("💰 Amount: $amount");

// Check if this is a vendor registration payment
// It's a registration if it explicitly says so, OR if no token is provided but an email is present
$isRegistrationFlag = isset($input['is_registration']) && ($input['is_registration'] === true || $input['is_registration'] === 1 || $input['is_registration'] === 'true' || $input['is_registration'] === '1');
$email = trim($input['email'] ?? '');

$isVendorRegistration = $isRegistrationFlag || ($amount == 1179 || $amount == 1 || $amount == 499) || (empty($_SERVER['HTTP_AUTHORIZATION']) && !empty($email));

if ($isVendorRegistration) {
    error_log("🏪 Vendor registration payment - authentication NOT required");
    $vendorId = 0; // Temporary vendor ID for registration
} else {
    // For other payments, require authentication
    error_log("🔒 Regular payment - authentication required");
    try {
        $user = requireAuth();
        error_log("✅ User authenticated: ID=" . $user['id']);
        $vendorId = $user['id'];
    } catch (Exception $e) {
        error_log("❌ Auth failed: " . $e->getMessage());
        jsonResponse(['success' => false, 'message' => 'Authentication failed'], 401);
    }
}

if ($amount <= 0) {
    error_log("❌ Invalid amount: $amount");
    jsonResponse(['success' => false, 'message' => 'Invalid amount'], 400);
}

try {
    $pdo = getDBConnection();
    error_log("✅ Database connected");
} catch (Exception $e) {
    error_log("❌ Database connection failed: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Database connection failed'], 500);
}

// For non-registration payments, verify vendor exists
if (!$isVendorRegistration) {
    $stmt = $pdo->prepare("SELECT id, owner_name, email, phone FROM vendors WHERE id = ? AND deleted_at IS NULL");
    $stmt->execute([$vendorId]);
    $vendorData = $stmt->fetch();

    if (!$vendorData) {
        error_log("❌ Vendor ID $vendorId does not exist in vendors table");
        jsonResponse(['success' => false, 'message' => 'Vendor not found. Please complete registration first.'], 404);
    }
    error_log("✅ Vendor exists in database");
    
    // Check for existing pending payments for regular vendors
    $stmt = $pdo->prepare("SELECT * FROM payments WHERE user_id = ? AND status = 'pending' AND amount = ? ORDER BY id DESC LIMIT 1");
    $stmt->execute([$vendorId, $amount]);
    $existingPayment = $stmt->fetch();

    if ($existingPayment) {
        error_log("📋 Existing pending payment found: ID=" . $existingPayment['id']);
    }
} else {
    error_log("✅ Vendor registration - skipping vendor verification");
    
    // For vendor registration, check if payment exists AND vendor was actually created
    // Get email from input to check if vendor exists
    $email = trim($input['email'] ?? '');
    
    if (!empty($email)) {
        // Check if vendor already exists with this email
        $stmt = $pdo->prepare("SELECT id FROM vendors WHERE email = ? AND deleted_at IS NULL");
        $stmt->execute([$email]);
        $existingVendor = $stmt->fetch();
        
        if ($existingVendor) {
            error_log("❌ Vendor already exists for email: $email");
            jsonResponse(['success' => false, 'message' => 'Vendor registration already completed. Please login.'], 400);
        }
        error_log("✅ No existing vendor found for email: $email");
    }
}

// Generate unique order ID
$razorpayOrderId = 'vendor_reg_' . $vendorId . '_' . time();
error_log("🔑 Generated Razorpay Order ID: $razorpayOrderId");

// Generate UUID - check if function exists, otherwise create one
if (function_exists('generateUUID')) {
    $uuid = generateUUID();
} else {
    // Generate UUID v4
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
// This is required before opening the checkout
error_log("🌐 Creating order on Razorpay's servers...");

$razorpayOrderId = null;
try {
    // Use Razorpay API to create the order
    $curl = curl_init();
    
    $postFields = [
        'amount' => (int)($amount * 100), // Convert to paise
        'currency' => 'INR',
        'receipt' => 'vendor_reg_' . $vendorId . '_' . time(),
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

try {
    $pdo->beginTransaction();
    error_log("🔄 Transaction started");

    // If pending payment exists, update it; otherwise create new
    if ($existingPayment && $existingPayment['status'] === 'pending') {
        error_log("🔄 Updating existing pending payment");
        $stmt = $pdo->prepare("UPDATE payments SET 
            amount = ?, 
            razorpay_order_id = ?, 
            updated_at = NOW() 
            WHERE id = ?");
        $stmt->execute([$amount, $razorpayOrderId, $existingPayment['id']]);
        $paymentId = $existingPayment['id'];
        error_log("✅ Payment updated: ID=$paymentId");
    } else {
        error_log("➕ Creating new payment record");
        // Insert new payment record
        // IMPORTANT: user_id has foreign key to users table which will fail
        // You need to either:
        // 1. Remove the foreign key constraint: ALTER TABLE payments DROP FOREIGN KEY payments_ibfk_2;
        // 2. Or set user_id to NULL and add vendor_id column
        
        // Try inserting with vendor ID (this will fail if foreign key exists)
        try {
            $stmt = $pdo->prepare("INSERT INTO payments 
                (uuid, order_id, user_id, amount, currency, payment_method, razorpay_order_id, status, created_at, updated_at) 
                VALUES (?, NULL, ?, ?, 'INR', 'razorpay', ?, 'pending', NOW(), NOW())");
            $stmt->execute([$uuid, $vendorId, $amount, $razorpayOrderId]);
            $paymentId = $pdo->lastInsertId();
            error_log("✅ Payment created: ID=$paymentId");
        } catch (PDOException $e) {
            // If foreign key constraint fails, inform about the fix needed
            if (strpos($e->getMessage(), 'foreign key constraint') !== false || strpos($e->getMessage(), '1452') !== false) {
                error_log("❌ Foreign key constraint error - user_id references users table");
                error_log("💡 Fix: Run this SQL: ALTER TABLE payments DROP FOREIGN KEY payments_ibfk_2;");
                jsonResponse(['success' => false, 'message' => 'Database constraint error. Please contact administrator to remove user_id foreign key from payments table.'], 500);
            }
            throw $e;
        }
    }

    $pdo->commit();
    error_log("✅ Transaction committed");

    // Use vendor data for prefill
    $response = [
        'success' => true,
        'payment_id' => $paymentId,
        'order_id' => $razorpayOrderId,
        'razorpay_key' => RAZORPAY_KEY_ID,
        'amount' => $amount * 100, // Convert to paise for Razorpay
        'currency' => 'INR',
        'prefill' => [
            'name' => $vendorData['owner_name'] ?? 'Vendor',
            'email' => $vendorData['email'] ?? '',
            'contact' => $vendorData['phone'] ?? '',
        ],
        'notes' => [
            'vendor_id' => $vendorId,
            'payment_type' => 'vendor_registration',
            'description' => 'Vendor Registration Fee'
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
    error_log("❌ Vendor payment creation error: " . $e->getMessage());
    error_log("📍 Stack trace: " . $e->getTraceAsString());
    jsonResponse(['success' => false, 'message' => 'Failed to create payment order: ' . $e->getMessage()], 500);
}

error_log("=== PAYMENT CREATE END ===");
?>
