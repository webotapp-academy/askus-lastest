<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Debug header to verify this file is executed by the server
header('X-Products-Endpoint: images-only-v1');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../config.php';

try {
    $pdo = getDBConnection();

    // Pagination and inputs
    $page = max(1, intval($_GET['page'] ?? 1));
    $limit = max(1, intval($_GET['limit'] ?? 20));
    $offset = ($page - 1) * $limit;

    $categoryId = intval($_GET['category_id'] ?? 0);
    $search = isset($_GET['search']) ? trim($_GET['search']) : '';

    // Base WHERE conditions (only active products)
    $whereClauses = ["p.status = 'active'"];
    $params = [];

    // Only include products that have at least one image in product_images
    $whereClauses[] = "EXISTS (SELECT 1 FROM product_images pi_exist WHERE pi_exist.product_id = p.id)";

    if ($categoryId > 0) {
        $whereClauses[] = 'p.category_id = :categoryId';
        $params[':categoryId'] = $categoryId;
    }

    if ($search !== '') {
        $whereClauses[] = '(p.name LIKE :search OR p.description LIKE :search)';
        $params[':search'] = '%' . $search . '%';
    }

    $where = '';
    if (!empty($whereClauses)) {
        $where = 'WHERE ' . implode(' AND ', $whereClauses);
    }

    // Get total count (only products that have images)
    $countSql = "SELECT COUNT(*) FROM products p $where";
    $countStmt = $pdo->prepare($countSql);
    foreach ($params as $k => $v) {
        $countStmt->bindValue($k, $v);
    }
    $countStmt->execute();
    $total = intval($countStmt->fetchColumn());

    // Fetch products with a computed thumbnail (first by is_primary desc, then sort_order asc)
    $query = "SELECT
                p.id,
                p.uuid,
                p.vendor_id,
                p.category_id,
                p.subcategory_id,
                p.name,
                p.slug,
                p.description,
                p.short_description,
                p.mrp,
                p.selling_price,
                p.stock_quantity,
                p.sku,
                p.rating,
                p.total_reviews,
                p.is_featured,
                p.status,
                p.created_at,
                (
                    SELECT image_url
                    FROM product_images pi
                    WHERE pi.product_id = p.id
                    ORDER BY pi.is_primary DESC, COALESCE(pi.sort_order, 9999) ASC
                    LIMIT 1
                ) AS thumbnail
              FROM products p
              $where
              ORDER BY p.created_at DESC
              LIMIT :limit OFFSET :offset";

    $stmt = $pdo->prepare($query);
    // bind filters
    foreach ($params as $k => $v) {
        $stmt->bindValue($k, $v);
    }
    // bind limit/offset as integers
    $stmt->bindValue(':limit', (int)$limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', (int)$offset, PDO::PARAM_INT);
    $stmt->execute();
    $products = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // If no products, return empty list with pagination
    if (empty($products)) {
        jsonResponse([
            'success' => true,
            'products' => [],
            'pagination' => [
                'page' => $page,
                'limit' => $limit,
                'total' => $total,
                'pages' => ($limit > 0 ? ceil($total / $limit) : 0)
            ]
        ]);
        exit;
    }

    // Fetch all images for returned products (ordered)
    $productIds = array_map(function($p) { return (int)$p['id']; }, $products);
    $placeholders = implode(',', array_fill(0, count($productIds), '?'));
    $imgSql = "SELECT id, product_id, image_url, alt_text, sort_order, is_primary
               FROM product_images
               WHERE product_id IN ($placeholders)
               ORDER BY product_id ASC, is_primary DESC, COALESCE(sort_order, 9999) ASC";
    $imgStmt = $pdo->prepare($imgSql);
    foreach ($productIds as $i => $pid) {
        // 1-indexed parameters for execute array below
        $imgStmt->bindValue($i+1, $pid, PDO::PARAM_INT);
    }
    $imgStmt->execute();
    $allImages = $imgStmt->fetchAll(PDO::FETCH_ASSOC);

    // Build absolute base URL for images (e.g. https://domain/app/askus)
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'] ?? '';
    $scriptDir = dirname($_SERVER['SCRIPT_NAME']); // e.g. /app/askus/api
    // Remove any /api and following path to get application root (e.g. /app/askus)
    $appRoot = preg_replace('#/api.*$#', '', $scriptDir);
    $imagesBase = rtrim($scheme . '://' . $host . $appRoot, '/');

    // Helper to normalise image URLs to absolute URLs
    $makeAbsolute = function ($url) use ($imagesBase) {
        if (empty($url)) return $url;
        // already absolute
        if (preg_match('#^https?://#i', $url)) return $url;
        // leading slash -> append to app root
        if (strpos($url, '/') === 0) return $imagesBase . $url;
        // otherwise assume relative to app root
        return $imagesBase . '/' . ltrim($url, '/');
    };

    // Convert all image_url values to absolute URLs so clients can load them directly
    foreach ($allImages as $k => $imgRow) {
        $allImages[$k]['image_url'] = $makeAbsolute($imgRow['image_url']);
    }

    $imagesMap = [];
    foreach ($allImages as $img) {
        $pid = $img['product_id'];
        if (!isset($imagesMap[$pid])) {
            $imagesMap[$pid] = [];
        }
        $imagesMap[$pid][] = $img;
    }

    // Build formatted response
    $formattedProducts = [];
    foreach ($products as $product) {
        $pid = (int)$product['id'];
        $productImages = $imagesMap[$pid] ?? [];
        // ensure thumbnail is present; if not, fallback to first image in productImages
        $thumbnail = $product['thumbnail'] ?? null;
        if (empty($thumbnail) && !empty($productImages)) {
            $thumbnail = $productImages[0]['image_url'];
        }

        $formattedProducts[] = [
            'id' => $pid,
            'uuid' => $product['uuid'],
            'vendor_id' => intval($product['vendor_id']),
            'category_id' => intval($product['category_id']),
            'subcategory_id' => $product['subcategory_id'] ? intval($product['subcategory_id']) : null,
            'name' => $product['name'],
            'slug' => $product['slug'],
            'description' => $product['description'],
            'short_description' => $product['short_description'],
            'price' => floatval($product['selling_price']),
            'mrp' => floatval($product['mrp']),
            'selling_price' => floatval($product['selling_price']),
            'compare_price' => floatval($product['mrp']),
            'stock' => intval($product['stock_quantity']),
            'sku' => $product['sku'],
            'rating' => floatval($product['rating']),
            'total_reviews' => intval($product['total_reviews']),
            'total_ratings' => intval($product['total_reviews']),
            'is_featured' => intval($product['is_featured']),
            'status' => $product['status'],
            'thumbnail' => $thumbnail,
            'images' => $productImages,
            'created_at' => $product['created_at']
        ];
    }

    jsonResponse([
        'success' => true,
        'products' => $formattedProducts,
        'pagination' => [
            'page' => $page,
            'limit' => $limit,
            'total' => $total,
            'pages' => ($limit > 0 ? ceil($total / $limit) : 0)
        ]
    ]);

} catch (Exception $e) {
    error_log("Products List Error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => $e->getMessage()], 500);
}

?>