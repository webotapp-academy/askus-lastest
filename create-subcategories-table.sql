-- Create subcategories table
CREATE TABLE IF NOT EXISTS `subcategories` (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `category_id` bigint UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `image` varchar(500) DEFAULT NULL,
  `sort_order` int(11) DEFAULT 0,
  `status` enum('active','inactive') DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`),
  KEY `category_id` (`category_id`),
  KEY `status` (`status`),
  KEY `sort_order` (`sort_order`),
  CONSTRAINT `fk_subcategories_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add subcategory_id column to products table
ALTER TABLE `products` 
ADD COLUMN `subcategory_id` bigint UNSIGNED DEFAULT NULL AFTER `category_id`,
ADD KEY `subcategory_id` (`subcategory_id`),
ADD CONSTRAINT `fk_products_subcategory` FOREIGN KEY (`subcategory_id`) REFERENCES `subcategories` (`id`) ON DELETE SET NULL;

-- Add subcategory_id column to services table
ALTER TABLE `services` 
ADD COLUMN `subcategory_id` bigint UNSIGNED DEFAULT NULL AFTER `category_id`,
ADD KEY `subcategory_id` (`subcategory_id`),
ADD CONSTRAINT `fk_services_subcategory` FOREIGN KEY (`subcategory_id`) REFERENCES `subcategories` (`id`) ON DELETE SET NULL;

-- Tables created successfully!
-- Now add subcategories for each category

-- Subcategories for Heavy Machinery (ID: 13)
INSERT INTO `subcategories` (`category_id`, `name`, `slug`, `description`, `sort_order`, `status`) VALUES
(13, 'Excavators', 'excavators', 'Heavy excavating equipment', 1, 'active'),
(13, 'Bulldozers', 'bulldozers', 'Bulldozer machinery', 2, 'active'),
(13, 'Cranes', 'cranes', 'Heavy lifting cranes', 3, 'active');

-- Subcategories for Hardwares (ID: 14)
INSERT INTO `subcategories` (`category_id`, `name`, `slug`, `description`, `sort_order`, `status`) VALUES
(14, 'Fasteners', 'fasteners', 'Nuts, bolts, screws', 1, 'active'),
(14, 'Tools', 'tools', 'Hand and power tools', 2, 'active'),
(14, 'Door Hardware', 'door-hardware', 'Locks, handles, hinges', 3, 'active');

-- Subcategories for Workers and Labours (ID: 15)
INSERT INTO `subcategories` (`category_id`, `name`, `slug`, `description`, `sort_order`, `status`) VALUES
(15, 'Construction Workers', 'construction-workers', 'Construction labor services', 1, 'active'),
(15, 'Skilled Technicians', 'skilled-technicians', 'Specialized technical workers', 2, 'active'),
(15, 'Support Staff', 'support-staff', 'General support workers', 3, 'active');

-- Subcategories for Interior Designer (ID: 16)
INSERT INTO `subcategories` (`category_id`, `name`, `slug`, `description`, `sort_order`, `status`) VALUES
(16, 'Residential Design', 'residential-design', 'Home interior design', 1, 'active'),
(16, 'Commercial Design', 'commercial-design', 'Office and commercial design', 2, 'active'),
(16, 'Space Planning', 'space-planning', 'Space optimization and planning', 3, 'active');

-- Subcategories for Interior Designing (ID: 17)
INSERT INTO `subcategories` (`category_id`, `name`, `slug`, `description`, `sort_order`, `status`) VALUES
(17, 'Furniture Design', 'furniture-design', 'Custom furniture design', 1, 'active'),
(17, 'Color Consultation', 'color-consultation', 'Color and theme consultation', 2, 'active'),
(17, 'Lighting Design', 'lighting-design', 'Professional lighting solutions', 3, 'active');

-- Subcategories for Electronics (ID: 18)
INSERT INTO `subcategories` (`category_id`, `name`, `slug`, `description`, `sort_order`, `status`) VALUES
(18, 'Wiring', 'wiring', 'Electrical wiring and cables', 1, 'active'),
(18, 'Switches and Outlets', 'switches-outlets', 'Electrical switches and outlets', 2, 'active'),
(18, 'Panels and Boards', 'panels-boards', 'Electrical panels and boards', 3, 'active');
