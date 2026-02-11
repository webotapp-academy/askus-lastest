<?php
// Database configuration
define('DB_HOST', 'localhost');
define('DB_NAME', 'askus');
define('DB_USER', 'root');
define('DB_PASS', '');

// Application configuration
define('BASE_URL', 'http://localhost');
define('UPLOAD_PATH', __DIR__ . '/uploads/');
define('UPLOAD_URL', BASE_URL . '/uploads/');

// API Configuration
define('API_VERSION', 'v1');
define('JWT_SECRET', 'your-jwt-secret-key-change-this');
define('PAGINATION_DEFAULT_LIMIT', 20);
define('PAGINATION_MAX_LIMIT', 100);

// Razorpay configuration (if needed)
define('RAZORPAY_KEY_ID', 'your_razorpay_key_id');
define('RAZORPAY_KEY_SECRET', 'your_razorpay_key_secret');

/**
 * Get database connection
 * @return PDO
 * @throws Exception
 */
function getDBConnection() {
    static $pdo = null;
    
    if ($pdo === null) {
        try {
            $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4";
            $pdo = new PDO($dsn, DB_USER, DB_PASS, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
                PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci"
            ]);
        } catch (PDOException $e) {
            error_log("Database connection failed: " . $e->getMessage());
            throw new Exception("Database connection failed");
        }
    }
    
    return $pdo;
}

/**
 * Send JSON response
 * @param array $data
 * @param int $statusCode
 */
function jsonResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    header('Content-Type: application/json');
    echo json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit;
}

/**
 * Set CORS headers
 */
function setCORSHeaders() {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
    header('Access-Control-Max-Age: 3600');
}

/**
 * Handle preflight OPTIONS request
 */
function handlePreflight() {
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        setCORSHeaders();
        http_response_code(200);
        exit;
    }
}

/**
 * Validate required fields in request data
 * @param array $data
 * @param array $requiredFields
 * @return array|null Returns array of missing fields or null if all present
 */
function validateRequiredFields($data, $requiredFields) {
    $missing = [];
    foreach ($requiredFields as $field) {
        if (!isset($data[$field]) || empty(trim($data[$field]))) {
            $missing[] = $field;
        }
    }
    return empty($missing) ? null : $missing;
}

/**
 * Sanitize input data
 * @param string $data
 * @return string
 */
function sanitizeInput($data) {
    return htmlspecialchars(strip_tags(trim($data)), ENT_QUOTES, 'UTF-8');
}

/**
 * Generate UUID
 * @return string
 */
function generateUUID() {
    return sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
        mt_rand(0, 0xffff), mt_rand(0, 0xffff),
        mt_rand(0, 0xffff),
        mt_rand(0, 0x0fff) | 0x4000,
        mt_rand(0, 0x3fff) | 0x8000,
        mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
    );
}

/**
 * Format image URL
 * @param string|null $imagePath
 * @return string|null
 */
function formatImageURL($imagePath) {
    if (empty($imagePath)) {
        return null;
    }
    
    if (strpos($imagePath, 'http') === 0) {
        return $imagePath;
    }
    
    return UPLOAD_URL . ltrim($imagePath, '/');
}

/**
 * Parse JSON images field
 * @param string|null $imagesJson
 * @return array
 */
function parseImages($imagesJson) {
    if (empty($imagesJson)) {
        return [];
    }
    
    $images = json_decode($imagesJson, true);
    if (!is_array($images)) {
        return [];
    }
    
    return array_map('formatImageURL', $images);
}

/**
 * Log error with context
 * @param string $message
 * @param array $context
 */
function logError($message, $context = []) {
    $logMessage = $message;
    if (!empty($context)) {
        $logMessage .= " | Context: " . json_encode($context);
    }
    error_log($logMessage);
}

// Set default timezone
date_default_timezone_set('UTC');

// Initialize
setCORSHeaders();
handlePreflight();
?>