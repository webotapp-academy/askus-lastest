<?php
require_once '../config.php';

header('Content-Type: application/json');

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['phone'])) {
    jsonResponse(['success' => false, 'message' => 'Phone number is required'], 400);
}

$phone = $input['phone'];

// Remove any non-numeric characters
$phone = preg_replace('/[^0-9]/', '', $phone);

// Validate phone number length (assuming 10-12 digits)
if (strlen($phone) < 10 || strlen($phone) > 12) {
    jsonResponse(['success' => false, 'message' => 'Invalid phone number format'], 400);
}

try {
    $pdo = getDBConnection();

    // Check if phone exists in users or vendors table
    // First check users
    $stmt = $pdo->prepare("SELECT id, 'user' as type FROM users WHERE phone = ?");
    $stmt->execute([$phone]);
    $user = $stmt->fetch();

    if (!$user) {
        // Check vendors if not found in users
        $stmt = $pdo->prepare("SELECT id, 'vendor' as type FROM vendors WHERE phone = ?");
        $stmt->execute([$phone]);
        $user = $stmt->fetch();
    }

    if (!$user) {
        // For security, proceed with fake OTP generation or return generic message
        // Here we'll return generic message that OTP sent if number exists
        // But for better UX, we might want to tell them to register.
        // Let's return error for now as it's a login flow.
        jsonResponse(['success' => false, 'message' => 'Phone number not registered. Please sign up first.'], 404);
    }

    // Generate 6-digit OTP
    $otp = (string) rand(100000, 999999);

    // Set expiry to 10 minutes from now
    $expiry = date('Y-m-d H:i:s', strtotime('+10 minutes'));

    // Update database with OTP
    $table = $user['type'] === 'user' ? 'users' : 'vendors';
    $updateStmt = $pdo->prepare("UPDATE $table SET otp_code = ?, otp_expiry = ? WHERE id = ?");
    $updateStmt->execute([$otp, $expiry, $user['id']]);

    // Send OTP via WhatsApp
    $phoneNumberId = WHATSAPP_PHONE_ID;
    $accessToken = WHATSAPP_ACCESS_TOKEN;

    // Format phone for WhatsApp (needs country code, default to 91 if roughly 10 digits)
    $recipient = $phone;
    if (strlen($recipient) == 10) {
        $recipient = '91' . $recipient;
    }

    $url = "https://graph.facebook.com/v18.0/$phoneNumberId/messages";

    $data = [
        "messaging_product" => "whatsapp",
        "to" => $recipient,
        "type" => "template",
        "template" => [
            "name" => "otp", // Ensure this template exists in your WhatsApp Business account
            "language" => ["code" => "en"],
            "components" => [
                [
                    "type" => "body",
                    "parameters" => [
                        [
                            "type" => "text",
                            "text" => $otp
                        ]
                    ]
                ],
                [
                    "type" => "button",
                    "sub_type" => "url",
                    "index" => "0",
                    "parameters" => [
                        [
                            "type" => "text",
                            "text" => $otp
                        ]
                    ]
                ]
            ]
        ]
    ];

    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        "Authorization: Bearer $accessToken",
        "Content-Type: application/json"
    ]);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

    if (curl_errno($ch)) {
        $error = curl_error($ch);
        curl_close($ch);
        logError("WhatsApp API Error", ['error' => $error]);
        jsonResponse(['success' => false, 'message' => 'Failed to send OTP. Please try again later.'], 500);
    }

    curl_close($ch);

    // Decode response to check for API errors
    $responseData = json_decode($response, true);

    if ($httpCode >= 200 && $httpCode < 300) {
        jsonResponse(['success' => true, 'message' => 'OTP sent successfully']);
    } else {
        logError("WhatsApp API Failed", ['response' => $responseData, 'http_code' => $httpCode]);
        jsonResponse(['success' => false, 'message' => 'Failed to send OTP via WhatsApp'], 500);
    }

} catch (Exception $e) {
    logError("Send OTP Error", ['error' => $e->getMessage()]);
    jsonResponse(['success' => false, 'message' => 'An error occurred'], 500);
}
?>