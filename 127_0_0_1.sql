-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Jan 06, 2026 at 06:14 AM
-- Server version: 8.4.6-6
-- PHP Version: 8.1.33

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `askus`
--
CREATE DATABASE IF NOT EXISTS `askus` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `askus`;

-- --------------------------------------------------------

--
-- Table structure for table `activity_logs`
--

CREATE TABLE `activity_logs` (
  `id` bigint UNSIGNED NOT NULL,
  `log_type` enum('user','vendor','admin','system') COLLATE utf8mb4_unicode_ci NOT NULL,
  `actor_type` enum('user','vendor','admin','delivery_agent','system') COLLATE utf8mb4_unicode_ci NOT NULL,
  `actor_id` bigint UNSIGNED DEFAULT NULL,
  `action` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `entity_id` bigint UNSIGNED DEFAULT NULL,
  `old_values` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `new_values` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `description` text COLLATE utf8mb4_unicode_ci,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ;

-- --------------------------------------------------------

--
-- Table structure for table `admins`
--

CREATE TABLE `admins` (
  `id` bigint UNSIGNED NOT NULL,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(15) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `avatar` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `role` enum('super_admin','admin','manager','support','accountant') COLLATE utf8mb4_unicode_ci DEFAULT 'admin',
  `permissions` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `status` enum('active','inactive') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `last_login_at` timestamp NULL DEFAULT NULL,
  `last_login_ip` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ;

--
-- Dumping data for table `admins`
--

INSERT INTO `admins` (`id`, `uuid`, `name`, `email`, `phone`, `password`, `avatar`, `role`, `permissions`, `status`, `last_login_at`, `last_login_ip`, `deleted_at`, `created_at`, `updated_at`) VALUES
(1, 'bf615aec-e950-11f0-b86a-9706569c0f76', 'Super Admin', 'admin@askus.com', NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, 'super_admin', NULL, 'active', '2026-01-04 11:39:58', '172.31.124.226', NULL, '2026-01-04 09:35:46', '2026-01-04 11:39:58');

-- --------------------------------------------------------

--
-- Table structure for table `app_settings`
--

CREATE TABLE `app_settings` (
  `id` bigint UNSIGNED NOT NULL,
  `group` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `key` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` text COLLATE utf8mb4_unicode_ci,
  `type` enum('string','number','boolean','json','file') COLLATE utf8mb4_unicode_ci DEFAULT 'string',
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_public` tinyint(1) DEFAULT '0',
  `updated_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `app_settings`
--

INSERT INTO `app_settings` (`id`, `group`, `key`, `value`, `type`, `description`, `is_public`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 'general', 'app_name', 'Ask Us', 'string', 'Application Name', 1, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(2, 'general', 'app_tagline', 'Your Local Multi-Vendor Marketplace', 'string', 'Application Tagline', 1, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(3, 'general', 'currency', 'INR', 'string', 'Default Currency', 1, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(4, 'general', 'currency_symbol', '₹', 'string', 'Currency Symbol', 1, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(5, 'general', 'timezone', 'Asia/Kolkata', 'string', 'Default Timezone', 0, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(6, 'general', 'date_format', 'd M Y', 'string', 'Date Format', 0, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(7, 'general', 'time_format', 'h:i A', 'string', 'Time Format', 0, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(8, 'order', 'min_order_amount', '99', 'number', 'Minimum Order Amount', 1, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(9, 'order', 'max_cod_amount', '5000', 'number', 'Maximum COD Amount', 1, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(10, 'order', 'order_accept_timeout', '120', 'number', 'Order Accept Timeout (seconds)', 0, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(11, 'order', 'auto_cancel_pending_orders', '30', 'number', 'Auto Cancel Pending Orders (minutes)', 0, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(12, 'delivery', 'base_delivery_charge', '20', 'number', 'Base Delivery Charge', 1, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(13, 'delivery', 'per_km_charge', '5', 'number', 'Per KM Delivery Charge', 1, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(14, 'delivery', 'free_delivery_above', '499', 'number', 'Free Delivery Above Amount', 1, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(15, 'delivery', 'max_delivery_radius', '10', 'number', 'Max Delivery Radius (KM)', 0, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(16, 'commission', 'default_commission_rate', '10', 'number', 'Default Vendor Commission %', 0, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(17, 'commission', 'payment_gateway_fee', '2', 'number', 'Payment Gateway Fee %', 0, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(18, 'vendor', 'auto_approve_vendors', '0', 'boolean', 'Auto Approve New Vendors', 0, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(19, 'vendor', 'settlement_period_days', '7', 'number', 'Settlement Period (Days)', 0, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(20, 'vendor', 'min_settlement_amount', '500', 'number', 'Minimum Settlement Amount', 0, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(21, 'wallet', 'referral_bonus_user', '50', 'number', 'Referral Bonus for User (INR)', 0, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(22, 'wallet', 'referral_bonus_referrer', '50', 'number', 'Referral Bonus for Referrer (INR)', 0, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(23, 'wallet', 'max_wallet_balance', '10000', 'number', 'Maximum Wallet Balance', 0, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(24, 'razorpay', 'key_id', '', 'string', 'Razorpay Key ID', 0, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(25, 'razorpay', 'key_secret', '', 'string', 'Razorpay Key Secret', 0, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46'),
(26, 'razorpay', 'webhook_secret', '', 'string', 'Razorpay Webhook Secret', 0, NULL, '2026-01-04 09:35:46', '2026-01-04 09:35:46');

-- --------------------------------------------------------

--
-- Table structure for table `banners`
--

CREATE TABLE `banners` (
  `id` bigint UNSIGNED NOT NULL,
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
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `banners`
--

INSERT INTO `banners` (`id`, `title`, `image`, `mobile_image`, `link_type`, `link_value`, `position`, `sort_order`, `start_date`, `end_date`, `status`, `created_at`, `updated_at`) VALUES
(1, 'Summer Sale - Up to 50% Off', 'https://indiawebdesigns.in/app/askus/images/1.jpg', NULL, 'category', '1', 'home_top', 1, '2026-01-04 19:04:14', '2026-02-03 19:04:14', 'active', '2026-01-04 13:34:14', '2026-01-05 11:03:50'),
(2, 'New Arrivals in Fashion', 'https://indiawebdesigns.in/app/askus/images/2.jpg', NULL, 'category', '2', 'home_top', 2, '2026-01-04 19:04:14', '2026-02-03 19:04:14', 'active', '2026-01-04 13:34:14', '2026-01-05 11:04:01'),
(3, 'Electronics Mega Deals', 'https://indiawebdesigns.in/app/askus/images/3.jpg', NULL, 'category', '1', 'home_top', 3, '2026-01-04 19:04:14', '2026-02-03 19:04:14', 'active', '2026-01-04 13:34:14', '2026-01-05 11:04:12'),
(4, 'Beauty & Health Offers', 'https://indiawebdesigns.in/app/askus/images/4.jpg', NULL, 'category', '4', 'home_middle', 4, '2026-01-04 19:04:14', '2026-02-03 19:04:14', 'active', '2026-01-04 13:34:14', '2026-01-05 11:04:25');

-- --------------------------------------------------------

--
-- Table structure for table `carts`
--

CREATE TABLE `carts` (
  `id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `coupon_id` bigint UNSIGNED DEFAULT NULL,
  `subtotal` decimal(12,2) DEFAULT '0.00',
  `discount` decimal(12,2) DEFAULT '0.00',
  `tax` decimal(12,2) DEFAULT '0.00',
  `delivery_charge` decimal(10,2) DEFAULT '0.00',
  `total` decimal(12,2) DEFAULT '0.00',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cart_items`
--

CREATE TABLE `cart_items` (
  `id` bigint UNSIGNED NOT NULL,
  `cart_id` bigint UNSIGNED NOT NULL,
  `product_id` bigint UNSIGNED NOT NULL,
  `variant_id` bigint UNSIGNED DEFAULT NULL,
  `vendor_id` bigint UNSIGNED NOT NULL,
  `quantity` int NOT NULL DEFAULT '1',
  `unit_price` decimal(10,2) NOT NULL,
  `total_price` decimal(12,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `id` bigint UNSIGNED NOT NULL,
  `parent_id` bigint UNSIGNED DEFAULT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `icon` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `image` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sort_order` int DEFAULT '0',
  `is_featured` tinyint(1) DEFAULT '0',
  `status` enum('active','inactive') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`id`, `parent_id`, `name`, `slug`, `description`, `icon`, `image`, `sort_order`, `is_featured`, `status`, `deleted_at`, `created_at`, `updated_at`) VALUES
(13, NULL, 'Construction', 'construction', 'Building Materials, Tools & Construction Services', 'fa fa-hard-hat', NULL, 7, 1, 'active', NULL, '2026-01-05 09:40:06', '2026-01-05 09:40:06'),
(14, NULL, 'Building Materials', 'building-materials', 'Cement, Bricks, Steel, Sand & Aggregates', 'fa fa-industry', NULL, 8, 1, 'active', NULL, '2026-01-05 09:40:06', '2026-01-05 09:40:06'),
(15, NULL, 'Construction Tools', 'construction-tools', 'Hand Tools, Power Tools & Machinery', 'fa fa-tools', NULL, 9, 1, 'active', NULL, '2026-01-05 09:40:06', '2026-01-05 09:40:06'),
(16, NULL, 'Electrical & Plumbing', 'electrical-plumbing', 'Wiring, Pipes, Fittings & Installations', 'fa fa-bolt', NULL, 10, 0, 'active', NULL, '2026-01-05 09:40:06', '2026-01-05 09:40:06'),
(17, NULL, 'Interior & Renovation', 'interior-renovation', 'Interior Design, Remodeling & Renovation Work', 'fa fa-paint-roller', NULL, 11, 1, 'active', NULL, '2026-01-05 09:40:06', '2026-01-05 09:40:06'),
(18, NULL, 'Construction Services', 'construction-services', 'Civil Work, Contractors & Project Execution', 'fa fa-building', NULL, 12, 0, 'active', NULL, '2026-01-05 09:40:06', '2026-01-05 09:40:06');

-- --------------------------------------------------------

--
-- Table structure for table `coupons`
--

CREATE TABLE `coupons` (
  `id` bigint UNSIGNED NOT NULL,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `discount_type` enum('flat','percentage') COLLATE utf8mb4_unicode_ci NOT NULL,
  `discount_value` decimal(10,2) NOT NULL,
  `min_order_amount` decimal(10,2) DEFAULT '0.00',
  `max_discount` decimal(10,2) DEFAULT NULL,
  `usage_limit` int DEFAULT NULL,
  `usage_per_user` int DEFAULT '1',
  `used_count` int DEFAULT '0',
  `applicable_on` enum('all','category','vendor','product') COLLATE utf8mb4_unicode_ci DEFAULT 'all',
  `applicable_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `user_type` enum('all','new','existing') COLLATE utf8mb4_unicode_ci DEFAULT 'all',
  `payment_methods` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `start_date` datetime NOT NULL,
  `end_date` datetime NOT NULL,
  `is_visible` tinyint(1) DEFAULT '1',
  `status` enum('active','inactive','expired') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ;

-- --------------------------------------------------------

--
-- Table structure for table `coupon_usages`
--

CREATE TABLE `coupon_usages` (
  `id` bigint UNSIGNED NOT NULL,
  `coupon_id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `order_id` bigint UNSIGNED NOT NULL,
  `discount_amount` decimal(10,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `delivery_agents`
--

CREATE TABLE `delivery_agents` (
  `id` bigint UNSIGNED NOT NULL,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `avatar` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `vehicle_type` enum('bicycle','motorcycle','scooter','car') COLLATE utf8mb4_unicode_ci DEFAULT 'motorcycle',
  `vehicle_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `license_number` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `aadhar_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bank_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bank_account_number` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bank_ifsc` varchar(15) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `current_latitude` decimal(10,8) DEFAULT NULL,
  `current_longitude` decimal(11,8) DEFAULT NULL,
  `is_online` tinyint(1) DEFAULT '0',
  `is_available` tinyint(1) DEFAULT '1',
  `rating` decimal(3,2) DEFAULT '0.00',
  `total_reviews` int DEFAULT '0',
  `total_deliveries` int DEFAULT '0',
  `fcm_token` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('pending','approved','rejected','suspended','inactive') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `last_online_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `delivery_tracking`
--

CREATE TABLE `delivery_tracking` (
  `id` bigint UNSIGNED NOT NULL,
  `vendor_order_id` bigint UNSIGNED NOT NULL,
  `delivery_agent_id` bigint UNSIGNED DEFAULT NULL,
  `status` enum('assigned','accepted','reached_vendor','picked','on_the_way','reached_customer','delivered','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `remarks` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `enquiries`
--

CREATE TABLE `enquiries` (
  `id` bigint UNSIGNED NOT NULL,
  `uuid` char(36) DEFAULT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `vendor_id` bigint UNSIGNED NOT NULL,
  `type` enum('product','service') DEFAULT 'product',
  `item_id` bigint UNSIGNED NOT NULL,
  `message` text NOT NULL,
  `preferred_date` date DEFAULT NULL,
  `preferred_time` varchar(20) DEFAULT NULL,
  `response` text,
  `status` enum('pending','responded','closed','cancelled') DEFAULT 'pending',
  `responded_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `enquiries`
--

INSERT INTO `enquiries` (`id`, `uuid`, `user_id`, `vendor_id`, `type`, `item_id`, `message`, `preferred_date`, `preferred_time`, `response`, `status`, `responded_at`, `deleted_at`, `created_at`, `updated_at`) VALUES
(1, 'd83a4a51-29ac-4095-a45a-8f1ba62fce50', 1, 1, 'product', 9, 'h ub', NULL, NULL, NULL, 'pending', NULL, NULL, '2026-01-04 16:30:37', '2026-01-04 16:30:37'),
(2, '14744e33-5c4a-4503-bbd3-0b6efecfdaee', 1, 1, 'service', 1, 'in ubu', NULL, NULL, NULL, 'pending', NULL, NULL, '2026-01-04 16:51:39', '2026-01-04 16:51:39'),
(3, 'c3be53b8-e07a-48ca-98d4-d2ff94490fb9', 22, 1, 'product', 42, 'hello', '2026-01-07', '7:15 PM', NULL, 'pending', NULL, NULL, '2026-01-05 11:45:53', '2026-01-05 11:45:53'),
(4, '8ec5505a-a2cf-404c-b363-feabba0cd0d1', 23, 1, 'service', 13, 'sss', '2026-01-07', '9:44 AM', NULL, 'pending', NULL, NULL, '2026-01-06 04:14:23', '2026-01-06 04:14:23');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` bigint UNSIGNED NOT NULL,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notifiable_type` enum('user','vendor','admin','delivery_agent') COLLATE utf8mb4_unicode_ci NOT NULL,
  `notifiable_id` bigint UNSIGNED NOT NULL,
  `type` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `body` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `image` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `action_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `read_at` timestamp NULL DEFAULT NULL,
  `sent_via` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ;

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `id` bigint UNSIGNED NOT NULL,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `order_number` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `address_id` bigint UNSIGNED DEFAULT NULL,
  `delivery_address` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `subtotal` decimal(12,2) NOT NULL,
  `tax_amount` decimal(10,2) DEFAULT '0.00',
  `discount_amount` decimal(10,2) DEFAULT '0.00',
  `delivery_charge` decimal(10,2) DEFAULT '0.00',
  `packaging_charge` decimal(10,2) DEFAULT '0.00',
  `tip_amount` decimal(10,2) DEFAULT '0.00',
  `total_amount` decimal(12,2) NOT NULL,
  `coupon_id` bigint UNSIGNED DEFAULT NULL,
  `coupon_code` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `coupon_discount` decimal(10,2) DEFAULT '0.00',
  `payment_method` enum('cod','razorpay','wallet','wallet_razorpay') COLLATE utf8mb4_unicode_ci NOT NULL,
  `payment_status` enum('pending','paid','failed','refunded','partial_refund') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `order_status` enum('pending','confirmed','processing','ready','out_for_delivery','delivered','cancelled','returned') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `order_note` text COLLATE utf8mb4_unicode_ci,
  `cancellation_reason` text COLLATE utf8mb4_unicode_ci,
  `cancelled_by` enum('user','vendor','admin','system') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cancelled_at` timestamp NULL DEFAULT NULL,
  `delivered_at` timestamp NULL DEFAULT NULL,
  `scheduled_at` timestamp NULL DEFAULT NULL,
  `is_scheduled` tinyint(1) DEFAULT '0',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ;

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

CREATE TABLE `order_items` (
  `id` bigint UNSIGNED NOT NULL,
  `order_id` bigint UNSIGNED NOT NULL,
  `vendor_order_id` bigint UNSIGNED DEFAULT NULL,
  `product_id` bigint UNSIGNED NOT NULL,
  `variant_id` bigint UNSIGNED DEFAULT NULL,
  `vendor_id` bigint UNSIGNED NOT NULL,
  `product_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `variant_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `product_image` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sku` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `quantity` int NOT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `tax_amount` decimal(10,2) DEFAULT '0.00',
  `discount_amount` decimal(10,2) DEFAULT '0.00',
  `total_price` decimal(12,2) NOT NULL,
  `status` enum('pending','confirmed','processing','ready','delivered','cancelled','returned') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `otp_verifications`
--

CREATE TABLE `otp_verifications` (
  `id` bigint UNSIGNED NOT NULL,
  `identifier` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `identifier_type` enum('phone','email') COLLATE utf8mb4_unicode_ci NOT NULL,
  `otp` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `purpose` enum('registration','login','password_reset','phone_verify','email_verify') COLLATE utf8mb4_unicode_ci NOT NULL,
  `attempts` int DEFAULT '0',
  `expires_at` timestamp NOT NULL,
  `verified_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `id` bigint UNSIGNED NOT NULL,
  `entity_type` enum('user','vendor','admin','delivery_agent') COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity_id` bigint UNSIGNED NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(15) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `token` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `otp` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `expires_at` timestamp NOT NULL,
  `used_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `id` bigint UNSIGNED NOT NULL,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `order_id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `currency` char(3) COLLATE utf8mb4_unicode_ci DEFAULT 'INR',
  `payment_method` enum('razorpay','cod','wallet','upi','card','netbanking') COLLATE utf8mb4_unicode_ci NOT NULL,
  `razorpay_order_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `razorpay_payment_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `razorpay_signature` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `razorpay_invoice_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `wallet_transaction_id` bigint UNSIGNED DEFAULT NULL,
  `status` enum('pending','processing','success','failed','refunded','partial_refund') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `failure_reason` text COLLATE utf8mb4_unicode_ci,
  `refund_amount` decimal(12,2) DEFAULT '0.00',
  `refund_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `refunded_at` timestamp NULL DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `paid_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ;

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `id` bigint UNSIGNED NOT NULL,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `vendor_id` bigint UNSIGNED NOT NULL,
  `category_id` bigint UNSIGNED NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `short_description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sku` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `barcode` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hsn_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mrp` decimal(10,2) NOT NULL,
  `selling_price` decimal(10,2) NOT NULL,
  `cost_price` decimal(10,2) DEFAULT NULL,
  `tax_rate` decimal(5,2) DEFAULT '0.00',
  `tax_type` enum('inclusive','exclusive') COLLATE utf8mb4_unicode_ci DEFAULT 'inclusive',
  `discount_type` enum('none','flat','percentage') COLLATE utf8mb4_unicode_ci DEFAULT 'none',
  `discount_value` decimal(10,2) DEFAULT '0.00',
  `stock_quantity` int DEFAULT '0',
  `low_stock_threshold` int DEFAULT '5',
  `unit` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'piece',
  `weight` decimal(10,3) DEFAULT NULL,
  `weight_unit` enum('g','kg','ml','l') COLLATE utf8mb4_unicode_ci DEFAULT 'g',
  `is_returnable` tinyint(1) DEFAULT '0',
  `return_days` int DEFAULT '0',
  `is_featured` tinyint(1) DEFAULT '0',
  `is_bestseller` tinyint(1) DEFAULT '0',
  `rating` decimal(3,2) DEFAULT '0.00',
  `total_reviews` int DEFAULT '0',
  `total_sold` int DEFAULT '0',
  `meta_title` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `meta_description` text COLLATE utf8mb4_unicode_ci,
  `status` enum('draft','active','inactive','out_of_stock') COLLATE utf8mb4_unicode_ci DEFAULT 'draft',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`id`, `uuid`, `vendor_id`, `category_id`, `name`, `slug`, `description`, `short_description`, `sku`, `barcode`, `hsn_code`, `mrp`, `selling_price`, `cost_price`, `tax_rate`, `tax_type`, `discount_type`, `discount_value`, `stock_quantity`, `low_stock_threshold`, `unit`, `weight`, `weight_unit`, `is_returnable`, `return_days`, `is_featured`, `is_bestseller`, `rating`, `total_reviews`, `total_sold`, `meta_title`, `meta_description`, `status`, `deleted_at`, `created_at`, `updated_at`) VALUES
(37, 'b7b56d2f-ea1c-11f0-8469-0050565d8541', 1, 13, 'Hydraulic Excavator', 'hydraulic-excavator', 'Heavy-duty excavator used for large construction projects.', 'Heavy-duty excavator', 'EXC-001', NULL, NULL, 3500000.00, 3200000.00, NULL, 18.00, 'exclusive', 'none', 0.00, 3, 5, 'piece', 21000.000, 'kg', 0, 0, 0, 0, 0.00, 0, 0, NULL, NULL, 'active', NULL, '2026-01-05 09:55:51', '2026-01-05 09:55:51'),
(38, 'bc2bfe30-ea1c-11f0-8469-0050565d8541', 1, 14, 'Portland Cement Bag (50kg)', 'portland-cement-50kg', 'High strength Portland cement for construction.', '50kg cement bag', 'CEM-002', NULL, NULL, 450.00, 420.00, NULL, 18.00, 'inclusive', 'none', 0.00, 500, 5, 'bag', 50.000, 'kg', 0, 0, 0, 0, 0.00, 0, 0, NULL, NULL, 'active', NULL, '2026-01-05 09:55:58', '2026-01-05 09:55:58'),
(39, 'c03ccab5-ea1c-11f0-8469-0050565d8541', 1, 15, 'Electric Concrete Mixer', 'electric-concrete-mixer', 'Portable concrete mixer for on-site construction.', 'Concrete mixer machine', 'TOOL-003', NULL, NULL, 98000.00, 92000.00, NULL, 18.00, 'exclusive', 'none', 0.00, 12, 5, 'piece', 350.000, 'kg', 0, 0, 0, 0, 0.00, 0, 0, NULL, NULL, 'active', NULL, '2026-01-05 09:56:05', '2026-01-05 09:56:05'),
(40, 'c3fc59bd-ea1c-11f0-8469-0050565d8541', 1, 16, 'PVC Electrical Conduit Pipe', 'pvc-electrical-conduit-pipe', 'Durable PVC pipe for electrical wiring.', 'PVC conduit pipe', 'ELC-004', NULL, NULL, 120.00, 95.00, NULL, 18.00, 'inclusive', 'none', 0.00, 300, 5, 'piece', 2.500, 'kg', 0, 0, 0, 0, 0.00, 0, 0, NULL, NULL, 'active', NULL, '2026-01-05 09:56:11', '2026-01-05 09:56:11'),
(41, 'c81073eb-ea1c-11f0-8469-0050565d8541', 1, 17, 'Interior Wall Paint (20L)', 'interior-wall-paint-20l', 'Premium washable interior wall paint.', 'Interior paint bucket', 'INT-005', NULL, NULL, 4800.00, 4500.00, NULL, 18.00, 'inclusive', 'none', 0.00, 80, 5, 'bucket', 22.000, 'kg', 0, 0, 0, 0, 0.00, 0, 0, NULL, NULL, 'active', NULL, '2026-01-05 09:56:18', '2026-01-05 09:56:18'),
(42, 'cc4314ca-ea1c-11f0-8469-0050565d8541', 1, 18, 'Residential Construction Service', 'residential-construction-service', 'Complete residential building construction service.', 'End-to-end construction service', 'SER-006', NULL, NULL, 6979.00, 5000.00, NULL, 18.00, 'exclusive', 'none', 0.00, 9999, 5, 'service', NULL, 'g', 0, 0, 0, 0, 0.00, 0, 0, NULL, NULL, 'active', NULL, '2026-01-05 09:56:25', '2026-01-05 11:32:04');

-- --------------------------------------------------------

--
-- Table structure for table `product_images`
--

CREATE TABLE `product_images` (
  `id` bigint UNSIGNED NOT NULL,
  `product_id` bigint UNSIGNED NOT NULL,
  `image_url` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `alt_text` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sort_order` int DEFAULT '0',
  `is_primary` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `product_images`
--

INSERT INTO `product_images` (`id`, `product_id`, `image_url`, `alt_text`, `sort_order`, `is_primary`, `created_at`) VALUES
(1, 37, 'https://thumbs.dreamstime.com/b/excavators-4563550.jpg?w=768', 'Hydraulic Excavator', 1, 1, '2026-01-04 15:42:35'),
(2, 38, 'https://imgs.search.brave.com/aQkmrVVWYgIcvvmwOmzXmaQfJPbSWZeAVFBoDpGgJ6A/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9zLmFs/aWNkbi5jb20vQHNj/MDQva2YvSDVlZTli/NDNiMmU4NzQ0MzVi/ZTcxOTg4MzE1MzFk/Nzg0YS5qcGdfMzAw/eDMwMC5qcGc', 'Portland Cement Bag (50kg)', 2, 0, '2026-01-04 15:42:35'),
(3, 39, 'https://imgs.search.brave.com/jLUEFW9C5ptmzAvlJWolX2P8nPrc5mkpcHdqDKvqPLY/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9tLm1l/ZGlhLWFtYXpvbi5j/b20vaW1hZ2VzL0kv/NzFjOVlHbXVpdkwu/anBn', 'Electric Concrete Mixer', 1, 1, '2026-01-04 15:42:35'),
(4, 40, 'https://imgs.search.brave.com/gsrKglRlNwr9zNCt6Wxxz4xUjaJDmShTjQvO7ghyS7g/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly81Lmlt/aW1nLmNvbS9kYXRh/NS9TRUxMRVIvRGVm/YXVsdC8yMDIyLzQv/UEsvT1YvTlYvMTM5/NjAxNjIxLzE2bW0t/ZWxlY3RyaWMtZml0/dGluZy1wdmMtY29u/ZHVpdC1waXBlLTUw/MHg1MDAuanBn', 'PVC Electrical Conduit Pipe', 2, 0, '2026-01-04 15:42:35'),
(5, 41, 'https://imgs.search.brave.com/apjYMtySvzW7r3h28EtiQy__K_J9-Jt8DDMmq-MYa_M/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9tLm1l/ZGlhLWFtYXpvbi5j/b20vaW1hZ2VzL0kv/NjF5YUNqWHhQMEwu/anBn', 'Interior Wall Paint (20L)', 1, 1, '2026-01-04 15:42:35'),
(6, 42, 'https://imgs.search.brave.com/JMXhjA9Dex4biY3p1aPB6v1kDfj9cSyhQ2q9X_3TkE4/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly81Lmlt/aW1nLmNvbS9kYXRh/NS9TRUxMRVIvRGVm/YXVsdC8yMDI0LzUv/NDIzNTEyNjAxL1FU/L1lVL1paLzY2NDgz/OTk1L3Jlc2lkZW50/aWFsLWhvdXNlLWNv/bnN0cnVjdGlvbi1z/ZXJ2aWNlLTI1MHgy/NTAucG5n', 'Residential Construction Service', 2, 0, '2026-01-04 15:42:35');

-- --------------------------------------------------------

--
-- Table structure for table `product_variants`
--

CREATE TABLE `product_variants` (
  `id` bigint UNSIGNED NOT NULL,
  `product_id` bigint UNSIGNED NOT NULL,
  `variant_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `variant_value` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sku` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mrp` decimal(10,2) NOT NULL,
  `selling_price` decimal(10,2) NOT NULL,
  `stock_quantity` int DEFAULT '0',
  `image_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('active','inactive') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `reviews`
--

CREATE TABLE `reviews` (
  `id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `order_id` bigint UNSIGNED NOT NULL,
  `product_id` bigint UNSIGNED DEFAULT NULL,
  `vendor_id` bigint UNSIGNED DEFAULT NULL,
  `delivery_agent_id` bigint UNSIGNED DEFAULT NULL,
  `review_type` enum('product','vendor','delivery') COLLATE utf8mb4_unicode_ci NOT NULL,
  `rating` tinyint NOT NULL,
  `title` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `comment` text COLLATE utf8mb4_unicode_ci,
  `images` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `is_verified_purchase` tinyint(1) DEFAULT '1',
  `is_approved` tinyint(1) DEFAULT '1',
  `admin_reply` text COLLATE utf8mb4_unicode_ci,
  `replied_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ;

-- --------------------------------------------------------

--
-- Table structure for table `services`
--

CREATE TABLE `services` (
  `id` bigint UNSIGNED NOT NULL,
  `uuid` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `vendor_id` bigint UNSIGNED NOT NULL,
  `category_id` bigint UNSIGNED DEFAULT NULL,
  `name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(220) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `short_description` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `price_type` enum('fixed','hourly','quote') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'fixed',
  `min_price` decimal(10,2) DEFAULT '0.00',
  `max_price` decimal(10,2) DEFAULT NULL,
  `duration_minutes` int DEFAULT NULL,
  `service_area` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `availability` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_featured` tinyint(1) DEFAULT '0',
  `rating` decimal(3,2) DEFAULT '0.00',
  `total_reviews` int DEFAULT '0',
  `status` enum('active','inactive','pending') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `services`
--

INSERT INTO `services` (`id`, `uuid`, `vendor_id`, `category_id`, `name`, `slug`, `description`, `short_description`, `price_type`, `min_price`, `max_price`, `duration_minutes`, `service_area`, `availability`, `is_featured`, `rating`, `total_reviews`, `status`, `deleted_at`, `created_at`, `updated_at`) VALUES
(13, '57cf61a8-ea28-11f0-8469-0050565d8541', 1, 18, 'Residential Building Construction', 'residential-building-construction', 'End-to-end residential house construction including planning, material, labor, and execution.', 'Complete house construction service', 'quote', 2990.00, NULL, NULL, 'City & Suburban Areas', 'Mon–Sat', 1, 4.60, 28, 'active', NULL, '2026-01-05 11:19:04', '2026-01-05 11:28:45'),
(14, '57cf676d-ea28-11f0-8469-0050565d8541', 1, 18, 'Commercial Construction Service', 'commercial-construction-service', 'Construction of offices, shops, warehouses, and commercial buildings.', 'Commercial construction service', 'quote', 9992.00, NULL, NULL, 'Metro & Industrial Zones', 'Mon–Sat', 1, 4.50, 19, 'active', NULL, '2026-01-05 11:19:04', '2026-01-05 11:28:51'),
(15, '57cf6823-ea28-11f0-8469-0050565d8541', 1, 17, 'Interior Renovation & Remodeling', 'interior-renovation-remodeling', 'Home and office interior renovation including flooring, painting, and redesign.', 'Interior renovation service', 'fixed', 75000.00, NULL, 10080, 'City Limits', 'Mon–Fri', 1, 4.40, 34, 'active', NULL, '2026-01-05 11:19:04', '2026-01-05 11:19:04'),
(16, '57cf68c3-ea28-11f0-8469-0050565d8541', 1, 16, 'Electrical Wiring Installation', 'electrical-wiring-installation', 'Complete electrical wiring installation for homes and commercial buildings.', 'Electrical wiring service', 'hourly', 800.00, 1200.00, 60, 'City Area', 'Mon–Sat', 0, 4.30, 22, 'active', NULL, '2026-01-05 11:19:04', '2026-01-05 11:19:04'),
(17, '57cf69e8-ea28-11f0-8469-0050565d8541', 1, 16, 'Plumbing Installation & Repair', 'plumbing-installation-repair', 'Professional plumbing services including fittings, leakage repair, and installation.', 'Plumbing service', 'hourly', 700.00, 1000.00, 60, 'City Area', 'Mon–Sat', 0, 4.20, 18, 'active', NULL, '2026-01-05 11:19:04', '2026-01-05 11:19:04'),
(18, '57cf6b50-ea28-11f0-8469-0050565d8541', 1, 17, 'Interior & Exterior Painting', 'interior-exterior-painting', 'Interior and exterior wall painting using premium quality paints.', 'Wall painting service', 'fixed', 25000.00, NULL, 2880, 'Urban & Semi-Urban Areas', 'Mon–Sat', 1, 4.50, 41, 'active', NULL, '2026-01-05 11:19:04', '2026-01-05 11:19:04'),
(19, '57cf6c30-ea28-11f0-8469-0050565d8541', 1, 18, 'Construction Site Inspection', 'construction-site-inspection', 'Professional site inspection and consultation by experienced engineers.', 'Site inspection & consultation', 'fixed', 3000.00, NULL, 120, 'Within City', 'Mon–Fri', 0, 4.70, 12, 'active', NULL, '2026-01-05 11:19:04', '2026-01-05 11:19:04');

-- --------------------------------------------------------

--
-- Table structure for table `service_images`
--

CREATE TABLE `service_images` (
  `id` bigint UNSIGNED NOT NULL,
  `service_id` bigint UNSIGNED NOT NULL,
  `image_url` varchar(500) NOT NULL,
  `sort_order` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `service_images`
--

INSERT INTO `service_images` (`id`, `service_id`, `image_url`, `sort_order`, `created_at`) VALUES
(7, 13, 'https://imgs.search.brave.com/9ageYb9VW4U3ckRLvI74cTFxrFTWRGdhJtrDjjWitpU/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9zdGF0/aWMudmVjdGVlenku/Y29tL3N5c3RlbS9y/ZXNvdXJjZXMvdGh1/bWJuYWlscy8wMDgv/NTA3LzkwMS9zbWFs/bC9jb25zdHJ1Y3Rp/b24tcmVzaWRlbnRp/YWwtbmV3LWhvdXNl/LWluLXByb2dyZXNz/LWF0LWJ1aWxkaW5n/LXNpdGUtcGhvdG8u/anBn', 1, '2026-01-04 16:59:08'),
(8, 14, 'https://imgs.search.brave.com/zuiBxJaVKdIPUSdes0kluQEF-4LIZDjf6XoRjGPiXI8/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9jcmVl/a2NyZS5jb20vd3At/Y29udGVudC91cGxv/YWRzL0NvbW1lcmNp/YWwtQ29uc3RydWN0/aW9uLVNlcnZpY2Ut/My5qcGc', 1, '2026-01-04 16:59:08'),
(9, 15, 'https://imgs.search.brave.com/8_kAojBzOIpyOAI6k_sQJmpPyPshgKEbs_XHgLok4no/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9zdGF0/aWMudmVjdGVlenku/Y29tL3N5c3RlbS9y/ZXNvdXJjZXMvdGh1/bWJuYWlscy8wMzAv/Nzg2LzYzNi9zbWFs/bC9pbnRlcmlvci1v/Zi1hLW5ldy1ob3Vz/ZS11bmRlci1jb25z/dHJ1Y3Rpb24tcmVt/b2RlbGluZy1hbmQt/cmVub3ZhdGlvLWdl/bmVyYXRpdmUtYWkt/cGhvdG8uanBlZw', 1, '2026-01-04 16:59:08'),
(10, 16, 'https://imgs.search.brave.com/A6iVZ4h8aLKGit-bibwsJGvufK3PXROEgnTv0T2FWOE/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly93d3cu/dWx0cmF0ZWNoY2Vt/ZW50LmNvbS9jb250/ZW50L3VsdHJhdGVj/aGNlbWVudC9pbi9l/bi9ob21lL2Zvci1o/b21lYnVpbGRlcnMv/aG9tZS1idWlsZGlu/Zy1leHBsYWluZWQt/c2luZ2xlL2Rlc2Ny/aXB0aXZlLWFydGlj/bGVzL2VsZWN0cmlj/YWwtd2lyaW5nL19q/Y3JfY29udGVudC9y/b290L2NvbnRhaW5l/ci9jb250YWluZXJf/MjA3MjA4OTE3Ny90/ZWFzZXJfY29weV9j/b3B5X2NvcF82ODg4/MDIzMDguY29yZWlt/Zy5qcGVnLzE3NDE2/NzUxMzcyODgvZWxl/Y3RyaWNhbC13aXJp/bmctNi5qcGVn', 1, '2026-01-04 16:59:08'),
(11, 17, 'https://imgs.search.brave.com/Jng4XjAWFRLfkojFMpHiJaPYISAwvxyYk2HAFOzavao/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9pLnBp/bmltZy5jb20vb3Jp/Z2luYWxzLzRmLzAw/L2IzLzRmMDBiM2Nj/NjU3OWQ2MWJkZDdl/M2MyMDZmMzQwOGZk/LmpwZw', 1, '2026-01-04 16:59:08'),
(12, 18, 'https://images.unsplash.com/photo-1580901369227-308f6f40bdeb?q=80&w=1472&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3Dhttps://imgs.search.brave.com/OxRTxQBr7tntINnQA5RV6QcUsJ0QKPZ-6bm8DWiAylE/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9jZXJ0/YXByby5jb20vd3At/Y29udGVudC91cGxv/YWRzL2NhY2hlL3Jl/bW90ZS9wdWItOWZj/MWYwNjVmMDdlNDQx/YjhmMzUzNjVjNzc0/ZjA5YWUtcjItZGV2/LzMyODgwMDE4MjEu/anBn', 1, '2026-01-04 16:59:08'),
(14, 19, 'https://imgs.search.brave.com/02bvOiij9T1K5UolMAOPsQbH-m4q3qDR1vMTGkjhRlc/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly93d3cu/ZG9mb3Jtcy5jb20v/d3AtY29udGVudC91/cGxvYWRzLzIwMjQv/MDQvY29uc3RydWN0/aW9uLXNpdGUtc2Fm/ZXR5LWluc3BlY3Rp/b24tY2hlY2tsaXN0/LWltcG9ydGFuY2Uu/anBn', 1, '2026-01-04 16:59:08');

-- --------------------------------------------------------

--
-- Table structure for table `settlements`
--

CREATE TABLE `settlements` (
  `id` bigint UNSIGNED NOT NULL,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `settlement_number` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `vendor_id` bigint UNSIGNED NOT NULL,
  `period_start` date NOT NULL,
  `period_end` date NOT NULL,
  `total_orders` int DEFAULT '0',
  `total_sales` decimal(14,2) DEFAULT '0.00',
  `total_commission` decimal(12,2) DEFAULT '0.00',
  `total_delivery_charge` decimal(10,2) DEFAULT '0.00',
  `total_tax` decimal(10,2) DEFAULT '0.00',
  `deductions` decimal(10,2) DEFAULT '0.00',
  `deduction_remarks` text COLLATE utf8mb4_unicode_ci,
  `net_payable` decimal(14,2) NOT NULL,
  `payment_method` enum('bank_transfer','upi','wallet') COLLATE utf8mb4_unicode_ci DEFAULT 'bank_transfer',
  `bank_reference` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('pending','processing','completed','failed') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `processed_at` timestamp NULL DEFAULT NULL,
  `processed_by` bigint UNSIGNED DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint UNSIGNED NOT NULL,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone_verified_at` timestamp NULL DEFAULT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `avatar` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `gender` enum('male','female','other') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `dob` date DEFAULT NULL,
  `referral_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `referred_by` bigint UNSIGNED DEFAULT NULL,
  `fcm_token` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `device_type` enum('android','ios','web') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('active','inactive','blocked') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `last_login_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `uuid`, `name`, `email`, `phone`, `phone_verified_at`, `email_verified_at`, `password`, `avatar`, `gender`, `dob`, `referral_code`, `referred_by`, `fcm_token`, `device_type`, `status`, `last_login_at`, `deleted_at`, `created_at`, `updated_at`) VALUES
(1, '', 'Paban', 'zzubizubi@gmail.com', '7002484119', NULL, NULL, '$2y$10$mpWfmbNXwsAxUEH4wKcP/.z6VZBM/XLETPMWManfCZJMFsopbkdvG', NULL, NULL, NULL, '26BDFE19', NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-04 09:38:49', '2026-01-04 09:38:49'),
(2, '59f0564a-228d-432d-b6ec-2712ab7b63da', 'ggg hhh', 'zzubizubi@gmail.comh', '7002160093', NULL, NULL, '$2y$12$R9SyjNkL8FOX/U9PR3eSy.DxdTRVKmxRMAgQb6uZ5G5E4teZBB8zu', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-04 13:03:04', '2026-01-04 13:03:04'),
(3, '38357413-69fb-4438-97af-931efc3f9178', 'ggg hhh', 'zzubigzubi@gmail.com', '7002160094', NULL, NULL, '$2y$12$eZjR.cp5GPdiKDc5YiiEyO4O8/Gem7gONeKYAKllxqDUEoObI7igS', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-04 13:04:26', '2026-01-04 13:04:26'),
(4, '3daa6548-684a-40f7-a4da-fc95636d88ba', 'true i', 'zzubizggubi@gmail.com', '9996668885', NULL, NULL, '$2y$12$n2TnAp5DT7lSpsFZjXrBpebZq2MWzJ/zH6t3fgAj2rLh/Qy56anke', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-04 13:09:04', '2026-01-04 13:09:04'),
(5, '3185b403-e12e-4128-81b8-caf530e8267c', 'panan hh', 'zzubizgghubi@gmail.com', '9638527411', NULL, NULL, '$2y$12$DlxE90/WoNABt9V5lPomLOpn8FwfhjbCtOoLkF/fjk56ZCmF92je.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-04 13:22:16', '2026-01-04 13:22:16'),
(6, 'u1a2b3c4-d5e6-4f7a-8b9c-0d1e2f3a4b5c', 'Rajesh Kumar', 'rajesh@store.com', '9876543210', NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-04 13:25:24', '2026-01-04 13:25:24'),
(7, 'u2b3c4d5-e6f7-5a8b-9c0d-1e2f3a4b5c6d', 'Priya Sharma', 'priya@store.com', '9876543211', NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-04 13:25:24', '2026-01-04 13:25:24'),
(8, 'u3c4d5e6-f7a8-6b9c-0d1e-2f3a4b5c6d7e', 'Amit Verma', 'amit@example.com', '9876543212', NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-04 13:25:24', '2026-01-04 13:25:24'),
(9, 'u4d5e6f7-a8b9-7c0d-1e2f-3a4b5c6d7e8f', 'Sneha Patel', 'sneha@example.com', '9876543213', NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-04 13:25:24', '2026-01-04 13:25:24'),
(22, 'd2acfe15-c4b4-4c71-a290-3ebbd5b43081', 'Rajat Pradhan', 'forpaisa28@gmail.com', '6009580782', NULL, NULL, '$2y$12$TU9fv84KquF8ZICHLuspwukAhQIuHYLfn6iG3wgXM6sodgW7oTLDG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-05 09:12:22', '2026-01-05 09:12:22'),
(23, '42c2d186-8a64-473f-ad6c-3962f59f3d0e', 'paban bhuyan', 'zzu1bizubi@gmail.com', '9999999999', NULL, NULL, '$2y$12$o8o1XCZowMO1sd4CFSTQkuxfoMEiH52JcTvMzpVLQMwR7HezJRn5i', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-06 04:13:42', '2026-01-06 04:13:42');

-- --------------------------------------------------------

--
-- Table structure for table `user_addresses`
--

CREATE TABLE `user_addresses` (
  `id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `type` enum('home','work','other') COLLATE utf8mb4_unicode_ci DEFAULT 'home',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `address_line_1` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `address_line_2` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `landmark` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `state` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pincode` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `is_default` tinyint(1) DEFAULT '0',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `vendors`
--

CREATE TABLE `vendors` (
  `id` bigint UNSIGNED NOT NULL,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `owner_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `store_name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `store_slug` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `store_logo` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `store_banner` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `store_description` text COLLATE utf8mb4_unicode_ci,
  `address` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pincode` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `gst_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pan_number` varchar(15) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fssai_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bank_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bank_account_number` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bank_ifsc` varchar(15) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bank_account_holder` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `upi_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `commission_rate` decimal(5,2) DEFAULT '10.00',
  `min_order_amount` decimal(10,2) DEFAULT '0.00',
  `delivery_radius_km` decimal(5,2) DEFAULT '5.00',
  `avg_delivery_time` int DEFAULT '30',
  `rating` decimal(3,2) DEFAULT '0.00',
  `total_reviews` int DEFAULT '0',
  `total_orders` int DEFAULT '0',
  `is_featured` tinyint(1) DEFAULT '0',
  `is_verified` tinyint(1) DEFAULT '0',
  `auto_accept_orders` tinyint(1) DEFAULT '0',
  `is_open` tinyint(1) DEFAULT '1',
  `opening_time` time DEFAULT NULL,
  `closing_time` time DEFAULT NULL,
  `fcm_token` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('pending','approved','rejected','suspended','inactive') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `rejection_reason` text COLLATE utf8mb4_unicode_ci,
  `approved_at` timestamp NULL DEFAULT NULL,
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `last_login_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `vendors`
--

INSERT INTO `vendors` (`id`, `uuid`, `owner_name`, `email`, `phone`, `password`, `store_name`, `store_slug`, `store_logo`, `store_banner`, `store_description`, `address`, `city`, `state`, `pincode`, `latitude`, `longitude`, `gst_number`, `pan_number`, `fssai_number`, `bank_name`, `bank_account_number`, `bank_ifsc`, `bank_account_holder`, `upi_id`, `commission_rate`, `min_order_amount`, `delivery_radius_km`, `avg_delivery_time`, `rating`, `total_reviews`, `total_orders`, `is_featured`, `is_verified`, `auto_accept_orders`, `is_open`, `opening_time`, `closing_time`, `fcm_token`, `status`, `rejection_reason`, `approved_at`, `approved_by`, `last_login_at`, `deleted_at`, `created_at`, `updated_at`) VALUES
(1, 'v1a2b3c4-d5e6-4f7a-8b9c-0d1e2f3a4b5c', 'Rajesh Kumar', 'rajesh@store.com', '9876543220', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Rajesh Electronics', 'rajesh-electronics-abc123', NULL, NULL, 'Your one-stop shop for all electronic gadgets, mobiles, laptops and accessories.', '123 MG Road, Koramangala', 'Bangalore', 'Karnataka', '560034', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10.00, 0.00, 5.00, 30, 4.50, 120, 0, 0, 1, 0, 1, NULL, NULL, NULL, 'approved', NULL, NULL, NULL, NULL, NULL, '2026-01-04 13:30:48', '2026-01-04 13:30:48'),
(2, 'v2b3c4d5-e6f7-5a8b-9c0d-1e2f3a4b5c6d', 'Priya Sharma', 'priya@store.com', '9876543221', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Priya Fashion House', 'priya-fashion-house-def456', NULL, NULL, 'Designer clothing, traditional wear, and modern fashion for all occasions.', '456 Brigade Road', 'Bangalore', 'Karnataka', '560001', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 12.00, 0.00, 5.00, 30, 4.80, 85, 0, 0, 1, 0, 1, NULL, NULL, NULL, 'approved', NULL, NULL, NULL, NULL, NULL, '2026-01-04 13:30:48', '2026-01-04 13:30:48');

-- --------------------------------------------------------

--
-- Table structure for table `vendor_documents`
--

CREATE TABLE `vendor_documents` (
  `id` bigint UNSIGNED NOT NULL,
  `vendor_id` bigint UNSIGNED NOT NULL,
  `document_type` enum('pan_card','aadhar_card','gst_certificate','fssai_license','shop_license','bank_statement','cancelled_cheque','other') COLLATE utf8mb4_unicode_ci NOT NULL,
  `document_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `document_url` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('pending','approved','rejected') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `rejection_reason` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `verified_at` timestamp NULL DEFAULT NULL,
  `verified_by` bigint UNSIGNED DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `vendor_orders`
--

CREATE TABLE `vendor_orders` (
  `id` bigint UNSIGNED NOT NULL,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `order_id` bigint UNSIGNED NOT NULL,
  `vendor_id` bigint UNSIGNED NOT NULL,
  `vendor_order_number` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subtotal` decimal(12,2) NOT NULL,
  `tax_amount` decimal(10,2) DEFAULT '0.00',
  `discount_amount` decimal(10,2) DEFAULT '0.00',
  `delivery_charge` decimal(10,2) DEFAULT '0.00',
  `total_amount` decimal(12,2) NOT NULL,
  `commission_rate` decimal(5,2) NOT NULL,
  `commission_amount` decimal(10,2) NOT NULL,
  `vendor_earning` decimal(12,2) NOT NULL,
  `status` enum('pending','accepted','rejected','processing','ready','picked','delivered','cancelled','returned') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `rejection_reason` text COLLATE utf8mb4_unicode_ci,
  `accepted_at` timestamp NULL DEFAULT NULL,
  `ready_at` timestamp NULL DEFAULT NULL,
  `picked_at` timestamp NULL DEFAULT NULL,
  `delivered_at` timestamp NULL DEFAULT NULL,
  `cancelled_at` timestamp NULL DEFAULT NULL,
  `estimated_prep_time` int DEFAULT NULL,
  `delivery_agent_id` bigint UNSIGNED DEFAULT NULL,
  `is_settled` tinyint(1) DEFAULT '0',
  `settled_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `wallets`
--

CREATE TABLE `wallets` (
  `id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED DEFAULT NULL,
  `vendor_id` bigint UNSIGNED DEFAULT NULL,
  `balance` decimal(12,2) DEFAULT '0.00',
  `pending_balance` decimal(12,2) DEFAULT '0.00',
  `total_credited` decimal(14,2) DEFAULT '0.00',
  `total_debited` decimal(14,2) DEFAULT '0.00',
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `wallet_transactions`
--

CREATE TABLE `wallet_transactions` (
  `id` bigint UNSIGNED NOT NULL,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `wallet_id` bigint UNSIGNED NOT NULL,
  `type` enum('credit','debit') COLLATE utf8mb4_unicode_ci NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `balance_after` decimal(12,2) NOT NULL,
  `transaction_type` enum('order_payment','order_refund','cashback','referral_bonus','admin_credit','admin_debit','vendor_settlement','withdrawal','topup') COLLATE utf8mb4_unicode_ci NOT NULL,
  `reference_type` enum('order','payment','settlement','admin','referral','withdrawal') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reference_id` bigint UNSIGNED DEFAULT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('pending','completed','failed','reversed') COLLATE utf8mb4_unicode_ci DEFAULT 'completed',
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `created_by` bigint UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ;

-- --------------------------------------------------------

--
-- Table structure for table `wishlists`
--

CREATE TABLE `wishlists` (
  `id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `product_id` bigint UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `activity_logs`
--
ALTER TABLE `activity_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_activity_actor` (`actor_type`,`actor_id`),
  ADD KEY `idx_activity_entity` (`entity_type`,`entity_id`),
  ADD KEY `idx_activity_action` (`action`),
  ADD KEY `idx_activity_date` (`created_at`);

--
-- Indexes for table `admins`
--
ALTER TABLE `admins`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uuid` (`uuid`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_admins_email` (`email`),
  ADD KEY `idx_admins_role` (`role`);

--
-- Indexes for table `app_settings`
--
ALTER TABLE `app_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `idx_settings_key` (`group`,`key`),
  ADD KEY `updated_by` (`updated_by`);

--
-- Indexes for table `banners`
--
ALTER TABLE `banners`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_banners_position` (`position`),
  ADD KEY `idx_banners_status` (`status`);

--
-- Indexes for table `carts`
--
ALTER TABLE `carts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `idx_carts_user` (`user_id`),
  ADD KEY `coupon_id` (`coupon_id`);

--
-- Indexes for table `cart_items`
--
ALTER TABLE `cart_items`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `idx_cart_product` (`cart_id`,`product_id`,`variant_id`),
  ADD KEY `idx_cart_items_vendor` (`vendor_id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `variant_id` (`variant_id`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `slug` (`slug`),
  ADD KEY `idx_categories_parent` (`parent_id`),
  ADD KEY `idx_categories_slug` (`slug`),
  ADD KEY `idx_categories_status` (`status`);

--
-- Indexes for table `coupons`
--
ALTER TABLE `coupons`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`),
  ADD KEY `idx_coupons_code` (`code`),
  ADD KEY `idx_coupons_status` (`status`),
  ADD KEY `idx_coupons_dates` (`start_date`,`end_date`),
  ADD KEY `created_by` (`created_by`);

--
-- Indexes for table `coupon_usages`
--
ALTER TABLE `coupon_usages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_coupon_usage_coupon` (`coupon_id`),
  ADD KEY `idx_coupon_usage_user` (`user_id`),
  ADD KEY `order_id` (`order_id`);

--
-- Indexes for table `delivery_agents`
--
ALTER TABLE `delivery_agents`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uuid` (`uuid`),
  ADD UNIQUE KEY `phone` (`phone`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_delivery_agents_phone` (`phone`),
  ADD KEY `idx_delivery_agents_status` (`status`),
  ADD KEY `idx_delivery_agents_available` (`is_online`,`is_available`),
  ADD KEY `idx_delivery_agents_location` (`current_latitude`,`current_longitude`);

--
-- Indexes for table `delivery_tracking`
--
ALTER TABLE `delivery_tracking`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_delivery_tracking_order` (`vendor_order_id`),
  ADD KEY `idx_delivery_tracking_agent` (`delivery_agent_id`);

--
-- Indexes for table `enquiries`
--
ALTER TABLE `enquiries`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `vendor_id` (`vendor_id`),
  ADD KEY `status` (`status`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uuid` (`uuid`),
  ADD KEY `idx_notifications_user` (`notifiable_type`,`notifiable_id`),
  ADD KEY `idx_notifications_read` (`is_read`),
  ADD KEY `idx_notifications_type` (`type`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uuid` (`uuid`),
  ADD UNIQUE KEY `order_number` (`order_number`),
  ADD KEY `idx_orders_user` (`user_id`),
  ADD KEY `idx_orders_number` (`order_number`),
  ADD KEY `idx_orders_status` (`order_status`),
  ADD KEY `idx_orders_payment` (`payment_status`),
  ADD KEY `idx_orders_date` (`created_at`),
  ADD KEY `address_id` (`address_id`),
  ADD KEY `coupon_id` (`coupon_id`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_order_items_order` (`order_id`),
  ADD KEY `idx_order_items_vendor` (`vendor_id`),
  ADD KEY `idx_order_items_product` (`product_id`),
  ADD KEY `variant_id` (`variant_id`),
  ADD KEY `vendor_order_id` (`vendor_order_id`);

--
-- Indexes for table `otp_verifications`
--
ALTER TABLE `otp_verifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_otp_identifier` (`identifier`,`identifier_type`),
  ADD KEY `idx_otp_expires` (`expires_at`);

--
-- Indexes for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_password_resets_token` (`token`),
  ADD KEY `idx_password_resets_entity` (`entity_type`,`entity_id`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uuid` (`uuid`),
  ADD KEY `idx_payments_order` (`order_id`),
  ADD KEY `idx_payments_user` (`user_id`),
  ADD KEY `idx_payments_razorpay` (`razorpay_payment_id`),
  ADD KEY `idx_payments_status` (`status`),
  ADD KEY `wallet_transaction_id` (`wallet_transaction_id`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uuid` (`uuid`),
  ADD UNIQUE KEY `idx_products_vendor_slug` (`vendor_id`,`slug`),
  ADD KEY `idx_products_vendor` (`vendor_id`),
  ADD KEY `idx_products_category` (`category_id`),
  ADD KEY `idx_products_slug` (`slug`),
  ADD KEY `idx_products_status` (`status`),
  ADD KEY `idx_products_price` (`selling_price`),
  ADD KEY `idx_products_featured` (`is_featured`);

--
-- Indexes for table `product_images`
--
ALTER TABLE `product_images`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_product_images` (`product_id`);

--
-- Indexes for table `product_variants`
--
ALTER TABLE `product_variants`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_product_variants` (`product_id`);

--
-- Indexes for table `reviews`
--
ALTER TABLE `reviews`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_reviews_user` (`user_id`),
  ADD KEY `idx_reviews_product` (`product_id`),
  ADD KEY `idx_reviews_vendor` (`vendor_id`),
  ADD KEY `idx_reviews_order` (`order_id`),
  ADD KEY `idx_reviews_rating` (`rating`),
  ADD KEY `delivery_agent_id` (`delivery_agent_id`);

--
-- Indexes for table `services`
--
ALTER TABLE `services`
  ADD PRIMARY KEY (`id`),
  ADD KEY `vendor_id` (`vendor_id`),
  ADD KEY `category_id` (`category_id`),
  ADD KEY `status` (`status`);

--
-- Indexes for table `service_images`
--
ALTER TABLE `service_images`
  ADD PRIMARY KEY (`id`),
  ADD KEY `service_id` (`service_id`);

--
-- Indexes for table `settlements`
--
ALTER TABLE `settlements`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uuid` (`uuid`),
  ADD UNIQUE KEY `settlement_number` (`settlement_number`),
  ADD KEY `idx_settlements_vendor` (`vendor_id`),
  ADD KEY `idx_settlements_status` (`status`),
  ADD KEY `idx_settlements_period` (`period_start`,`period_end`),
  ADD KEY `processed_by` (`processed_by`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uuid` (`uuid`),
  ADD UNIQUE KEY `phone` (`phone`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `referral_code` (`referral_code`),
  ADD KEY `idx_users_phone` (`phone`),
  ADD KEY `idx_users_email` (`email`),
  ADD KEY `idx_users_status` (`status`),
  ADD KEY `idx_users_referral` (`referral_code`),
  ADD KEY `referred_by` (`referred_by`);

--
-- Indexes for table `user_addresses`
--
ALTER TABLE `user_addresses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_address_user` (`user_id`),
  ADD KEY `idx_address_pincode` (`pincode`);

--
-- Indexes for table `vendors`
--
ALTER TABLE `vendors`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uuid` (`uuid`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `phone` (`phone`),
  ADD UNIQUE KEY `store_slug` (`store_slug`),
  ADD KEY `idx_vendors_phone` (`phone`),
  ADD KEY `idx_vendors_email` (`email`),
  ADD KEY `idx_vendors_slug` (`store_slug`),
  ADD KEY `idx_vendors_status` (`status`),
  ADD KEY `idx_vendors_city` (`city`),
  ADD KEY `idx_vendors_pincode` (`pincode`),
  ADD KEY `idx_vendors_location` (`latitude`,`longitude`),
  ADD KEY `approved_by` (`approved_by`);

--
-- Indexes for table `vendor_documents`
--
ALTER TABLE `vendor_documents`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_vendor_docs` (`vendor_id`,`document_type`),
  ADD KEY `verified_by` (`verified_by`);

--
-- Indexes for table `vendor_orders`
--
ALTER TABLE `vendor_orders`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uuid` (`uuid`),
  ADD UNIQUE KEY `vendor_order_number` (`vendor_order_number`),
  ADD KEY `idx_vendor_orders_order` (`order_id`),
  ADD KEY `idx_vendor_orders_vendor` (`vendor_id`),
  ADD KEY `idx_vendor_orders_status` (`status`),
  ADD KEY `idx_vendor_orders_settled` (`is_settled`),
  ADD KEY `delivery_agent_id` (`delivery_agent_id`);

--
-- Indexes for table `wallets`
--
ALTER TABLE `wallets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `idx_wallet_user` (`user_id`),
  ADD UNIQUE KEY `idx_wallet_vendor` (`vendor_id`);

--
-- Indexes for table `wallet_transactions`
--
ALTER TABLE `wallet_transactions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uuid` (`uuid`),
  ADD KEY `idx_wallet_trans_wallet` (`wallet_id`),
  ADD KEY `idx_wallet_trans_type` (`transaction_type`),
  ADD KEY `idx_wallet_trans_date` (`created_at`);

--
-- Indexes for table `wishlists`
--
ALTER TABLE `wishlists`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `idx_wishlist_user_product` (`user_id`,`product_id`),
  ADD KEY `product_id` (`product_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `activity_logs`
--
ALTER TABLE `activity_logs`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `admins`
--
ALTER TABLE `admins`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `app_settings`
--
ALTER TABLE `app_settings`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=39;

--
-- AUTO_INCREMENT for table `banners`
--
ALTER TABLE `banners`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `carts`
--
ALTER TABLE `carts`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `cart_items`
--
ALTER TABLE `cart_items`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `coupons`
--
ALTER TABLE `coupons`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `coupon_usages`
--
ALTER TABLE `coupon_usages`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `delivery_agents`
--
ALTER TABLE `delivery_agents`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `delivery_tracking`
--
ALTER TABLE `delivery_tracking`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `enquiries`
--
ALTER TABLE `enquiries`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `otp_verifications`
--
ALTER TABLE `otp_verifications`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `products`
--
ALTER TABLE `products`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;

--
-- AUTO_INCREMENT for table `product_images`
--
ALTER TABLE `product_images`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT for table `product_variants`
--
ALTER TABLE `product_variants`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `reviews`
--
ALTER TABLE `reviews`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `services`
--
ALTER TABLE `services`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `service_images`
--
ALTER TABLE `service_images`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `settlements`
--
ALTER TABLE `settlements`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `user_addresses`
--
ALTER TABLE `user_addresses`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `vendors`
--
ALTER TABLE `vendors`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `vendor_documents`
--
ALTER TABLE `vendor_documents`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `vendor_orders`
--
ALTER TABLE `vendor_orders`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `wallets`
--
ALTER TABLE `wallets`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `wallet_transactions`
--
ALTER TABLE `wallet_transactions`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `wishlists`
--
ALTER TABLE `wishlists`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `app_settings`
--
ALTER TABLE `app_settings`
  ADD CONSTRAINT `app_settings_ibfk_1` FOREIGN KEY (`updated_by`) REFERENCES `admins` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `carts`
--
ALTER TABLE `carts`
  ADD CONSTRAINT `carts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `carts_ibfk_2` FOREIGN KEY (`coupon_id`) REFERENCES `coupons` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `cart_items`
--
ALTER TABLE `cart_items`
  ADD CONSTRAINT `cart_items_ibfk_1` FOREIGN KEY (`cart_id`) REFERENCES `carts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `cart_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `cart_items_ibfk_3` FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `cart_items_ibfk_4` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `categories`
--
ALTER TABLE `categories`
  ADD CONSTRAINT `categories_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `coupons`
--
ALTER TABLE `coupons`
  ADD CONSTRAINT `coupons_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `admins` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `coupon_usages`
--
ALTER TABLE `coupon_usages`
  ADD CONSTRAINT `coupon_usages_ibfk_1` FOREIGN KEY (`coupon_id`) REFERENCES `coupons` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `coupon_usages_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `coupon_usages_ibfk_3` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `delivery_tracking`
--
ALTER TABLE `delivery_tracking`
  ADD CONSTRAINT `delivery_tracking_ibfk_1` FOREIGN KEY (`vendor_order_id`) REFERENCES `vendor_orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `delivery_tracking_ibfk_2` FOREIGN KEY (`delivery_agent_id`) REFERENCES `delivery_agents` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`address_id`) REFERENCES `user_addresses` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `orders_ibfk_3` FOREIGN KEY (`coupon_id`) REFERENCES `coupons` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`),
  ADD CONSTRAINT `order_items_ibfk_3` FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `order_items_ibfk_4` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`),
  ADD CONSTRAINT `order_items_ibfk_5` FOREIGN KEY (`vendor_order_id`) REFERENCES `vendor_orders` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`),
  ADD CONSTRAINT `payments_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `payments_ibfk_3` FOREIGN KEY (`wallet_transaction_id`) REFERENCES `wallet_transactions` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `products_ibfk_1` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `products_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`);

--
-- Constraints for table `product_images`
--
ALTER TABLE `product_images`
  ADD CONSTRAINT `product_images_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `product_variants`
--
ALTER TABLE `product_variants`
  ADD CONSTRAINT `product_variants_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `reviews`
--
ALTER TABLE `reviews`
  ADD CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reviews_ibfk_2` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reviews_ibfk_3` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reviews_ibfk_4` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reviews_ibfk_5` FOREIGN KEY (`delivery_agent_id`) REFERENCES `delivery_agents` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `settlements`
--
ALTER TABLE `settlements`
  ADD CONSTRAINT `settlements_ibfk_1` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`),
  ADD CONSTRAINT `settlements_ibfk_2` FOREIGN KEY (`processed_by`) REFERENCES `admins` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`referred_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `user_addresses`
--
ALTER TABLE `user_addresses`
  ADD CONSTRAINT `user_addresses_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `vendors`
--
ALTER TABLE `vendors`
  ADD CONSTRAINT `vendors_ibfk_1` FOREIGN KEY (`approved_by`) REFERENCES `admins` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `vendor_documents`
--
ALTER TABLE `vendor_documents`
  ADD CONSTRAINT `vendor_documents_ibfk_1` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `vendor_documents_ibfk_2` FOREIGN KEY (`verified_by`) REFERENCES `admins` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `vendor_orders`
--
ALTER TABLE `vendor_orders`
  ADD CONSTRAINT `vendor_orders_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `vendor_orders_ibfk_2` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`),
  ADD CONSTRAINT `vendor_orders_ibfk_3` FOREIGN KEY (`delivery_agent_id`) REFERENCES `delivery_agents` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `wallets`
--
ALTER TABLE `wallets`
  ADD CONSTRAINT `wallets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `wallets_ibfk_2` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `wallet_transactions`
--
ALTER TABLE `wallet_transactions`
  ADD CONSTRAINT `wallet_transactions_ibfk_1` FOREIGN KEY (`wallet_id`) REFERENCES `wallets` (`id`);

--
-- Constraints for table `wishlists`
--
ALTER TABLE `wishlists`
  ADD CONSTRAINT `wishlists_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `wishlists_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
