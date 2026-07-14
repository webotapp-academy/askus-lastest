<?php
require_once __DIR__ . '/../config.php';

$user = requireAuth();

$input = getInput();
$code = strtoupper(trim($input['code'] ?? ''));
$amount = floatval($input['amount'] ?? 0);

if (empty($code) || $amount <= 0) {
    jsonResponse(['success' => false, 'message' => 'Coupon code and amount required'], 400);
}

$pdo = getDBConnection();

$stmt = $pdo->prepare("
    SELECT * FROM coupons 
    WHERE code = ? AND status = 'active' AND deleted_at IS NULL
    AND start_date <= NOW() AND end_date >= NOW()
");
$stmt->execute([$code]);
$coupon = $stmt->fetch();

if (!$coupon) {
    jsonResponse(['success' => false, 'message' => 'Invalid or expired coupon'], 400);
}

if ($coupon['min_order_amount'] > 0 && $amount < $coupon['min_order_amount']) {
    jsonResponse(['success' => false, 'message' => "Minimum order amount is ₹{$coupon['min_order_amount']}"], 400);
}

if ($coupon['usage_limit'] > 0) {
    $usageCount = $pdo->prepare("SELECT COUNT(*) FROM coupon_usages WHERE coupon_id = ?");
    $usageCount->execute([$coupon['id']]);
    if ($usageCount->fetchColumn() >= $coupon['usage_limit']) {
        jsonResponse(['success' => false, 'message' => 'Coupon usage limit reached'], 400);
    }
}

$userUsage = $pdo->prepare("SELECT COUNT(*) FROM coupon_usages WHERE coupon_id = ? AND user_id = ?");
$userUsage->execute([$coupon['id'], $user['id']]);
if ($userUsage->fetchColumn() >= $coupon['usage_per_user']) {
    jsonResponse(['success' => false, 'message' => 'You have already used this coupon'], 400);
}

$discount = 0;
if ($coupon['discount_type'] === 'percentage') {
    $discount = ($amount * $coupon['discount_value']) / 100;
    if ($coupon['max_discount'] > 0 && $discount > $coupon['max_discount']) {
        $discount = $coupon['max_discount'];
    }
} else {
    $discount = $coupon['discount_value'];
}

$finalAmount = max(0, $amount - $discount);

jsonResponse([
    'success' => true,
    'coupon' => [
        'id' => $coupon['id'],
        'code' => $coupon['code'],
        'title' => $coupon['title'],
        'discount_type' => $coupon['discount_type'],
        'discount_value' => floatval($coupon['discount_value']),
    ],
    'discount' => $discount,
    'final_amount' => $finalAmount
]);
