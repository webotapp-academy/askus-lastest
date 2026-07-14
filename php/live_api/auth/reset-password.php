<?php
require_once '../config.php';

header('Content-Type: application/json');

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

$requiredFields = ['email', 'otp', 'new_password'];
$missing = [];
foreach ($requiredFields as $field) {
    if (empty($input[$field])) {
        $missing[] = $field;
    }
}

if (!empty($missing)) {
    jsonResponse(['success' => false, 'message' => 'Missing required fields: ' . implode(', ', $missing)], 400);
}

$email = trim(strtolower($input['email']));
$otp = trim($input['otp']);
$newPassword = $input['new_password'];

// Validate password length
if (strlen($newPassword) < 8) {
    jsonResponse(['success' => false, 'message' => 'Password must be at least 8 characters long'], 400);
}

try {
    $pdo = getDBConnection();

    // Check users table
    $stmt = $pdo->prepare("SELECT * FROM users WHERE email = ? AND deleted_at IS NULL");
    $stmt->execute([$email]);
    $entity = $stmt->fetch();
    $type = 'user';

    if (!$entity) {
        // Check vendors table
        $stmt = $pdo->prepare("SELECT * FROM vendors WHERE email = ? AND deleted_at IS NULL");
        $stmt->execute([$email]);
        $entity = $stmt->fetch();
        $type = 'vendor';
    }

    if (!$entity) {
        jsonResponse(['success' => false, 'message' => 'User not found'], 404);
    }

    // Verify OTP code matches
    if ($entity['otp_code'] === null || $entity['otp_code'] !== $otp) {
        jsonResponse(['success' => false, 'message' => 'Invalid OTP code'], 401);
    }

    // Check OTP expiry
    if (strtotime($entity['otp_expiry']) < time()) {
        jsonResponse(['success' => false, 'message' => 'OTP has expired. Please request a new one.'], 401);
    }

    // OTP is valid - reset password
    $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);

    $table = $type === 'user' ? 'users' : 'vendors';
    
    $updateStmt = $pdo->prepare("UPDATE $table SET password = ?, otp_code = NULL, otp_expiry = NULL WHERE id = ?");
    $updateStmt->execute([$hashedPassword, $entity['id']]);

    jsonResponse(['success' => true, 'message' => 'Password reset successfully']);

} catch (Exception $e) {
    logError("Reset Password Error", ['error' => $e->getMessage()]);
    jsonResponse(['success' => false, 'message' => 'An error occurred: ' . $e->getMessage()], 500);
}
?>
