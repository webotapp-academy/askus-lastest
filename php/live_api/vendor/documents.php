<?php
require_once __DIR__ . '/../config.php';

try {
    $vendor = requireVendor();
    $pdo = getDBConnection();
    
    $stmt = $pdo->prepare("SELECT * FROM vendor_documents WHERE vendor_id = ? AND deleted_at IS NULL ORDER BY created_at DESC");
    $stmt->execute([$vendor['id']]);
    $documents = $stmt->fetchAll();
    
    jsonResponse([
        'success' => true,
        'documents' => $documents
    ]);
    
} catch (Exception $e) {
    error_log("Vendor documents error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Failed to load documents'], 500);
}
