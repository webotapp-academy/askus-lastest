<?php
require_once __DIR__ . '/../../config.php';

$functions = get_defined_functions()['user'];
sort($functions);

echo "<h1>Defined Functions</h1>";
echo "<ul>";
foreach ($functions as $f) {
    echo "<li>$f</li>";
}
echo "</ul>";

if (function_exists('getInput')) {
    echo "<p style='color:green'>✅ getInput exists</p>";
} else {
    echo "<p style='color:red'>❌ getInput DOES NOT exist</p>";
}
?>