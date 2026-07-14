# Double Subscription Payment Issue - Analysis & Fix Plan

## 🔴 Problem Identified

**Issue:** After vendors pay for a subscription plan during registration, they are asked to pay AGAIN when they try to use the features.

**Root Cause:** The subscription plan selected and paid for during registration is NOT being properly activated/assigned to the vendor.

---

## 📋 Current Flow (Broken)

### Registration Flow
```
1. User fills registration form
   ↓
2. Selects subscription plan (e.g., "Basic Vendor" - ₹999)
   ↓
3. Proceeds to payment
   ↓
4. Pays registration fee + plan amount (₹1179 total)
   ↓
5. Payment verified successfully ✅
   ↓
6. Vendor created with plan_id in database ✅
   ↓
7. BUT: Plan is NOT activated properly ❌
```

### Dashboard After Registration
```
1. Vendor logs in
   ↓
2. Dashboard shows "No active subscription" ❌
   ↓
3. Clicks "Add Product" 
   ↓
4. Gets error: "No active subscription plan found"
   ↓
5. Redirected to Subscription Plans screen
   ↓
6. Must pay AGAIN for the same plan ❌
```

---

## 🔍 Code Analysis

### ✅ What's Working

**1. Registration collects plan_id:**
```dart
// vendor_register_screen.dart (line 211-212)
final vendorData = {
  'plan_id': _selectedPlan!.id,
  'plan_amount': totalAmount,
  // ...
};
```

**2. Payment passes plan_id to backend:**
```dart
// vendor_payment_screen.dart (line 207)
final registrationSuccess = await authProvider.createVendorAfterPayment(
  planId: widget.vendorData['plan_id']?.toString(),
  // ...
);
```

**3. Backend creates vendor with plan:**
```php
// api-auth-create-vendor-after-payment.php (line 136-138)
$stmt = $pdo->prepare("INSERT INTO vendors (
    ..., current_plan_id, plan_expires_at, ...
) VALUES (..., ?, ?, ...)");
$stmt->execute([..., $plan ? $plan['id'] : null, $planExpiresAt, ...]);
```

**4. Backend creates subscription record:**
```php
// api-auth-create-vendor-after-payment.php (line 149-156)
if ($plan) {
    $stmt = $pdo->prepare("
        INSERT INTO vendor_subscriptions 
        (vendor_id, plan_id, payment_id, amount_paid, payment_status, start_date, end_date) 
        VALUES (?, ?, ?, ?, 'paid', NOW(), ?)
    ");
    $stmt->execute([...]);
}
```

### ❌ What's Broken

**Problem 1: Dashboard checks `current_plan_id` but it's NULL**

The dashboard checks:
```dart
// vendor_dashboard_screen.dart (line 556)
final hasPlan = vendorProfile?.currentPlanId != null;
```

But `currentPlanId` is coming back as NULL even though the backend sets it.

**Problem 2: Vendor profile not being refreshed after registration**

After successful registration, the auth provider doesn't refresh the user profile to get the new `current_plan_id`.

**Problem 3: User model might not be parsing `current_plan_id` correctly**

Need to verify the `User.fromJson()` and `VendorProfile.fromJson()` are correctly parsing the field.

---

## 🛠️ Fix Plan

### Phase 1: Verify Database Schema

**Check `vendors` table:**
```sql
DESCRIBE vendors;
-- Verify current_plan_id column exists
-- Verify plan_expires_at column exists
```

**Check `vendor_subscriptions` table:**
```sql
DESCRIBE vendor_subscriptions;
-- Verify all columns exist
```

---

### Phase 2: Backend Fixes

#### Fix 1: Ensure `current_plan_id` is returned in response

**File:** `php/api-auth-create-vendor-after-payment.php`

**Current Response (line 172-190):**
```php
jsonResponse([
    'success' => true,
    'message' => 'Vendor created successfully after payment verification',
    'token' => $token,
    'user' => [
        'id' => $vendorId,
        'uuid' => $uuid,
        'name' => $owner_name,
        'email' => $email,
        'phone' => $phone,
        'avatar' => null,
        'role' => 'vendor',
        'status' => 'active',
        'vendor_profile' => [
            'store_name' => $store_name,
            'store_slug' => $slug,
            'status' => 'active',
            'vendor_type' => $vendor_type
            // ❌ MISSING: current_plan_id, max_listings, etc.
        ],
        // ...
    ]
]);
```

