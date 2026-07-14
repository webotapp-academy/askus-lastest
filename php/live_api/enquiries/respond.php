<?php
require_once __DIR__ . '/../config.php';

$vendor = requireVendor();
$input = getInput();

$id = intval($input['id'] ?? 0);
$response = trim($input['response'] ?? '');
$status = trim($input['status'] ?? 'responded');

if (!$id) {
    jsonResponse(['success' => false, 'message' => 'Enquiry ID required'], 400);
}

if (empty($response)) {
    jsonResponse(['success' => false, 'message' => 'Response message required'], 400);
}

$pdo = getDBConnection();

// Check if enquiry belongs to this vendor
$stmt = $pdo->prepare("SELECT * FROM enquiries WHERE id = ? AND vendor_id = ? AND deleted_at IS NULL");
$stmt->execute([$id, $vendor['id']]);
$enquiry = $stmt->fetch();

if (!$enquiry) {
    jsonResponse(['success' => false, 'message' => 'Enquiry not found'], 404);
}

// Update enquiry - status will be 'responded'
$stmt = $pdo->prepare("UPDATE enquiries SET response = ?, status = ?, responded_at = NOW(), updated_at = NOW() WHERE id = ?");
$stmt->execute([$response, $status, $id]);

jsonResponse([
    'success' => true,
    'message' => 'Response sent successfully'
]);
