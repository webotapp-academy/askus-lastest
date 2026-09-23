<?php
require_once __DIR__ . '/../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST' && $_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    jsonResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}

try {
    $vendor = requireVendor();
    $vendorId = $vendor['id'];

    $pdo = getDBConnection();

    // Soft delete vendor and set status to inactive
    $stmt = $pdo->prepare("
        UPDATE vendors 
        SET status = 'inactive', 
            deleted_at = NOW(), 
            updated_at = NOW() 
        WHERE id = ? AND deleted_at IS NULL
    ");
    $stmt->execute([$vendorId]);

    if ($stmt->rowCount() > 0) {
        jsonResponse([
            'success' => true,
            'message' => 'Vendor account has been successfully deactivated and removed from listings.'
        ]);
    } else {
        jsonResponse([
            'success' => false,
            'message' => 'Vendor account not found or already deactivated.'
        ], 404);
    }

} catch (Exception $e) {
    error_log("Error deactivating vendor: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Failed to deactivate vendor account'], 500);
}
