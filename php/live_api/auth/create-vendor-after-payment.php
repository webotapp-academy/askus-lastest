<?php
require_once __DIR__ . '/../config.php';

/**
 * Create vendor record AFTER successful payment verification.
 * Called only after payment is verified.
 *
 * Architecture note (live server):
 *   generateToken($vendorId, 'vendor')
 *   getAuthUser() for vendors → SELECT * FROM vendors WHERE id = token['user_id']
 * So the JWT must encode the VENDOR'S id (vendors.id), NOT a users table id.
 */

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}

$input = getInput();

$owner_name  = trim($input['owner_name'] ?? '');
$email       = trim($input['email'] ?? '');
$phone       = trim($input['phone'] ?? '');
$password    = $input['password'] ?? '';
$store_name  = trim($input['store_name'] ?? '');
$address     = trim($input['address'] ?? '');
$city        = trim($input['city'] ?? '');
$state       = trim($input['state'] ?? '');
$pincode     = trim($input['pincode'] ?? '');
$gst_number  = trim($input['gst_number'] ?? '');
$pan_number  = trim($input['pan_number'] ?? '');
$payment_id  = trim($input['payment_id'] ?? '');
$vendor_type = trim($input['vendor_type'] ?? 'vendor');
$plan_id     = trim($input['plan_id'] ?? '');

error_log("=== CREATE VENDOR AFTER PAYMENT START ===");
error_log("Email: $email | Payment ID: $payment_id | Plan ID: $plan_id");

if (empty($payment_id)) {
    jsonResponse(['success' => false, 'message' => 'Payment ID is required'], 400);
}

$pdo = getDBConnection();

// Fetch plan details
$plan = null;
if (!empty($plan_id)) {
    $stmt = $pdo->prepare("SELECT * FROM subscription_plans WHERE id = ?");
    $stmt->execute([$plan_id]);
    $plan = $stmt->fetch();
    if (!$plan) {
        error_log("Plan not found: $plan_id");
    }
}

// Verify payment exists and is completed
$stmt = $pdo->prepare("SELECT id, status, amount FROM payments WHERE id = ?");
$stmt->execute([$payment_id]);
$payment = $stmt->fetch();

if (!$payment) {
    jsonResponse(['success' => false, 'message' => 'Payment not found'], 404);
}

if ($payment['status'] !== 'success') {
    jsonResponse(['success' => false, 'message' => 'Payment has not been completed yet'], 400);
}

error_log("Payment verified OK: status=" . $payment['status']);

// Validate required fields
if (empty($owner_name) || empty($email) || empty($phone) || empty($password) ||
    empty($store_name) || empty($address) || empty($city) || empty($state) || empty($pincode)) {
    jsonResponse(['success' => false, 'message' => 'All required fields must be filled'], 400);
}

// Check if vendor already exists
$stmt = $pdo->prepare("SELECT id FROM vendors WHERE email = ? AND deleted_at IS NULL");
$stmt->execute([$email]);
if ($stmt->fetch()) {
    error_log("Vendor already exists: $email");
    jsonResponse(['success' => false, 'message' => 'Vendor already registered'], 400);
}

