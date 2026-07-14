<?php
require_once __DIR__ . '/../config.php';

$user = requireAuth();

$input = getInput();
$id = $input['id'] ?? null;
$all = $input['all'] ?? false;

$pdo = getDBConnection();

$userId = $user['id'];
$userType = $user['role'] === 'vendor' ? 'vendor' : 'user';

if ($all) {
    $stmt = $pdo->prepare("UPDATE notifications SET read_at = NOW() WHERE notifiable_id = ? AND notifiable_type = ? AND read_at IS NULL");
    $stmt->execute([$userId, $userType]);
} elseif ($id) {
    $stmt = $pdo->prepare("UPDATE notifications SET read_at = NOW() WHERE id = ? AND notifiable_id = ? AND notifiable_type = ?");
    $stmt->execute([$id, $userId, $userType]);
}

jsonResponse(['success' => true]);
