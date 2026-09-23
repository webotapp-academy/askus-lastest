-- Migration: Add Category and Subcategory support to Vendors
-- Date: 2026-08-05

-- 1. Add primary category_id column to vendors table if it doesn't exist
ALTER TABLE `vendors` 
ADD COLUMN IF NOT EXISTS `category_id` bigint UNSIGNED NULL DEFAULT NULL AFTER `store_description`,
ADD INDEX IF NOT EXISTS `idx_vendors_category_id` (`category_id`);

-- 2. Create junction table for multi-category / multi-subcategory vendor support
CREATE TABLE IF NOT EXISTS `vendor_categories` (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `vendor_id` bigint UNSIGNED NOT NULL,
  `category_id` bigint UNSIGNED NOT NULL,
  `subcategory_id` bigint UNSIGNED NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_vendor_cat_subcat` (`vendor_id`, `category_id`, `subcategory_id`),
  KEY `idx_vc_vendor` (`vendor_id`),
  KEY `idx_vc_category` (`category_id`),
  KEY `idx_vc_subcategory` (`subcategory_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
