<?php
/**
 * Vendor Profile Endpoint
 * Returns current vendor's profile with subscription details
 */

require_once __DIR__ . '/../config.php';

try {
    // Authenticate user
    $user = requireAuth();
    $pdo = getDBConnection();

    // Get vendor profile
    $stmt = $pdo->prepare("
        SELECT 
            v.id,
            v.uuid,
            v.vendor_type,
            v.owner_name,
            v.email,
            v.phone,
            v.store_name,
            v.store_slug,
            v.address,
            v.city,
            v.state,
            v.pincode,
            v.gst_number,
            v.pan_number,
            v.store_description,
            v.store_logo AS logo,
            v.store_banner AS banner,
            v.rating,
            v.total_reviews AS total_ratings,
            v.status,
            v.current_plan_id,
            v.plan_expires_at,
            v.available_featured_days,
            v.available_boost_days,
            v.is_verified_local,
            v.is_founding_member,
            v.created_at,
            v.updated_at,
            sp.name AS plan_name,
            sp.max_listings,
            sp.price AS plan_price,
            sp.duration_days AS plan_duration
        FROM vendors v
        LEFT JOIN subscription_plans sp ON v.current_plan_id = sp.id
        WHERE v.id = ? AND v.deleted_at IS NULL
    ");
    
    $stmt->execute([$user['id']]);
    $vendor = $stmt->fetch();

    if (!$vendor) {
        // Check if user exists but has no vendor profile
        $stmt = $pdo->prepare("SELECT id, role FROM users WHERE id = ?");
        $stmt->execute([$user['id']]);
        $userData = $stmt->fetch();
        
        if ($userData && $userData['role'] === 'vendor') {
            jsonResponse([
                'success' => false,
                'message' => 'Vendor profile not found. Please complete registration.'
            ], 404);
        }
        
        jsonResponse([
            'success' => false,
            'message' => 'Vendor profile not found'
        ], 404);
    }

    // Check if plan is expired
    $planExpired = false;
    if ($vendor['plan_expires_at'] && strtotime($vendor['plan_expires_at']) < time()) {
        $planExpired = true;
    }

    // Build response
    $response = [
        'success' => true,
        'vendor' => [
            'id' => (int) $vendor['id'],
            'uuid' => $vendor['uuid'],
            'vendor_type' => $vendor['vendor_type'],
            'owner_name' => $vendor['owner_name'],
            'email' => $vendor['email'],
            'phone' => $vendor['phone'],
            'store_name' => $vendor['store_name'],
            'store_slug' => $vendor['store_slug'],
            'store_address' => $vendor['address'],
            'city' => $vendor['city'],
            'state' => $vendor['state'],
            'pincode' => $vendor['pincode'],
            'gst_number' => $vendor['gst_number'],
            'pan_number' => $vendor['pan_number'],
            'store_description' => $vendor['store_description'],
            'logo' => formatImageURL($vendor['logo']),
            'banner' => formatImageURL($vendor['banner']),
            'rating' => floatval($vendor['rating'] ?? 0),
            'total_ratings' => (int) ($vendor['total_ratings'] ?? 0),
            'status' => $vendor['status'],
            'created_at' => $vendor['created_at'],
            'updated_at' => $vendor['updated_at'],
            
            // ✅ Subscription Details
            'current_plan_id' => $vendor['current_plan_id'] ? (int) $vendor['current_plan_id'] : null,
            'plan_expires_at' => $vendor['plan_expires_at'],
            'plan_expired' => $planExpired,
            'available_featured_days' => (int) ($vendor['available_featured_days'] ?? 0),
            'available_boost_days' => (int) ($vendor['available_boost_days'] ?? 0),
            'is_verified_local' => (bool) $vendor['is_verified_local'],
            'is_founding_member' => (bool) ($vendor['is_founding_member'] ?? false),
            
            // Plan details (if has active plan)
            'plan' => $vendor['current_plan_id'] && !$planExpired ? [
                'id' => (int) $vendor['current_plan_id'],
                'name' => $vendor['plan_name'],
                'max_listings' => (int) ($vendor['max_listings'] ?? 0),
                'price' => floatval($vendor['plan_price'] ?? 0),
                'duration_days' => (int) ($vendor['plan_duration'] ?? 0),
                'expires_at' => $vendor['plan_expires_at'],
            ] : null,
        ]
    ];

    jsonResponse($response);

} catch (Exception $e) {
    error_log("Vendor profile error: " . $e->getMessage());
    jsonResponse([
        'success' => false,
        'message' => 'Failed to fetch vendor profile: ' . $e->getMessage()
    ], 500);
}
?>
