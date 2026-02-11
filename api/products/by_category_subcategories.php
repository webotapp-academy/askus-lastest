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

function _json($data, $code = 200) {
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
    $scriptDir = dirname($_SERVER['SCRIPT_NAME']); // e.g. /app/askus/api/products
    $appRoot = preg_replace('#/api.*$#', '', $scriptDir);
    $imagesBase = rtrim($scheme . '://' . $host . $appRoot, '/');

    $makeAbsolute = function ($url) use ($imagesBase) {
        if (empty($url)) return $url;
        if (preg_match('#^https?://#i', $url)) return $url;
        if (strpos($url, '/') === 0) return $imagesBase . $url;
        return $imagesBase . '/' . ltrim($url, '/');
    };

    // Fetch subcategories for this category
    $subStmt = $pdo->prepare("SELECT id, name FROM subcategories WHERE category_id = :cat AND status = 'active' ORDER BY sort_order ASC, id ASC");
    $subStmt->execute([':cat' => $categoryId]);
    $subcategories = $subStmt->fetchAll(PDO::FETCH_ASSOC);

    // Map subcategory ids to names
    $subMap = [];
    foreach ($subcategories as $sc) {
        $subMap[(int)$sc['id']] = $sc['name'];
    }

    // Ensure we also resolve names for any subcategory IDs that appear on products
    // (some subcategories may be inactive or not returned above)

    // Fetch products for this category that have images
    $prodSql = "SELECT
                    p.id, p.uuid, p.vendor_id, p.category_id, p.subcategory_id,
                    p.name, p.slug, p.description, p.short_description,
                    p.mrp, p.selling_price, p.stock_quantity, p.sku,
                    p.rating, p.total_reviews, p.is_featured, p.status, p.created_at,
                    (
                      SELECT image_url FROM product_images pi
                      WHERE pi.product_id = p.id
                      ORDER BY pi.is_primary DESC, COALESCE(pi.sort_order, 9999) ASC
                      LIMIT 1
                    ) AS thumbnail
                FROM products p
                WHERE p.status = 'active'
                  AND p.category_id = :categoryId
                  AND EXISTS (SELECT 1 FROM product_images pi2 WHERE pi2.product_id = p.id)
                ORDER BY p.subcategory_id ASC, p.created_at DESC";

    $prodStmt = $pdo->prepare($prodSql);
    $prodStmt->execute([':categoryId' => $categoryId]);
    $products = $prodStmt->fetchAll(PDO::FETCH_ASSOC);

    if (empty($products)) {
        _json(['success' => true, 'subcategories' => [], 'pagination' => ['total_products' => 0]]);
    }

    // Collect any subcategory IDs used by products so we can resolve their names
    $usedSubIds = [];
    foreach ($products as $p) {
        if (isset($p['subcategory_id']) && $p['subcategory_id'] !== null && $p['subcategory_id'] !== '' && (int)$p['subcategory_id'] !== 0) {
            $usedSubIds[] = (int)$p['subcategory_id'];
        }
    }
    $usedSubIds = array_values(array_unique($usedSubIds));
    if (!empty($usedSubIds)) {
        // find any missing ids not present in $subMap
        $missing = array_filter($usedSubIds, function($id) use ($subMap) { return !isset($subMap[$id]); });
        if (!empty($missing)) {
            $place = implode(',', array_fill(0, count($missing), '?'));
            $stm = $pdo->prepare("SELECT id, name FROM subcategories WHERE id IN ($place)");
            foreach (array_values($missing) as $i => $mid) {
                $stm->bindValue($i+1, $mid, PDO::PARAM_INT);
            }
            $stm->execute();
            $more = $stm->fetchAll(PDO::FETCH_ASSOC);
            foreach ($more as $m) {
                $subMap[(int)$m['id']] = $m['name'];
            }
        }
    }

    // Fetch all images for returned products
    $productIds = array_map(function($p) { return (int)$p['id']; }, $products);
    $placeholders = implode(',', array_fill(0, count($productIds), '?'));
    $imgSql = "SELECT id, product_id, image_url, alt_text, sort_order, is_primary
               FROM product_images
               WHERE product_id IN ($placeholders)
               ORDER BY product_id ASC, is_primary DESC, COALESCE(sort_order, 9999) ASC";
    $imgStmt = $pdo->prepare($imgSql);
    foreach ($productIds as $i => $pid) {
        $imgStmt->bindValue($i+1, $pid, PDO::PARAM_INT);
    }
    $imgStmt->execute();
    $allImages = $imgStmt->fetchAll(PDO::FETCH_ASSOC);

    // Normalize image URLs
    foreach ($allImages as $k => $row) {
        $allImages[$k]['image_url'] = $makeAbsolute($row['image_url']);
    }

    $imagesMap = [];
    foreach ($allImages as $img) {
        $pid = (int)$img['product_id'];
        if (!isset($imagesMap[$pid])) $imagesMap[$pid] = [];
        $imagesMap[$pid][] = $img;
    }

    // Group products by subcategory
    $grouped = [];
    foreach ($products as $p) {
        $pid = (int)$p['id'];
        $subId = isset($p['subcategory_id']) && $p['subcategory_id'] !== null ? (int)$p['subcategory_id'] : 0;
        if (!isset($grouped[$subId])) $grouped[$subId] = [];

        $prodImages = $imagesMap[$pid] ?? [];
        $thumbnail = $p['thumbnail'] ?? null;
        if (empty($thumbnail) && !empty($prodImages)) $thumbnail = $prodImages[0]['image_url'];
        // ensure thumbnail absolute
        $thumbnail = $makeAbsolute($thumbnail);

        $grouped[$subId][] = [
            'id' => $pid,
            'uuid' => $p['uuid'],
            'vendor_id' => (int)$p['vendor_id'],
            'category_id' => (int)$p['category_id'],
            'subcategory_id' => $subId === 0 ? null : $subId,
            'name' => $p['name'],
            'slug' => $p['slug'],
            'description' => $p['description'],
            'short_description' => $p['short_description'],
            'price' => isset($p['selling_price']) ? floatval($p['selling_price']) : 0,
            'mrp' => isset($p['mrp']) ? floatval($p['mrp']) : 0,
            'selling_price' => isset($p['selling_price']) ? floatval($p['selling_price']) : 0,
            'compare_price' => isset($p['mrp']) ? floatval($p['mrp']) : null,
            'stock' => isset($p['stock_quantity']) ? (int)$p['stock_quantity'] : 0,
            'sku' => $p['sku'],
            'rating' => isset($p['rating']) ? floatval($p['rating']) : 0,
            'total_reviews' => isset($p['total_reviews']) ? (int)$p['total_reviews'] : 0,
            'is_featured' => isset($p['is_featured']) ? (int)$p['is_featured'] : 0,
            'status' => $p['status'],
            'thumbnail' => $thumbnail,
            'images' => $prodImages,
            'created_at' => $p['created_at']
        ];
    }

    // Build final subcategory list with product arrays, apply per-subcategory limit and name lookup
    $final = [];
    foreach ($grouped as $subId => $prods) {
        // apply limit
        $slice = array_slice($prods, 0, $perLimit);
        // skip empty
        if (empty($slice)) continue;
        $name = $subId === 0 ? 'Uncategorized' : ($subMap[$subId] ?? 'Uncategorized');
        $final[] = [
            'subcategory_id' => $subId === 0 ? null : $subId,
            'subcategory_name' => $name,
            'products' => $slice,
            'count' => count($prods)
        ];
    }

    _json([
        'success' => true,
        'category_id' => $categoryId,
        'subcategories' => $final,
        'total_products' => count($products)
    ]);

} catch (Exception $e) {
    error_log('By-category subcategories error: ' . $e->getMessage());
    _json(['success' => false, 'message' => 'Server error', 'error' => $e->getMessage()], 500);
}

?>