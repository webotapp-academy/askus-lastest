<?php
require_once __DIR__ . '/../config.php';

$vendor = requireVendor();

$input = getInput();
$id = intval($input['id'] ?? 0);

if (!$id) {
    jsonResponse(['success' => false, 'message' => 'Service ID required'], 400);
}

$pdo = getDBConnection();

$stmt = $pdo->prepare("SELECT id FROM services WHERE id = ? AND vendor_id = ? AND deleted_at IS NULL");
$stmt->execute([$id, $vendor['id']]);
if (!$stmt->fetch()) {
    jsonResponse(['success' => false, 'message' => 'Service not found'], 404);
}

$stmt = $pdo->prepare("UPDATE services SET deleted_at = NOW() WHERE id = ?");
$stmt->execute([$id]);

jsonResponse(['success' => true, 'message' => 'Service deleted']);
