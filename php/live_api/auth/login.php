<?php
require_once __DIR__ . '/../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}

try {
    $input = getInput();
    $identifier = trim($input['phone'] ?? $input['identifier'] ?? $input['email'] ?? '');
    $password = $input['password'] ?? '';
    $requestedRole = trim($input['role'] ?? $input['login_type'] ?? '');

    if (empty($identifier) || empty($password)) {
        jsonResponse(['success' => false, 'message' => 'Phone/Email and password are required'], 400);
    }

    $pdo = getDBConnection();
    $isEmail = filter_var($identifier, FILTER_VALIDATE_EMAIL) !== false;

    // Function to attempt Vendor Login
    $attemptVendorLogin = function() use ($pdo, $identifier, $password, $isEmail, $input) {
        $vendor = null;
        if (!empty($input['phone'])) {
            $vStmt = $pdo->prepare("SELECT * FROM vendors WHERE phone = ? AND deleted_at IS NULL");
            $vStmt->execute([$identifier]);
            $vendor = $vStmt->fetch();
        } else {
            if ($isEmail) {
                $vStmt = $pdo->prepare("SELECT * FROM vendors WHERE email = ? AND deleted_at IS NULL");
                $vStmt->execute([$identifier]);
                $vendor = $vStmt->fetch();
            }
            if (!$vendor) {
                $vStmt = $pdo->prepare("SELECT * FROM vendors WHERE phone = ? AND deleted_at IS NULL");
                $vStmt->execute([$identifier]);
                $vendor = $vStmt->fetch();
            }
        }

        if (!$vendor) return null;

        if (!password_verify($password, $vendor['password'])) {
            jsonResponse(['success' => false, 'message' => 'Invalid credentials'], 401);
        }

        if (!in_array($vendor['status'], ['approved', 'active'])) {
            jsonResponse(['success' => false, 'message' => 'Vendor account is pending approval or inactive'], 403);
        }

        // Fetch full vendor details + subscription plan
        $vStmt = $pdo->prepare("
            SELECT 
                v.*,
                sp.max_listings,
                sp.name        AS plan_name,
                sp.price       AS plan_price,
                sp.duration_days AS plan_duration
            FROM vendors v
            LEFT JOIN subscription_plans sp ON v.current_plan_id = sp.id
            WHERE v.id = ? AND v.deleted_at IS NULL
        ");
        $vStmt->execute([$vendor['id']]);
        $vendorData = $vStmt->fetch();

        if (!$vendorData) {
            jsonResponse(['success' => false, 'message' => 'Vendor data corrupted'], 500);
        }

        $planExpired = false;
        if ($vendorData['plan_expires_at'] && strtotime($vendorData['plan_expires_at']) < time()) {
            $planExpired = true;
        }

        $hasActivePlan = $vendorData['current_plan_id'] && !$planExpired;
        $token = generateToken($vendorData['id'], 'vendor');

        jsonResponse([
            'success' => true,
            'token' => $token,
            'user' => [
                'id' => intval($vendorData['id']),
                'uuid' => $vendorData['uuid'] ?? null,
                'name' => $vendorData['owner_name'],
                'email' => $vendorData['email'],
                'phone' => $vendorData['phone'],
                'avatar' => $vendorData['store_logo'] ?? null,
                'role' => 'vendor',
                'status' => $vendorData['status'],
                'created_at' => $vendorData['created_at'],
                'vendor_profile' => [
                    'id'                      => (int) $vendorData['id'],
                    'vendor_type'             => $vendorData['vendor_type'] ?? 'vendor',
                    'store_name'              => $vendorData['store_name'],
                    'store_slug'              => $vendorData['store_slug'],
                    'address'                 => $vendorData['address'],
                    'city'                    => $vendorData['city'],
                    'state'                   => $vendorData['state'],
                    'pincode'                 => $vendorData['pincode'],
                    'category_id'             => isset($vendorData['category_id']) ? (int)$vendorData['category_id'] : null,
                    'gst_number'              => $vendorData['gst_number'],
                    'pan_number'              => $vendorData['pan_number'],
                    'store_description'       => $vendorData['store_description'],
                    'status'                  => $vendorData['status'],
                    'rating'                  => floatval($vendorData['rating'] ?? 0),
                    'total_reviews'           => (int) ($vendorData['total_reviews'] ?? 0),
                    'is_verified'             => (bool) ($vendorData['is_verified'] ?? false),
                    'is_verified_local'       => (bool) ($vendorData['is_verified_local'] ?? false),
                    'is_open'                 => (bool) ($vendorData['is_open'] ?? true),
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
            ]
        ]);
    };

    // If role explicitly requested as 'vendor', prioritize vendor login
    if ($requestedRole === 'vendor') {
        $attemptVendorLogin();
    }

    // Attempt Customer/User login
    $user = null;
    if (!empty($input['phone'])) {
        $stmt = $pdo->prepare("SELECT * FROM users WHERE phone = ? AND deleted_at IS NULL");
        $stmt->execute([$identifier]);
        $user = $stmt->fetch();
    } else {
        if ($isEmail) {
            $stmt = $pdo->prepare("SELECT * FROM users WHERE email = ? AND deleted_at IS NULL");
            $stmt->execute([$identifier]);
            $user = $stmt->fetch();
        }
        if (!$user) {
            $stmt = $pdo->prepare("SELECT * FROM users WHERE phone = ? AND deleted_at IS NULL");
            $stmt->execute([$identifier]);
            $user = $stmt->fetch();
        }
    }

    if ($user && password_verify($password, $user['password'])) {
        if ($user['status'] !== 'active') {
            jsonResponse(['success' => false, 'message' => 'Account is inactive'], 403);
        }

        $token = generateToken($user['id'], 'user');

        jsonResponse([
            'success' => true,
            'token' => $token,
            'user' => [
                'id' => intval($user['id']),
                'uuid' => $user['uuid'] ?? null,
                'name' => $user['name'],
                'email' => $user['email'],
                'phone' => $user['phone'],
                'avatar' => $user['avatar'] ?? null,
                'role' => 'user',
                'status' => $user['status'],
                'vendor_profile' => null,
                'created_at' => $user['created_at'],
            ]
        ]);
    }

    // Fallback: If not logged in as regular user, attempt vendor login
    $attemptVendorLogin();

    jsonResponse(['success' => false, 'message' => 'Invalid credentials'], 401);

} catch (PDOException $e) {
    error_log("Database error in login: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Database connection error'], 500);
} catch (Exception $e) {
    error_log("General error in login: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Internal server error'], 500);
}