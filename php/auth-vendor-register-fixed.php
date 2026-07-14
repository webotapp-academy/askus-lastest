<?php
require_once __DIR__ . '/../config.php';

error_log("=== VENDOR REGISTRATION START ===");

$input = getInput();
error_log("📥 Input received: " . json_encode($input));

// Validate required fields
$required = ['owner_name', 'email', 'phone', 'password', 'store_name', 'address', 'city', 'state', 'pincode', 'vendor_type'];
foreach ($required as $field) {
    if (empty($input[$field])) {
        error_log("❌ Missing required field: $field");
        jsonResponse(['success' => false, 'message' => "Missing required field: $field"], 400);
    }
}

$ownerName = trim($input['owner_name']);
$email = trim(strtolower($input['email']));
$phone = trim($input['phone']);
$password = $input['password'];
$storeName = trim($input['store_name']);
$address = trim($input['address']);
$city = trim($input['city']);
$state = trim($input['state']);
$pincode = trim($input['pincode']);
$vendorType = trim(strtolower($input['vendor_type']));
$gstNumber = $input['gst_number'] ?? null;
$panNumber = $input['pan_number'] ?? null;
$storeDescription = $input['store_description'] ?? null;

if (!in_array($vendorType, ['vendor', 'worker'])) {
    error_log("❌ Invalid vendor_type: $vendorType");
    jsonResponse(['success' => false, 'message' => "Invalid vendor_type, must be 'vendor' or 'worker'"], 400);
}

// Validate email format
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    error_log("❌ Invalid email format: $email");
    jsonResponse(['success' => false, 'message' => 'Invalid email format'], 400);
}

// Validate phone number (should be 10 digits)
if (!preg_match('/^\d{10}$/', $phone)) {
    error_log("❌ Invalid phone number: $phone");
    jsonResponse(['success' => false, 'message' => 'Phone number must be 10 digits'], 400);
}

try {
    $pdo = getDBConnection();
    error_log("✅ Database connected");

    // Check if email already exists in users table
    $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ? AND deleted_at IS NULL");
    $stmt->execute([$email]);
    if ($stmt->fetch()) {
        error_log("❌ Email already exists: $email");
        jsonResponse(['success' => false, 'message' => 'Email already registered'], 409);
    }

    // Check if phone already exists in users table
    $stmt = $pdo->prepare("SELECT id FROM users WHERE phone = ? AND deleted_at IS NULL");
    $stmt->execute([$phone]);
    if ($stmt->fetch()) {
        error_log("❌ Phone already exists: $phone");
        jsonResponse(['success' => false, 'message' => 'Phone number already registered'], 409);
    }

    // Check if email already exists in vendors table
    $stmt = $pdo->prepare("SELECT id FROM vendors WHERE email = ? AND deleted_at IS NULL");
    $stmt->execute([$email]);
    if ($stmt->fetch()) {
        error_log("❌ Vendor email already exists: $email");
        jsonResponse(['success' => false, 'message' => 'Vendor email already registered'], 409);
    }

    $pdo->beginTransaction();
    error_log("🔄 Transaction started");

    // Hash password
    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
    error_log("🔐 Password hashed");

    // 1. Create user record first (this is crucial for foreign key)
    $userUuid = generateUUID();
    $stmt = $pdo->prepare("INSERT INTO users 
        (uuid, name, email, phone, password, status, created_at, updated_at) 
        VALUES (?, ?, ?, ?, ?, 'pending', NOW(), NOW())");
    $stmt->execute([$userUuid, $ownerName, $email, $phone, $hashedPassword]);
    $userId = $pdo->lastInsertId();
    error_log("✅ User created: ID=$userId");

    // 2. Create vendor record linked to user
    $vendorUuid = generateUUID();
    $stmt = $pdo->prepare("INSERT INTO vendors 
        (uuid, user_id, vendor_type, owner_name, email, phone, password, store_name, store_slug, address, city, state, pincode, gst_number, pan_number, store_description, status, rating, total_reviews, total_orders, created_at, updated_at) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', 0.00, 0, 0, NOW(), NOW())");

    $storeSlug = createSlug($storeName);

    $stmt->execute([
        $vendorUuid,
        $userId,
        $vendorType,
        $ownerName,
        $email,
        $phone,
        $hashedPassword,
        $storeName,
        $storeSlug,
        $address,
        $city,
        $state,
        $pincode,
        $gstNumber,
        $panNumber,
        $storeDescription
    ]);
    $vendorId = $pdo->lastInsertId();
    error_log("✅ Vendor created: ID=$vendorId");

    $pdo->commit();
    error_log("✅ Transaction committed");

    // Generate JWT token for the user
    $token = generateToken($userId, 'vendor');
    error_log("🔑 JWT token generated for user ID: $userId");

    // Fetch the created user and vendor data
    $stmt = $pdo->prepare("SELECT u.*, v.store_name, v.store_slug, v.address, v.city, v.state, v.pincode, 
        v.gst_number, v.pan_number, v.store_description, v.rating, v.total_ratings, v.status as vendor_status 
        FROM users u 
        JOIN vendors v ON v.user_id = u.id 
        WHERE u.id = ?");
    $stmt->execute([$userId]);
    $userData = $stmt->fetch();

    $response = [
        'success' => true,
        'message' => 'Vendor registered successfully. Please complete payment to activate your account.',
        'token' => $token,
        'user' => [
            'id' => $userData['id'],
            'uuid' => $userData['uuid'],
            'name' => $userData['name'],
            'email' => $userData['email'],
            'phone' => $userData['phone'],
            'role' => 'vendor', // Role is determined by having a vendor record
            'status' => $userData['status'],
            'vendor_profile' => [
                'store_name' => $userData['store_name'],
                'store_slug' => $userData['store_slug'],
                'address' => $userData['address'],
                'city' => $userData['city'],
                'state' => $userData['state'],
                'pincode' => $userData['pincode'],
                'gst_number' => $userData['gst_number'],
                'pan_number' => $userData['pan_number'],
                'store_description' => $userData['store_description'],
                'rating' => floatval($userData['rating']),
                'total_ratings' => intval($userData['total_ratings']),
                'status' => $userData['vendor_status']
            ]
        ]
    ];

    error_log("✅ Vendor registration successful");
    error_log("📤 Response: " . json_encode($response));
    jsonResponse($response);

} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
        error_log("🔄 Transaction rolled back");
    }
    error_log("❌ Vendor registration error: " . $e->getMessage());
    error_log("📍 Stack trace: " . $e->getTraceAsString());
    jsonResponse(['success' => false, 'message' => 'Registration failed: ' . $e->getMessage()], 500);
}

error_log("=== VENDOR REGISTRATION END ===");
?>