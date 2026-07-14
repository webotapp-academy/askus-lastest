<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>Path Debugger</h1>";
echo "Current File: " . __FILE__ . "<br>";
echo "Current Dir: " . __DIR__ . "<br>";

$path1 = __DIR__ . '/../../config.php';
$path2 = __DIR__ . '/../config.php';
$path3 = __DIR__ . '/config.php';

echo "Path 1 (../../): $path1 - " . (file_exists($path1) ? "✅ EXISTS" : "❌ NOT FOUND") . "<br>";
echo "Path 2 (../): $path2 - " . (file_exists($path2) ? "✅ EXISTS" : "❌ NOT FOUND") . "<br>";
echo "Path 3 (./): $path3 - " . (file_exists($path3) ? "✅ EXISTS" : "❌ NOT FOUND") . "<br>";

if (file_exists($path1)) {
    require_once $path1;
    echo "Successfully required config.php from Path 1<br>";
}
?>