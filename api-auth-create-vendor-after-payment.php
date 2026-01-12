<?php
require_once __DIR__ . '/../config.php';

/**
 * NEW ENDPOINT: Create vendor record AFTER successful payment verification
 * This is called only after payment is verified
 */

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}

$input = getInput();

// Get the registration data from request
$owner_name = trim($input['owner_name'] ?? '');
$email = trim($input['email'] ?? '');
$phone = trim($input['phone'] ?? '');
$password = $input['password'] ?? '';
$store_name = trim($input['store_name'] ?? '');
$address = trim($input['address'] ?? '');
$city = trim($input['city'] ?? '');
$state = trim($input['state'] ?? '');
$pincode = trim($input['pincode'] ?? '');
$gst_number = trim($input['gst_number'] ?? '');
$pan_number = trim($input['pan_number'] ?? '');
$payment_id = trim($input['payment_id'] ?? '');

error_log("=== CREATE VENDOR AFTER PAYMENT START ===");
error_log("📋 Creating vendor for email: $email");
error_log("💳 Payment ID: $payment_id");

// Verify payment is completed
if (empty($payment_id)) {
    error_log("❌ No payment ID provided");
    jsonResponse(['success' => false, 'message' => 'Payment ID is required'], 400);
}

$pdo = getDBConnection();

// Verify payment exists and is completed
$stmt = $pdo->prepare("SELECT id, status, amount FROM payments WHERE id = ?");
$stmt->execute([$payment_id]);
$payment = $stmt->fetch();

if (!$payment) {
    error_log("❌ Payment not found: $payment_id");
    jsonResponse(['success' => false, 'message' => 'Payment not found'], 404);
}

if ($payment['status'] !== 'success') {
    error_log("❌ Payment not completed. Status: " . $payment['status']);
    jsonResponse(['success' => false, 'message' => 'Payment has not been completed yet'], 400);
}

error_log("✅ Payment verified: Status=" . $payment['status']);

// Validate all required fields
if (empty($owner_name) || empty($email) || empty($phone) || empty($password) || 
    empty($store_name) || empty($address) || empty($city) || empty($state) || empty($pincode)) {
    error_log("❌ Missing required fields");
    jsonResponse(['success' => false, 'message' => 'All required fields must be filled'], 400);
}

// Check if vendor already exists
$stmt = $pdo->prepare("SELECT id FROM vendors WHERE email = ? AND deleted_at IS NULL");
$stmt->execute([$email]);
if ($stmt->fetch()) {
    error_log("❌ Vendor already exists for email: $email");
    jsonResponse(['success' => false, 'message' => 'Vendor already registered'], 400);
}

try {
    $pdo->beginTransaction();
    error_log("🔄 Transaction started");

    // Generate vendor data
    $uuid = generateUUID();
    $slug = strtolower(preg_replace('/[^a-zA-Z0-9]+/', '-', $store_name)) . '-' . substr(md5(time()), 0, 6);
    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);

    error_log("🆔 Generated UUID: $uuid");
    error_log("📝 Generated slug: $slug");

    // ✅ NOW CREATE THE VENDOR (only after payment verification)
    $stmt = $pdo->prepare("INSERT INTO vendors (uuid, owner_name, email, phone, password, store_name, store_slug, address, city, state, pincode, gst_number, pan_number, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', NOW(), NOW())");
    $stmt->execute([
        $uuid,
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
        $pan_number ?: null
    ]);

    $vendorId = $pdo->lastInsertId();
    error_log("✅ Vendor created: ID=$vendorId, Email=$email, Status=pending");

    // Update payment with vendor_id if your table has this column
    // (optional, depending on your schema)
    $stmt = $pdo->prepare("UPDATE payments SET user_id = ? WHERE id = ?");
    $stmt->execute([$vendorId, $payment_id]);
    error_log("✅ Payment updated with vendor_id");

    // Generate auth token
    $token = generateToken($vendorId, 'vendor');
    error_log("✅ Token generated");

    $pdo->commit();
    error_log("🔄 Transaction committed");

    jsonResponse([
        'success' => true,
        'message' => 'Vendor created successfully after payment verification',
        'token' => $token,
        'user' => [
            'id' => $vendorId,
            'uuid' => $uuid,
            'name' => $owner_name,
            'email' => $email,
            'phone' => $phone,
            'avatar' => null,
            'role' => 'vendor',
            'status' => 'active',
            'vendor_profile' => [
                'store_name' => $store_name,
                'store_slug' => $slug,
                'status' => 'active'
            ],
            'created_at' => date('Y-m-d H:i:s'),
        ]
    ]);

    error_log("=== CREATE VENDOR AFTER PAYMENT END ===");

} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
        error_log("🔄 Transaction rolled back");
    }
    error_log("❌ Error creating vendor: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Failed to create vendor: ' . $e->getMessage()], 500);
}
?>
