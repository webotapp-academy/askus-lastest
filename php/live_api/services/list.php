<?php
// Minimal services list API: returns services that have images
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../../config.php';

function _json($data, $code = 200) {
    http_response_code($code);
    echo json_encode($data);
    exit;
}

try {
    $pdo = getDBConnection();

    // pagination
    $page = max(1, intval($_GET['page'] ?? 1));
    $limit = min(100, max(1, intval($_GET['limit'] ?? 20)));
    $offset = ($page - 1) * $limit;

    // simple filters (keep minimal)
    $categoryId = intval($_GET['category_id'] ?? 0);
    $vendorId = intval($_GET['vendor_id'] ?? 0);

    $where = ["s.status = 'active'"];
    $params = [];
    if ($categoryId > 0) {
        $where[] = 's.category_id = :category';
        $params[':category'] = $categoryId;
    }
    if ($vendorId > 0) {
        $where[] = 's.vendor_id = :vendor';
        $params[':vendor'] = $vendorId;
    }
    $whereSql = count($where) ? 'WHERE ' . implode(' AND ', $where) : '';

    // Count distinct services that have at least one image
    $countSql = "SELECT COUNT(DISTINCT s.id) as cnt
                 FROM services s
                 INNER JOIN service_images si ON s.id = si.service_id
                 $whereSql";
    $countStmt = $pdo->prepare($countSql);
    $countStmt->execute($params);
    $total = intval($countStmt->fetchColumn());

    // Fetch services (distinct) that have images
    $sql = "SELECT DISTINCT
                s.id, s.uuid, s.vendor_id, s.category_id, s.subcategory_id,
                s.name, s.slug, s.description, s.short_description,
                s.price_type, s.min_price, s.max_price, s.duration_minutes,
                s.service_area, s.availability, s.rating, s.total_reviews,
                s.is_featured, s.status, s.created_at, s.updated_at
            FROM services s
            INNER JOIN service_images si ON s.id = si.service_id
            $whereSql
            ORDER BY s.is_featured DESC, s.created_at DESC
            LIMIT :limit OFFSET :offset";

    $stmt = $pdo->prepare($sql);
    foreach ($params as $k => $v) {
        $stmt->bindValue($k, $v);
    }
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    $services = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // attach images
    $serviceIds = array_column($services, 'id');
    $images = [];
    if (!empty($serviceIds)) {
        $placeholders = implode(',', array_fill(0, count($serviceIds), '?'));
        $imgSql = "SELECT id, service_id, image_url, sort_order, created_at FROM service_images WHERE service_id IN ($placeholders) ORDER BY sort_order ASC";
        $imgStmt = $pdo->prepare($imgSql);
        $imgStmt->execute($serviceIds);
        $allImages = $imgStmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($allImages as $img) {
            $images[$img['service_id']][] = $img;
        }
    }

    $out = [];
    foreach ($services as $s) {
        $svcImages = $images[$s['id']] ?? [];
        $thumbnail = !empty($svcImages) ? $svcImages[0]['image_url'] : null;
        $out[] = [
            'id' => (int)$s['id'],
            'uuid' => $s['uuid'] ?? null,
            'vendor_id' => (int)$s['vendor_id'],
            'category_id' => $s['category_id'] !== null ? (int)$s['category_id'] : null,
            'subcategory_id' => $s['subcategory_id'] !== null ? (int)$s['subcategory_id'] : null,
            'name' => $s['name'],
            'slug' => $s['slug'],
            'description' => $s['description'],
            'short_description' => $s['short_description'],
                'price_type' => $s['price_type'],
                // Provide `price` and `compare_price` (matches detail endpoint and Flutter expectations)
                'price' => isset($s['min_price']) ? (float)$s['min_price'] : 0,
                'compare_price' => isset($s['max_price']) ? (float)$s['max_price'] : null,
                // legacy fields still available if needed
                'min_price' => isset($s['min_price']) ? (float)$s['min_price'] : null,
                'max_price' => isset($s['max_price']) ? (float)$s['max_price'] : null,
            'rating' => isset($s['rating']) ? (float)$s['rating'] : 0,
            'total_reviews' => isset($s['total_reviews']) ? (int)$s['total_reviews'] : 0,
            'is_featured' => isset($s['is_featured']) ? (int)$s['is_featured'] : 0,
            'status' => $s['status'] ?? null,
            'thumbnail' => $thumbnail,
            'images' => $svcImages,
            'created_at' => $s['created_at'] ?? null,
            'updated_at' => $s['updated_at'] ?? $s['created_at'] ?? null
        ];
    }

    _json([
        'success' => true,
        'message' => 'Services retrieved',
        'data' => $out,
        'services' => $out,
        'pagination' => [
            'page' => $page,
            'limit' => $limit,
            'total' => $total,
            'pages' => $total ? ceil($total / $limit) : 0,
            'has_more' => $page < ($total ? ceil($total / $limit) : 0)
        ]
    ]);

} catch (PDOException $e) {
    error_log('Services list error: ' . $e->getMessage());
    _json(['success' => false, 'message' => 'Database error', 'error' => $e->getMessage()], 500);
} catch (Exception $e) {
    error_log('Services list error: ' . $e->getMessage());
    _json(['success' => false, 'message' => 'Server error', 'error' => $e->getMessage()], 500);
}

?>