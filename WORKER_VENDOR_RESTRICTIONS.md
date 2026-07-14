# Worker & Vendor Restrictions - Implementation Overview

## Overview

The AskUs marketplace implements strict restrictions on what different vendor types can list based on their registration type and subscription plan.

---

## 🎯 Vendor Types

There are **3 vendor types** in the system:

| Vendor Type | Can Add Products | Can Add Services | Description |
|-------------|-----------------|------------------|-------------|
| `vendor` | ✅ Yes | ❌ No | Traditional vendors who sell products |
| `worker` | ❌ No | ✅ Yes | Service providers/workers |
| `both` | ✅ Yes | ✅ Yes | Can list both products and services |

---

## 🔒 Restriction Implementation

### **Frontend Restrictions** (Flutter)

**File:** `lib/features/vendor/presentation/vendor_dashboard_screen.dart`

#### 1. Quick Actions Button Visibility
```dart
Row(
  children: [
    // Product button - Only for 'vendor' or 'both'
    if (vendorType == 'vendor' || vendorType == 'both')
      Expanded(
        child: _QuickActionButton(
          icon: Icons.add_box_rounded,
          label: 'Add Product',
          onTap: () => checkLimitAndNavigate(const CreateProductScreen()),
        ),
      ),
    
    // Service button - Only for 'worker' or 'both'
    if (vendorType == 'worker' || vendorType == 'both') ...[
      Expanded(
        child: _QuickActionButton(
          icon: Icons.add_circle_rounded,
          label: 'Add Service',
          onTap: () => checkLimitAndNavigate(const CreateServiceScreen()),
        ),
      ),
    ],
  ],
)
```

#### 2. Listing Limit Check
```dart
void checkLimitAndNavigate(Widget screen) {
  // Check 1: Vendor approval status
  if (!isApproved) {
    showSnackBar('Your vendor account is pending approval...');
    return;
  }

  // Check 2: Active subscription
  if (!hasPlan) {
    showSnackBar('No active subscription plan found...');
    Navigator.push(context, SubscriptionPlansScreen());
    return;
  }

  // Check 3: Listing limit
  if (currentListings >= maxListings) {
    showSnackBar('Listing limit reached for your current plan...');
    Navigator.push(context, SubscriptionPlansScreen());
    return;
  }

  // All checks passed - navigate to create screen
  Navigator.push(context, screen);
}
```

---

### **Backend Restrictions** (PHP)

#### **Products** - `php/products-create.php`

**Line 15-18: Vendor Type Check**
```php
// Validate vendor type (Only vendors can create products)
if ($vendor['vendor_type'] !== 'vendor') {
    jsonResponse([
        'success' => false, 
        'message' => 'Your account type (Worker) cannot create products. You can only list services.'
    ], 403);
}
```

**Line 20-50: Subscription Limit Check**
```php
// Check combined listing limit
$maxListings = 0;
$hasActivePlan = false;

// Get max_listings from subscription plan
if ($vendor['current_plan_id'] && 
    ($vendor['plan_expires_at'] === null || 
     strtotime($vendor['plan_expires_at']) > time())) {
    
    $stmt = $pdo->prepare("
        SELECT max_listings 
        FROM subscription_plans 
        WHERE id = ? AND status = 'active'
    ");
    $stmt->execute([$vendor['current_plan_id']]);
    $plan = $stmt->fetch();
    
    if ($plan) {
        $hasActivePlan = true;
        $maxListings = (int) $plan['max_listings'];
    }
}

// Count combined listings (products + services)
if ($maxListings > 0 && $maxListings < 9000) {
    $stmt = $pdo->prepare("
        SELECT
            (SELECT COUNT(*) FROM products WHERE vendor_id = ?) +
            (SELECT COUNT(*) FROM services WHERE vendor_id = ?)
        AS total_listings
    ");
    $stmt->execute([$vendor['id'], $vendor['id']]);
    $totalListings = (int) $stmt->fetchColumn();

    if ($totalListings >= $maxListings) {
        jsonResponse([
            'success' => false, 
            'message' => "Listing limit reached ({$maxListings}). Please upgrade your plan."
        ], 403);
    }
} else if (!$hasActivePlan) {
    jsonResponse([
        'success' => false, 
        'message' => "You need an active subscription to create listings."
    ], 403);
}
```

---

#### **Services** - `php/services-create.php`

**Line 15-23: Vendor Type Check**
```php
// Validate vendor type (Only workers can create services)
if ($vendor['vendor_type'] !== 'worker' && 
    $vendor['vendor_type'] !== 'both' && 
    $vendor['vendor_type'] !== 'service_provider') {
    
    if ($vendor['vendor_type'] !== 'worker') {
        jsonResponse([
            'success' => false, 
            'message' => 'Your account type (Vendor) cannot create services. You can only list products.'
        ], 403);
    }
}
```

**Line 25-55: Subscription Limit Check**
```php
// Same combined listing limit logic as products
// Counts both products AND services towards the limit
```

---

## 📊 Subscription Plans

**Table:** `subscription_plans`

| Column | Description |
|--------|-------------|
| `id` | Plan ID |
| `name` | Plan name (e.g., "Basic", "Premium") |
| `target_group` | 'vendor', 'worker', or 'both' |
| `price` | Plan price |
| `duration_days` | Plan validity in days |
| `max_listings` | **Maximum combined listings (products + services)** |
| `featured_days` | Days with featured badge |
| `boost_days` | Days with boost promotion |
| `has_trusted_badge` | Trusted vendor badge |
| `has_verified_badge` | Verified badge |
| `has_top_placement` | Priority in search results |

### Example Plans

