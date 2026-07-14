-- =====================================================
-- Vendor Subscriptions Table Migration
-- =====================================================
-- This table tracks vendor subscription history
-- Created: March 17, 2026
-- =====================================================

-- Create vendor_subscriptions table if not exists
CREATE TABLE IF NOT EXISTS `vendor_subscriptions` (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `vendor_id` bigint UNSIGNED NOT NULL,
  `plan_id` int UNSIGNED NOT NULL,
  `payment_id` int UNSIGNED DEFAULT NULL,
  `amount_paid` decimal(10,2) DEFAULT NULL,
  `payment_status` enum('pending','paid','failed','refunded') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `start_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `end_date` timestamp NULL DEFAULT NULL,
  `status` enum('active','expired','cancelled') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `vendor_id` (`vendor_id`),
  KEY `plan_id` (`plan_id`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Verify vendors table has required columns
-- =====================================================
-- These columns should already exist from api-auth-create-vendor-after-payment.php
-- Run this to verify:

-- ALTER TABLE `vendors` 
-- ADD COLUMN IF NOT EXISTS `current_plan_id` int UNSIGNED DEFAULT NULL AFTER `vendor_type`,
-- ADD COLUMN IF NOT EXISTS `plan_expires_at` timestamp NULL DEFAULT NULL AFTER `current_plan_id`,
-- ADD COLUMN IF NOT EXISTS `available_featured_days` int DEFAULT 0 AFTER `plan_expires_at`,
-- ADD COLUMN IF NOT EXISTS `available_boost_days` int DEFAULT 0 AFTER `available_featured_days`,
-- ADD COLUMN IF NOT EXISTS `is_verified_local` tinyint(1) DEFAULT 0 AFTER `available_boost_days`;

-- =====================================================
-- Add foreign key constraints (optional, for data integrity)
-- =====================================================
-- Uncomment if you want to enforce referential integrity:

-- ALTER TABLE `vendor_subscriptions`
--   ADD CONSTRAINT `vendor_subscriptions_ibfk_1` FOREIGN KEY (`vendor_id`) REFERENCES `vendors`(`id`) ON DELETE CASCADE,
--   ADD CONSTRAINT `vendor_subscriptions_ibfk_2` FOREIGN KEY (`plan_id`) REFERENCES `subscription_plans`(`id`) ON DELETE RESTRICT;

-- =====================================================
-- Sample Data (for testing)
-- =====================================================
-- Uncomment to insert test data:

-- INSERT INTO `vendor_subscriptions` 
-- (`vendor_id`, `plan_id`, `payment_id`, `amount_paid`, `payment_status`, `start_date`, `end_date`, `status`)
-- VALUES 
-- (1, 1, 1, 999.00, 'paid', NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), 'active');

-- =====================================================
-- Verification Query
-- =====================================================
-- Run this to check if table was created:

-- SELECT 
--     TABLE_NAME, 
--     COLUMN_NAME, 
--     DATA_TYPE, 
--     IS_NULLABLE, 
--     COLUMN_DEFAULT
-- FROM INFORMATION_SCHEMA.COLUMNS
-- WHERE TABLE_SCHEMA = 'askus' 
--   AND TABLE_NAME = 'vendor_subscriptions'
-- ORDER BY ORDINAL_POSITION;

-- =====================================================
-- Check vendors with active subscriptions
-- =====================================================
-- Query to verify vendors have their subscription data:

-- SELECT 
--     v.id AS vendor_id,
--     v.owner_name,
--     v.store_name,
--     v.vendor_type,
--     v.current_plan_id,
--     v.plan_expires_at,
--     v.available_featured_days,
--     v.available_boost_days,
--     sp.name AS plan_name,
--     sp.max_listings,
--     sp.price
-- FROM vendors v
-- LEFT JOIN subscription_plans sp ON v.current_plan_id = sp.id
-- WHERE v.deleted_at IS NULL
-- ORDER BY v.created_at DESC;
