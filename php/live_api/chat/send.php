<?php
require_once __DIR__ . '/../config.php';

$user = requireAuth();

$input = getInput();
$threadId = intval($input['thread_id'] ?? 0);
$message = trim($input['message'] ?? '');

if (!$threadId || empty($message)) {
    jsonResponse(['success' => false, 'message' => 'Thread ID and message required'], 400);
}

$pdo = getDBConnection();

$userId = $user['id'];
$userType = $user['role'] === 'vendor' ? 'vendor' : 'user';

$stmt = $pdo->prepare("SELECT id FROM chat_threads WHERE id = ? AND ((user_id = ? AND user_type = ?) OR (other_user_id = ? AND other_user_type = ?))");
$stmt->execute([$threadId, $userId, $userType, $userId, $userType]);
if (!$stmt->fetch()) {
    jsonResponse(['success' => false, 'message' => 'Thread not found'], 404);
}

$uuid = generateUUID();

$stmt = $pdo->prepare("INSERT INTO chat_messages (uuid, thread_id, sender_id, sender_type, message, created_at) VALUES (?, ?, ?, ?, ?, NOW())");
$stmt->execute([$uuid, $threadId, $userId, $userType, $message]);
$messageId = $pdo->lastInsertId();

$pdo->prepare("UPDATE chat_threads SET updated_at = NOW() WHERE id = ?")->execute([$threadId]);

$senderName = $user['role'] === 'vendor' ? $user['store_name'] : $user['name'];

jsonResponse([
    'success' => true,
    'message' => [
        'id' => $messageId,
        'uuid' => $uuid,
        'sender_id' => $userId,
        'sender_type' => $userType,
        'sender_name' => $senderName,
        'message' => $message,
        'is_read' => false,
        'created_at' => date('Y-m-d H:i:s'),
    ]
]);
