# Double Payment Fix - Deployment Instructions

## 🔴 Problem
Vendors pay for a subscription plan during registration, but are asked to pay again when trying to use features.

## ✅ Solution
Fixed the backend to return subscription details and ensured frontend refreshes the profile after registration.

---

## 📦 Files to Upload to Server

### 1. Updated: `api/auth/create-vendor-after-payment.php`
**Local File:** `php/api-auth-create-vendor-after-payment.php`  
**Server Path:** `/app/askus/api/auth/create-vendor-after-payment.php`

**What Changed:**
- ✅ Now returns `current_plan_id`, `max_listings`, `available_featured_days`, etc. in response
- ✅ Includes `plan_expires_at` for expiration checking
- ✅ Adds vendor profile `id` field

### 2. New: `api/vendor/profile.php`
**Local File:** `php/vendor-profile.php`  
**Server Path:** `/app/askus/api/vendor/profile.php`

**Purpose:**
- ✅ Returns complete vendor profile with subscription details
- ✅ Includes plan information and limits
- ✅ Checks if plan is expired

### 3. New: Database Migration
**Local File:** `create-vendor-subscriptions-table.sql`  
**Action:** Run on database

**Purpose:**
- ✅ Creates `vendor_subscriptions` table for tracking subscription history
- ✅ Adds proper indexes for performance

---

## 🚀 Deployment Steps

### Option 1: Via FTP/SFTP (Recommended)

```bash
# 1. Connect to server
Host: indiawebdesigns.in
Username: your-username
Password: your-password

# 2. Navigate to API directory
cd /app/askus/api

# 3. Backup existing file
cp auth/create-vendor-after-payment.php auth/create-vendor-after-payment.php.backup

# 4. Upload updated file
# Upload: php/api-auth-create-vendor-after-payment.php
# As: auth/create-vendor-after-payment.php

# 5. Create new vendor profile endpoint
# Upload: php/vendor-profile.php
# As: vendor/profile.php

# 6. Set permissions
chmod 644 auth/create-vendor-after-payment.php
chmod 644 vendor/profile.php
```

### Option 2: Via SSH

```bash
# SSH into server
ssh your-user@indiawebdesigns.in

# Navigate to API directory
cd /app/askus/api

# Backup existing file
cp auth/create-vendor-after-payment.php auth/create-vendor-after-payment.php.backup

# Create vendor directory if not exists
mkdir -p vendor

# Use nano/vim to create files, or upload via SCP
# Then set permissions
chmod 644 auth/create-vendor-after-payment.php
chmod 644 vendor/profile.php

# Restart web server
sudo systemctl restart nginx
```

### Option 3: Via cPanel File Manager

1. Login to cPanel
2. Go to File Manager
3. Navigate to `/app/askus/api`
4. Download backup of `auth/create-vendor-after-payment.php`
5. Upload new `auth/create-vendor-after-payment.php`
6. Create `vendor/` directory if not exists
7. Upload `vendor/profile.php`
8. Set permissions to 644

---

## 🗄️ Database Migration

### Step 1: Run SQL Migration

