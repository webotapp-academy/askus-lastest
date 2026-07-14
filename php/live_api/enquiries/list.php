<?php
require_once __DIR__ . '/../config.php';

$user = requireAuth();

$pdo = getDBConnection();

if ($user['role'] === 'vendor') {
    $stmt = $pdo->prepare("
        SELECT e.*, u.name as user_name, u.phone as user_phone,
               CASE 
                   WHEN e.type = 'product' THEN (SELECT name FROM products WHERE id = e.item_id)
                   WHEN e.type = 'service' THEN (SELECT name FROM services WHERE id = e.item_id)
               END as item_name
        FROM enquiries e
        JOIN users u ON e.user_id = u.id
        WHERE e.vendor_id = ?
        ORDER BY e.created_at DESC
    ");
    $stmt->execute([$user['id']]);
} else {
    $stmt = $pdo->prepare("
        SELECT e.*, v.store_name as vendor_name,
               CASE 
                   WHEN e.type = 'product' THEN (SELECT name FROM products WHERE id = e.item_id)
                   WHEN e.type = 'service' THEN (SELECT name FROM services WHERE id = e.item_id)
               END as item_name
        FROM enquiries e
        JOIN vendors v ON e.vendor_id = v.id
        WHERE e.user_id = ?
        ORDER BY e.created_at DESC
    ");
    $stmt->execute([$user['id']]);
}

$enquiries = $stmt->fetchAll();

jsonResponse([
    'success' => true,
    'enquiries' => $enquiries
]);
