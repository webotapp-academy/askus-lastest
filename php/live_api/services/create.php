<?php
require_once __DIR__ . '/../config.php';

try {
    $vendor = requireApprovedVendor();
    $pdo = getDBConnection();

    // Fetch vendor subscription details (JOIN with plans to get max_listings)
    $stmt = $pdo->prepare("
        SELECT v.current_plan_id, v.plan_expires_at, sp.max_listings
        FROM vendors v
        LEFT JOIN subscription_plans sp ON v.current_plan_id = sp.id
        WHERE v.id = ?
    ");
    $stmt->execute([$vendor['id']]);
    $vendorData = $stmt->fetch();

    if (!$vendorData['current_plan_id']) {
        jsonResponse(['success' => false, 'message' => 'No active subscription plan found.'], 403);
    }

    if ($vendorData['plan_expires_at'] && strtotime($vendorData['plan_expires_at']) < time()) {
        jsonResponse(['success' => false, 'message' => 'Your subscription plan has expired.'], 403);
    }

    // Check listing limits (Products + Services)
    $pStmt = $pdo->prepare("SELECT COUNT(*) FROM products WHERE vendor_id = ? AND deleted_at IS NULL");
    $pStmt->execute([$vendor['id']]);
    $productCount = $pStmt->fetchColumn();

    $sStmt = $pdo->prepare("SELECT COUNT(*) FROM services WHERE vendor_id = ? AND deleted_at IS NULL");
    $sStmt->execute([$vendor['id']]);
    $serviceCount = $sStmt->fetchColumn();

    if (($productCount + $serviceCount) >= $vendorData['max_listings']) {
        jsonResponse(['success' => false, 'message' => 'Listing limit reached for your current plan. Please upgrade to add more.'], 403);
    }

    $input = getInput();
    
    $name = trim($input['name'] ?? '');
    $description = trim($input['description'] ?? '');
    $shortDescription = trim($input['short_description'] ?? '');
    $categoryId = intval($input['category_id'] ?? 0);
    
    // Service price mapping: frontend sends 'price' as main price
    $minPrice = floatval($input['min_price'] ?? $input['price'] ?? 0);
    $maxPrice = floatval($input['max_price'] ?? $minPrice);
    
    $priceType = trim($input['price_type'] ?? 'fixed');
    $durationMinutes = intval($input['duration'] ?? $input['duration_minutes'] ?? 60);
    $serviceArea = trim($input['service_area'] ?? '');
    $availability = trim($input['availability'] ?? '');
    
    if (empty($name) || empty($description) || !$categoryId || $minPrice <= 0) {
        jsonResponse(['success' => false, 'message' => 'Required fields missing'], 400);
    }
    
    $pdo = getDBConnection();
    $uuid = generateUUID();
    $slug = createSlug($name);
    
    // is_approved = 0 means pending admin approval
    $stmt = $pdo->prepare("INSERT INTO services (uuid, vendor_id, category_id, name, slug, description, short_description, price_type, min_price, max_price, duration_minutes, service_area, availability, status, is_approved, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', 0, NOW(), NOW())");
    $stmt->execute([
        $uuid, 
        $vendor['id'], 
        $categoryId, 
        $name, 
        $slug, 
        $description,
        $shortDescription,
        $priceType,
        $minPrice, 
        $maxPrice,
        $durationMinutes,
        $serviceArea ?: null,
        $availability ?: null
    ]);
    
    $serviceId = $pdo->lastInsertId();
    
    // Handle image uploads
    if (!empty($_FILES['images'])) {
        $count = is_array($_FILES['images']['name']) ? count($_FILES['images']['name']) : 1;
        
        for ($i = 0; $i < $count; $i++) {
            if (is_array($_FILES['images']['name'])) {
                $file = [
                    'name' => $_FILES['images']['name'][$i],
                    'tmp_name' => $_FILES['images']['tmp_name'][$i],
                    'error' => $_FILES['images']['error'][$i],
                ];
            } else {
                $file = $_FILES['images'];
            }
            
            if ($file['error'] === 0) {
                $imageUrl = uploadFile($file, 'services');
                if ($imageUrl) {
                    $pdo->prepare("INSERT INTO service_images (service_id, image_url, sort_order) VALUES (?, ?, ?)")
                        ->execute([$serviceId, $imageUrl, $i]);
                }
            }
        }
    }
    
    jsonResponse([
        'success' => true,
        'id' => $serviceId,
        'message' => 'Service created successfully. It will be visible after admin approval.'
    ]);
    
} catch (PDOException $e) {
    error_log("Service Create DB Error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Database error: ' . $e->getMessage()], 500);
} catch (Exception $e) {
    error_log("Service Create Error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Error: ' . $e->getMessage()], 500);
}