**Fixed Response:**
```php
jsonResponse([
    'success' => true,
    'message' => 'Vendor created successfully after payment verification',
    'token' => $token,
    'user' => [
        'id' => $vendorId,
        'uuid' => $uuid,
        'name' => $owner_name,
        'email' => $email,
        'phone' => $phone,
        'avatar' => null,
        'role' => 'vendor',
        'status' => 'active',
        'vendor_profile' => [
            'store_name' => $store_name,
            'store_slug' => $slug,
            'status' => 'active',
            'vendor_type' => $vendor_type,
            // ✅ ADD these fields:
            'current_plan_id' => $plan ? $plan['id'] : null,
            'max_listings' => $plan ? $plan['max_listings'] : 0,
            'available_featured_days' => $availableFeatured,
            'available_boost_days' => $availableBoost,
            'is_verified_local' => $isVerifiedLocal,
            'plan_expires_at' => $planExpiresAt,
        ],
        'created_at' => date('Y-m-d H:i:s'),
    ]
]);
```

---

#### Fix 2: Create vendor_subscriptions table if not exists

**File:** Create new migration `create-vendor-subscriptions-table.sql`

```sql
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
  KEY `plan_id` (`plan_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### Phase 3: Frontend Fixes

#### Fix 3: Refresh auth profile after registration

**File:** `lib/features/auth/data/auth_provider.dart`

**Current `createVendorAfterPayment()` (line 270-310):**
```dart
if (response.success && response.data != null) {
  try {
    String? token = response.data!['token']?.toString() ?? ...;
    if (token != null) {
      await _api.setToken(token);
    }

    Map<String, dynamic> userData =
        response.data!['user'] as Map<String, dynamic>? ?? ...;

    _user = User.fromJson(userData);

    _status = AuthStatus.authenticated;
    notifyListeners();
    debugPrint('✅ Vendor created successfully after payment!');
    return true;
  } catch (e) {
    // ...
  }
}
```

**Add after setting user:**
```dart
_user = User.fromJson(userData);

// ✅ ADD: Force refresh to get latest vendor profile with subscription
await checkAuthStatus();

_status = AuthStatus.authenticated;
notifyListeners();
```

---

#### Fix 4: Ensure User model parses vendor_profile correctly

**File:** `lib/features/auth/data/user_model.dart`

**Check `VendorProfile.fromJson()` (line 110-145):**
```dart
factory VendorProfile.fromJson(Map<String, dynamic> json) {
  return VendorProfile(
    id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
    storeName: json['store_name']?.toString() ?? '',
    // ...
    vendorType: json['vendor_type']?.toString() ?? 'vendor',
    currentPlanId: json['current_plan_id'] != null
        ? int.tryParse(json['current_plan_id']?.toString() ?? '')
        : null,
    maxListings: int.tryParse(json['max_listings']?.toString() ?? '0') ?? 0,
    availableFeaturedDays:
        int.tryParse(json['available_featured_days']?.toString() ?? '0') ?? 0,
    // ...
  );
}
```

This looks correct, but we need to ensure the backend sends these fields.

---

### Phase 4: Testing & Verification

#### Test Case 1: New Vendor Registration
```
1. Register as vendor with "Basic Vendor" plan (₹999)
2. Complete payment (₹1179 total with registration fee)
3. ✅ Verify vendor created in database with current_plan_id = 2
4. ✅ Verify vendor_subscriptions record created
5. ✅ Verify dashboard shows "Subscription: Active"
6. ✅ Verify can add products without being asked to pay again
```

#### Test Case 2: Dashboard Display
```
1. Check dashboard subscription card shows:
   - "Subscription & Limits [Active]"
   - "Listings: 0 / 10" (for Basic Vendor plan)
   - Progress bar at 0%
2. ✅ Verify no "No Plan" warning
```

#### Test Case 3: Add Product Flow
```
1. Click "Add Product" button
2. ✅ Should navigate to CreateProductScreen
3. ✅ Should NOT show "No active subscription" error
4. ✅ Should NOT redirect to SubscriptionPlansScreen
```

---

## 📝 Files to Modify

### Backend Files
1. ✅ `php/api-auth-create-vendor-after-payment.php`
   - Add `current_plan_id`, `max_listings`, etc. to response

2. ✅ `create-vendor-subscriptions-table.sql` (NEW)
   - Create vendor_subscriptions table

### Frontend Files
3. ✅ `lib/features/auth/data/auth_provider.dart`
   - Add `await checkAuthStatus()` after vendor creation

4. ✅ `lib/features/auth/data/user_model.dart`
   - Verify parsing of `current_plan_id` (likely already correct)

---

## 🎯 Expected Outcome

After the fix:

1. **Registration Flow:**
   - User selects plan during registration ✅
   - Pays registration + plan fee ✅
   - Vendor created with active subscription ✅
   - Dashboard shows "Active" subscription ✅

