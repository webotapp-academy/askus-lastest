# 🔍 RAZORPAY "SOMETHING WENT WRONG" - DIAGNOSIS GUIDE

## Issue: Error on Physical Device Too

If you're seeing "Uh! oh! Something went wrong" on a **physical device**, this indicates a real configuration issue, not an emulator problem.

## 🚨 Most Common Causes

### 1. **Invalid or Missing Razorpay API Key** (90% of cases)
The key sent from server doesn't match your Razorpay account

### 2. **Razorpay Test Mode Not Enabled**
Your Razorpay dashboard might be in live mode while using test keys

### 3. **Key Mismatch Between Server and Order**
The order was created with one key, but a different key is being used in the app

### 4. **Razorpay Account Not Activated**
Your Razorpay account needs KYC verification

## 🔧 Step-by-Step Diagnosis

### Step 1: Run the Diagnostic Script

```bash
cd /path/to/your/backend
php test-razorpay-diagnosis.php
```

This will check:
- ✓ If RAZORPAY_KEY_ID is defined
- ✓ If key format is valid (rzp_test_xxx)
- ✓ If Razorpay API is accessible
- ✓ Database connection
- ✓ Required tables exist

### Step 2: Check Flutter App Logs

Run your app with verbose logging:

```bash
flutter run --release
```

Look for these critical lines in the output:

```
🔍 Validating required fields...
   Key: ✓ Present (rzp_test_xxxxx)     # ← MUST show ✓ Present
   Order ID: ✓ Present (vendor_reg_)  # ← MUST show ✓ Present
   Amount: ✓ Present (117882)          # ← MUST show ✓ Present
```

**If any shows "✗ MISSING"** → That's your problem!

### Step 3: Check the Key Value

In your logs, find this line:
```
💳 Final Options:
   ├─ key: rzp_test_XXXXXXXXXXXXX
```

**Compare this key with your Razorpay Dashboard:**
1. Go to https://dashboard.razorpay.com/
2. Click "Settings" → "API Keys"
3. Check if Test Mode is enabled (toggle at top)
4. Compare the "Key Id" shown there with what's in your logs

**They MUST match exactly!**

### Step 4: Verify Your Backend Config

Check your `config.php` file:

```php
// This is what you should have:
define('RAZORPAY_KEY_ID', 'rzp_test_1DP5mmOlF5G5ag'); // Your actual test key
define('RAZORPAY_KEY_SECRET', 'your_secret_key');     // Your actual secret
```

**Common mistakes:**
- ❌ Using placeholder values (your_key_here)
- ❌ Extra spaces before/after the key
- ❌ Missing 'rzp_test_' prefix
- ❌ Using live key (rzp_live_) while in test mode
- ❌ Key is undefined or commented out

## 🎯 Quick Fixes

### Fix 1: Key Not Defined

If diagnostic shows "RAZORPAY_KEY_ID is NOT defined":

1. Edit your `config.php`
2. Add these lines:
```php
define('RAZORPAY_KEY_ID', 'rzp_test_YOUR_KEY_HERE');
define('RAZORPAY_KEY_SECRET', 'YOUR_SECRET_HERE');
```
3. Restart your PHP server

### Fix 2: Wrong Key Being Used

From your earlier logs, the key being used is: `rzp_test_RHaYMz3TX2P05g`

**Action:** 
1. Go to Razorpay Dashboard
2. Verify this key exists and is active
3. If not, update `config.php` with the correct key
4. If yes, check if this account is activated

### Fix 3: Test Mode Issues

On Razorpay Dashboard:
1. Check the toggle at the top - it should say **"Test Mode"** (not "Live Mode")
2. If in Live Mode, switch to Test Mode
3. Use Test Mode API keys in your app

### Fix 4: Account Not Activated

If your Razorpay account is new:
1. You might need to complete KYC
2. Or enable test mode explicitly
3. Or wait for account activation

In test mode, you should be able to test immediately without KYC.

## 📱 Testing After Fixes

After making changes:

```bash
# 1. Rebuild the app
flutter clean
flutter build apk

# 2. Install on device
flutter install

# 3. Watch logs
flutter logs
```

## 🔍 What to Look For in Logs

### ✅ GOOD - Payment should work:
```
✅ Order data is valid, preparing Razorpay options...
🔍 Validating required fields...
   Key: ✓ Present (rzp_test_RHaYMz3TX2P05g)
   Order ID: ✓ Present (vendor_reg_13_1768034768)
   Amount: ✓ Present (117882)
✅ All validations passed, calling Razorpay.open()...
✅ Razorpay.open() called successfully
```

### ❌ BAD - Will fail:
```
❌ CRITICAL: Razorpay Key is missing from server response!
📋 This will cause "Something went wrong" error in Razorpay checkout
```

Or:
```
⚠️ WARNING: Invalid Razorpay key format: your_key_here
   Expected format: rzp_test_xxxxx or rzp_live_xxxxx
```

## 🧪 Test with Razorpay Test Cards

Once you fix the key issue, use these test cards:

**Success:**
- Card: 4111 1111 1111 1111
- CVV: Any 3 digits
- Expiry: Any future date

**Failure:**
- Card: 4111 1111 1111 1234

## 🆘 Still Not Working?

If after all checks it still fails:

### Check Server Logs

```bash
# On your server
tail -f /path/to/php/error.log
```

Look for:
- "Razorpay Key ID found: ..." ← Should show your key
- "Payment order created successfully"
- "Response: {success:true, ...}"

### Check Network Request

Use Flutter DevTools or check logs for the API response:
```
📦 Response data: {payment_id: 123, order_id: vendor_reg_13_..., razorpay_key: rzp_test_...}
```

### Enable Razorpay Debug Mode

In your app, add more detailed Razorpay logs by modifying payment_service.dart.

### Contact Razorpay Support

If the key is correct but still fails:
1. Your Razorpay account might have restrictions
2. Contact Razorpay support with your Key ID (not secret!)
3. Ask them to check if test mode is enabled for your account

## 📋 Checklist

Before declaring it broken:

- [ ] Run `test-razorpay-diagnosis.php`
- [ ] Verify RAZORPAY_KEY_ID is defined in config.php
- [ ] Verify key format starts with rzp_test_ or rzp_live_
- [ ] Check Razorpay Dashboard is in Test Mode
- [ ] Compare key in logs with key in Razorpay Dashboard
- [ ] All validations in app logs show ✓ Present
- [ ] Server logs show "Payment order created successfully"
- [ ] Razorpay API authentication test passes

## 🎯 Expected Result

When everything is correct, you should see:
1. ✅ Order created on server
2. ✅ All fields validated in app
3. ✅ Razorpay checkout opens
4. ✅ Test card payment succeeds
5. ✅ Success screen appears

---

**Next Step:** Run `test-razorpay-diagnosis.php` and share the output!
