<?php
require_once __DIR__ . '/../config.php';

/**
 * FIXED VENDOR REGISTRATION ENDPOINT
 * This endpoint NOW ONLY VALIDATES the registration data and creates auth user
 * The actual vendor record will be created after payment verification
 */

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}

$input = getInput();

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

// Validation
if (empty($owner_name) || empty($email) || empty($phone) || empty($password) || 
    empty($store_name) || empty($address) || empty($city) || empty($state) || empty($pincode)) {
    jsonResponse(['success' => false, 'message' => 'All required fields must be filled'], 400);
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonResponse(['success' => false, 'message' => 'Invalid email format'], 400);
}

if (strlen($phone) !== 10 || !ctype_digit($phone)) {
    jsonResponse(['success' => false, 'message' => 'Invalid phone number'], 400);
}

if (strlen($password) < 6) {
    jsonResponse(['success' => false, 'message' => 'Password must be at least 6 characters'], 400);
}

$pdo = getDBConnection();

// ⚠️ IMPORTANT: Check in BOTH users and vendors tables
$stmt = $pdo->prepare("SELECT email FROM users WHERE email = ? AND deleted_at IS NULL");
$stmt->execute([$email]);
if ($stmt->fetch()) {
    jsonResponse(['success' => false, 'message' => 'Email already registered'], 400);
}

$stmt = $pdo->prepare("SELECT email FROM vendors WHERE email = ? AND deleted_at IS NULL");
$stmt->execute([$email]);
if ($stmt->fetch()) {
    jsonResponse(['success' => false, 'message' => 'Email already registered as vendor'], 400);
}

// ✅ CHANGED: Don't create vendor here anymore
// Instead, just return success with temporary registration data
// The vendor will be created after payment verification

jsonResponse([
    'success' => true,
    'message' => 'Validation successful. Please proceed to payment.',
    'registration_data' => [
        'owner_name' => $owner_name,
        'email' => $email,
        'phone' => $phone,
        'store_name' => $store_name,
        'address' => $address,
        'city' => $city,
        'state' => $state,
        'pincode' => $pincode,
        'gst_number' => $gst_number ?: null,
        'pan_number' => $pan_number ?: null,
    ]
]);
?>