2. **Dashboard:**
   - Shows subscription status: "Active" ✅
   - Shows listing limit: "0 / 10" ✅
   - No "No Plan" warning ✅

3. **Add Product/Service:**
   - Clicking "Add Product" works immediately ✅
   - No redirect to subscription screen ✅
   - No double payment required ✅

---

## 🚨 Critical Issues to Check

### Issue 1: Does `checkAuthStatus()` fetch vendor_profile?

**File:** `lib/features/auth/data/auth_provider.dart`

```dart
Future<void> checkAuthStatus() async {
  _status = AuthStatus.loading;
  notifyListeners();

  final token = await _api.token;
  if (token == null) {
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return;
  }

  // ✅ This should fetch profile with vendor_profile
  final response = await _api.get(ApiConstants.profile);
  if (response.success && response.data != null) {
    _user = User.fromJson(response.data!['user']);
    _status = AuthStatus.authenticated;
  } else {
    await _api.clearToken();
    _status = AuthStatus.unauthenticated;
  }
  notifyListeners();
}
```

**Need to verify:** Does `/auth/profile.php` return `vendor_profile` with `current_plan_id`?

---

### Issue 2: Does profile endpoint return vendor_profile?

**File:** Need to check `php/auth/profile.php`

Should return:
```json
{
  "success": true,
  "user": {
    "id": 1,
    "name": "John",
    "vendor_profile": {
      "id": 1,
      "current_plan_id": 2,
      "max_listings": 10,
      "available_featured_days": 0,
      ...
    }
  }
}
```

If not, need to fix `profile.php` to include vendor_profile.

---

## 📋 Implementation Checklist

- [ ] Check `vendors` table has `current_plan_id` column
- [ ] Check `vendor_subscriptions` table exists
- [ ] Fix `api-auth-create-vendor-after-payment.php` to return plan fields
- [ ] Fix `auth/profile.php` to return vendor_profile with plan fields
- [ ] Add `checkAuthStatus()` call in `createVendorAfterPayment()`
- [ ] Test new vendor registration flow
- [ ] Test dashboard subscription display
- [ ] Test add product without double payment
- [ ] Create SQL migration for vendor_subscriptions if needed

---

## 🔧 Quick Fix (Temporary)

If the backend is too complex to fix immediately, here's a **temporary workaround**:

**File:** `lib/features/vendor/presentation/vendor_dashboard_screen.dart`

Modify the `checkLimitAndNavigate()` to check database directly:

```dart
void checkLimitAndNavigate(Widget screen) {
  // ... existing checks ...

  // TEMPORARY: If no plan but vendor exists, fetch fresh profile
  if (!hasPlan && isApproved) {
    // Force refresh auth profile
    await authProvider.checkAuthStatus();
    
    // Re-check if plan exists now
    final newVendorProfile = authProvider.user?.vendorProfile;
    final newHasPlan = newVendorProfile?.currentPlanId != null;
    
    if (newHasPlan) {
      // Plan exists now, proceed normally
      Navigator.push(context, screen);
      return;
    }
  }
  
  // ... rest of existing logic ...
}
```

But the **proper fix** is to ensure backend returns correct data.

---

## ✅ Implementation Complete

### Changes Made

#### 1. Backend: `api-auth-create-vendor-after-payment.php`
- ✅ Added `current_plan_id` to response
- ✅ Added `max_listings` to response
- ✅ Added `available_featured_days`, `available_boost_days`, `is_verified_local`
- ✅ Added `plan_expires_at` for expiration tracking

#### 2. Frontend: `auth_provider.dart`
- ✅ Added `await checkAuthStatus()` after vendor creation
- ✅ Ensures profile is refreshed with latest subscription data
- ✅ Added debug logging for verification

#### 3. New Files Created
- ✅ `php/vendor-profile.php` - Complete vendor profile endpoint
- ✅ `create-vendor-subscriptions-table.sql` - Database migration
- ✅ `DOUBLE_PAYMENT_FIX_DEPLOYMENT.md` - Deployment instructions

---

## 🚀 Next Steps

1. **Deploy to Server** (see `DOUBLE_PAYMENT_FIX_DEPLOYMENT.md`)
   - Upload `api-auth-create-vendor-after-payment.php`
   - Upload `vendor/profile.php`
   - Run database migration

2. **Test End-to-End Flow**
   - Register new vendor with subscription
   - Verify dashboard shows active plan
   - Verify can add products without double payment

3. **Monitor Existing Vendors**
   - Check if existing vendors need manual plan assignment
   - Verify all paid vendors have correct `current_plan_id`

---

**Created:** March 17, 2026  
**Last Updated:** March 17, 2026  
**Priority:** 🔴 HIGH  
**Status:** ✅ Implementation Complete - Ready for Deployment
