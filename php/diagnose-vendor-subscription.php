<?php
/**
 * Diagnostic Script: Check Vendor Subscription Data
 * Run this to verify if vendors have subscription data
 */

require_once __DIR__ . '/../../config.php';

// Support preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    $pdo = getDBConnection();
    
    echo "<h2>Vendor Subscription Diagnostic</h2>";
    echo "<hr>";
    
    // 1. Check vendors table structure
    echo "<h3>1. Vendors Table Structure</h3>";
    $stmt = $pdo->query("DESCRIBE vendors");
    $columns = $stmt->fetchAll();
    
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th></tr>";
    foreach ($columns as $col) {
        if (in_array($col['Field'], ['current_plan_id', 'plan_expires_at', 'available_featured_days', 'available_boost_days', 'is_verified_local'])) {
            echo "<tr style='background:#d4edda'>";
            echo "<td>{$col['Field']}</td><td>{$col['Type']}</td><td>{$col['Null']}</td><td>{$col['Key']}</td><td>{$col['Default']}</td>";
            echo "</tr>";
        }
    }
    echo "</table>";
    
    // 2. Check vendors with plans
    echo "<h3>2. Vendors with Subscription Data</h3>";
    $stmt = $pdo->query("
        SELECT 
            v.id,
            v.owner_name,
            v.email,
            v.store_name,
            v.vendor_type,
            v.current_plan_id,
            v.plan_expires_at,
            v.available_featured_days,
            v.available_boost_days,
            sp.name as plan_name,
            sp.max_listings,
            sp.price,
            CASE
                WHEN v.current_plan_id IS NULL THEN '❌ NO PLAN'
                WHEN v.plan_expires_at IS NULL THEN '⚠️ NO EXPIRY'
                WHEN v.plan_expires_at < NOW() THEN '❌ EXPIRED'
                WHEN v.plan_expires_at > NOW() THEN '✅ ACTIVE'
                ELSE '❓ UNKNOWN'
            END as plan_status
        FROM vendors v
        LEFT JOIN subscription_plans sp ON v.current_plan_id = sp.id
        WHERE v.deleted_at IS NULL
        ORDER BY v.created_at DESC
        LIMIT 20
    ");
    $vendors = $stmt->fetchAll();
    
    echo "<table border='1' cellpadding='5'>";
    echo "<tr>";
    echo "<th>ID</th><th>Name</th><th>Email</th><th>Store</th><th>Type</th>";
    echo "<th>Plan ID</th><th>Plan Name</th><th>Max Listings</th><th>Price</th>";
    echo "<th>Expires At</th><th>Status</th>";
    echo "</tr>";
    
    foreach ($vendors as $v) {
        $statusClass = '';
        if (strpos($v['plan_status'], '✅') !== false) $statusClass = 'style="background:#d4edda"';
        elseif (strpos($v['plan_status'], '❌') !== false) $statusClass = 'style="background:#f8d7da"';
        elseif (strpos($v['plan_status'], '⚠️') !== false) $statusClass = 'style="background:#fff3cd"';
        
        echo "<tr $statusClass>";
        echo "<td>{$v['id']}</td>";
        echo "<td>{$v['owner_name']}</td>";
        echo "<td>{$v['email']}</td>";
        echo "<td>{$v['store_name']}</td>";
        echo "<td>{$v['vendor_type']}</td>";
        echo "<td>" . ($v['current_plan_id'] ?? 'NULL') . "</td>";
        echo "<td>" . ($v['plan_name'] ?? 'N/A') . "</td>";
        echo "<td>" . ($v['max_listings'] ?? '0') . "</td>";
        echo "<td>₹" . ($v['price'] ?? '0') . "</td>";
        echo "<td>" . ($v['plan_expires_at'] ?? 'NULL') . "</td>";
        echo "<td>{$v['plan_status']}</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // 3. Check vendor_subscriptions table
    echo "<h3>3. Vendor Subscriptions Table Records</h3>";
    $stmt = $pdo->query("
        SELECT 
            vs.id,
            vs.vendor_id,
            vs.plan_id,
            vs.payment_id,
            vs.amount_paid,
            vs.payment_status,
            vs.status,
            vs.start_date,
            vs.end_date,
            v.owner_name,
            v.store_name,
            sp.name as plan_name
        FROM vendor_subscriptions vs
        JOIN vendors v ON vs.vendor_id = v.id
        LEFT JOIN subscription_plans sp ON vs.plan_id = sp.id
        ORDER BY vs.created_at DESC
        LIMIT 10
    ");
    $subscriptions = $stmt->fetchAll();
    
    if (empty($subscriptions)) {
        echo "<p style='color:red'><strong>⚠️ No records in vendor_subscriptions table!</strong></p>";
    } else {
        echo "<table border='1' cellpadding='5'>";
        echo "<tr>";
        echo "<th>ID</th><th>Vendor ID</th><th>Plan ID</th><th>Payment ID</th>";
        echo "<th>Amount</th><th>Status</th><th>Payment Status</th>";
        echo "<th>Start</th><th>End</th><th>Vendor</th><th>Plan</th>";
        echo "</tr>";
        
        foreach ($subscriptions as $s) {
            echo "<tr>";
            echo "<td>{$s['id']}</td>";
            echo "<td>{$s['vendor_id']}</td>";
            echo "<td>{$s['plan_id']}</td>";
            echo "<td>{$s['payment_id']}</td>";
            echo "<td>₹{$s['amount_paid']}</td>";
            echo "<td>{$s['status']}</td>";
            echo "<td>{$s['payment_status']}</td>";
            echo "<td>{$s['start_date']}</td>";
            echo "<td>{$s['end_date']}</td>";
            echo "<td>{$s['owner_name']}</td>";
            echo "<td>{$s['plan_name']}</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
    
    // 4. Check subscription_plans table
    echo "<h3>4. Subscription Plans</h3>";
    $stmt = $pdo->query("SELECT * FROM subscription_plans WHERE status = 'active' ORDER BY price");
    $plans = $stmt->fetchAll();
    
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>ID</th><th>Name</th><th>Target</th><th>Price</th><th>Days</th><th>Max Listings</th><th>Featured</th><th>Boost</th></tr>";
    foreach ($plans as $p) {
        echo "<tr>";
        echo "<td>{$p['id']}</td>";
        echo "<td>{$p['name']}</td>";
        echo "<td>{$p['target_group']}</td>";
        echo "<td>₹{$p['price']}</td>";
        echo "<td>{$p['duration_days']}</td>";
        echo "<td>{$p['max_listings']}</td>";
        echo "<td>{$p['featured_days']}</td>";
        echo "<td>{$p['boost_days']}</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // 5. Summary
    echo "<hr>";
    echo "<h3>5. Summary</h3>";
    
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM vendors WHERE deleted_at IS NULL");
    $totalVendors = $stmt->fetch()['total'];
    
    $stmt = $pdo->query("SELECT COUNT(*) as has_plan FROM vendors WHERE current_plan_id IS NOT NULL AND deleted_at IS NULL");
    $withPlan = $stmt->fetch()['has_plan'];
    
    $stmt = $pdo->query("SELECT COUNT(*) as active FROM vendors WHERE current_plan_id IS NOT NULL AND (plan_expires_at IS NULL OR plan_expires_at > NOW()) AND deleted_at IS NULL");
    $activePlan = $stmt->fetch()['active'];
    
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM vendor_subscriptions");
    $totalSubscriptions = $stmt->fetch()['total'];
    
    echo "<ul>";
    echo "<li><strong>Total Vendors:</strong> $totalVendors</li>";
    echo "<li><strong>Vendors with Plan:</strong> $withPlan</li>";
    echo "<li><strong>Vendors with Active Plan:</strong> $activePlan</li>";
    echo "<li><strong>Total Subscription Records:</strong> $totalSubscriptions</li>";
    echo "</ul>";
    
    if ($withPlan == 0) {
        echo "<p style='color:red;font-weight:bold'>⚠️ PROBLEM: No vendors have current_plan_id set! This means the create-vendor-after-payment.php is not saving the plan data.</p>";
    }
    
    if ($totalSubscriptions == 0) {
        echo "<p style='color:red;font-weight:bold'>⚠️ PROBLEM: vendor_subscriptions table is empty! Subscriptions are not being recorded.</p>";
    }
    
} catch (PDOException $e) {
    echo "<p style='color:red'><strong>Error: " . $e->getMessage() . "</strong></p>";
} catch (Exception $e) {
    echo "<p style='color:red'><strong>Error: " . $e->getMessage() . "</strong></p>";
}
?>