try {
    $pdo->beginTransaction();

    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
    $uuid = generateUUID();
    $slug = createSlug($store_name);

    // Subscription fields
    $planExpiresAt     = null;
    $availableFeatured = 0;
    $availableBoost    = 0;
    $isVerifiedLocal   = 0;

    if ($plan) {
        $planExpiresAt     = date('Y-m-d H:i:s', strtotime("+{$plan['duration_days']} days"));
        $availableFeatured = (int) ($plan['featured_days'] ?? 0);
        $availableBoost    = (int) ($plan['boost_days'] ?? 0);
        $isVerifiedLocal   = (int) (($plan['has_verified_badge'] ?? 0) ? 1 : 0);
    }

    // ✅ CREATE THE VENDOR ROW
    $sql = "INSERT INTO vendors (
        uuid, vendor_type,
        owner_name, email, phone, password,
        store_name, store_slug, address, city, state, pincode,
        gst_number, pan_number,
        current_plan_id, plan_expires_at,
        available_featured_days, available_boost_days, is_verified_local,
        status, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', NOW(), NOW())";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        $uuid,
        $vendor_type,
        $owner_name,
        $email,
        $phone,
        $hashedPassword,
        $store_name,
        $slug,
        $address,
        $city,
        $state,
        $pincode,
        $gst_number ?: null,
        $pan_number ?: null,
        $plan ? (int) $plan['id'] : null,
        $planExpiresAt,
        $availableFeatured,
        $availableBoost,
        $isVerifiedLocal,
    ]);

    $vendorId = (int) $pdo->lastInsertId();
    error_log("Vendor created: ID=$vendorId, Email=$email, Type=$vendor_type, Plan=" . ($plan ? $plan['name'] : 'None'));

    // Record subscription history
    if ($plan) {
        $stmt = $pdo->prepare("
            INSERT INTO vendor_subscriptions
                (vendor_id, plan_id, payment_id, amount_paid, payment_status, start_date, end_date, created_at)
            VALUES (?, ?, ?, ?, 'paid', NOW(), ?, NOW())
        ");
        $stmt->execute([
            $vendorId,
            (int) $plan['id'],
            $payment_id,
            $payment['amount'],
            $planExpiresAt,
        ]);
        error_log("Subscription record created for vendor $vendorId");
    }

    // Update payment with vendor_id
    $stmt = $pdo->prepare("UPDATE payments SET user_id = ? WHERE id = ?");
    $stmt->execute([$vendorId, $payment_id]);

    // ✅ Generate JWT using VENDOR's ID (vendors.id).
    // Live server getAuthUser() for vendors does:
    //   SELECT * FROM vendors WHERE id = token['user_id']
    // So we must pass vendorId here.
    $token = generateToken($vendorId, 'vendor');
    error_log("JWT generated for vendor_id=$vendorId");

    $pdo->commit();
    error_log("Transaction committed");

    $responsePlanId      = $plan ? (int) $plan['id'] : null;
    $responseMaxListings = $plan ? (int) $plan['max_listings'] : 0;

    jsonResponse([
        'success' => true,
        'message' => 'Vendor created successfully after payment verification',
        'token'   => $token,
        'user'    => [
            // ✅ Use vendorId as 'id' so profile.php / getAuthUser() can find this vendor
            'id'         => $vendorId,
            'uuid'       => $uuid,
            'name'       => $owner_name,
            'email'      => $email,
            'phone'      => $phone,
            'avatar'     => null,
            'role'       => 'vendor',
            'status'     => 'pending',
            'vendor_profile' => [
                'id'                      => $vendorId,
                'store_name'              => $store_name,
                'store_slug'              => $slug,
                'address'                 => $address,
                'city'                    => $city,
                'state'                   => $state,
                'pincode'                 => $pincode,
                'status'                  => 'pending',
                'vendor_type'             => $vendor_type,
                'current_plan_id'         => $responsePlanId,
                'max_listings'            => $responseMaxListings,
                'available_featured_days' => $availableFeatured,
                'available_boost_days'    => $availableBoost,
                'is_verified_local'       => (bool) $isVerifiedLocal,
                'plan_expires_at'         => $planExpiresAt,
                'plan' => $plan ? [
                    'id'            => (int) $plan['id'],
                    'name'          => $plan['name'],
                    'price'         => (float) $plan['price'],
                    'duration_days' => (int) $plan['duration_days'],
                    'max_listings'  => $responseMaxListings,
                    'expires_at'    => $planExpiresAt,
                ] : null,
            ],
            'created_at' => date('Y-m-d H:i:s'),
        ],
    ]);

    error_log("=== CREATE VENDOR AFTER PAYMENT END ===");

} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    error_log("Error creating vendor: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Failed to create vendor: ' . $e->getMessage()], 500);
}
