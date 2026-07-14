<?php
require_once __DIR__ . '/../config.php';

$vendor = requireVendor();

$pdo = getDBConnection();

$stmt = $pdo->prepare("
    SELECT s.*, c.name as category_name,
           (SELECT si.image_url FROM service_images si WHERE si.service_id = s.id ORDER BY si.sort_order LIMIT 1) as thumbnail
    FROM services s
    LEFT JOIN categories c ON s.category_id = c.id
    WHERE s.vendor_id = ? AND s.deleted_at IS NULL
    ORDER BY s.created_at DESC
");
$stmt->execute([$vendor['id']]);
$services = $stmt->fetchAll();

foreach ($services as &$service) {
    $imgStmt = $pdo->prepare("SELECT image_url FROM service_images WHERE service_id = ? ORDER BY sort_order");
    $imgStmt->execute([$service['id']]);
    $service['images'] = array_column($imgStmt->fetchAll(), 'image_url');
}

jsonResponse([
    'success' => true,
    'services' => $services
]);
