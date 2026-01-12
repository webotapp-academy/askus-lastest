# 🔍 Payment Creation Debugging Guide

## Step 1: Check Flutter Debug Logs

When you click "Pay ₹1179", check the Flutter debug console for these logs:

```
🌐 API POST Request:
📍 URL: https://indiawebdesigns.in/app/askus/api/payments/vendor-create.php
📋 Headers: {Content-Type: application/json, Accept: application/json, Authorization: Bearer xxx}
📦 Body: {"vendor_id":123,"amount":1179.0}

📥 API POST Response:
📊 Status Code: 500 (or other error code)
📄 Response Body: {"success":false,"message":"error details"}
```

**What to look for:**
- ✅ **URL is correct**: Should end with `/payments/vendor-create.php`
- ✅ **Authorization header present**: Should have `Bearer xxx`
- ❌ **Status Code 500**: Server error (check server logs)
- ❌ **Status Code 404**: File not found
- ❌ **Status Code 401**: Authentication failed

## Step 2: Check Server Setup

### 2.1 Verify File Locations
Make sure these files exist on your server:

```
/your-api-root/
├── config.php (updated with Razorpay keys)
└── payments/
    ├── vendor-create.php (the debug version)
    └── vendor-verify.php
```

### 2.2 Test API Endpoint Directly
Visit this URL in your browser (replace with your domain):
```
https://indiawebdesigns.in/app/askus/api/test-payment-api.php
```

Expected response:
```json
{
  "step": 1,
  "status": "Config loaded successfully"
}
```

## Step 3: Check Server Logs

Look at your server's error logs (usually in `/var/log/apache2/error.log` or similar):

```bash
tail -f /path/to/error.log
```

Common errors you might see:
- `RAZORPAY_KEY_ID not defined` → Add keys to config.php
- `Call to undefined function requireAuth()` → config.php not loaded properly
- `Table 'payments' doesn't exist` → Database issue
- `Access denied for user` → Database credentials wrong

## Step 4: Test Database Connection

Upload and run the debug script:
```
https://indiawebdesigns.in/app/askus/api/debug-payment.php
```

This will show:
- ✅ Database connection status
- ✅ Payments table columns
- ❌ Missing columns or connection issues

## Step 5: Test Authentication

The payment creation requires authentication. Make sure:

1. **User is logged in** in the Flutter app
2. **Auth token is valid** (check API client logs)
3. **requireAuth() function works** (test with debug script)

## Step 6: Common Fixes

### Fix 1: Add Razorpay Keys to config.php
```php
// Add these lines to your config.php after UPLOAD_URL
define('RAZORPAY_KEY_ID', 'rzp_test_1DP5mmOlF5G5ag');
define('RAZORPAY_KEY_SECRET', 'your_secret_key');
```

### Fix 2: Update API Endpoint Path
If your file structure is different, update the Flutter constant:
```dart
// In lib/core/constants/api_constants.dart
static const String vendorPaymentCreate = '/payments/vendor-create.php';
```

### Fix 3: Fix Database Columns
If you get column errors, run this SQL to add missing columns:
```sql
ALTER TABLE payments 
ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50) DEFAULT 'razorpay',
ADD COLUMN IF NOT EXISTS currency VARCHAR(3) DEFAULT 'INR';
```

### Fix 4: Test with Minimal Script
Replace your `vendor-create.php` with this minimal test:
```php
<?php
header('Content-Type: application/json');
echo json_encode([
    'success' => true,
    'message' => 'Test endpoint working',
    'timestamp' => date('Y-m-d H:i:s')
]);
?>
```

If this works, gradually add back the real functionality.

## Step 7: Enable Detailed Logging

Replace your `vendor-create.php` with `vendor-create-debug.php` which logs every step.

Then check the logs to see exactly where it fails:
```
=== VENDOR PAYMENT CREATE DEBUG ===
Step 1: Loading config...
✅ Config loaded
Step 2: Checking Razorpay config...
❌ Error: RAZORPAY_KEY_ID not defined
```

## Step 8: Test Payment Flow

1. **Upload debug files** to your server
2. **Add Razorpay keys** to config.php
3. **Test authentication** with test script
4. **Run payment creation** and check logs
5. **Fix issues one by one** based on error messages

## Quick Checklist

- [ ] Razorpay keys added to config.php
- [ ] vendor-create.php uploaded to /payments/ folder
- [ ] File permissions are correct (755 for folders, 644 for files)
- [ ] Database connection works
- [ ] User authentication works
- [ ] API endpoint URL is correct in Flutter app
- [ ] Server error logs checked

## Need Help?

If you're still stuck, share:
1. **Flutter debug logs** (the API request/response)
2. **Server error logs** (any PHP errors)
3. **Test script results** (what the debug scripts show)

This will help identify the exact issue!