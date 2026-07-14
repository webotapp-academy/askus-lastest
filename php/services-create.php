<?php
require_once __DIR__ . '/config.php';

try {
    $user = requireAuth();
    $pdo = getDBConnection();

    // 1. Get vendor details
    $stmt = $pdo->prepare("SELECT id, vendor_type, current_plan_id, plan_expires_at FROM vendors WHERE user_id = ? AND deleted_at IS NULL");
    $stmt->execute([$user['id']]);
    $vendor = $stmt->fetch();

    if (!$vendor) {
        jsonResponse(['success' => false, 'message' => 'Vendor profile not found'], 404);
    }

    // 2. Validate vendor type (Only workers can create services)
    // Actually wait, sometimes vendors can do both? The plan says "Workers can list services only; Vendors can list products only".
    if ($vendor['vendor_type'] !== 'worker' && $vendor['vendor_type'] !== 'both' && $vendor['vendor_type'] !== 'service_provider') {
        // Let's just strictly check for worker if that's what the plan said, but if a vendor types can do it...
        // The implementation plan said: "Workers can list services only; Vendors can list products only (enforced via vendor_type field)"
        if ($vendor['vendor_type'] !== 'worker') {
            jsonResponse(['success' => false, 'message' => 'Your account type (Vendor) cannot create services. You can only list products.'], 403);
        }
    }

    // 3. Check combined listing limit
    $maxListings = 0;
    $hasActivePlan = false;

    if ($vendor['current_plan_id'] && ($vendor['plan_expires_at'] === null || strtotime($vendor['plan_expires_at']) > time())) {
        $stmt = $pdo->prepare("SELECT max_listings FROM subscription_plans WHERE id = ? AND status = 'active'");
        $stmt->execute([$vendor['current_plan_id']]);
        $plan = $stmt->fetch();
        if ($plan) {
            $hasActivePlan = true;
            $maxListings = (int) $plan['max_listings'];
        }
    }

    // Treat anything above 9000 as unlimited
    if ($maxListings > 0 && $maxListings < 9000) {
        // Count active/pending products & services for this vendor
        $stmt = $pdo->prepare("
            SELECT 
                (SELECT COUNT(*) FROM products WHERE vendor_id = ?) +
                (SELECT COUNT(*) FROM services WHERE vendor_id = ?) 
            AS total_listings
        ");
        $stmt->execute([$vendor['id'], $vendor['id']]);
        $totalListings = (int) $stmt->fetchColumn();

        if ($totalListings >= $maxListings) {
            $msg = "Listing limit reached ({$maxListings}). Please upgrade your plan.";
            jsonResponse(['success' => false, 'message' => $msg], 403);
        }
    } else if (!$hasActivePlan) {
        // No active plan means 0 listings allowed
        jsonResponse(['success' => false, 'message' => "You need an active subscription to create listings."], 403);
    }

    // 4. Validate Service Input
    $name = trim($_POST['name'] ?? '');
    $description = trim($_POST['description'] ?? '');
    $categoryId = intval($_POST['category_id'] ?? 0);
    $price = floatval($_POST['price'] ?? 0);
    $duration = trim($_POST['duration'] ?? '');

    if (empty($name) || empty($description) || !$categoryId || $price <= 0) {
        jsonResponse(['success' => false, 'message' => 'Missing or invalid required fields'], 400);
    }

    // 5. Handle Image Uploads
    $imageUrls = [];
    $thumbnail = null;

    if (!empty($_FILES['images']['name'][0])) {
        $uploadDir = __DIR__ . '/../uploads/services/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }

        foreach ($_FILES['images']['tmp_name'] as $key => $tmpName) {
            if ($_FILES['images']['error'][$key] === UPLOAD_ERR_OK) {
                $ext = strtolower(pathinfo($_FILES['images']['name'][$key], PATHINFO_EXTENSION));
                $filename = 'srv_' . time() . '_' . uniqid() . '.' . $ext;
                $destination = $uploadDir . $filename;

                if (move_uploaded_file($tmpName, $destination)) {
                    $url = 'uploads/services/' . $filename;
                    $imageUrls[] = $url;
                    if ($thumbnail === null) {
                        $thumbnail = $url;
                    }
                }
            }
        }
    }

    $imagesJson = json_encode($imageUrls);

    // 6. Insert Service
    $uuid = generateUUID();
    $sql = "INSERT INTO services (
        uuid, vendor_id, category_id, name, description, 
        price, duration, thumbnail, images, 
        status, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', NOW(), NOW())";

    $stmt = $pdo->prepare($sql);
    $result = $stmt->execute([
        $uuid,
        $vendor['id'],
        $categoryId,
        $name,
        $description,
        $price,
        $duration ?: null,
        $thumbnail,
        $imagesJson
    ]);

    if (!$result) {
        throw new Exception("Failed to insert service");
    }

    $serviceId = $pdo->lastInsertId();

    jsonResponse([
        'success' => true,
        'message' => 'Service created successfully and is pending approval',
        'service_id' => $serviceId
    ]);

} catch (Exception $e) {
    error_log("Service create error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Failed to create service'], 500);
}
?>
