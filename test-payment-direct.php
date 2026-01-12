<?php
// Direct test of payment creation endpoint
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Simulate the exact request your Flutter app makes
$_SERVER['REQUEST_METHOD'] = 'POST';

// Mock input data
$mockInput = json_encode([
    'vendor_id' => 1, // Use a valid user ID from your database
    'amount' => 1179
]);

// Mock the input stream
file_put_contents('php://temp', $mockInput);

// Mock authentication (you'll need to replace this with a real token)
$_SERVER['HTTP_AUTHORIZATION'] = 'Bearer your_test_token_here';

echo "Testing payment creation endpoint...\n";
echo "Mock input: " . $mockInput . "\n";

try {
    // Include your payment creation script
    include __DIR__ . '/payments/create.php';
} catch (Exception $e) {
    echo json_encode([
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ]);
}
?>