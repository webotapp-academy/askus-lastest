<?php
require_once __DIR__ . '/../config.php';

error_log("=== PAYMENT TABLE DIAGNOSTIC START ===");

$pdo = getDBConnection();

// Test 1: Check if payments table exists and get its structure
try {
    $stmt = $pdo->query("DESCRIBE payments");
    $columns = $stmt->fetchAll();
    error_log("✅ Payments table structure:");
    foreach ($columns as $column) {
        error_log("   - " . $column['Field'] . " (" . $column['Type'] . ") " . 
                  ($column['Null'] === 'YES' ? 'NULL' : 'NOT NULL') . 
                  ($column['Key'] ? " KEY: " . $column['Key'] : ""));
    }
} catch (Exception $e) {
    error_log("❌ Error getting table structure: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Cannot access payments table: ' . $e->getMessage()], 500);
}

// Test 2: Find the most recent payment
try {
    $stmt = $pdo->query("SELECT * FROM payments ORDER BY id DESC LIMIT 1");
    $payment = $stmt->fetch();
    if ($payment) {
        error_log("✅ Most recent payment found:");
        error_log("   ID: " . $payment['id']);
        error_log("   Status: " . ($payment['status'] ?? 'NULL'));
        error_log("   Amount: " . ($payment['amount'] ?? 'NULL'));
        error_log("   Razorpay Order ID: " . ($payment['razorpay_order_id'] ?? 'NULL'));
        error_log("   Razorpay Payment ID: " . ($payment['razorpay_payment_id'] ?? 'NULL'));
        error_log("   Created: " . ($payment['created_at'] ?? 'NULL'));
        error_log("   Updated: " . ($payment['updated_at'] ?? 'NULL'));
    } else {
        error_log("⚠️ No payments found in table");
    }
} catch (Exception $e) {
    error_log("❌ Error fetching payment: " . $e->getMessage());
}

// Test 3: Try to update the most recent payment (dry run)
try {
    $pdo->beginTransaction();
    
    $stmt = $pdo->prepare("UPDATE payments SET 
        status = 'completed',
        razorpay_payment_id = 'test_payment_123',
        razorpay_signature = 'test_signature_xyz',
        updated_at = NOW()
        WHERE id = ?");
    
    $result = $stmt->execute([$payment['id']]);
    $rowsAffected = $stmt->rowCount();
    
    error_log("✅ Test UPDATE executed successfully");
    error_log("   Result: " . ($result ? "true" : "false"));
    error_log("   Rows affected: $rowsAffected");
    
    // Rollback to not actually change the data
    $pdo->rollBack();
    error_log("✅ Transaction rolled back (test only)");
    
} catch (PDOException $e) {
    $pdo->rollBack();
    error_log("❌ PDO Error during test update: " . $e->getMessage());
    error_log("   Error code: " . $e->getCode());
    error_log("   SQL State: " . ($e->errorInfo[0] ?? 'unknown'));
} catch (Exception $e) {
    $pdo->rollBack();
    error_log("❌ General Error during test update: " . $e->getMessage());
}

error_log("=== PAYMENT TABLE DIAGNOSTIC END ===");

jsonResponse([
    'success' => true,
    'message' => 'Diagnostic completed - check error logs',
    'table_columns' => array_column($columns, 'Field'),
    'most_recent_payment_id' => $payment['id'] ?? null
]);
?>
