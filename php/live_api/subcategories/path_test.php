<?php
ini_set('display_errors', 1); error_reporting(E_ALL);

echo "<h2>Server Path Diagnostic</h2>";
echo "<b>Current File:</b> " . __FILE__ . "<br>";
echo "<b>Current Dir:</b> " . __DIR__ . "<br>";

// Check potential locations
$paths = [
    'config.php',
    '../config.php',
    '../../config.php',
    '../../../config.php',
    '../../inc/config.php',
    '../../includes/config.php'
];

foreach ($paths as $path) {
    echo "<hr>Checking: <code>$path</code><br>";
    if (file_exists($path)) {
        echo "✅ <b>FOUND!</b> Real path: " . realpath($path) . "<br>";
        try {
            include($path);
            echo "✅ Include SUCCESS!<br>";
        } catch (Throwable $e) {
            echo "❌ Include CRASHED: " . $e->getMessage() . "<br>";
        }
    } else {
        echo "❌ Not found.<br>";
    }
}
?>