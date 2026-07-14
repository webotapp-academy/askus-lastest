<?php
/**
 * User/Vendor Profile Endpoint
 * Returns current user's profile with subscription details (for vendors).
 *
 * Live server auth architecture:
 *   - requireAuth() calls getAuthUser()
 *   - For role='vendor': SELECT * FROM vendors WHERE id = token['user_id']
 *   - So $user returned is the VENDOR ROW (not from users table)
 *   - We must build the response from vendor data, not query users table for vendors.
 */

require_once __DIR__ . '/../../config.php';

// Support preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    // requireAuth() returns vendor row (for vendors) or user row (for users)
    $user = requireAuth();
    $pdo  = getDBConnection();

    $userRole = $user['role']; // set by getAuthUser(): $user['role'] = $tokenData['role']
    $userId   = (int) $user['id'];

    if ($userRole === 'vendor') {
        // =====================================================================
        // VENDOR: $user is already the vendors row.
        // Fetch full vendor details + subscription plan in one query.
        // =====================================================================
        $stmt = $pdo->prepare("
            SELECT
                v.id,
                v.uuid,
                v.vendor_type,
                v.owner_name,
                v.email,
                v.phone,
                v.store_logo  AS avatar,
                v.store_name,
                v.store_slug,
                v.store_description,
                v.address,
                v.city,
                v.state,
                v.pincode,
                v.gst_number,
                v.pan_number,
                v.status      AS vendor_status,
                v.rating,
                v.total_reviews,
                v.is_verified,
                v.is_verified_local,
                v.is_open,
                v.current_plan_id,
                v.plan_expires_at,
                v.available_featured_days,
                v.available_boost_days,
                v.created_at,
                sp.max_listings,
                sp.name        AS plan_name,
                sp.price       AS plan_price,
                sp.duration_days AS plan_duration
            FROM vendors v
            LEFT JOIN subscription_plans sp ON v.current_plan_id = sp.id
            WHERE v.id = ? AND v.deleted_at IS NULL
        ");
        $stmt->execute([$userId]);
        $vendorData = $stmt->fetch();

        if (!$vendorData) {
            jsonResponse(['success' => false, 'message' => 'Vendor not found'], 404);
        }

        $planExpired = false;
        if ($vendorData['plan_expires_at'] && strtotime($vendorData['plan_expires_at']) < time()) {
            $planExpired = true;
        }

        $hasActivePlan = $vendorData['current_plan_id'] && !$planExpired;

        jsonResponse([
            'success' => true,
            'user' => [
                'id'         => (int) $vendorData['id'],
                'uuid'       => $vendorData['uuid'],
                'name'       => $vendorData['owner_name'],
                'email'      => $vendorData['email'],
                'phone'      => $vendorData['phone'],
                'avatar'     => $vendorData['avatar'] ?? null,
                'role'       => 'vendor',
                'status'     => 'active', // vendor user status (not vendor approval status)
                'created_at' => $vendorData['created_at'],
                'vendor_profile' => [
                    'id'                      => (int) $vendorData['id'],
                    'vendor_type'             => $vendorData['vendor_type'],
                    'store_name'              => $vendorData['store_name'],
                    'store_slug'              => $vendorData['store_slug'],
                    'address'                 => $vendorData['address'],
                    'city'                    => $vendorData['city'],
                    'state'                   => $vendorData['state'],
                    'pincode'                 => $vendorData['pincode'],
                    'gst_number'              => $vendorData['gst_number'],
                    'pan_number'              => $vendorData['pan_number'],
                    'store_description'       => $vendorData['store_description'],
                    'status'                  => $vendorData['vendor_status'],
                    'rating'                  => floatval($vendorData['rating'] ?? 0),
                    'total_reviews'           => (int) ($vendorData['total_reviews'] ?? 0),
                    'is_verified'             => (bool) ($vendorData['is_verified'] ?? false),
                    'is_verified_local'       => (bool) ($vendorData['is_verified_local'] ?? false),
                    'is_open'                 => (bool) ($vendorData['is_open'] ?? true),
                    // Subscription details
                    'current_plan_id'         => $hasActivePlan ? (int) $vendorData['current_plan_id'] : null,
                    'max_listings'            => $hasActivePlan ? (int) ($vendorData['max_listings'] ?? 0) : 0,
                    'available_featured_days' => (int) ($vendorData['available_featured_days'] ?? 0),
                    'available_boost_days'    => (int) ($vendorData['available_boost_days'] ?? 0),
                    'plan_expires_at'         => $vendorData['plan_expires_at'],
                    'plan' => $hasActivePlan ? [
                        'id'            => (int) $vendorData['current_plan_id'],
                        'name'          => $vendorData['plan_name'],
                        'price'         => floatval($vendorData['plan_price'] ?? 0),
                        'duration_days' => (int) ($vendorData['plan_duration'] ?? 0),
                        'max_listings'  => (int) ($vendorData['max_listings'] ?? 0),
                        'expires_at'    => $vendorData['plan_expires_at'],
                    ] : null,
                ],
            ],
        ]);

    } else {
        // =====================================================================
        // USER: query the users table as normal.
        // =====================================================================
        $stmt = $pdo->prepare("
            SELECT id, uuid, name, email, phone, avatar, status, created_at
            FROM users
            WHERE id = ? AND deleted_at IS NULL
        ");
        $stmt->execute([$userId]);
        $userData = $stmt->fetch();

        if (!$userData) {
            jsonResponse(['success' => false, 'message' => 'User not found'], 404);
        }

        jsonResponse([
            'success' => true,
            'user' => [
                'id'         => (int) $userData['id'],
                'uuid'       => $userData['uuid'],
                'name'       => $userData['name'],
                'email'      => $userData['email'],
                'phone'      => $userData['phone'],
                'avatar'     => $userData['avatar'] ?? null,
                'role'       => 'user',
                'status'     => $userData['status'],
                'created_at' => $userData['created_at'],
            ],
        ]);
    }

} catch (PDOException $e) {
    error_log("Profile API PDO Error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Database error'], 500);
} catch (Exception $e) {
    error_log("Profile API Error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Internal server error'], 500);
}
?>
