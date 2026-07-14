<?php
require_once __DIR__ . '/../config.php';

try {
    $vendor = requireApprovedVendor();

    
    $id = intval($_GET['id'] ?? 0);
    if (!$id) {
        jsonResponse(['success' => false, 'message' => 'Service ID required'], 400);
    }
    
    $pdo = getDBConnection();
    
    $stmt = $pdo->prepare("SELECT * FROM services WHERE id = ? AND vendor_id = ? AND deleted_at IS NULL");
    $stmt->execute([$id, $vendor['id']]);
    $service = $stmt->fetch();
    
    if (!$service) {
        jsonResponse(['success' => false, 'message' => 'Service not found'], 404);
    }
    
    $input = getInput();
    $updates = [];
    $params = [];

    // Special handling for service prices
    if (isset($input['price']) || isset($input['min_price'])) {
        $newMinPrice = floatval($input['price'] ?? $input['min_price']);
        $updates[] = "min_price = ?";
        $params[] = $newMinPrice;

        // If max_price is not provided, match it to min_price
        if (!isset($input['max_price'])) {
            $updates[] = "max_price = ?";
            $params[] = $newMinPrice;
        }
    }

    // Map input fields to actual database columns
    $fieldMapping = [
        'name' => 'name',
        'description' => 'description',
        'short_description' => 'short_description',
        'category_id' => 'category_id',
        // min_price handled above
        'max_price' => 'max_price',
        'price_type' => 'price_type',
        'duration' => 'duration_minutes',
        'duration_minutes' => 'duration_minutes',
        'service_area' => 'service_area',
        'availability' => 'availability',
        'is_featured' => 'is_featured',
        'status' => 'status'
    ];
    
    foreach ($fieldMapping as $inputField => $dbColumn) {
        if (isset($input[$inputField])) {
            $updates[] = "$dbColumn = ?";
            $params[] = $input[$inputField];
        }
    }
    
    // Update slug if name changed
    if (isset($input['name'])) {
        $updates[] = "slug = ?";
        $params[] = createSlug($input['name']);
    }
    
    if (empty($updates)) {
        jsonResponse(['success' => false, 'message' => 'No fields to update'], 400);
    }
    
    $updates[] = "updated_at = NOW()";
    $params[] = $id;
    
    $sql = "UPDATE services SET " . implode(", ", $updates) . " WHERE id = ?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    
    jsonResponse([
        'success' => true,
        'message' => 'Service updated successfully'
    ]);
    
} catch (PDOException $e) {
    error_log("Service Update DB Error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Database error: ' . $e->getMessage()], 500);
} catch (Exception $e) {
    error_log("Service Update Error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Error: ' . $e->getMessage()], 500);
}
