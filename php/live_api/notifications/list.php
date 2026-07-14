<?php
require_once __DIR__ . '/../config.php';

$user = requireAuth();

$pdo = getDBConnection();

$userId = $user['id'];
$userType = $user['role'] === 'vendor' ? 'vendor' : 'user';

$stmt = $pdo->prepare("
    SELECT * FROM notifications 
    WHERE notifiable_id = ? AND notifiable_type = ?
    ORDER BY created_at DESC
    LIMIT 50
");
$stmt->execute([$userId, $userType]);
$notifications = $stmt->fetchAll();

jsonResponse([
    'success' => true,
    'notifications' => $notifications
]);
