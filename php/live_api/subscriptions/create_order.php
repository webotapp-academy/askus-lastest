<?php
require_once __DIR__ . '/../config.php';

error_log("=== SUBSCRIPTION ORDER CREATE START ===");

try {
    $user = requireAuth();
    $vendorId = $user['id'];
} catch (Exception $e) {
    jsonResponse(['success' => false, 'message' => 'Authentication failed'], 401);
}

$input = getInput();
if (empty($input['plan_id'])) {
    jsonResponse(['success' => false, 'message' => 'Plan ID required'], 400);
}

$planId = $input['plan_id'];
$pdo = getDBConnection();

$stmt = $pdo->prepare("SELECT * FROM subscription_plans WHERE id = ? AND status = 'active'");
$stmt->execute([$planId]);
$plan = $stmt->fetch();

if (!$plan) {
    jsonResponse(['success' => false, 'message' => 'Invalid subscription plan'], 400);
}

$amount = floatval($plan['price']);

if (!defined('RAZORPAY_KEY_ID') || !defined('RAZORPAY_KEY_SECRET')) {
    jsonResponse(['success' => false, 'message' => 'Payment configuration error'], 500);
}

try {
    $curl = curl_init();
    $postFields = [
        'amount' => (int) ($amount * 100), // Convert to paise
        'currency' => 'INR',
        'receipt' => 'sub_' . $vendorId . '_' . $planId . '_' . time(),
    ];

    curl_setopt_array($curl, [
        CURLOPT_URL => 'https://api.razorpay.com/v1/orders',
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => http_build_query($postFields),
        CURLOPT_USERPWD => RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET,
        CURLOPT_HTTPHEADER => ['Content-Type: application/x-www-form-urlencoded'],
        CURLOPT_TIMEOUT => 10,
        CURLOPT_SSL_VERIFYPEER => true,
    ]);

    $response = curl_exec($curl);
    $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
    $error = curl_error($curl);
    curl_close($curl);

    if ($error || $httpCode !== 200) {
        error_log("Razorpay Order APi error: " . $response);
        jsonResponse(['success' => false, 'message' => 'Failed to create order on Razorpay'], 500);
    }

    $razorpayResponse = json_decode($response, true);

    if (!isset($razorpayResponse['id'])) {
        jsonResponse(['success' => false, 'message' => 'Razorpay response missing order ID'], 500);
    }

    $razorpayOrderId = $razorpayResponse['id'];

    jsonResponse([
        'success' => true,
        'order_id' => $razorpayOrderId,
        'razorpay_key' => RAZORPAY_KEY_ID,
        'amount' => $amount * 100,
        'currency' => 'INR',
        'prefill' => [
            'name' => $user['name'] ?? 'Vendor',
            'email' => $user['email'] ?? '',
            'contact' => $user['phone'] ?? '',
        ]
    ]);
} catch (Exception $e) {
    jsonResponse(['success' => false, 'message' => 'Error: ' . $e->getMessage()], 500);
}
?>