<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Adjust path using __DIR__ for reliability
require_once __DIR__ . '/../config.php';

// Your domain base URL
define('BASE_URL', 'https://indiawebdesigns.in');

// Fallback helper if not defined in config
if (!function_exists('jsonResponse')) {
    function jsonResponse($data, $code = 200) {
        http_response_code($code);
        echo json_encode($data);
        exit;
    }
}

try {
    // 1. Use PDO connection (matches products logic)
    $pdo = getDBConnection();
    
    $categoryId = isset($_GET['category_id']) ? intval($_GET['category_id']) : 0;
    $status = isset($_GET['status']) ? $_GET['status'] : 'active';
    
    if ($categoryId > 0) {
        $query = "SELECT id, category_id, name, slug, description, image, sort_order, status, created_at, updated_at
                  FROM subcategories 
                  WHERE category_id = :categoryId AND status = :status
                  ORDER BY sort_order ASC, name ASC";
        
        $stmt = $pdo->prepare($query);
        $stmt->bindValue(':categoryId', $categoryId, PDO::PARAM_INT);
        $stmt->bindValue(':status', $status, PDO::PARAM_STR);
    } else {
        $query = "SELECT s.id, s.category_id, s.name, s.slug, s.description, s.image, 
                         s.sort_order, s.status, s.created_at, s.updated_at,
                         c.name as category_name
                  FROM subcategories s
                  LEFT JOIN categories c ON s.category_id = c.id
                  WHERE s.status = :status
                  ORDER BY c.name ASC, s.sort_order ASC, s.name ASC";
        
        $stmt = $pdo->prepare($query);
        $stmt->bindValue(':status', $status, PDO::PARAM_STR);
    }
    
    $stmt->execute();
    $subcategories = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Process image URLs - prepend domain for mobile app
    foreach ($subcategories as &$row) {
        if (!empty($row['image'])) {
            // If image doesn't start with http, prepend the domain
            if (strpos($row['image'], 'http') !== 0) {
                $row['image'] = BASE_URL . $row['image'];
            }
        }
    }
    unset($row);
    
    jsonResponse([
        'success' => true,
        'subcategories' => $subcategories, 
        'count' => count($subcategories)
    ]);
    
} catch (Exception $e) {
    error_log("Subcategories List Error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Error: ' . $e->getMessage()], 500);
}
?>