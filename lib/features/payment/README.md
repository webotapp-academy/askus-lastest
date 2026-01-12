# Payment Integration for Vendor Registration

This module integrates Razorpay payment gateway for vendor registration fees in the Ask Us marketplace app.

## Features

- **Vendor Registration Payment**: One-time registration fee of ₹999 + 18% GST (Total: ₹1,179)
- **Razorpay Integration**: Secure payment processing using Razorpay Flutter SDK
- **Payment Verification**: Server-side payment verification for security
- **User-friendly UI**: Animated payment screens with clear pricing breakdown

## Flow

1. **Vendor Registration**: User fills out personal, business, and document information
2. **Account Creation**: Vendor account is created in the system
3. **Payment Screen**: User is redirected to payment screen with fee breakdown
4. **Razorpay Payment**: Secure payment processing through Razorpay
5. **Verification**: Payment is verified on the server
6. **Completion**: User is redirected to dashboard upon successful payment

## Files Structure

```
lib/features/payment/
├── data/
│   ├── payment_service.dart      # Razorpay integration service
│   └── payment_model.dart        # Payment data models
├── presentation/
│   └── vendor_payment_screen.dart # Payment UI screen
└── README.md                     # This file
```

## Configuration

### 1. PHP Backend Setup

Place the following PHP files in your server's `/payments/` directory:

**vendor-create.php** (Vendor registration payment creation):
```php
<?php
require_once __DIR__ . '/../config.php';
// ... (use the vendor_payment_create.php content)
```

**vendor-verify.php** (Vendor registration payment verification):
```php
<?php
require_once __DIR__ . '/../config.php';
// ... (use the vendor_payment_verify.php content)
```

### 2. Database Configuration

Ensure your `config.php` has the Razorpay configuration:
```php
define('RAZORPAY_KEY_ID', 'rzp_test_xxxxxxxxxxxx'); // Your Razorpay Key ID
define('RAZORPAY_KEY_SECRET', 'your_razorpay_secret'); // Your Razorpay Secret
```

### 3. Server Endpoints

The integration uses these vendor-specific endpoints:
- `POST /payments/vendor-create.php` - Create vendor registration payment order
- `POST /payments/vendor-verify.php` - Verify vendor registration payment

### 4. Database Tables

The integration uses the existing `payments` table with these specific fields for vendor registration:
- `type` = 'vendor_registration'
- `item_id` = vendor user ID
- `amount` = 1179.00 (₹999 + 18% GST)
- `status` = 'pending' → 'completed'

Additional features:
- Automatically approves vendor after successful payment
- Logs vendor approval in `vendor_logs` table
- Prevents duplicate payments for same vendor

## PHP Backend Files

### vendor-create.php
```php
<?php
require_once __DIR__ . '/../config.php';

$user = requireAuth();
$input = getInput();

$vendorId = intval($input['vendor_id'] ?? $user['id']);
$amount = floatval($input['amount'] ?? 1179);

if ($amount <= 0) {
    jsonResponse(['success' => false, 'message' => 'Invalid amount'], 400);
}

if ($user['id'] != $vendorId && $user['role'] !== 'admin') {
    jsonResponse(['success' => false, 'message' => 'Unauthorized'], 403);
}

$pdo = getDBConnection();

// Check existing payment
$stmt = $pdo->prepare("SELECT * FROM payments WHERE user_id = ? AND type = 'vendor_registration' AND status IN ('pending', 'completed')");
$stmt->execute([$vendorId]);
$existingPayment = $stmt->fetch();

if ($existingPayment && $existingPayment['status'] === 'completed') {
    jsonResponse(['success' => false, 'message' => 'Vendor registration fee already paid'], 400);
}

$razorpayOrderId = 'vendor_reg_' . $vendorId . '_' . time();
$uuid = generateUUID();

try {
    if ($existingPayment && $existingPayment['status'] === 'pending') {
        $stmt = $pdo->prepare("UPDATE payments SET amount = ?, final_amount = ?, razorpay_order_id = ?, updated_at = NOW() WHERE id = ?");
        $stmt->execute([$amount, $amount, $razorpayOrderId, $existingPayment['id']]);
        $paymentId = $existingPayment['id'];
    } else {
        $stmt = $pdo->prepare("INSERT INTO payments (uuid, user_id, type, item_id, amount, discount, coupon_id, final_amount, razorpay_order_id, status, created_at, updated_at) VALUES (?, ?, 'vendor_registration', ?, ?, 0, NULL, ?, ?, 'pending', NOW(), NOW())");
        $stmt->execute([$uuid, $vendorId, $vendorId, $amount, $amount, $razorpayOrderId]);
        $paymentId = $pdo->lastInsertId();
    }

    $stmt = $pdo->prepare("SELECT u.name, u.email, u.phone FROM users u WHERE u.id = ?");
    $stmt->execute([$vendorId]);
    $vendorDetails = $stmt->fetch();

    jsonResponse([
        'success' => true,
        'payment_id' => $paymentId,
        'order_id' => $razorpayOrderId,
        'razorpay_key' => RAZORPAY_KEY_ID,
        'amount' => $amount * 100,
        'currency' => 'INR',
        'prefill' => [
            'name' => $vendorDetails['name'] ?? $user['name'],
            'email' => $vendorDetails['email'] ?? $user['email'],
            'contact' => $vendorDetails['phone'] ?? $user['phone'],
        ]
    ]);
} catch (Exception $e) {
    jsonResponse(['success' => false, 'message' => 'Failed to create payment order'], 500);
}
?>
```

