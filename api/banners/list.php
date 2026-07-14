<?php
require_once __DIR__ . '/../../php/config.php';

header('Content-Type: application/json');

try {
    $pdo = getDBConnection();
    
    // simplified query: ignore dates and positions for now to ensure we see data
    $query = "SELECT * FROM banners WHERE status = 'active' ORDER BY sort_order ASC";
    
    $stmt = $pdo->prepare($query);
    $stmt->execute();
    $banners = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Format numeric values and URLs
    foreach ($banners as &$banner) {
        $banner['id'] = intval($banner['id']);
        $banner['sort_order'] = intval($banner['sort_order']);
        
        // Robust Image URL formatting
        if (isset($banner['image']) && !empty($banner['image'])) {
            $img = trim($banner['image']);
            
            // If it already has a protocol, leave it alone
            if (preg_match('/^https?:\/\//i', $img)) {
                $banner['image'] = $img;
            } 
            // If it starts with /app/askus/, it's an absolute path from root
            elseif (strpos($img, '/app/askus/') === 0) {
                $banner['image'] = 'https://indiawebdesigns.in' . $img;
            }
            // If it starts with / (but not our app path), it's probably wrong or from root
            elseif (strpos($img, '/') === 0) {
                $banner['image'] = 'https://indiawebdesigns.in/app/askus' . $img;
            }
            // Just a filename or relative path
            else {
                $banner['image'] = 'https://indiawebdesigns.in/app/askus/uploads/banners/' . $img;
            }
        }
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Banners retrieved successfully',
        'all_banners' => $banners,
        'banners' => $banners
    ]);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Database error occurred: ' . $e->getMessage()
    ]);
}
?>