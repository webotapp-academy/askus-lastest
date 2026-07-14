<?php
require_once '../config.php';

// Include PHPMailer library
require_once '../vendor/PHPMailer/src/Exception.php';
require_once '../vendor/PHPMailer/src/PHPMailer.php';
require_once '../vendor/PHPMailer/src/SMTP.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

header('Content-Type: application/json');

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

if (empty($input['email'])) {
    jsonResponse(['success' => false, 'message' => 'Email is required'], 400);
}

$email = trim(strtolower($input['email']));

// Validate email format
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonResponse(['success' => false, 'message' => 'Invalid email format'], 400);
}

try {
    $pdo = getDBConnection();

    // Check if email exists in users or vendors table
    // Check users table
    $stmt = $pdo->prepare("SELECT id, 'user' as type FROM users WHERE email = ? AND deleted_at IS NULL");
    $stmt->execute([$email]);
    $entity = $stmt->fetch();

    if (!$entity) {
        // Check vendors table
        $stmt = $pdo->prepare("SELECT id, 'vendor' as type FROM vendors WHERE email = ? AND deleted_at IS NULL");
        $stmt->execute([$email]);
        $entity = $stmt->fetch();
    }

    if (!$entity) {
        jsonResponse(['success' => false, 'message' => 'Email address is not registered'], 404);
    }

    // Generate 6-digit OTP
    $otp = (string) rand(100000, 999999);

    // Set expiry to 10 minutes from now
    $expiry = date('Y-m-d H:i:s', strtotime('+10 minutes'));

    // Update database with OTP
    $table = $entity['type'] === 'user' ? 'users' : 'vendors';
    $updateStmt = $pdo->prepare("UPDATE $table SET otp_code = ?, otp_expiry = ? WHERE id = ?");
    $updateStmt->execute([$otp, $expiry, $entity['id']]);

    // Send OTP via Email using PHPMailer and Gmail SMTP
    $to = $email;
    $subject = "AskUs - Password Reset OTP";
    
    // HTML email template
    $message = "
    <html>
    <head>
        <title>Password Reset OTP</title>
        <style>
            body { font-family: Arial, sans-serif; background-color: #f6f6f6; margin: 0; padding: 20px; color: #333; }
            .card { background-color: #fff; border-radius: 8px; padding: 30px; margin: 0 auto; max-width: 500px; box-shadow: 0 4px 10px rgba(0,0,0,0.05); }
            h2 { color: #002547; margin-top: 0; }
            .otp { font-size: 32px; font-weight: bold; color: #e94560; letter-spacing: 4px; padding: 15px; background-color: #f7f9fc; border-radius: 6px; text-align: center; margin: 20px 0; }
            .footer { font-size: 12px; color: #777; margin-top: 30px; border-top: 1px solid #eee; padding-top: 15px; }
        </style>
    </head>
    <body>
        <div class='card'>
            <h2>Reset Your Password</h2>
            <p>We received a request to reset your password. Use the following One-Time Password (OTP) to proceed. This code is valid for 10 minutes.</p>
            <div class='otp'>$otp</div>
            <p>If you did not request this, you can safely ignore this email.</p>
            <div class='footer'>
                <p>This is an automated message from AskUs Marketplace. Please do not reply.</p>
            </div>
        </div>
    </body>
    </html>
    ";

    $mail = new PHPMailer(true);
    
    try {
        // Server settings
        $mail->isSMTP();
        $mail->Host       = 'smtp.gmail.com';
        $mail->SMTPAuth   = true;
        // REPLACE WITH YOUR GMAIL ADDRESS
        $mail->Username   = 'askus.marketplace@gmail.com';
        // REPLACE WITH YOUR GOOGLE APP PASSWORD (NOT regular password)
        $mail->Password   = 'kddp yzry nacp jfqm';
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_SMTPS;
        $mail->Port       = 465;

        // Recipients
        $mail->setFrom('askus.marketplace@gmail.com', 'AskUs Marketplace');
        $mail->addAddress($to);

        // Content
        $mail->isHTML(true);
        $mail->Subject = $subject;
        $mail->Body    = $message;
        $mail->AltBody = "Your OTP for password reset is: $otp (Valid for 10 minutes)";

        $mail->send();
        jsonResponse(['success' => true, 'message' => 'OTP sent successfully to your email']);
    } catch (Exception $e) {
        logError("PHPMailer Error to $email: {$mail->ErrorInfo}");
        jsonResponse(['success' => false, 'message' => "Failed to send email. Mailer Error: {$mail->ErrorInfo}"], 500);
    }

} catch (Exception $e) {
    logError("Send Email OTP Error", ['error' => $e->getMessage()]);
    jsonResponse(['success' => false, 'message' => 'An error occurred: ' . $e->getMessage()], 500);
}
?>
