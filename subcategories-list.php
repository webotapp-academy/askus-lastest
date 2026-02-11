<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'config.php';

try {
    $categoryId = isset($_GET['category_id']) ? intval($_GET['category_id']) : 0;
    $status = isset($_GET['status']) ? $_GET['status'] : 'active';
    
    // Debug logging
    error_log("Subcategories Request - Category ID: $categoryId, Status: $status");
    
    if ($categoryId > 0) {
        // Get subcategories for a specific category
        $query = "SELECT 
                    id,
                    category_id,
                    name,
                    slug,
                    description,
                    image,
                    sort_order,
                    status,
                    created_at,
                    updated_at
                  FROM subcategories 
                  WHERE category_id = ? AND status = ?
                  ORDER BY sort_order ASC, name ASC";
        
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param("is", $categoryId, $status);
        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }
    } else {
        // Get all active subcategories
        $query = "SELECT 
                    s.id,
                    s.category_id,
                    s.name,
                    s.slug,
                    s.description,
                    s.image,
                    s.sort_order,
                    s.status,
                    s.created_at,
                    s.updated_at,
                    c.name as category_name
                  FROM subcategories s
                  LEFT JOIN categories c ON s.category_id = c.id
                  WHERE s.status = ?
                  ORDER BY c.name ASC, s.sort_order ASC, s.name ASC";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("s", $status);
    }
    
    $stmt->execute();
    $result = $stmt->get_result();
    
    $subcategories = [];
    while ($row = $result->fetch_assoc()) {
        // Add full image URL if image exists
        if (!empty($row['image'])) {
            $row['image'] = BASE_URL . '/' . $row['image'];
        }
        $subcategories[] = $row;
    }
    
    echo json_encode([
        'success' => true,
        'subcategories' => $subcategories,
        'count' => count($subcategories)
    ]);
    
} catch (Exception $e) {
    error_log("Subcategories list error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to fetch subcategories',
        'error' => $e->getMessage()
    ]);
}

$conn->close();
?>
