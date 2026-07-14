<?php
require_once __DIR__ . '/../config.php';

$user = requireAuth();

$threadId = intval($_GET['thread_id'] ?? 0);
if (!$threadId) {
    jsonResponse(['success' => false, 'message' => 'Thread ID required'], 400);
}

$pdo = getDBConnection();

$userId = $user['id'];
$userType = $user['role'] === 'vendor' ? 'vendor' : 'user';

$stmt = $pdo->prepare("SELECT id FROM chat_threads WHERE id = ? AND ((user_id = ? AND user_type = ?) OR (other_user_id = ? AND other_user_type = ?))");
$stmt->execute([$threadId, $userId, $userType, $userId, $userType]);
if (!$stmt->fetch()) {
    jsonResponse(['success' => false, 'message' => 'Thread not found'], 404);
}

$pdo->prepare("UPDATE chat_messages SET is_read = 1, read_at = NOW() WHERE thread_id = ? AND sender_id != ? AND sender_type != ? AND is_read = 0")
    ->execute([$threadId, $userId, $userType]);

$stmt = $pdo->prepare("
    SELECT cm.*, 
           CASE 
               WHEN cm.sender_type = 'user' THEN (SELECT name FROM users WHERE id = cm.sender_id)
               WHEN cm.sender_type = 'vendor' THEN (SELECT store_name FROM vendors WHERE id = cm.sender_id)
           END as sender_name
    FROM chat_messages cm
    WHERE cm.thread_id = ?
    ORDER BY cm.created_at ASC
");
$stmt->execute([$threadId]);
$messages = $stmt->fetchAll();

jsonResponse([
    'success' => true,
    'messages' => $messages
]);
