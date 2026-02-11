<?php
require_once __DIR__ . '/../config.php';

error_log("=== PAYMENT VERIFY START ===");

$input = getInput();
error_log("📥 Verify input: " . json_encode($input));

$razorpay_order_id = $input['razorpay_order_id'] ?? '';
$razorpay_payment_id = $input['razorpay_payment_id'] ?? '';
$razorpay_signature = $input['razorpay_signature'] ?? '';

if (empty($razorpay_order_id) || empty($razorpay_payment_id) || empty($razorpay_signature)) {
    error_log("❌ Missing required fields for verification");
    jsonResponse(['success' => false, 'message' => 'Missing required payment verification fields'], 400);
}

$pdo = getDBConnection();

// Find the payment by razorpay_order_id
$stmt = $pdo->prepare("SELECT * FROM payments WHERE razorpay_order_id = ? ORDER BY id DESC LIMIT 1");
$stmt->execute([$razorpay_order_id]);
$payment = $stmt->fetch();

if (!$payment) {
    error_log("❌ Payment not found for order: $razorpay_order_id");
    jsonResponse(['success' => false, 'message' => 'Payment not found'], 404);
}

error_log("✅ Payment found: ID=" . $payment['id'] . ", Amount=" . $payment['amount']);

// ✅ FIXED: Check if this is a vendor registration payment
$isVendorRegistration = ($payment['amount'] == 1179 || $payment['amount'] == 1);

if ($isVendorRegistration) {
    error_log("🏪 Vendor registration payment - authentication not required for verification");
} else {
    // For other payments, require authentication
    try {
        $user = requireAuth();
        error_log("✅ User authenticated: ID=" . $user['id']);
    } catch (Exception $e) {
        error_log("❌ Auth failed: " . $e->getMessage());
        jsonResponse(['success' => false, 'message' => 'Authentication failed'], 401);
    }
}

// Verify signature
$generated_signature = hash_hmac('sha256', $razorpay_order_id . "|" . $razorpay_payment_id, RAZORPAY_KEY_SECRET);

error_log("🔐 Signature verification:");
error_log("   Received: $razorpay_signature");
error_log("   Generated: $generated_signature");

if ($generated_signature !== $razorpay_signature) {
    error_log("❌ Signature mismatch - payment verification failed");
    jsonResponse(['success' => false, 'message' => 'Invalid payment signature'], 400);
}

error_log("✅ Signature verified successfully");

// Update payment status
try {
    error_log("🔄 Attempting to update payment ID: " . $payment['id']);
    error_log("   razorpay_payment_id: $razorpay_payment_id");
    error_log("   razorpay_signature: $razorpay_signature");
    
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $stmt = $pdo->prepare("UPDATE payments SET 
        status = 'success',
        razorpay_payment_id = ?,
        razorpay_signature = ?,
        paid_at = NOW(),
        updated_at = NOW()
        WHERE id = ?");
    
    $result = $stmt->execute([$razorpay_payment_id, $razorpay_signature, $payment['id']]);
    $rowsAffected = $stmt->rowCount();
    
    error_log("✅ Execute result: " . ($result ? "true" : "false"));
    error_log("✅ Rows affected: $rowsAffected");
    
    if ($rowsAffected > 0) {
        error_log("✅ Payment status updated to 'success'");
        
        // Verify the update
        $verifyStmt = $pdo->prepare("SELECT status, razorpay_payment_id FROM payments WHERE id = ?");
        $verifyStmt->execute([$payment['id']]);
        $updatedPayment = $verifyStmt->fetch();
        error_log("✅ Verified payment status: " . json_encode($updatedPayment));
        
        jsonResponse([
            'success' => true,
            'message' => 'Payment verified successfully',
            'payment_id' => $payment['id'],
            'status' => 'success'
        ]);
    } else {
        error_log("⚠️ No rows were updated for payment ID: " . $payment['id']);
        jsonResponse(['success' => false, 'message' => 'Payment not updated - no rows affected'], 500);
    }
    
} catch (PDOException $e) {
    error_log("❌ PDO Error updating payment: " . $e->getMessage());
    error_log("❌ Error code: " . $e->getCode());
    error_log("❌ SQL State: " . $e->errorInfo[0]);
    jsonResponse(['success' => false, 'message' => 'Database error: ' . $e->getMessage()], 500);
} catch (Exception $e) {
    error_log("❌ General Error updating payment: " . $e->getMessage());
    error_log("❌ Stack trace: " . $e->getTraceAsString());
    jsonResponse(['success' => false, 'message' => 'Failed to update payment status: ' . $e->getMessage()], 500);
}

error_log("=== PAYMENT VERIFY END ===");
?>