```sql
-- Execute: create-vendor-subscriptions-table.sql

-- Or run manually:
CREATE TABLE IF NOT EXISTS `vendor_subscriptions` (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `vendor_id` bigint UNSIGNED NOT NULL,
  `plan_id` int UNSIGNED NOT NULL,
  `payment_id` int UNSIGNED DEFAULT NULL,
  `amount_paid` decimal(10,2) DEFAULT NULL,
  `payment_status` enum('pending','paid','failed','refunded') DEFAULT 'pending',
  `start_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `end_date` timestamp NULL DEFAULT NULL,
  `status` enum('active','expired','cancelled') DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `vendor_id` (`vendor_id`),
  KEY `plan_id` (`plan_id`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Step 2: Verify Vendors Table Columns

```sql
-- Check if vendors table has required columns
DESCRIBE vendors;

-- Should have these columns:
-- - current_plan_id (int)
-- - plan_expires_at (timestamp)
-- - available_featured_days (int)
-- - available_boost_days (int)
-- - is_verified_local (tinyint)

-- If missing, add them:
ALTER TABLE `vendors` 
ADD COLUMN `current_plan_id` int UNSIGNED DEFAULT NULL AFTER `vendor_type`,
ADD COLUMN `plan_expires_at` timestamp NULL DEFAULT NULL AFTER `current_plan_id`,
ADD COLUMN `available_featured_days` int DEFAULT 0 AFTER `plan_expires_at`,
ADD COLUMN `available_boost_days` int DEFAULT 0 AFTER `available_featured_days`,
ADD COLUMN `is_verified_local` tinyint(1) DEFAULT 0 AFTER `available_boost_days`;
```

### Step 3: Verify Subscription Plans Table

```sql
-- Check if subscription_plans table exists and has data
SELECT * FROM subscription_plans WHERE status = 'active';

-- Should have columns:
-- - id
-- - name
-- - target_group (vendor/worker/both)
-- - price
-- - duration_days
-- - max_listings
-- - featured_days
-- - boost_days
-- - has_trusted_badge
-- - has_verified_badge
-- - has_top_placement
```

---

## ✅ Verification Checklist

After deployment, test the following:

### Test 1: New Vendor Registration
```
1. Register as new vendor
2. Select "Basic Vendor" plan (₹999)
3. Complete payment (₹1179 total)
4. ✅ Check dashboard shows:
   - "Subscription & Limits [Active]"
   - "Listings: 0 / 10"
   - Progress bar at 0%
5. ✅ Click "Add Product" - should open create form
6. ✅ Should NOT see "No active subscription" error
```

### Test 2: Database Verification
```sql
-- Check vendor was created with plan
SELECT 
    id, 
    owner_name, 
    email, 
    current_plan_id, 
    plan_expires_at,
    available_featured_days
FROM vendors 
ORDER BY created_at DESC 
LIMIT 1;

-- Should show:
-- current_plan_id: 2 (or whatever plan ID)
-- plan_expires_at: [future date]
-- available_featured_days: [from plan]
```

### Test 3: API Response Verification
```bash
# Test vendor profile endpoint
curl -X GET https://indiawebdesigns.in/app/askus/api/vendor/profile.php \
  -H "Authorization: Bearer YOUR_TOKEN"

# Should return:
{
  "success": true,
  "vendor": {
    "current_plan_id": 2,
    "max_listings": 10,
    "plan": {
      "id": 2,
      "name": "Basic Vendor",
      "max_listings": 10,
      ...
    }
  }
}
```

### Test 4: Existing Vendors
```
1. Login as existing vendor who paid during registration
2. ✅ Check if subscription details appear
3. ✅ Verify can add products/services
4. ✅ Verify listing count is correct
```

---

## 🔧 Troubleshooting

### Issue 1: "current_plan_id is NULL"

**Cause:** Vendor created before fix was deployed

**Fix:**
```sql
-- Manually set plan for existing vendors
UPDATE vendors 
SET 
    current_plan_id = 2,  -- Replace with actual plan ID
    plan_expires_at = DATE_ADD(NOW(), INTERVAL 30 DAY),
    available_featured_days = 0,
    available_boost_days = 0,
    is_verified_local = 0
WHERE email = 'vendor@example.com';  -- Replace with vendor email
```

### Issue 2: "Profile endpoint returns 404"

**Cause:** File not uploaded or wrong path

**Fix:**
```bash
# Verify file exists
ls -la /app/askus/api/vendor/profile.php

# Check file permissions
chmod 644 /app/askus/api/vendor/profile.php

# Check web server config
# Ensure /api/vendor/ directory is accessible
```

### Issue 3: "Dashboard still shows no plan"

**Cause:** Frontend cache or token issue

**Fix:**
```dart
// In Flutter app, force logout and login again
// Or clear app data and login fresh

// Alternatively, add this to vendor_dashboard_screen.dart:
@override
void initState() {
  super.initState();
  // Force refresh profile
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<AuthProvider>().checkAuthStatus();
  });
}
```

---

## 📊 Monitoring

### Query: Check All Vendors with Plans

```sql
SELECT 
    v.id,
    v.owner_name,
    v.email,
    v.vendor_type,
    v.current_plan_id,
    sp.name AS plan_name,
    sp.max_listings,
    v.plan_expires_at,
    v.available_featured_days,
    CASE 
        WHEN v.plan_expires_at < NOW() THEN 'EXPIRED'
        WHEN v.plan_expires_at IS NULL THEN 'NO PLAN'
        ELSE 'ACTIVE'
    END AS plan_status
FROM vendors v
LEFT JOIN subscription_plans sp ON v.current_plan_id = sp.id
WHERE v.deleted_at IS NULL
ORDER BY v.created_at DESC;
```

### Query: Check Vendor Subscriptions History

```sql
SELECT 
    vs.id,
    v.owner_name,
    sp.name AS plan_name,
    vs.amount_paid,
    vs.payment_status,
    vs.start_date,
    vs.end_date,
    vs.status
FROM vendor_subscriptions vs
JOIN vendors v ON vs.vendor_id = v.id
JOIN subscription_plans sp ON vs.plan_id = sp.id
ORDER BY vs.created_at DESC;
```

---

## 🎯 Expected Results

After deployment:

1. ✅ New vendors see active subscription immediately
2. ✅ No double payment required
3. ✅ Dashboard shows correct listing limits
4. ✅ Can add products/services without errors
5. ✅ Subscription card shows "Active" status
6. ✅ Progress bar shows correct usage (e.g., "0 / 10")

---

## 📝 Files Modified Summary

| File | Status | Purpose |
|------|--------|---------|
| `php/api-auth-create-vendor-after-payment.php` | ✅ Updated | Returns subscription details |
| `php/vendor-profile.php` | ✅ New | Profile endpoint with plan info |
| `create-vendor-subscriptions-table.sql` | ✅ New | Database migration |
| `lib/features/auth/data/auth_provider.dart` | ✅ Updated | Refreshes profile after registration |

---

## 🚨 Rollback Plan

If issues occur:

```bash
# 1. Restore backup
cp auth/create-vendor-after-payment.php.backup auth/create-vendor-after-payment.php

# 2. Remove new endpoint
rm vendor/profile.php

# 3. Restart web server
sudo systemctl restart nginx
```

---

**Deployed By**: CodeMuji  
**Date**: March 17, 2026  
**Priority**: 🔴 HIGH  
**Status**: Ready for Deployment
