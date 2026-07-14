<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once __DIR__ . '/../../config.php';

try {
    $pdo = getDBConnection();
    echo "<h1>Database Connected Successfully</h1>";

    // 1. Check if table exists
    $stmt = $pdo->query("SHOW TABLES LIKE 'subscription_plans'");
    $tableExists = $stmt->fetch();
    
    if (!$tableExists) {
        echo "<p style='color:red'>❌ Table 'subscription_plans' does NOT exist!</p>";
        
        // List all tables
        echo "<h3>Available Tables:</h3>";
        $stmt = $pdo->query("SHOW TABLES");
        while ($row = $stmt->fetch(PDO::FETCH_NUM)) {
            echo $row[0] . "<br>";
        }
    } else {
        echo "<p style='color:green'>✅ Table 'subscription_plans' exists.</p>";
        
        // 2. Check structure
        echo "<h3>Table Structure:</h3>";
        $stmt = $pdo->query("DESCRIBE subscription_plans");
        echo "<table border='1'><tr><th>Field</th><th>Type</th></tr>";
        while ($row = $stmt->fetch()) {
            echo "<tr><td>{$row['Field']}</td><td>{$row['Type']}</td></tr>";
        }
        echo "</table>";
        
        // 3. Check data
        echo "<h3>Plan Count:</h3>";
        $stmt = $pdo->query("SELECT COUNT(*) FROM subscription_plans");
        echo "Count: " . $stmt->fetchColumn();
    }

} catch (Exception $e) {
    echo "<h1>Error</h1>";
    echo "<p style='color:red'>" . $e->getMessage() . "</p>";
    echo "<pre>" . $e->getTraceAsString() . "</pre>";
}
?>