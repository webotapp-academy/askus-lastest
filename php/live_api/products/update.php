<?php
require_once __DIR__ . '/../config.php';

try {
    $vendor = requireApprovedVendor();

    
    $id = intval($_GET['id'] ?? 0);
    if (!$id) {
        jsonResponse(['success' => false, 'message' => 'Product ID required'], 400);
    }
    
    $pdo = getDBConnection();
    
    $stmt = $pdo->prepare("SELECT * FROM products WHERE id = ? AND vendor_id = ? AND deleted_at IS NULL");
    $stmt->execute([$id, $vendor['id']]);
    $product = $stmt->fetch();
    
    if (!$product) {
        jsonResponse(['success' => false, 'message' => 'Product not found'], 404);
    }
    
    $input = getInput();
    $updates = [];
    $params = [];

    // Special handling for prices to prevent 0 values
    if (isset($input['price']) || isset($input['mrp'])) {
        $newMrp = floatval($input['price'] ?? $input['mrp']);
        $updates[] = "mrp = ?";
        $params[] = $newMrp;

        // If selling_price is not provided in update, and current selling_price is 0 or we want it to match MRP
        if (!isset($input['selling_price']) && !isset($input['compare_price'])) {
            $updates[] = "selling_price = ?";
            $params[] = $newMrp;
        }
    }

    // Map other input fields to actual database columns
    $fieldMapping = [
        'name' => 'name',
        'description' => 'description',
        'short_description' => 'short_description',
        'category_id' => 'category_id',
        // mrp handled above
        'compare_price' => 'selling_price',
        'selling_price' => 'selling_price',
        'stock' => 'stock_quantity',
        'stock_quantity' => 'stock_quantity',
        'sku' => 'sku',
        'barcode' => 'barcode',
        'hsn_code' => 'hsn_code',
        'unit' => 'unit',
        'weight' => 'weight',
        'weight_unit' => 'weight_unit',
        'tax_rate' => 'tax_rate',
        'tax_type' => 'tax_type',
        'discount_type' => 'discount_type',
        'discount_value' => 'discount_value',
        'is_returnable' => 'is_returnable',
        'return_days' => 'return_days',
        'is_featured' => 'is_featured',
        'is_bestseller' => 'is_bestseller',
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
    
    $sql = "UPDATE products SET " . implode(", ", $updates) . " WHERE id = ?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    
    jsonResponse([
        'success' => true,
        'message' => 'Product updated successfully'
    ]);
    
} catch (PDOException $e) {
    error_log("Product Update DB Error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Database error: ' . $e->getMessage()], 500);
} catch (Exception $e) {
    error_log("Product Update Error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Error: ' . $e->getMessage()], 500);
}
