# 🚀 Vendor Registration Fix - DEPLOYMENT INSTRUCTIONS

## Files to Upload to Server

You have 3 fixed PHP files that need to be uploaded to your server to fix the vendor registration flow:

---

## 1️⃣ Replace: `/api/payments/create.php`

**Local File:** `payments-create-fixed-2.php`
**Server Path:** `/api/payments/create.php`

**What it fixes:**
- Removes authentication requirement for vendor registration payments
- Allows payment creation before vendor account exists
- Uses temporary user_id (0) for vendor registration payments

---

## 2️⃣ Replace: `/api/payments/verify.php`

**Local File:** `payments-verify-fixed-2.php`
**Server Path:** `/api/payments/verify.php`

**What it fixes:**
- Removes authentication requirement for vendor registration payment verification
- Verifies Razorpay signature
- Updates payment status to 'completed'

---

## 3️⃣ Create New: `/api/auth/create-vendor-after-payment.php`

**Local File:** `api-auth-create-vendor-after-payment.php`
**Server Path:** `/api/auth/create-vendor-after-payment.php`

**What it does:**
- Creates vendor in database ONLY after payment verification
- Checks payment is completed before creating vendor
- Updates payment with vendor ID
- Returns auth token for new vendor

---

## 📋 Step-by-Step Deployment

### Option 1: Via FTP/SFTP
1. Connect to your server at `indiawebdesigns.in`
2. Navigate to `/app/askus/api/payments/`
3. **Backup existing files first!**
   - Download `create.php` → save as `create.php.backup`
   - Download `verify.php` → save as `verify.php.backup`
4. Upload `payments-create-fixed-2.php` as `create.php`
5. Upload `payments-verify-fixed-2.php` as `verify.php`
6. Navigate to `/app/askus/api/auth/`
7. Upload `api-auth-create-vendor-after-payment.php` as `create-vendor-after-payment.php`

### Option 2: Via SSH/Terminal
```bash
# Connect to your server
ssh your-user@indiawebdesigns.in

# Navigate to API directory
cd /path/to/app/askus/api

# Backup existing files
cp payments/create.php payments/create.php.backup
cp payments/verify.php payments/verify.php.backup

# Upload new files (use your preferred method)
# Then restart web server if needed
sudo systemctl restart nginx
# or
sudo systemctl restart apache2
```

---

## ✅ Verification Checklist

After deployment, verify each endpoint:

### 1. Check Payment Creation (No Auth Required)
```bash
curl -X POST https://indiawebdesigns.in/app/askus/api/payments/create.php \
  -H "Content-Type: application/json" \
  -d '{"amount":1,"email":"test@test.com","phone":"1234567890","name":"Test"}'
```
**Expected:** Should return payment order data (no 401 error)

### 2. Check Payment Verification (No Auth Required)
```bash
curl -X POST https://indiawebdesigns.in/app/askus/api/payments/verify.php \
  -H "Content-Type: application/json" \
  -d '{"razorpay_order_id":"order_xxx","razorpay_payment_id":"pay_xxx","razorpay_signature":"xxx"}'
```
**Expected:** Should verify payment (no 401 error)

### 3. Check Vendor Creation Endpoint Exists
```bash
curl -X POST https://indiawebdesigns.in/app/askus/api/auth/create-vendor-after-payment.php \
  -H "Content-Type: application/json" \
  -d '{}'
```
**Expected:** Should return error about missing fields (not 404)

---

## 🔄 Complete Flow After Deployment

```
User Registration Form
  ↓
Validate Data (no vendor created yet)
  ↓
Proceed to Payment Screen
  ↓
Create Payment Order (✅ No auth required)
  ↓
User Pays via Razorpay
  ↓
Verify Payment (✅ No auth required)
  ↓
✅ Payment Verified & Status = 'completed'
  ↓
Create Vendor in Database
  ↓
Generate Auth Token
  ↓
Success Screen
```

---

## 🐛 Troubleshooting

### Still getting "Unauthorized" error?
- Check if files were uploaded to correct paths
- Clear any server-side caching (opcache, etc.)
- Restart web server
- Check file permissions (should be readable by web server)

### Still creating vendors without payment?
- Make sure you also updated `/api/auth/vendor-register.php` to NOT create vendors
- Or keep it as-is but ensure Flutter app doesn't call it

### Database errors?
- Check if `user_id` column in `payments` table allows value `0`
- If not, may need to alter table or adjust the code

---

## 📝 Important Notes

⚠️ **Backup First!** Always backup existing files before replacing them

⚠️ **Test Thoroughly** After deployment, test the complete registration flow:
1. Register new vendor
2. Complete payment
3. Verify vendor is created in database
4. Check vendor can login

⚠️ **Database Schema** Ensure your `payments` table allows `user_id = 0` for temporary records

---

## 🎯 Files Summary

| File | Purpose | Location |
|------|---------|----------|
| `payments-create-fixed-2.php` | Create payment without auth | `/api/payments/create.php` |
| `payments-verify-fixed-2.php` | Verify payment without auth | `/api/payments/verify.php` |
| `api-auth-create-vendor-after-payment.php` | Create vendor after payment | `/api/auth/create-vendor-after-payment.php` |

---

## ✨ After Deployment

Once all files are deployed:
1. Restart the Flutter app
2. Try registering a new vendor
3. Complete the payment
4. Vendor should be created successfully!

Good luck! 🎉
