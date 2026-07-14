<?php
require_once __DIR__ . '/../config.php';

try {
    $pdo = getDBConnection();
    
    $position = $_GET['position'] ?? null;
    
    $hasPosition = false;
    try {
        $checkCol = $pdo->query("SHOW COLUMNS FROM banners LIKE 'position'");
        $hasPosition = $checkCol->rowCount() > 0;
    } catch (Exception $e) {
        $hasPosition = false;
    }
    
    if ($hasPosition && $position) {
        $stmt = $pdo->prepare("
            SELECT *
            FROM banners 
            WHERE status = 'active' 
            AND position = ?
            ORDER BY sort_order ASC
        ");
        $stmt->execute([$position]);
        $banners = $stmt->fetchAll();
    } else {
        $stmt = $pdo->prepare("
            SELECT *
            FROM banners 
            WHERE status = 'active' 
            ORDER BY sort_order ASC
        ");
        $stmt->execute();
        $banners = $stmt->fetchAll();
    }
    
    foreach ($banners as &$banner) {
        if (!isset($banner['position']) || empty($banner['position'])) {
            $banner['position'] = 'home_top';
        }
        
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
    
    jsonResponse([
        'success' => true,
        'banners' => $banners,
        'all_banners' => $banners
    ]);
    
} catch (Exception $e) {
    error_log("Banners list error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Failed to load banners'], 500);
}
