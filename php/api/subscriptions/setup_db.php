<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once __DIR__ . '/../../config.php';

echo "<h1>Starting Subscription Database Setup</h1>";

try {
    $pdo = getDBConnection();
    echo "<p>Connected to database: " . DB_NAME . "</p>";

    $sqlFile = __DIR__ . '/../../../update_subscriptions_db.sql';
    echo "<p>Looking for SQL file at: $sqlFile</p>";

    if (!file_exists($sqlFile)) {
        // Try another path
        $sqlFile = __DIR__ . '/../../update_subscriptions_db.sql';
        echo "<p>Retrying SQL file at: $sqlFile</p>";
    }

    if (!file_exists($sqlFile)) {
        throw new Exception("SQL file not found! Please ensure 'update_subscriptions_db.sql' is in the project root.");
    }

    $sql = file_get_contents($sqlFile);
    
    // The SQL file contains multiple statements. PDO::exec doesn't always support multiple statements.
    // Let's split them by semicolon (basic splitting)
    $statements = explode(';', $sql);
    $count = 0;
    $errors = 0;

    foreach ($statements as $statement) {
        $trimmed = trim($statement);
        if (empty($trimmed)) continue;

        try {
            $pdo->exec($trimmed);
            $count++;
        } catch (PDOException $e) {
            echo "<p style='color:orange'>Warning in statement: " . substr($trimmed, 0, 50) . "...<br>";
            echo "Error: " . $e->getMessage() . "</p>";
            $errors++;
        }
    }

    echo "<h3>Setup Complete</h3>";
    echo "<p style='color:green'>Successfully executed $count statements.</p>";
    if ($errors > 0) {
        echo "<p style='color:red'>Encountered $errors errors/warnings (some might be 'table already exists').</p>";
    }

} catch (Exception $e) {
    echo "<h1>Critical Error</h1>";
    echo "<p style='color:red'>" . $e->getMessage() . "</p>";
}
?>