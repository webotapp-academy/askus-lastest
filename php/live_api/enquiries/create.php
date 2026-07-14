<?php
require_once __DIR__ . '/../config.php';

$user = requireAuth();

$input = getInput();
$type = $input['type'] ?? 'product';
$itemId = intval($input['item_id'] ?? 0);
$vendorId = intval($input['vendor_id'] ?? 0);
$message = trim($input['message'] ?? '');
$preferredDate = $input['preferred_date'] ?? null;
$preferredTime = $input['preferred_time'] ?? null;

if (!$itemId || !$vendorId || empty($message)) {
    jsonResponse(['success' => false, 'message' => 'Required fields missing'], 400);
}

$pdo = getDBConnection();

$vendorCheck = $pdo->prepare("SELECT id FROM vendors WHERE id = ? AND deleted_at IS NULL");
$vendorCheck->execute([$vendorId]);
if (!$vendorCheck->fetch()) {
    jsonResponse(['success' => false, 'message' => 'Vendor not found'], 404);
}

$uuid = generateUUID();

$stmt = $pdo->prepare("INSERT INTO enquiries (uuid, user_id, vendor_id, type, item_id, message, preferred_date, preferred_time, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending', NOW(), NOW())");
$stmt->execute([$uuid, $user['id'], $vendorId, $type, $itemId, $message, $preferredDate, $preferredTime]);
$enquiryId = $pdo->lastInsertId();

jsonResponse([
    'success' => true,
    'id' => $enquiryId,
    'message' => 'Enquiry sent successfully'
]);
