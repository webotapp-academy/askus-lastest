<?php
require_once __DIR__ . '/../config.php';

// Enable detailed error logging
error_log("=== PAYMENT VERIFY START ===");

// Get authenticated user
try {
    $user = requireAuth();
    error_log("✅ User authenticated: ID=" . $user['id']);
} catch (Exception $e) {
    error_log("❌ Auth failed: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Authentication failed'], 401);
}

$input = getInput();
error_log("📥 Input received: " . json_encode($input));

// Validate required fields
$razorpayPaymentId = $input['razorpay_payment_id'] ?? '';
$razorpayOrderId = $input['razorpay_order_id'] ?? '';
$razorpaySignature = $input['razorpay_signature'] ?? '';

error_log("💳 Payment ID: $razorpayPaymentId");
error_log("📋 Order ID: $razorpayOrderId");
error_log("🔐 Signature: " . substr($razorpaySignature, 0, 20) . "...");

if (empty($razorpayPaymentId) || empty($razorpayOrderId) || empty($razorpaySignature)) {
    error_log("❌ Missing payment details");
    jsonResponse(['success' => false, 'message' => 'Payment details required'], 400);
}

try {
    $pdo = getDBConnection();
    error_log("✅ Database connected");
} catch (Exception $e) {
    error_log("❌ Database connection failed: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Database connection failed'], 500);
}

// Find the payment record
$stmt = $pdo->prepare("SELECT * FROM payments WHERE razorpay_order_id = ?");
$stmt->execute([$razorpayOrderId]);
$payment = $stmt->fetch();

if (!$payment) {
    error_log("❌ Payment record not found for order: $razorpayOrderId");
    jsonResponse(['success' => false, 'message' => 'Payment record not found'], 404);
}

error_log("📋 Payment record found: ID=" . $payment['id'] . ", Status=" . $payment['status']);

// Check if user is authorized to verify this payment
if ($user['id'] != $payment['user_id'] && ($user['role'] ?? '') !== 'admin') {
    error_log("❌ Unauthorized: User ID " . $user['id'] . " cannot verify payment for user " . $payment['user_id']);
    jsonResponse(['success' => false, 'message' => 'Unauthorized'], 403);
}

// Check if payment is already processed
if ($payment['status'] !== 'pending') {
    error_log("⚠️ Payment already processed with status: " . $payment['status']);
    jsonResponse([
        'success' => true, 
        'message' => 'Payment already processed',
        'payment' => [
            'id' => $payment['id'],
            'status' => $payment['status']
        ]
    ]);
}

// 🚨 CRITICAL: Verify signature with Razorpay
error_log("🔐 Verifying Razorpay signature...");

if (!defined('RAZORPAY_KEY_SECRET')) {
    error_log("❌ RAZORPAY_KEY_SECRET not defined");
    jsonResponse(['success' => false, 'message' => 'Payment configuration error'], 500);
}

// Create the signature that Razorpay should have created
$signatureData = $razorpayOrderId . '|' . $razorpayPaymentId;
$expectedSignature = hash_hmac('sha256', $signatureData, RAZORPAY_KEY_SECRET);

error_log("📋 Signature Verification:");
error_log("   Expected: $expectedSignature");
error_log("   Received: $razorpaySignature");
error_log("   Match: " . (hash_equals($expectedSignature, $razorpaySignature) ? "✅ YES" : "❌ NO"));

if (!hash_equals($expectedSignature, $razorpaySignature)) {
    error_log("❌ SIGNATURE VERIFICATION FAILED - Payment is fraudulent or tampered!");
    jsonResponse(['success' => false, 'message' => 'Payment verification failed: Invalid signature'], 400);
}

error_log("✅ Signature verified successfully");

try {
    $pdo->beginTransaction();
    error_log("🔄 Transaction started");

    // Update payment record
    $stmt = $pdo->prepare("UPDATE payments SET 
        razorpay_payment_id = ?, 
        razorpay_signature = ?, 
        status = 'completed', 
        paid_at = NOW(), 
        updated_at = NOW() 
        WHERE id = ?");
    $stmt->execute([$razorpayPaymentId, $razorpaySignature, $payment['id']]);
    error_log("✅ Payment record updated to completed");

    // Update vendor status to approved after successful payment
    $vendorUpdated = false;
    
    // Try updating vendors table first (check with user_id column)
    try {
        error_log("🔍 Attempting to update vendors table with user_id...");
        $stmt = $pdo->prepare("UPDATE vendors SET 
            status = 'approved',
            approved_at = NOW(),
            updated_at = NOW()
            WHERE user_id = ?");
        $result = $stmt->execute([$payment['user_id']]);
        if ($stmt->rowCount() > 0) {
            $vendorUpdated = true;
            error_log("✅ Vendor status updated via user_id (rows affected: " . $stmt->rowCount() . ")");
        } else {
            error_log("⚠️ No vendor found with user_id: " . $payment['user_id']);
        }
    } catch (Exception $e) {
        error_log("⚠️ Vendors table update via user_id failed: " . $e->getMessage());
    }
    
    // If that didn't work, try with id column
    if (!$vendorUpdated) {
        try {
            error_log("🔍 Attempting to update vendors table with id...");
            $stmt = $pdo->prepare("UPDATE vendors SET 
                status = 'approved',
                approved_at = NOW(),
                updated_at = NOW()
                WHERE id = ?");
            $result = $stmt->execute([$payment['user_id']]);
            if ($stmt->rowCount() > 0) {
                $vendorUpdated = true;
                error_log("✅ Vendor status updated via id (rows affected: " . $stmt->rowCount() . ")");
            }
        } catch (Exception $e) {
            error_log("⚠️ Vendors table update via id failed: " . $e->getMessage());
        }
    }
    
    // If vendor table update failed, try users table
    if (!$vendorUpdated) {
        try {
            error_log("🔍 Attempting to update users table...");
            // Check if approved_at column exists
            $stmt = $pdo->prepare("SHOW COLUMNS FROM users LIKE 'approved_at'");
            $stmt->execute();
            $hasApprovedAt = $stmt->fetch();
            
            if ($hasApprovedAt) {
                $stmt = $pdo->prepare("UPDATE users SET 
                    status = 'approved',
                    approved_at = NOW(),
                    updated_at = NOW()
                    WHERE id = ?");
            } else {
                $stmt = $pdo->prepare("UPDATE users SET 
                    status = 'approved',
                    updated_at = NOW()
                    WHERE id = ?");
            }
            $stmt->execute([$payment['user_id']]);
            if ($stmt->rowCount() > 0) {
                error_log("✅ User status updated (rows affected: " . $stmt->rowCount() . ")");
            } else {
                error_log("⚠️ No user found with id: " . $payment['user_id']);
            }
        } catch (Exception $e) {
            error_log("⚠️ Users table update failed: " . $e->getMessage());
        }
    }

    $pdo->commit();
    error_log("✅ Transaction committed");

    $response = [
        'success' => true,
        'message' => 'Payment verified and vendor approved successfully',
        'payment' => [
            'id' => $payment['id'],
            'amount' => floatval($payment['amount']),
            'status' => 'completed',
            'paid_at' => date('Y-m-d H:i:s')
        ],
        'vendor_status' => 'approved'
    ];

    error_log("✅ Payment verified successfully");
    error_log("📤 Response: " . json_encode($response));
    jsonResponse($response);

} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
        error_log("🔄 Transaction rolled back");
    }
    error_log("❌ Vendor payment verification error: " . $e->getMessage());
    error_log("📍 Stack trace: " . $e->getTraceAsString());
    jsonResponse(['success' => false, 'message' => 'Payment verification failed: ' . $e->getMessage()], 500);
}

error_log("=== PAYMENT VERIFY END ===");
?>
