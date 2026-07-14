-- 1. Create subscription_plans table
CREATE TABLE `subscription_plans` (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `target_group` enum('vendor','worker') COLLATE utf8mb4_unicode_ci NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `duration_days` int NOT NULL,
  `max_listings` int NOT NULL DEFAULT '0',
  `featured_days` int NOT NULL DEFAULT '0',
  `boost_days` int NOT NULL DEFAULT '0',
  `has_trusted_badge` tinyint(1) DEFAULT '0',
  `has_verified_badge` tinyint(1) DEFAULT '0',
  `has_top_placement` tinyint(1) DEFAULT '0',
  `status` enum('active','inactive') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- 2. Insert Default Plans (Based on Requirements)
INSERT INTO `subscription_plans` (`name`, `target_group`, `price`, `duration_days`, `max_listings`, `featured_days`, `boost_days`, `has_trusted_badge`, `has_verified_badge`, `has_top_placement`) VALUES
-- Vendors
('Monthly', 'vendor', 499.00, 30, 2, 0, 0, 0, 0, 0),
('Quarterly', 'vendor', 1399.00, 90, 5, 5, 0, 0, 0, 0),
('Half-Yearly', 'vendor', 2699.00, 180, 10, 15, 0, 1, 0, 1),
('Yearly', 'vendor', 4999.00, 365, 20, 30, 7, 1, 0, 1),

-- Workers
('Monthly', 'worker', 199.00, 30, 1, 0, 0, 0, 0, 0),
('Quarterly', 'worker', 549.00, 90, 2, 3, 0, 0, 0, 0),
('Half-Yearly', 'worker', 1049.00, 180, 3, 10, 0, 0, 1, 0),
('Yearly', 'worker', 1999.00, 365, 5, 20, 0, 0, 1, 1);


-- 3. Create vendor_subscriptions table to track history and payments
CREATE TABLE `vendor_subscriptions` (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `vendor_id` bigint UNSIGNED NOT NULL,
  `plan_id` bigint UNSIGNED NOT NULL,
  `payment_id` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `amount_paid` decimal(10,2) NOT NULL,
  `payment_status` enum('pending','paid','failed') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `start_date` datetime DEFAULT NULL,
  `end_date` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`vendor_id`) REFERENCES `vendors`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`plan_id`) REFERENCES `subscription_plans`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- 4. Alter vendors table to add the new subscription and badge fields
ALTER TABLE `vendors` 
  ADD COLUMN `vendor_type` enum('vendor','worker') COLLATE utf8mb4_unicode_ci DEFAULT 'vendor' AFTER `uuid`,
  ADD COLUMN `current_plan_id` bigint UNSIGNED DEFAULT NULL AFTER `is_verified`,
  ADD COLUMN `plan_expires_at` datetime DEFAULT NULL AFTER `current_plan_id`,
  ADD COLUMN `available_featured_days` int DEFAULT '0' AFTER `plan_expires_at`,
  ADD COLUMN `available_boost_days` int DEFAULT '0' AFTER `available_featured_days`,
  ADD COLUMN `is_verified_local` tinyint(1) DEFAULT '0' AFTER `available_boost_days`,
  ADD COLUMN `is_founding_member` tinyint(1) DEFAULT '0' AFTER `is_verified_local`;
  
-- Add Foreign Key for the new plan ID reference
ALTER TABLE `vendors`
  ADD CONSTRAINT `fk_vendor_current_plan` FOREIGN KEY (`current_plan_id`) REFERENCES `subscription_plans`(`id`) ON DELETE SET NULL;
