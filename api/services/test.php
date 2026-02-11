<?php
// Simple test script for services list API
require_once __DIR__ . '/../../config.php';

echo "<h1>Services List API Test</h1>\n";

try {
    // Test database connection
    echo "<h2>1. Database Connection Test</h2>\n";
    $pdo = getDBConnection();
    echo "✅ Database connection successful<br>\n";
    
    // Test if services table exists
    echo "<h2>2. Services Table Test</h2>\n";
    $tableCheck = $pdo->query("SHOW TABLES LIKE 'services'");
    if ($tableCheck->rowCount() > 0) {
        echo "✅ Services table exists<br>\n";
        
        // Check table structure
        $columns = $pdo->query("DESCRIBE services");
        $columnNames = [];
        while ($column = $columns->fetch()) {
            $columnNames[] = $column['Field'];
        }
        echo "📋 Table columns: " . implode(', ', $columnNames) . "<br>\n";
        
        // Check if required columns exist
        $requiredColumns = ['id', 'name', 'status', 'min_price'];
        $missingColumns = [];
        foreach ($requiredColumns as $req) {
            if (!in_array($req, $columnNames)) {
                $missingColumns[] = $req;
            }
        }
        
        if (empty($missingColumns)) {
            echo "✅ All required columns present<br>\n";
        } else {
            echo "⚠️ Missing columns: " . implode(', ', $missingColumns) . "<br>\n";
        }
        
    } else {
        echo "❌ Services table does not exist<br>\n";
    }
    
    // Test services count
    echo "<h2>3. Services Count Test</h2>\n";
    $countStmt = $pdo->query("SELECT COUNT(*) as total FROM services");
    $count = $countStmt->fetch();
    echo "📊 Total services: " . $count['total'] . "<br>\n";
    
    // Test active services count
    $activeCountStmt = $pdo->query("SELECT COUNT(*) as total FROM services WHERE status = 'active'");
    $activeCount = $activeCountStmt->fetch();
    echo "📊 Active services: " . $activeCount['total'] . "<br>\n";
    
    // Test sample query
    echo "<h2>4. Sample Services Query</h2>\n";
    $sampleStmt = $pdo->query("SELECT id, name, min_price, status FROM services LIMIT 5");
    $samples = $sampleStmt->fetchAll();
    
    if (count($samples) > 0) {
        echo "✅ Sample services found:<br>\n";
        echo "<table border='1' style='border-collapse: collapse;'>\n";
        echo "<tr><th>ID</th><th>Name</th><th>Price</th><th>Status</th></tr>\n";
        foreach ($samples as $service) {
            echo "<tr>";
            echo "<td>" . $service['id'] . "</td>";
            echo "<td>" . htmlspecialchars($service['name']) . "</td>";
            echo "<td>" . $service['min_price'] . "</td>";
            echo "<td>" . $service['status'] . "</td>";
            echo "</tr>\n";
        }
        echo "</table><br>\n";
    } else {
        echo "⚠️ No services found in database<br>\n";
    }
    
    // Test API endpoint
    echo "<h2>5. API Endpoint Test</h2>\n";
    $apiUrl = (isset($_SERVER['HTTPS']) ? 'https' : 'http') . '://' . $_SERVER['HTTP_HOST'] . dirname($_SERVER['REQUEST_URI']) . '/list.php?limit=3';
    echo "🔗 API URL: <a href='" . $apiUrl . "' target='_blank'>" . $apiUrl . "</a><br>\n";
    
    // Test with cURL if available
    if (function_exists('curl_init')) {
        echo "<h3>Testing API response:</h3>\n";
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $apiUrl);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HEADER, false);
        curl_setopt($ch, CURLOPT_TIMEOUT, 10);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        echo "HTTP Status: " . $httpCode . "<br>\n";
        if ($response) {
            echo "Response: <pre>" . htmlspecialchars($response) . "</pre>\n";
        } else {
            echo "❌ No response received<br>\n";
        }
    }
    
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "<br>\n";
    echo "Error details: " . $e->getFile() . " line " . $e->getLine() . "<br>\n";
}

echo "<hr>\n";
echo "<h2>Quick Actions</h2>\n";
echo "<a href='list.php' target='_blank'>🚀 Test Services List API</a><br>\n";
echo "<a href='list.php?featured=true' target='_blank'>⭐ Test Featured Services</a><br>\n";
echo "<a href='list.php?limit=5&page=1' target='_blank'>📄 Test Pagination</a><br>\n";
?>