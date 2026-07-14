<?php
require_once __DIR__ . '/../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}

$user = requireAuth();

$input = getInput();
$name = trim($input['name'] ?? '');
$phone = trim($input['phone'] ?? '');

$pdo = getDBConnection();

$updates = [];
$params = [];

if (!empty($name)) {
    $updates[] = "name = ?";
    $params[] = $name;
}

if (!empty($phone)) {
    if (strlen($phone) !== 10 || !ctype_digit($phone)) {
        jsonResponse(['success' => false, 'message' => 'Invalid phone number'], 400);
    }
    
    $stmt = $pdo->prepare("SELECT id FROM users WHERE phone = ? AND id != ? AND deleted_at IS NULL");
    $stmt->execute([$phone, $user['id']]);
    if ($stmt->fetch()) {
        jsonResponse(['success' => false, 'message' => 'Phone number already in use'], 400);
    }
    
    $updates[] = "phone = ?";
    $params[] = $phone;
}

if (empty($updates)) {
    jsonResponse(['success' => false, 'message' => 'No fields to update'], 400);
}

$updates[] = "updated_at = NOW()";
$params[] = $user['id'];

$sql = "UPDATE users SET " . implode(", ", $updates) . " WHERE id = ?";
$stmt = $pdo->prepare($sql);
$stmt->execute($params);

$stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$user['id']]);
$updatedUser = $stmt->fetch();

jsonResponse([
    'success' => true,
    'message' => 'Profile updated successfully',
    'user' => [
        'id' => $updatedUser['id'],
        'uuid' => $updatedUser['uuid'],
        'name' => $updatedUser['name'],
        'email' => $updatedUser['email'],
        'phone' => $updatedUser['phone'],
        'avatar' => $updatedUser['avatar'],
        'role' => $user['role'],
        'status' => $updatedUser['status'],
        'created_at' => $updatedUser['created_at'],
    ]
]);
