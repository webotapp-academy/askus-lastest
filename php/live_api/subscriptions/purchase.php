<?php
require_once __DIR__ . '/../config.php';

error_log("=== SUBSCRIPTION PURCHASE START ===");

try {
    $user = requireAuth();
    error_log("✅ User authenticated: ID=" . $user['id']);
} catch (Exception $e) {
    error_log("❌ Auth failed: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Authentication failed'], 401);
}

// Ensure the user actually has a vendor profile
$pdo = getDBConnection();
$stmt = $pdo->prepare("SELECT id, vendor_type, current_plan_id FROM vendors WHERE id = ? AND deleted_at IS NULL");
$stmt->execute([$user['id']]);
$vendor = $stmt->fetch();

if (!$vendor) {
    error_log("❌ User ID {$user['id']} does not have a vendor profile");
    jsonResponse(['success' => false, 'message' => 'Vendor profile not found'], 404);
}

$input = getInput();
error_log("📥 Input received: " . json_encode($input));

// Requires: plan_id, razorpay_payment_id, razorpay_order_id, razorpay_signature
$required = ['plan_id', 'razorpay_payment_id', 'razorpay_order_id', 'razorpay_signature'];
foreach ($required as $field) {
    if (empty($input[$field])) {
        error_log("❌ Missing required field: $field");
        jsonResponse(['success' => false, 'message' => "Payment details required: missing $field"], 400);
    }
}

$planId = $input['plan_id'];
$razorpayPaymentId = $input['razorpay_payment_id'];
$razorpayOrderId = $input['razorpay_order_id'];
$razorpaySignature = $input['razorpay_signature'];

// Fetch the targeted plan
$stmt = $pdo->prepare("SELECT * FROM subscription_plans WHERE id = ? AND status = 'active'");
$stmt->execute([$planId]);
$plan = $stmt->fetch();

if (!$plan) {
    error_log("❌ Invalid or inactive plan ID: $planId");
    jsonResponse(['success' => false, 'message' => 'Invalid subscription plan'], 400);
}

// 🚨 Verify signature with Razorpay
error_log("🔐 Verifying Razorpay signature...");

if (!defined('RAZORPAY_KEY_SECRET')) {
    error_log("❌ RAZORPAY_KEY_SECRET not defined");
    jsonResponse(['success' => false, 'message' => 'Payment configuration error'], 500);
}

// Create the signature that Razorpay should have created
$signatureData = $razorpayOrderId . '|' . $razorpayPaymentId;
$expectedSignature = hash_hmac('sha256', $signatureData, RAZORPAY_KEY_SECRET);

if (!hash_equals($expectedSignature, $razorpaySignature)) {
    error_log("❌ SIGNATURE VERIFICATION FAILED - Payment is fraudulent or tampered!");
    jsonResponse(['success' => false, 'message' => 'Payment verification failed: Invalid signature'], 400);
}

error_log("✅ Signature verified successfully");

try {
    $pdo->beginTransaction();
    error_log("🔄 Transaction started");

    // Insert into vendor_subscriptions
    $stmt = $pdo->prepare("INSERT INTO vendor_subscriptions 
        (vendor_id, plan_id, payment_id, amount_paid, payment_status, start_date, end_date) 
        VALUES (?, ?, ?, ?, 'paid', NOW(), DATE_ADD(NOW(), INTERVAL ? DAY))");

    $stmt->execute([
        $vendor['id'],
        $plan['id'],
        $razorpayPaymentId,
        $plan['price'],
        $plan['duration_days']
    ]);

    // Update the vendor's limits and active plan
    $stmt = $pdo->prepare("UPDATE vendors SET 
        current_plan_id = ?,
        plan_expires_at = DATE_ADD(NOW(), INTERVAL ? DAY),
        available_featured_days = available_featured_days + ?,
        available_boost_days = available_boost_days + ?,
        is_verified_local = CASE WHEN ? = 1 THEN 1 ELSE is_verified_local END,
        updated_at = NOW()
        WHERE id = ?");

    $stmt->execute([
        $plan['id'],
        $plan['duration_days'],
        $plan['featured_days'],
        $plan['boost_days'],
        $plan['has_verified_badge'],
        $vendor['id']
    ]);

    $pdo->commit();
    error_log("✅ Transaction committed");

    jsonResponse([
        'success' => true,
        'message' => 'Subscription activated successfully',
        'data' => [
            'plan_name' => $plan['name'],
            'duration_days' => $plan['duration_days']
        ]
    ]);

} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
        error_log("🔄 Transaction rolled back");
    }
    error_log("❌ Subscription purchase error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Failed to process subscription: ' . $e->getMessage()], 500);
}

error_log("=== SUBSCRIPTION PURCHASE END ===");
?>