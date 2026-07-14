<?php
require_once __DIR__ . '/config.php';

header('Content-Type: application/json');

try {
    $pdo = getDBConnection();
    
    // 1. Check total count
    $stmt = $pdo->query("SELECT COUNT(*) FROM banners");
    $total = $stmt->fetchColumn();
    
    // 2. Check status distribution
    $stmt = $pdo->query("SELECT status, COUNT(*) as count FROM banners GROUP BY status");
    $statuses = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // 3. Check position distribution
    $stmt = $pdo->query("SELECT position, COUNT(*) as count FROM banners GROUP BY position");
    $positions = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // 4. Check for date issues (if they exist)
    $stmt = $pdo->query("SELECT id, title, start_date, end_date, status, position FROM banners LIMIT 10");
    $samples = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // 5. Current Server Time
    $stmt = $pdo->query("SELECT NOW() as current_time");
    $server_time = $stmt->fetchColumn();

    echo json_encode([
        'success' => true,
        'diagnostics' => [
            'total_rows' => $total,
            'status_counts' => $statuses,
            'position_counts' => $positions,
            'server_time' => $server_time,
            'samples' => $samples
        ]
    ], JSON_PRETTY_PRINT);

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>