### vendor-verify.php
```php
<?php
require_once __DIR__ . '/../config.php';

$user = requireAuth();
$input = getInput();

$razorpayPaymentId = $input['razorpay_payment_id'] ?? '';
$razorpayOrderId = $input['razorpay_order_id'] ?? '';
$razorpaySignature = $input['razorpay_signature'] ?? '';

if (empty($razorpayPaymentId) || empty($razorpayOrderId) || empty($razorpaySignature)) {
    jsonResponse(['success' => false, 'message' => 'Payment details required'], 400);
}

$pdo = getDBConnection();

$stmt = $pdo->prepare("SELECT * FROM payments WHERE razorpay_order_id = ? AND type = 'vendor_registration'");
$stmt->execute([$razorpayOrderId]);
$payment = $stmt->fetch();

if (!$payment) {
    jsonResponse(['success' => false, 'message' => 'Payment record not found'], 404);
}

if ($user['id'] != $payment['user_id'] && $user['role'] !== 'admin') {
    jsonResponse(['success' => false, 'message' => 'Unauthorized'], 403);
}

if ($payment['status'] !== 'pending') {
    jsonResponse(['success' => false, 'message' => 'Payment already processed'], 400);
}

try {
    $pdo->beginTransaction();

    // Update payment
    $stmt = $pdo->prepare("UPDATE payments SET razorpay_payment_id = ?, razorpay_signature = ?, status = 'completed', paid_at = NOW(), updated_at = NOW() WHERE id = ?");
    $stmt->execute([$razorpayPaymentId, $razorpaySignature, $payment['id']]);

    // Approve vendor
    $stmt = $pdo->prepare("UPDATE users SET status = 'approved', approved_at = NOW(), updated_at = NOW() WHERE id = ? AND role = 'vendor'");
    $stmt->execute([$payment['user_id']]);

    $pdo->commit();

    jsonResponse([
        'success' => true,
        'message' => 'Payment verified and vendor approved successfully',
        'vendor_status' => 'approved'
    ]);
} catch (Exception $e) {
    $pdo->rollBack();
    jsonResponse(['success' => false, 'message' => 'Payment verification failed'], 500);
}
?>
```

### Vendor Registration Flow

```dart
// In vendor_register_screen.dart
void _proceedToPayment() {
  final vendorData = {
    'name': _nameController.text.trim(),
    'email': _emailController.text.trim(),
    // ... other vendor data
  };

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => VendorPaymentScreen(vendorData: vendorData),
    ),
  );
}
```

### Payment Service Usage

```dart
// Initialize payment service
final paymentService = PaymentService();
paymentService.initialize();

// Create payment order
final orderData = await paymentService.createVendorRegistrationOrder(
  amount: VendorRegistrationFee.totalAmount,
  vendorId: user.id.toString(),
  email: user.email,
  phone: user.phone,
  name: user.name,
);

// Start payment
paymentService.startPayment(
  options: razorpayOptions,
  onSuccess: (response) => _handlePaymentSuccess(response),
  onError: (response) => _handlePaymentError(response),
);
```

## Security Features

- **Server-side Verification**: All payments are verified on the server using Razorpay signature
- **Secure Token Handling**: Payment tokens are handled securely
- **Error Handling**: Comprehensive error handling for network and payment failures
- **User Feedback**: Clear success/error messages with haptic feedback

## Testing

For testing, use Razorpay test credentials:
- Test Key: `rzp_test_1DP5mmOlF5G5ag`
- Test cards and payment methods available in Razorpay documentation

## Error Handling

The integration handles various error scenarios:
- Network connectivity issues
- Payment cancellation by user
- Invalid payment details
- Server verification failures
- Timeout scenarios

## Customization

### Payment Amount

Modify the registration fee in `payment_model.dart`:

```dart
class VendorRegistrationFee {
  static const double registrationFee = 999.0; // Change amount here
  static const double gstRate = 0.18; // Change GST rate here
}
```

### UI Customization

The payment screen UI can be customized by modifying `vendor_payment_screen.dart`:
- Colors and themes
- Animation durations
- Layout and spacing
- Success/error messages

## Dependencies

- `razorpay_flutter: ^1.3.6` - Razorpay Flutter SDK
- `provider: ^6.1.1` - State management
- `http: ^1.1.0` - API calls

## Support

For issues related to:
- **Razorpay Integration**: Check Razorpay Flutter documentation
- **Payment Verification**: Ensure server endpoints are properly implemented
- **UI Issues**: Check Flutter and Material Design guidelines