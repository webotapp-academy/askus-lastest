<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../../config.php';

function _json($data, $code = 200)
{
    http_response_code($code);
    echo json_encode($data);
    exit;
}

try {
    $pdo = getDBConnection();

    $categoryId = intval($_GET['category_id'] ?? 0);
    if ($categoryId <= 0) {
        _json(['success' => false, 'message' => 'category_id is required'], 400);
    }

    // per-subcategory limit (optional)
    $perLimit = max(1, intval($_GET['per_subcategory_limit'] ?? 50));

    // Build absolute base URL for images
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'] ?? '';
    $scriptDir = dirname($_SERVER['SCRIPT_NAME']);
    $appRoot = preg_replace('#/api.*$#', '', $scriptDir);
    $imagesBase = rtrim($scheme . '://' . $host . $appRoot, '/');

    $makeAbsolute = function ($url) use ($imagesBase) {
        if (empty($url))
            return $url;
        if (preg_match('#^https?://#i', $url))
            return $url;
        if (strpos($url, '/') === 0)
            return $imagesBase . $url;
        return $imagesBase . '/' . ltrim($url, '/');
    };

    // Fetch subcategories for this category
    $subStmt = $pdo->prepare("SELECT id, name FROM subcategories WHERE category_id = :cat AND status = 'active' ORDER BY sort_order ASC, id ASC");
    $subStmt->execute([':cat' => $categoryId]);
    $subcategories = $subStmt->fetchAll(PDO::FETCH_ASSOC);

    // Map subcategory ids to names
    $subMap = [];
    foreach ($subcategories as $sc) {
        $subMap[(int) $sc['id']] = $sc['name'];
    }

    // Fetch services for this category that have images
    $svcSql = "SELECT
                    s.id, s.uuid, s.vendor_id, s.category_id, s.subcategory_id,
                    s.name, s.slug, s.description, s.short_description,
                    s.price_type, s.min_price, s.max_price, s.duration_minutes,
                    s.rating, s.total_reviews, s.is_featured, s.status, s.created_at,
                    (
                      SELECT image_url FROM service_images si
                      WHERE si.service_id = s.id
                      ORDER BY COALESCE(si.sort_order, 9999) ASC, si.id ASC
                      LIMIT 1
                    ) AS thumbnail
                FROM services s
                WHERE s.status = 'active'
                  AND s.category_id = :categoryId
                  AND EXISTS (SELECT 1 FROM service_images si2 WHERE si2.service_id = s.id)
                ORDER BY s.subcategory_id ASC, s.created_at DESC";

    $svcStmt = $pdo->prepare($svcSql);
    $svcStmt->execute([':categoryId' => $categoryId]);
    $services = $svcStmt->fetchAll(PDO::FETCH_ASSOC);

    if (empty($services)) {
        _json(['success' => true, 'subcategories' => [], 'total_services' => 0]);
    }

    // Collect any subcategory IDs used by products so we can resolve their names
    $usedSubIds = [];
    foreach ($services as $s) {
        if (isset($s['subcategory_id']) && $s['subcategory_id'] !== null && $s['subcategory_id'] !== '' && (int) $s['subcategory_id'] !== 0) {
            $usedSubIds[] = (int) $s['subcategory_id'];
        }
    }
    $usedSubIds = array_values(array_unique($usedSubIds));
    if (!empty($usedSubIds)) {
        $missing = array_filter($usedSubIds, function ($id) use ($subMap) {
            return !isset($subMap[$id]); });
        if (!empty($missing)) {
            $place = implode(',', array_fill(0, count($missing), '?'));
            $stm = $pdo->prepare("SELECT id, name FROM subcategories WHERE id IN ($place)");
            foreach (array_values($missing) as $i => $mid) {
                $stm->bindValue($i + 1, $mid, PDO::PARAM_INT);
            }
            $stm->execute();
            $more = $stm->fetchAll(PDO::FETCH_ASSOC);
            foreach ($more as $m) {
                $subMap[(int) $m['id']] = $m['name'];
            }
        }
    }

    // Fetch all images for returned services
    $serviceIds = array_map(function ($s) {
        return (int) $s['id']; }, $services);
    $placeholders = implode(',', array_fill(0, count($serviceIds), '?'));
    $imgSql = "SELECT id, service_id, image_url, sort_order
               FROM service_images
               WHERE service_id IN ($placeholders)
               ORDER BY service_id ASC, COALESCE(sort_order, 9999) ASC, id ASC";
    $imgStmt = $pdo->prepare($imgSql);
    foreach ($serviceIds as $i => $sid) {
        $imgStmt->bindValue($i + 1, $sid, PDO::PARAM_INT);
    }
    $imgStmt->execute();
    $allImages = $imgStmt->fetchAll(PDO::FETCH_ASSOC);

    // Normalize image URLs
    foreach ($allImages as $k => $row) {
        $allImages[$k]['image_url'] = $makeAbsolute($row['image_url']);
    }

    $imagesMap = [];
    foreach ($allImages as $img) {
        $sid = (int) $img['service_id'];
        if (!isset($imagesMap[$sid]))
            $imagesMap[$sid] = [];
        $imagesMap[$sid][] = $img;
    }

    // Group services by subcategory
    $grouped = [];
    foreach ($services as $s) {
        $sid = (int) $s['id'];
        $subId = isset($s['subcategory_id']) && $s['subcategory_id'] !== null ? (int) $s['subcategory_id'] : 0;
        if (!isset($grouped[$subId]))
            $grouped[$subId] = [];

        $svcImages = $imagesMap[$sid] ?? [];
        $thumbnail = $s['thumbnail'] ?? null;
        if (empty($thumbnail) && !empty($svcImages))
            $thumbnail = $svcImages[0]['image_url'];
        $thumbnail = $makeAbsolute($thumbnail);

        $grouped[$subId][] = [
            'id' => $sid,
            'uuid' => $s['uuid'],
            'vendor_id' => (int) $s['vendor_id'],
            'category_id' => (int) $s['category_id'],
            'subcategory_id' => $subId === 0 ? null : $subId,
            'name' => $s['name'],
            'slug' => $s['slug'],
            'description' => $s['description'],
            'short_description' => $s['short_description'],
            'price_type' => $s['price_type'],
            'price' => isset($s['min_price']) ? floatval($s['min_price']) : 0,
            'compare_price' => isset($s['max_price']) ? floatval($s['max_price']) : null,
            'rating' => isset($s['rating']) ? floatval($s['rating']) : 0,
            'total_reviews' => isset($s['total_reviews']) ? (int) $s['total_reviews'] : 0,
            'is_featured' => isset($s['is_featured']) ? (int) $s['is_featured'] : 0,
            'status' => $s['status'],
            'thumbnail' => $thumbnail,
            'images' => $svcImages,
            'created_at' => $s['created_at']
        ];
    }

    $final = [];
    foreach ($grouped as $subId => $svcs) {
        $slice = array_slice($svcs, 0, $perLimit);
        if (empty($slice))
            continue;
        $name = $subId === 0 ? 'Uncategorized' : ($subMap[$subId] ?? 'Uncategorized');
        $final[] = [
            'subcategory_id' => $subId === 0 ? null : $subId,
            'subcategory_name' => $name,
            'services' => $slice,
            'count' => count($svcs)
        ];
    }

    _json([
        'success' => true,
        'category_id' => $categoryId,
        'subcategories' => $final,
        'total_services' => count($services)
    ]);

} catch (Exception $e) {
    error_log('By-category subcategories services error: ' . $e->getMessage());
    _json(['success' => false, 'message' => 'Server error', 'error' => $e->getMessage()], 500);
}
