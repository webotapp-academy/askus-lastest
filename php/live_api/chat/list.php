<?php
require_once __DIR__ . '/../config.php';

$user = requireAuth();

$pdo = getDBConnection();

$userId = $user['id'];
$userType = $user['role'] === 'vendor' ? 'vendor' : 'user';

$stmt = $pdo->prepare("
    SELECT ct.*,
           (SELECT cm.message FROM chat_messages cm WHERE cm.thread_id = ct.id ORDER BY cm.created_at DESC LIMIT 1) as last_message,
           (SELECT cm.created_at FROM chat_messages cm WHERE cm.thread_id = ct.id ORDER BY cm.created_at DESC LIMIT 1) as last_message_at,
           (SELECT COUNT(*) FROM chat_messages cm WHERE cm.thread_id = ct.id AND cm.is_read = 0 AND cm.sender_id != ? AND cm.sender_type != ?) as unread_count,
           CASE 
               WHEN ct.user_id = ? AND ct.user_type = ? THEN ct.other_user_name
               ELSE ct.user_name
           END as other_user_name,
           CASE 
               WHEN ct.user_id = ? AND ct.user_type = ? THEN ct.other_user_id
               ELSE ct.user_id
           END as other_user_id
    FROM chat_threads ct
    WHERE (ct.user_id = ? AND ct.user_type = ?) OR (ct.other_user_id = ? AND ct.other_user_type = ?)
    ORDER BY last_message_at DESC
");
$stmt->execute([$userId, $userType, $userId, $userType, $userId, $userType, $userId, $userType, $userId, $userType]);
$threads = $stmt->fetchAll();

jsonResponse([
    'success' => true,
    'threads' => $threads
]);