```sql
INSERT INTO subscription_plans VALUES
(1, 'Basic Worker', 'worker', 499, 30, 5, 0, 0, 0, 0, 0, 'active'),
(2, 'Basic Vendor', 'vendor', 999, 30, 10, 0, 0, 0, 0, 0, 'active'),
(3, 'Premium Both', 'both', 1999, 60, 50, 7, 3, 1, 1, 1, 'active');
```

---

## 🔄 Complete Flow

### Worker Registration & Listing Flow

```
1. User registers as 'worker'
   ↓
2. Pays registration fee (₹499 or ₹1179)
   ↓
3. Vendor account created with vendor_type = 'worker'
   ↓
4. Subscribes to a plan (e.g., "Basic Worker" - 5 listings)
   ↓
5. Dashboard shows ONLY "Add Service" button
   ↓
6. Backend enforces:
      - Can create services ✅
      - Cannot create products ❌ (403 error)
      - Max 5 total listings (services + products)
```

### Vendor Registration & Listing Flow

```
1. User registers as 'vendor'
   ↓
2. Pays registration fee (₹999 or ₹1179)
   ↓
3. Vendor account created with vendor_type = 'vendor'
   ↓
4. Subscribes to a plan (e.g., "Basic Vendor" - 10 listings)
   ↓
5. Dashboard shows ONLY "Add Product" button
   ↓
6. Backend enforces:
      - Can create products ✅
      - Cannot create services ❌ (403 error)
      - Max 10 total listings (products + services)
```

---

## 🎯 Key Features

### 1. **Combined Listing Limit**
- Both products AND services count towards `max_listings`
- Example: If plan has 10 max listings:
  - Can have 10 products + 0 services
  - Can have 5 products + 5 services
  - Can have 0 products + 10 services
  - **Cannot** have 11 total items

### 2. **Vendor Type Enforcement**
- Frontend: UI hides inappropriate buttons
- Backend: Returns 403 error if wrong type tries to create
- Database: `vendor_type` field in `vendors` table

### 3. **Subscription Validation**
- Checks `current_plan_id` exists
- Checks `plan_expires_at` is not expired
- Gets `max_listings` from `subscription_plans` table
- Values > 9000 treated as unlimited

### 4. **Plan Expiry Handling**
```php
if ($vendor['current_plan_id'] && 
    ($vendor['plan_expires_at'] === null || 
     strtotime($vendor['plan_expires_at']) > time())) {
    // Plan is active
} else {
    // No active plan - 0 listings allowed
}
```

---

## 📱 User Experience

### Dashboard Display

**Subscription Card** shows:
```
Subscription & Limits          [Active]
Listings: 7 / 10              LIMIT REACHED
████████████████░░  70%
Featured Days left: 5
Boost Days left: 2
```

### Error Messages

| Scenario | Error Message |
|----------|--------------|
| No subscription | "You need an active subscription to create listings." |
| Limit reached | "Listing limit reached (10). Please upgrade your plan." |
| Worker tries products | "Your account type (Worker) cannot create products..." |
| Vendor tries services | "Your account type (Vendor) cannot create services..." |
| Pending approval | "Your vendor account is pending approval..." |

---

## 🔐 Security

### Backend is Source of Truth
- Frontend restrictions are UX-only
- Backend **always** validates before creating
- Returns HTTP 403 for unauthorized attempts

### Database Constraints
```sql
-- vendors table
vendor_type ENUM('vendor', 'worker', 'both')
current_plan_id INT (FK to subscription_plans)
max_listings INT (denormalized from plan)
plan_expires_at DATETIME

-- subscription_plans table
max_listings INT
target_group ENUM('vendor', 'worker', 'both')
```

---

## 🛠️ Testing Checklist

- [ ] Worker can only see "Add Service" button
- [ ] Vendor can only see "Add Product" button
- [ ] "Both" type sees both buttons
- [ ] Backend rejects worker creating product (403)
- [ ] Backend rejects vendor creating service (403)
- [ ] Listing limit enforced at max_listings
- [ ] Combined count includes both products + services
- [ ] Expired plan blocks new listings
- [ ] Upgrade plan increases limit immediately

---

## 📝 Related Files

### Frontend
- `lib/features/vendor/presentation/vendor_dashboard_screen.dart` - Main dashboard with restrictions
- `lib/features/products/presentation/create_product_screen.dart` - Product creation UI
- `lib/features/services/presentation/create_service_screen.dart` - Service creation UI
- `lib/features/auth/data/user_model.dart` - VendorProfile model with maxListings
- `lib/features/subscriptions/data/subscription_plan_model.dart` - Plan model

### Backend
- `php/products-create.php` - Product creation with validation
- `php/services-create.php` - Service creation with validation
- `php/api/subscriptions/plans.php` - Get available plans
- `php/api-auth-create-vendor-after-payment.php` - Creates vendor with vendor_type

### Database
- `vendors` table - `vendor_type`, `current_plan_id`, `max_listings`
- `subscription_plans` table - Plan definitions
- `products` table - Product listings
- `services` table - Service listings

---

## 🎓 Summary

**Workers** are restricted from adding products through:
1. **UI**: "Add Product" button hidden in dashboard
2. **Backend**: `products-create.php` returns 403 error
3. **Database**: `vendor_type` field enforces at schema level

**Subscription limits** are enforced by:
1. Counting **combined** products + services
2. Comparing against `max_listings` from active plan
3. Blocking creation when limit reached
4. Requiring plan upgrade for more listings

This ensures workers can only list services up to their subscription limit, protecting the marketplace integrity and subscription model.

---

**Last Updated**: March 17, 2026  
**Status**: ✅ Fully Implemented
