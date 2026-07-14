<?php
require_once __DIR__ . '/../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}

$input = getInput();
$name = trim($input['name'] ?? '');
$email = trim($input['email'] ?? '');
$phone = trim($input['phone'] ?? '');
$password = $input['password'] ?? '';

if (empty($name) || empty($email) || empty($phone) || empty($password)) {
    jsonResponse(['success' => false, 'message' => 'All fields are required'], 400);
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

$stmt = $pdo->prepare("SELECT id FROM users WHERE (email = ? OR phone = ?) AND deleted_at IS NULL");
$stmt->execute([$email, $phone]);
if ($stmt->fetch()) {
    jsonResponse(['success' => false, 'message' => 'Email or phone already registered'], 400);
}

$uuid = generateUUID();
$hashedPassword = password_hash($password, PASSWORD_DEFAULT);

$stmt = $pdo->prepare("INSERT INTO users (uuid, name, email, phone, password, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, 'active', NOW(), NOW())");
$stmt->execute([$uuid, $name, $email, $phone, $hashedPassword]);
$userId = $pdo->lastInsertId();

$token = generateToken($userId, 'user');

jsonResponse([
    'success' => true,
    'token' => $token,
    'user' => [
        'id' => $userId,
        'uuid' => $uuid,
        'name' => $name,
        'email' => $email,
        'phone' => $phone,
        'avatar' => null,
        'role' => 'user',
        'status' => 'active',
        'vendor_profile' => null,
        'created_at' => date('Y-m-d H:i:s'),
    ]
]);
