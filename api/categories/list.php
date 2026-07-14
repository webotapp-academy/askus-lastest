<?php
require_once __DIR__ . '/../../config.php';

try {
    $pdo = getDBConnection();
    
    // Get parameters
    $includeServices = filter_var($_GET['include_services'] ?? false, FILTER_VALIDATE_BOOLEAN);
    $includeSubcategories = filter_var($_GET['include_subcategories'] ?? true, FILTER_VALIDATE_BOOLEAN);
    $activeOnly = filter_var($_GET['active_only'] ?? true, FILTER_VALIDATE_BOOLEAN);
    
    // Build WHERE clause
    $where = $activeOnly ? "WHERE c.status = 'active'" : "";
    
    // Get categories
    $query = "SELECT 
                c.id,
                c.name,
                c.slug,
                c.description,
                c.icon,
                c.image,
                c.gallery_images,
                c.sort_order,
                c.status,
                c.created_at,
                c.updated_at
              FROM categories c
              $where
              ORDER BY c.sort_order ASC, c.name ASC";
    
    $stmt = $pdo->prepare($query);
    $stmt->execute();
    $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $formattedCategories = [];
    foreach ($categories as $category) {
        $categoryData = [
            'id' => intval($category['id']),
            'name' => $category['name'],
            'slug' => $category['slug'],
            'description' => $category['description'],
            'icon' => formatImageURL($category['icon']),
            'image' => formatImageURL($category['image']),
            'gallery_images' => formatImageURL($category['gallery_images']),
            'sort_order' => intval($category['sort_order']),
            'status' => $category['status'],
            'created_at' => $category['created_at'],
            'updated_at' => $category['updated_at']
        ];
        
        // Include subcategories if requested
        if ($includeSubcategories) {
            $subcategoryWhere = $activeOnly ? "AND s.status = 'active'" : "";
            $subcategoryQuery = "SELECT 
                                    s.id,
                                    s.name,
                                    s.slug,
                                    s.description,
                                    s.sort_order,
                                    s.status
                                 FROM subcategories s
                                 WHERE s.category_id = :categoryId $subcategoryWhere
                                 ORDER BY s.sort_order ASC, s.name ASC";
            
            $subcategoryStmt = $pdo->prepare($subcategoryQuery);
            $subcategoryStmt->bindValue(':categoryId', $category['id'], PDO::PARAM_INT);
            $subcategoryStmt->execute();
            $subcategories = $subcategoryStmt->fetchAll(PDO::FETCH_ASSOC);
            
            $formattedSubcategories = [];
            foreach ($subcategories as $subcategory) {
                $formattedSubcategories[] = [
                    'id' => intval($subcategory['id']),
                    'name' => $subcategory['name'],
                    'slug' => $subcategory['slug'],
                    'description' => $subcategory['description'],
                    'sort_order' => intval($subcategory['sort_order']),
                    'status' => $subcategory['status']
                ];
            }
            $categoryData['subcategories'] = $formattedSubcategories;
            $categoryData['subcategories_count'] = count($formattedSubcategories);
        }
        
        // Include services count if requested
        if ($includeServices) {
            $servicesCountQuery = "SELECT COUNT(*) as count 
                                  FROM services s 
                                  WHERE s.category_id = :categoryId 
                                    AND s.status = 'active' 
                                    AND s.deleted_at IS NULL";
            
            $servicesCountStmt = $pdo->prepare($servicesCountQuery);
            $servicesCountStmt->bindValue(':categoryId', $category['id'], PDO::PARAM_INT);
            $servicesCountStmt->execute();
            $servicesCount = $servicesCountStmt->fetchColumn();
            
            $categoryData['services_count'] = intval($servicesCount);
        }
        
        $formattedCategories[] = $categoryData;
    }
    
    jsonResponse([
        'success' => true,
        'message' => 'Categories retrieved successfully',
        'data' => $formattedCategories,
        'categories' => $formattedCategories, // Backward compatibility
        'total' => count($formattedCategories)
    ]);
    
} catch (PDOException $e) {
    logError("Categories List DB Error: " . $e->getMessage());
    jsonResponse([
        'success' => false,
        'message' => 'Database error occurred',
        'error' => 'Failed to fetch categories'
    ], 500);
} catch (Exception $e) {
    logError("Categories List Error: " . $e->getMessage());
    jsonResponse([
        'success' => false,
        'message' => 'An error occurred while fetching categories',
        'error' => $e->getMessage()
    ], 500);
}
?>