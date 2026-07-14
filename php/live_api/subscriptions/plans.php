<?php
// Handle absolute path to config.php safely
$config_path = __DIR__ . '/../config.php';
if (!file_exists($config_path)) {
    $config_path = __DIR__ . '/../config.php';
}
require_once $config_path;

// Function to get input from multiple sources (JSON or Form Data)
if (!function_exists('getInput')) {
    function getInput() {
        $input = json_decode(file_get_contents('php://input'), true);
        if (is_array($input)) {
            return array_merge($_GET, $_POST, $input);
        }
        return array_merge($_GET, $_POST);
    }
}

// Support preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    if (function_exists('setCORSHeaders')) {
        setCORSHeaders();
    } else {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
    }
    http_response_code(200);
    exit;
}

try {
    $pdo = getDBConnection();
    
    // Use the more robust input helper
    $input = getInput();
    $targetGroup = isset($input['target_group']) ? sanitizeInput($input['target_group']) : null;

    $query = "SELECT id, name, target_group, price, duration_days, max_listings, featured_days, boost_days, has_trusted_badge, has_verified_badge, has_top_placement FROM subscription_plans WHERE status = 'active'";
    $params = [];

    if ($targetGroup && in_array($targetGroup, ['vendor', 'worker'])) {
        $query .= " AND target_group = ?";
        $params[] = $targetGroup;
    }

    $query .= " ORDER BY price ASC";

    $stmt = $pdo->prepare($query);
    $stmt->execute($params);
    $plans = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Format values for frontend
    foreach ($plans as &$plan) {
        $plan['id'] = (int) $plan['id'];
        $plan['price'] = (float) $plan['price'];
        $plan['duration_days'] = (int) $plan['duration_days'];
        $plan['max_listings'] = (int) $plan['max_listings'];
        $plan['featured_days'] = (int) $plan['featured_days'];
        $plan['boost_days'] = (int) $plan['boost_days'];
        $plan['has_trusted_badge'] = (bool)$plan['has_trusted_badge'];
        $plan['has_verified_badge'] = (bool)$plan['has_verified_badge'];
        $plan['has_top_placement'] = (bool)$plan['has_top_placement'];
    }

    // Use the helper from config.php if available, else manual response
    if (function_exists('jsonResponse')) {
        jsonResponse([
            'success' => true,
            'data' => $plans
        ]);
    } else {
        header('Content-Type: application/json');
        echo json_encode(['success' => true, 'data' => $plans]);
        exit;
    }

} catch (PDOException $e) {
    error_log("Database error in plans: " . $e->getMessage());
    if (function_exists('jsonResponse')) {
        jsonResponse(['success' => false, 'message' => 'Database connection error'], 500);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database connection error']);
        exit;
    }
} catch (Exception $e) {
    error_log("General error in plans: " . $e->getMessage());
    if (function_exists('jsonResponse')) {
        jsonResponse(['success' => false, 'message' => 'Internal server error'], 500);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Internal server error']);
        exit;
    }
}
?>