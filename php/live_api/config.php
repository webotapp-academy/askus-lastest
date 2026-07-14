<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$dbUrl = getenv('DATABASE_URL');

if ($dbUrl) {
    $parsed = parse_url($dbUrl);
    define('DB_HOST', $parsed['host']);
    define('DB_PORT', $parsed['port'] ?? 5432);
    define('DB_NAME', ltrim($parsed['path'], '/'));
    define('DB_USER', $parsed['user']);
    define('DB_PASS', $parsed['pass']);
    define('DB_TYPE', 'pgsql');
} else {
    define('DB_HOST', 'localhost');
    define('DB_PORT', 3306);
    define('DB_NAME', 'askus');
    define('DB_USER', 'askus');
    define('DB_PASS', 'JAIhanuman89@@@');
    define('DB_TYPE', 'mysql');
}

define('JWT_SECRET', 'askus-jwt-secret-key-2024-production');
define('JWT_EXPIRY', 86400 * 30);

define('UPLOAD_DIR', __DIR__ . '/uploads/');
define('UPLOAD_URL', 'https://indiawebdesigns.in/app/askus/api/uploads/');
// Razorpay Configuration
define('RAZORPAY_KEY_ID', 'rzp_live_Rr1ievS9AKmSno'); // Replace with your actual Razorpay Key ID
define('RAZORPAY_KEY_SECRET', 'sD85eYTIjVahnVYZglBCumSf'); // Replace with your actual Razorpay Secret Key


date_default_timezone_set('Asia/Kolkata');

function getDBConnection() {
    static $pdo = null;
    if ($pdo === null) {
        try {
            if (DB_TYPE === 'mysql') {
                $dsn = "mysql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME . ";charset=utf8mb4";
            } else {
                $dsn = "pgsql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME;
            }
            $options = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ];
            $pdo = new PDO($dsn, DB_USER, DB_PASS, $options);
        } catch (PDOException $e) {
            error_log("Database connection failed: " . $e->getMessage());
            jsonResponse(['success' => false, 'message' => 'Database connection failed'], 500);
        }
    }
    return $pdo;
}

function jsonResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode($data);
    exit;
}

function generateUUID() {
    return sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
        mt_rand(0, 0xffff), mt_rand(0, 0xffff),
        mt_rand(0, 0xffff),
        mt_rand(0, 0x0fff) | 0x4000,
        mt_rand(0, 0x3fff) | 0x8000,
        mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
    );
}

function generateToken($userId, $role) {
    $header = base64_encode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
    $payload = base64_encode(json_encode([
        'user_id' => $userId,
        'role' => $role,
        'exp' => time() + JWT_EXPIRY,
        'iat' => time()
    ]));
    $signature = hash_hmac('sha256', "$header.$payload", JWT_SECRET, true);
    $signature = base64_encode($signature);
    return "$header.$payload.$signature";
}

function verifyToken($token) {
    $parts = explode('.', $token);
    if (count($parts) !== 3) return null;
    
    list($header, $payload, $signature) = $parts;
    $expectedSignature = base64_encode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true));
    
    if ($signature !== $expectedSignature) return null;
    
    $data = json_decode(base64_decode($payload), true);
    if (!$data || $data['exp'] < time()) return null;
    
    return $data;
}

function getAuthUser() {
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    
    if (empty($authHeader) || !preg_match('/Bearer\s+(.+)/', $authHeader, $matches)) {
        return null;
    }
    
    $tokenData = verifyToken($matches[1]);
    if (!$tokenData) return null;
    
    $pdo = getDBConnection();
    
    if ($tokenData['role'] === 'vendor') {
        $stmt = $pdo->prepare("SELECT * FROM vendors WHERE id = ? AND deleted_at IS NULL");
        $stmt->execute([$tokenData['user_id']]);
    } else {
        $stmt = $pdo->prepare("SELECT * FROM users WHERE id = ? AND deleted_at IS NULL");
        $stmt->execute([$tokenData['user_id']]);
    }
    
    $user = $stmt->fetch();
    if (!$user) return null;
    
    $user['role'] = $tokenData['role'];
    return $user;
}

function requireAuth() {
    $user = getAuthUser();
    if (!$user) {
        jsonResponse(['success' => false, 'message' => 'Unauthorized'], 401);
    }
    return $user;
}

function requireVendor() {
    $user = requireAuth();
    if ($user['role'] !== 'vendor') {
        jsonResponse(['success' => false, 'message' => 'Vendor access required'], 403);
    }
    return $user;
}

function requireApprovedVendor() {
    $vendor = requireVendor();
    if ($vendor['status'] !== 'approved') {
        jsonResponse([
            'success' => false, 
            'message' => 'Your vendor account is pending approval. Please wait for admin verification.', 
            'status' => $vendor['status']
        ], 403);
    }
    return $vendor;
}


function getInput() {
    $input = json_decode(file_get_contents('php://input'), true);
    return $input ?: $_POST;
}

function createSlug($text) {
    $slug = strtolower(trim(preg_replace('/[^A-Za-z0-9-]+/', '-', $text)));
    return $slug . '-' . substr(uniqid(), -6);
}

function uploadFile($file, $folder = '') {
    $uploadDir = UPLOAD_DIR . $folder . '/';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0755, true);
    }
    
    $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
    $filename = uniqid() . '_' . time() . '.' . $ext;
    $filepath = $uploadDir . $filename;
    
    if (move_uploaded_file($file['tmp_name'], $filepath)) {
        return UPLOAD_URL . $folder . '/' . $filename;
    }
    
    return null;
}
