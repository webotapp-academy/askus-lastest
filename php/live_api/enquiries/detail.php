<?php
require_once __DIR__ . '/../config.php';

$user = requireAuth();

$id = intval($_GET['id'] ?? 0);
if (!$id) {
    jsonResponse(['success' => false, 'message' => 'Enquiry ID required'], 400);
}

$pdo = getDBConnection();

$stmt = $pdo->prepare("
    SELECT e.*, 
           u.name as user_name, u.phone as user_phone,
           v.store_name as vendor_name,
           CASE 
               WHEN e.type = 'product' THEN (SELECT name FROM products WHERE id = e.item_id)
               WHEN e.type = 'service' THEN (SELECT name FROM services WHERE id = e.item_id)
           END as item_name
    FROM enquiries e
    JOIN users u ON e.user_id = u.id
    JOIN vendors v ON e.vendor_id = v.id
    WHERE e.id = ?
");
$stmt->execute([$id]);
$enquiry = $stmt->fetch();

if (!$enquiry) {
    jsonResponse(['success' => false, 'message' => 'Enquiry not found'], 404);
}

if ($user['role'] === 'vendor' && $enquiry['vendor_id'] != $user['id']) {
    jsonResponse(['success' => false, 'message' => 'Access denied'], 403);
}

if ($user['role'] === 'user' && $enquiry['user_id'] != $user['id']) {
    jsonResponse(['success' => false, 'message' => 'Access denied'], 403);
}

jsonResponse([
    'success' => true,
    'enquiry' => $enquiry
]);
