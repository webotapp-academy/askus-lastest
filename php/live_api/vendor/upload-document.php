<?php
require_once __DIR__ . '/../config.php';

try {
    $vendor = requireVendor();
    
    $documentType = $_POST['document_type'] ?? '';
    $documentNumber = $_POST['document_number'] ?? '';
    
    if (empty($documentType) || empty($documentNumber)) {
        jsonResponse(['success' => false, 'message' => 'Document type and number are required'], 400);
    }
    
    // Validate document type
    $validTypes = ['pan_card', 'aadhar_card', 'gst_certificate'];
    if (!in_array($documentType, $validTypes)) {
        jsonResponse(['success' => false, 'message' => 'Invalid document type'], 400);
    }
    
    // Check if file uploaded
    if (empty($_FILES['document']) || $_FILES['document']['error'] !== 0) {
        jsonResponse(['success' => false, 'message' => 'Document file is required'], 400);
    }
    
    $pdo = getDBConnection();
    
    // Check if document type already exists for this vendor
    $stmt = $pdo->prepare("SELECT id FROM vendor_documents WHERE vendor_id = ? AND document_type = ? AND deleted_at IS NULL");
    $stmt->execute([$vendor['id'], $documentType]);
    if ($stmt->fetch()) {
        jsonResponse(['success' => false, 'message' => 'This document type is already uploaded. Please wait for verification or contact support.'], 400);
    }
    
    // Upload file
    $documentUrl = uploadFile($_FILES['document'], 'vendor_documents');
    if (!$documentUrl) {
        jsonResponse(['success' => false, 'message' => 'Failed to upload document'], 500);
    }
    
    // Insert document record
    $stmt = $pdo->prepare("INSERT INTO vendor_documents (vendor_id, document_type, document_number, document_url, status, created_at, updated_at) VALUES (?, ?, ?, ?, 'pending', NOW(), NOW())");
    $stmt->execute([$vendor['id'], $documentType, $documentNumber, $documentUrl]);
    
    $documentId = $pdo->lastInsertId();
    
    jsonResponse([
        'success' => true,
        'message' => 'Document uploaded successfully. It will be verified within 24-48 hours.',
        'document' => [
            'id' => $documentId,
            'document_type' => $documentType,
            'document_number' => $documentNumber,
            'document_url' => $documentUrl,
            'status' => 'pending'
        ]
    ]);
    
} catch (PDOException $e) {
    error_log("Document upload DB error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Database error'], 500);
} catch (Exception $e) {
    error_log("Document upload error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Failed to upload document'], 500);
}
