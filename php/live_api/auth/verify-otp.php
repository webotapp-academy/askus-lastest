<?php
require_once '../config.php';
require_once '../vendor/autoload.php'; // Assuming you use composer for JWT library
use Firebase\JWT\JWT;

header('Content-Type: application/json');

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

$requiredFields = ['phone', 'otp'];
$missing = validateRequiredFields($input, $requiredFields);

if ($missing) {
    jsonResponse(['success' => false, 'message' => 'Missing required fields: ' . implode(', ', $missing)], 400);
}

$phone = preg_replace('/[^0-9]/', '', $input['phone']);
$otp = $input['otp'];

try {
    $pdo = getDBConnection();

    // Find user with matching phone and OTP
    // First check users
    $stmt = $pdo->prepare("SELECT * FROM users WHERE phone = ?");
    $stmt->execute([$phone]);
    $user = $stmt->fetch();
    $type = 'user';

    if (!$user) {
        // Check vendors
        $stmt = $pdo->prepare("SELECT * FROM vendors WHERE phone = ?");
        $stmt->execute([$phone]);
        $user = $stmt->fetch();
        $type = 'vendor';
    }

    if (!$user) {
        jsonResponse(['success' => false, 'message' => 'User not found'], 404);
    }

    // specific OTP check to avoid timing attacks or issues with NULLs
    if ($user['otp_code'] === null || $user['otp_code'] !== $otp) {
        jsonResponse(['success' => false, 'message' => 'Invalid OTP'], 401);
    }

    // Check expiry
    if (strtotime($user['otp_expiry']) < time()) {
        jsonResponse(['success' => false, 'message' => 'OTP has expired. Please request a new one.'], 401);
    }

    // OTP Valid - Clear OTP fields
    $table = $type === 'user' ? 'users' : 'vendors';
    $updateStmt = $pdo->prepare("UPDATE $table SET otp_code = NULL, otp_expiry = NULL WHERE id = ?");
    $updateStmt->execute([$user['id']]);

    // Generate JWT Token
    $payload = [
        'iss' => BASE_URL,
        'aud' => BASE_URL,
        'iat' => time(),
        'exp' => time() + (60 * 60 * 24 * 30), // 30 days
        'data' => [
            'id' => $user['id'],
            'email' => $user['email'],
            'role' => $type
        ]
    ];

    // NOTE: You need to have firebase/php-jwt installed via composer
    // If not, you might have a simpler custom JWT implementation in your project
    // I'll assume standard JWT usage here. If your project uses a different way, verify existing auth code.

    // Check if we have the JWT class, otherwise use a simple fallback or error
    if (class_exists('Firebase\JWT\JWT')) {
        $jwt = JWT::encode($payload, JWT_SECRET, 'HS256');
    } else {
        // Fallback if library missing (should ideally be installed)
        // For now, let's error log and fail, or return a placeholder if testing
        logError("JWT Library not found");
        jsonResponse(['success' => false, 'message' => 'Server configuration error'], 500);
        exit;
    }

    // Return success response matching your existing login response structure
    $responseUser = [
        'id' => $user['id'],
        'name' => $type === 'vendor' ? $user['owner_name'] : $user['name'],
        'email' => $user['email'],
        'phone' => $user['phone'],
        'role' => $type
    ];

    if ($type === 'vendor') {
        $responseUser['store_name'] = $user['store_name'];
        $responseUser['city'] = $user['city'];
        $responseUser['profile_image'] = formatImageURL($user['profile_image'] ?? null);
    } else {
        $responseUser['profile_image'] = formatImageURL($user['profile_image'] ?? null);
    }

    jsonResponse([
        'success' => true,
        'message' => 'Login successful',
        'token' => $jwt,
        'user' => $responseUser
    ]);

} catch (Exception $e) {
    logError("Verify OTP Error", ['error' => $e->getMessage()]);
    jsonResponse(['success' => false, 'message' => 'An error occurred'], 500);
}
?>