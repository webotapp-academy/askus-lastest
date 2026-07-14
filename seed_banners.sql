-- Ensure banners table exists
CREATE TABLE IF NOT EXISTS `banners` (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `image` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mobile_image` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `link_type` enum('none','url','category','vendor','product') COLLATE utf8mb4_unicode_ci DEFAULT 'none',
  `link_value` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `position` enum('home_top','home_middle','category','vendor') COLLATE utf8mb4_unicode_ci DEFAULT 'home_top',
  `sort_order` int DEFAULT '0',
  `start_date` datetime DEFAULT NULL,
  `end_date` datetime DEFAULT NULL,
  `status` enum('active','inactive') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Clear existing sample data to avoid duplicates during testing
TRUNCATE TABLE `banners`;

-- Insert Home Top Banners
INSERT INTO `banners` (`title`, `image`, `position`, `sort_order`, `link_type`) VALUES 
('Quality Construction Materials', 'https://images.unsplash.com/photo-1581094794329-c8112a89af12?q=80&w=1470&auto=format&fit=crop', 'home_top', 1, 'category'),
('Professional Workers & Labours', 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?q=80&w=1470&auto=format&fit=crop', 'home_top', 2, 'category'),
('Heavy Machinery Solutions', 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?q=80&w=1470&auto=format&fit=crop', 'home_top', 3, 'category'),
('Interior Design Services', 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?q=80&w=1470&auto=format&fit=crop', 'home_top', 4, 'category');

-- Insert Home Middle Banner
INSERT INTO `banners` (`title`, `image`, `position`, `sort_order`, `link_type`) VALUES 
('Special Summer Offer - 20% Off on All Services', 'https://images.unsplash.com/photo-1621905235277-22668582d005?q=80&w=1470&auto=format&fit=crop', 'home_middle', 1, 'none');
