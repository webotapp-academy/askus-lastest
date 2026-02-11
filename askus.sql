-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Feb 02, 2026 at 07:58 AM
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
(1, 'bf615aec-e950-11f0-b86a-9706569c0f76', 'Super Admin', 'admin@askus.com', NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, 'super_admin', NULL, 'active', '2026-01-29 06:46:43', '103.80.68.236', NULL, '2026-01-04 09:35:46', '2026-01-29 06:46:43');

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
  `gallery_images` text COLLATE utf8mb4_unicode_ci COMMENT 'JSON array of gallery image URLs',
  `gallery_count` int DEFAULT '0',
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

INSERT INTO `categories` (`id`, `parent_id`, `name`, `slug`, `description`, `icon`, `image`, `gallery_images`, `gallery_count`, `sort_order`, `is_featured`, `status`, `deleted_at`, `created_at`, `updated_at`) VALUES
(13, NULL, 'Heavy Machinery', 'Heavy Machinery', NULL, 'fa fa-hard-hat', 'https://indiawebdesigns.in/app/askus/images/heavy_machinery.jpg', '[\"https:\\/\\/images.unsplash.com\\/photo-1642927778267-4e8b787b325a?q=80&w=1074&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D\",\"https:\\/\\/images.unsplash.com\\/photo-1580901369227-308f6f40bdeb?q=80&w=1172&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D\",\"https:\\/\\/plus.unsplash.com\\/premium_photo-1677707394493-09962b13b675?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D\",\"https:\\/\\/images.unsplash.com\\/photo-1621922688758-359fc864071e?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D\",\"https:\\/\\/images.unsplash.com\\/photo-1603814744174-115311ad645e?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D\",\"https:\\/\\/images.unsplash.com\\/photo-1523660778745-247ed0bcce31?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D\"]', 6, 7, 1, 'active', NULL, '2026-01-05 09:40:06', '2026-02-02 06:40:47'),
(14, NULL, 'Hardwares', 'Hardwares', 'Cement, Nails', 'fa fa-industry', 'https://indiawebdesigns.in/app/askus/images/hardwares.jpg', '[\"https:\\/\\/imgs.search.brave.com\\/xuuJnWurykK7AtbRwAiC_Ali_GaJRTPi1DMhndiM-44\\/rs:fit:500:0:1:0\\/g:ce\\/aHR0cHM6Ly9tZWRp\\/YS5nZXR0eWltYWdl\\/cy5jb20vaWQvMTI3\\/Mjk5ODU4MC9waG90\\/by9zdGVlbC1yb2Rz\\/LWF0LWEtZmFjdG9y\\/eS5qcGc_cz02MTJ4\\/NjEyJnc9MCZrPTIw\\/JmM9dTFrcC1ELUhV\\/MDhRTFFvMV9uVkpl\\/SkpTbXVBNUlHeUZr\\/T1VDTTlMTlR0UT0\",\"https:\\/\\/imgs.search.brave.com\\/yNul58mO7pH0R3tOObM8ELdM5brhGtFEnfhvZK2aiYk\\/rs:fit:500:0:1:0\\/g:ce\\/aHR0cHM6Ly93d3cu\\/c2h1dHRlcnN0b2Nr\\/LmNvbS9pbWFnZS1w\\/aG90by9waWxlLWNl\\/bWVudC1iYWdzLXN0\\/YWNrZWQtY29uc3Ry\\/dWN0aW9uLTI2MG53\\/LTEzMDU0NTgyOTMu\\/anBn\",\"https:\\/\\/imgs.search.brave.com\\/g0l29lcNlfY-HluEOKRiLqkS3I-z4_2QNiw1itC7n6I\\/rs:fit:500:0:1:0\\/g:ce\\/aHR0cHM6Ly9zdGF0\\/aWMuYXNpYW5wYWlu\\/dHMuY29tL2NvbnRl\\/bnQvZGFtL2FzaWFu\\/X3BhaW50cy9wcm9k\\/dWN0cy9wYWNrc2hv\\/dHMvaW50ZXJpb3It\\/d2FsbHMtcm95YWxl\\/LW1hdHQtYXNpYW4t\\/cGFpbnRzLnBuZw\",\"https:\\/\\/imgs.search.brave.com\\/Piy6EjxYz11eu2wd7jo1NltgRsNsgqtWRCixzvrDS98\\/rs:fit:500:0:1:0\\/g:ce\\/aHR0cHM6Ly9jb250\\/ZW50LmpkbWFnaWNi\\/b3guY29tL2NvbXAv\\/ZXJuYWt1bGFtL2My\\/LzA0ODRweDQ4NC54\\/NDg0LjE0MDMxODIw\\/MzIxOC5yMWMyL2Nh\\/dGFsb2d1ZS9zcmkt\\/a3Jpc2huYS1oYXJk\\/d2FyZXMtZXJuYWt1\\/bGFtLW5kY3VoLTI1\\/MC5qcGc_dz02NDAm\\/cT03NQ\",\"https:\\/\\/imgs.search.brave.com\\/9k_hUpZkj-3e1fuVHLnf9ZVKGxDgZvFePWgxyOMzg5c\\/rs:fit:500:0:1:0\\/g:ce\\/aHR0cHM6Ly9jb250\\/ZW50LmpkbWFnaWNi\\/b3guY29tL2NvbXAv\\/aG9zdXIveTQvOTk5\\/OXA0MzQ0LjQzNDQu\\/MTIwNzI1MTYxODUz\\/LnE3eTQvY2F0YWxv\\/Z3VlL3JveWFsLWNl\\/cmFtaWNzLWFuZC1o\\/YXJkd2FyZXMtaG9z\\/dXItaG8taG9zdXIt\\/aGFyZHdhcmUtc2hv\\/cHMtNjJwMDItMjUw\\/LmpwZz93PTY0MCZx\\/PTc1\",\"https:\\/\\/imgs.search.brave.com\\/p_ZTVU1CXMzoBuBS89XUPvYalqMzT6nGiJZKNJV_DbI\\/rs:fit:500:0:1:0\\/g:ce\\/aHR0cHM6Ly9jb250\\/ZW50LmpkbWFnaWNi\\/b3guY29tL2NvbXAv\\/aG9zdXIvZjkvOTk5\\/OXA0MzQ0LjQzNDQu\\/MTEwMzAyMTUwNjUy\\/LmMzZjkvY2F0YWxv\\/Z3VlL2FuaXRoYS1w\\/bHl3b29kcy1hbmQt\\/aGFyZHdhcmVzLWhv\\/c3VyLWhvLWhvc3Vy\\/LWhhcmR3YXJlLXNo\\/b3BzLWNiNnpzMDF5\\/cmktMjUwLmpwZz93\\/PTY0MCZxPTc1\"]', 6, 8, 1, 'active', NULL, '2026-01-05 09:40:06', '2026-01-29 07:01:53'),
(15, NULL, 'Workers and Labours', 'Workers and Labours', 'Labours, Workers', 'fa fa-tools', 'https://indiawebdesigns.in/app/askus/images/workers.jpg', '[\"https:\\/\\/imgs.search.brave.com\\/R8jrDZLm7vSdZDzr1sDjysKpfakctg2hgvurxlCR1zc\\/rs:fit:500:0:1:0\\/g:ce\\/aHR0cHM6Ly90NC5m\\/dGNkbi5uZXQvanBn\\/LzA2LzA1LzE4LzYx\\/LzM2MF9GXzYwNTE4\\/NjE3Ml9vazY3TEox\\/RXFVMENhZlE3ZHls\\/dzE3TlZpb2pNU3hQ\\/Vy5qcGc\",\"https:\\/\\/imgs.search.brave.com\\/JU04Drdg_-7Gy4CpqjLmtjbMPpdMeYs7r_P8hgmkUYo\\/rs:fit:500:0:1:0\\/g:ce\\/aHR0cHM6Ly90aHVt\\/YnMuZHJlYW1zdGlt\\/ZS5jb20vYi9oYXBw\\/eS13b3JrZXJzLWNv\\/bnN0cnVjdGlvbi1z\\/aXRlLWx1bmNoLWJy\\/ZWFrLXBlb3BsZS13\\/b3JraW5nLW1lbi13\\/b3JrLW5ldy1ob3Vz\\/aW5nLXByb2plY3Qt\\/dGVhbS1sYXVnaGlu\\/Zy10YWxraW5nLTEz\\/NTEwNTI5MS5qcGc\",\"https:\\/\\/imgs.search.brave.com\\/um2yBtspiI3RAXiNvpYgShsES-gz1WeZ7ao1pd_Ecak\\/rs:fit:500:0:1:0\\/g:ce\\/aHR0cHM6Ly9pbWcu\\/ZnJlZXBpay5jb20v\\/ZnJlZS1waG90by9j\\/b25zdHJ1Y3Rpb24t\\/d29ya2Vycy1jb2xs\\/YWJvcmF0aW5nLWJs\\/dWVwcmludHMtY29u\\/c3RydWN0aW9uLXNp\\/dGVfMjMtMjE1MjAw\\/NjExNy5qcGc_c2Vt\\/dD1haXNfaHlicmlk\\/Jnc9NzQwJnE9ODA\",\"https:\\/\\/imgs.search.brave.com\\/_4QTmlAFW_UTNdWkF0bWfLNu2pvi3MwRmVznJ5N44Fw\\/rs:fit:500:0:1:0\\/g:ce\\/aHR0cHM6Ly9tZWRp\\/YS5nZXR0eWltYWdl\\/cy5jb20vaWQvMTA1\\/OTkyMjgwL3Bob3Rv\\/L2ZvcmVpZ24td29y\\/a2Vycy1sYXktYW4t\\/ZW50cmFuY2Utcm9h\\/ZC1hdC10aGUtY29u\\/c3RydWN0aW9uLXNp\\/dGUtb2YtYS1uZXct\\/aG90ZWwtaW4tdGhl\\/LW5ldy1jaXR5Lmpw\\/Zz9zPTYxMng2MTIm\\/dz0wJms9MjAmYz1Y\\/OTRwRXBHUHBvN1NZ\\/UFB2cUpmNVBtcFZR\\/cmVTcXYzVk91YVR0\\/XzB2di1zPQ\",\"https:\\/\\/imgs.search.brave.com\\/61G5YxbF8pmee76wDMacPSv9fplQczhlvNpWuB4fBAI\\/rs:fit:500:0:1:0\\/g:ce\\/aHR0cHM6Ly90aHVt\\/YnMuZHJlYW1zdGlt\\/ZS5jb20vYi90aHJl\\/ZS1jb25zdHJ1Y3Rp\\/b24td29ya2Vycy1z\\/aXR0aW5nLWNvbmNy\\/ZXRlLXNpdGUtZGlz\\/Y3Vzc2luZy1idWls\\/ZGluZy1wbGFucy0x\\/MTk3NjYyMjYuanBn\",\"https:\\/\\/imgs.search.brave.com\\/51mH-46q-9QU85FPINVRxpWxOITKo6x_RoNAnBbyUVY\\/rs:fit:500:0:1:0\\/g:ce\\/aHR0cHM6Ly9tZWRp\\/YS5nZXR0eWltYWdl\\/cy5jb20vaWQvNDY3\\/NDE0NzQ4L3Bob3Rv\\/L3FhdGFyLW91dC13\\/b3JrZXJzLW9mLXFk\\/dmMtdGhlLXFhdGFy\\/aS1icmFuY2gtb2Yt\\/ZnJlbmNoLWNvbnN0\\/cnVjdGlvbi1naWFu\\/dC12aW5jaS1wcmVw\\/YXJlLmpwZz9zPTYx\\/Mng2MTImdz0wJms9\\/MjAmYz1wMmlRakdf\\/N0k0empHQnIwTnI3\\/bm9SOXZYeGVRVGd6\\/SGV0U3VmN09icnQ4\\/PQ\"]', 6, 9, 1, 'active', NULL, '2026-01-05 09:40:06', '2026-01-29 06:50:43'),
(16, NULL, 'Interior Designer', 'Interior Designer', 'Interior Designing', 'fa fa-bolt', 'https://images.pexels.com/photos/4977353/pexels-photo-4977353.jpeg', NULL, 0, 10, 0, 'inactive', NULL, '2026-01-05 09:40:06', '2026-01-20 09:21:09'),
(17, NULL, 'Interior Designing', 'Interior Designing', 'Interior Designing', 'fa fa-paint-roller', 'https://images.pexels.com/photos/5691613/pexels-photo-5691613.jpeg', '[\"https:\\/\\/imgs.search.brave.com\\/DmuMcSNZRFSX80DCaNwSHzbJ7k7tjP2xFv31v2Hj8Bk\\/rs:fit:500:0:1:0\\/g:ce\\/aHR0cHM6Ly90My5m\\/dGNkbi5uZXQvanBn\\/LzAxLzM4LzEwLzM0\\/LzM2MF9GXzEzODEw\\/MzQwNV9XT25pS0tH\\/eFA3VDJGcHNnQncy\\/aklDUmM1WkRTcW9l\\/Qy5qcGc\",\"https:\\/\\/imgs.search.brave.com\\/rB5mR7TSaWGDU7ewJV_Vm7h1y-BIymAj3CMPIpARBvs\\/rs:fit:500:0:1:0\\/g:ce\\/aHR0cHM6Ly90NC5m\\/dGNkbi5uZXQvanBn\\/LzAzLzE0LzAxLzM1\\/LzM2MF9GXzMxNDAx\\/MzUxOV9iOXEyVzZ0\\/c0dTRWg5SW1DVG13\\/TEJaeHRyVEV1WDRC\\/eS5qcGc\",\"https:\\/\\/imgs.search.brave.com\\/ZQ1lReBI3JSlQjXVhNVedbGH6f9bq6G_zntZiU4N6cM\\/rs:fit:500:0:1:0\\/g:ce\\/aHR0cHM6Ly9tZWRp\\/YS5pc3RvY2twaG90\\/by5jb20vaWQvNDg1\\/NjI0MTQyL3Bob3Rv\\/L2FyY2hpdGVjdHMt\\/aW50ZXJpb3ItZGVz\\/aWduZXItaGFuZHMt\\/d29ya2luZy13aXRo\\/LXRhYmxldC1jb21w\\/dXRlci1tYXRlcmlh\\/bC1zYW1wbGUuanBn\\/P3M9NjEyeDYxMiZ3\\/PTAmaz0yMCZjPXhQ\\/a1ZlZzh6WFlEaG05\\/XzFzaXZLenpvRjlv\\/RTlsTUZYaGVUS3ds\\/ck56OGM9\",\"https:\\/\\/imgs.search.brave.com\\/AW5i3NoykBOq4LJxaS5aLkPIh3w3GMk5NzOzjg4Iv6s\\/rs:fit:500:0:1:0\\/g:ce\\/aHR0cHM6Ly9tYXJr\\/ZXRwbGFjZS5jYW52\\/YS5jb20vRUFFN3Mx\\/enJ0TGMvMi8wLzE2\\/MDB3L2NhbnZhLXdo\\/aXRlLW1vZGVybi1t\\/aW5pbWFsaXN0LWlu\\/dGVyaW9yLWRlc2ln\\/bi1waG90by1jb2xs\\/YWdlLWdySkZlZ0lY\\/RHpzLmpwZw\",\"https:\\/\\/imgs.search.brave.com\\/uQCjHFd9Uy8yJH5pJ0dQWDrHG8HwM8Hw8qeBX1jfpDM\\/rs:fit:500:0:1:0\\/g:ce\\/aHR0cHM6Ly90My5m\\/dGNkbi5uZXQvanBn\\/LzAyLzUyLzYzLzky\\/LzM2MF9GXzI1MjYz\\/OTI4NF96T29rWTBI\\/WkowbVFBSUZwMkpW\\/WUZOVHVJU3YwUVR6\\/Ry5qcGc\",\"https:\\/\\/imgs.search.brave.com\\/udfXYxbt-D1QDal2NzXFWPt5ALRUfqBIwr3apaHELRw\\/rs:fit:500:0:1:0\\/g:ce\\/aHR0cHM6Ly9jYWNo\\/ZS5jYXJlZXJzMzYw\\/Lm1vYmkvbWVkaWEv\\/cHJlc2V0cy84MjBY\\/NDEwL2NhcmVlcnMv\\/YmFubmVyX2ltYWdl\\/cy8yMDIwLzcvMTcv\\/SW50ZXJpb3IlMjBE\\/ZXNpZ25lci5qcGc\"]', 6, 11, 1, 'active', NULL, '2026-01-05 09:40:06', '2026-01-20 12:00:19'),
(18, NULL, 'Electronics', 'Electronics', 'Wires, Switch', 'fa fa-building', 'https://images.pexels.com/photos/7541342/pexels-photo-7541342.jpeg', '[\"https:\\/\\/plus.unsplash.com\\/premium_photo-1661644806232-24ffa6f67cc3?q=80&w=1208&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D\",\"https:\\/\\/images.unsplash.com\\/photo-1510016290251-68aaad49723e?q=80&w=1176&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D\",\"https:\\/\\/images.unsplash.com\\/photo-1759200165738-6366977a73c6?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D\",\"https:\\/\\/images.unsplash.com\\/photo-1562408590-e32931084e23?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D\",\"https:\\/\\/plus.unsplash.com\\/premium_photo-1661277751867-52a44000d9b8?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D\",\"https:\\/\\/images.unsplash.com\\/photo-1562034037-ba96b6312a80?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D\"]', 6, 12, 0, 'active', NULL, '2026-01-05 09:40:06', '2026-01-29 06:51:17'),
(19, NULL, 'test', 'test', NULL, '/askus/uploads/categories/icon_1768639725_3b46c2c3.jpeg', '/askus/uploads/categories/image_1768639054_f9f40899.png', NULL, 0, 1, 0, 'active', '2026-01-20 04:50:06', '2026-01-17 08:37:34', '2026-01-20 04:50:06'),
(20, NULL, 'test2', 'test2', NULL, NULL, '/askus/uploads/categories/image_1768639709_9cd14f1e.jpeg', NULL, 0, 1, 0, 'active', '2026-01-20 04:50:04', '2026-01-17 08:48:29', '2026-01-20 04:50:04');

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
(4, '8ec5505a-a2cf-404c-b363-feabba0cd0d1', 23, 1, 'service', 13, 'sss', '2026-01-07', '9:44 AM', NULL, 'pending', NULL, NULL, '2026-01-06 04:14:23', '2026-01-06 04:14:23'),
(5, '5c2c32c5-641a-467c-83d7-4d8ec82c6edc', 22, 4, 'product', 46, 'hello I am interested', '2026-01-08', '6:33 PM', 'hi', 'responded', '2026-01-07 08:03:33', NULL, '2026-01-06 07:04:25', '2026-01-07 08:03:33'),
(6, 'f803a5a1-49b7-41fe-b452-e0ec1a451fa4', 22, 4, 'product', 49, 'rahasdf', '2026-01-14', '2:48 PM', 'helo lets go', 'responded', '2026-01-07 10:45:05', NULL, '2026-01-07 08:19:03', '2026-01-07 10:45:05'),
(7, '9949568e-23f3-4c77-9871-2a504233e96b', 22, 1, 'product', 42, 'taiav', '2026-01-15', '4:45 PM', NULL, 'pending', NULL, NULL, '2026-01-07 12:16:02', '2026-01-07 12:16:02'),
(8, '90c8d996-7a97-49c2-b3e9-d809a4511b25', 22, 4, 'product', 49, 'sgsgsgsg', '2026-02-11', '5:08 AM', NULL, 'pending', NULL, NULL, '2026-01-31 05:38:20', '2026-01-31 05:38:20');

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

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `uuid`, `notifiable_type`, `notifiable_id`, `type`, `title`, `body`, `image`, `data`, `action_url`, `is_read`, `read_at`, `sent_via`, `created_at`) VALUES
(1, 'f9d2afa9-8f3b-4577-97ef-61abc6c16b79', 'user', 1, 'broadcast', 'Test', 'This is a test', NULL, NULL, NULL, 0, NULL, NULL, '2026-01-19 09:23:51'),
(2, '4eddfe41-754d-4b11-8ae0-589dc171a041', 'user', 2, 'broadcast', 'Test', 'This is a test', NULL, NULL, NULL, 0, NULL, NULL, '2026-01-19 09:23:51'),
(3, '3048817b-159c-48c2-a15d-3dba1c6f7a43', 'user', 3, 'broadcast', 'Test', 'This is a test', NULL, NULL, NULL, 0, NULL, NULL, '2026-01-19 09:23:51'),
(4, '8ba2198d-b30c-4561-b886-6193437a9582', 'user', 4, 'broadcast', 'Test', 'This is a test', NULL, NULL, NULL, 0, NULL, NULL, '2026-01-19 09:23:51'),
(5, '97a899e7-158d-4816-a83f-2eb729a3a230', 'user', 5, 'broadcast', 'Test', 'This is a test', NULL, NULL, NULL, 0, NULL, NULL, '2026-01-19 09:23:51'),
(6, '24b05982-eb91-42fb-a999-95d02e0a8767', 'user', 6, 'broadcast', 'Test', 'This is a test', NULL, NULL, NULL, 0, NULL, NULL, '2026-01-19 09:23:51'),
(7, '17a39435-647f-427c-9a90-26e3bb75b7d3', 'user', 7, 'broadcast', 'Test', 'This is a test', NULL, NULL, NULL, 0, NULL, NULL, '2026-01-19 09:23:51'),
(8, 'a4d66e3b-2a3f-4e98-beea-2ca1181526c3', 'user', 8, 'broadcast', 'Test', 'This is a test', NULL, NULL, NULL, 0, NULL, NULL, '2026-01-19 09:23:51'),
(9, 'b4f75414-6eb2-4eda-81a1-cfe2e6e956c4', 'user', 9, 'broadcast', 'Test', 'This is a test', NULL, NULL, NULL, 0, NULL, NULL, '2026-01-19 09:23:51'),
(10, 'b3fd547f-1506-401a-a89d-7d137c7ba0af', 'user', 22, 'broadcast', 'Test', 'This is a test', NULL, NULL, NULL, 0, NULL, NULL, '2026-01-19 09:23:51'),
(11, 'e21b94de-1ae8-4628-a435-2adcbed37d5c', 'user', 23, 'broadcast', 'Test', 'This is a test', NULL, NULL, NULL, 0, NULL, NULL, '2026-01-19 09:23:51'),
(12, '7ae84339-3905-4ea8-bd1b-ac1e13607224', 'user', 24, 'broadcast', 'Test', 'This is a test', NULL, NULL, NULL, 0, NULL, NULL, '2026-01-19 09:23:51'),
(13, '696ab5f9-c058-4012-b6f1-4c8424651f6c', 'user', 27, 'broadcast', 'Test', 'This is a test', NULL, NULL, NULL, 0, NULL, NULL, '2026-01-19 09:23:51'),
(14, '62018e36-9900-4943-addf-bb5fe48c6245', 'user', 28, 'broadcast', 'Test', 'This is a test', NULL, NULL, NULL, 0, NULL, NULL, '2026-01-19 09:23:51');

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
  `order_id` bigint UNSIGNED DEFAULT NULL,
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

--
-- Dumping data for table `payments`
--

INSERT INTO `payments` (`id`, `uuid`, `order_id`, `user_id`, `amount`, `currency`, `payment_method`, `razorpay_order_id`, `razorpay_payment_id`, `razorpay_signature`, `razorpay_invoice_id`, `wallet_transaction_id`, `status`, `failure_reason`, `refund_amount`, `refund_id`, `refunded_at`, `metadata`, `paid_at`, `created_at`, `updated_at`) VALUES
(4, '53f396cc-3f9a-4a45-88d1-56499ee62288', NULL, 11, 1178.82, 'INR', 'razorpay', 'vendor_reg_11_1767963320', NULL, NULL, NULL, NULL, 'pending', NULL, 0.00, NULL, NULL, NULL, NULL, '2026-01-09 12:55:20', '2026-01-09 12:55:20'),
(5, '9db13032-b326-49eb-9aca-03d032505e4d', NULL, 12, 1178.82, 'INR', 'razorpay', 'vendor_reg_12_1767963785', NULL, NULL, NULL, NULL, 'pending', NULL, 0.00, NULL, NULL, NULL, NULL, '2026-01-09 13:01:40', '2026-01-09 13:03:05'),
(6, '1f8bfc40-1b40-4cb1-9680-4b0d08346e75', NULL, 13, 1178.82, 'INR', 'razorpay', 'vendor_reg_13_1768034768', NULL, NULL, NULL, NULL, 'pending', NULL, 0.00, NULL, NULL, NULL, NULL, '2026-01-10 08:46:08', '2026-01-10 08:46:08'),
(7, '7f6346c8-a25a-4b2b-9a9d-474facca72f5', NULL, 14, 1178.82, 'INR', 'razorpay', 'vendor_reg_14_1768035544', NULL, NULL, NULL, NULL, 'pending', NULL, 0.00, NULL, NULL, NULL, NULL, '2026-01-10 08:59:04', '2026-01-10 08:59:04'),
(8, '66223ecc-95d7-46d6-ae48-dbfc683a7aa3', NULL, 15, 1178.82, 'INR', 'razorpay', 'vendor_reg_15_1768035976', NULL, NULL, NULL, NULL, 'pending', NULL, 0.00, NULL, NULL, NULL, NULL, '2026-01-10 09:06:16', '2026-01-10 09:06:16'),
(9, '0adda2e2-f183-4fec-a563-c74ba44b681f', NULL, 16, 1178.82, 'INR', 'razorpay', 'order_S27i6KgebFeI5j', NULL, NULL, NULL, NULL, 'pending', NULL, 0.00, NULL, NULL, NULL, NULL, '2026-01-10 09:17:39', '2026-01-10 09:17:39'),
(10, 'aff05415-0330-4bbc-b6a7-9cb6b1acf3a0', NULL, 17, 1.00, 'INR', 'razorpay', 'order_S29PCTzWkd7PTS', NULL, NULL, NULL, NULL, 'pending', NULL, 0.00, NULL, NULL, NULL, NULL, '2026-01-10 10:55:45', '2026-01-10 10:57:09'),
(11, '342066ab-5902-4993-b10f-f1f91660a4f3', NULL, 18, 1.00, 'INR', 'razorpay', 'order_S2AHPByNEHVmxi', NULL, NULL, NULL, NULL, 'pending', NULL, 0.00, NULL, NULL, NULL, NULL, '2026-01-10 11:48:28', '2026-01-10 11:48:28'),
(12, 'fac240f0-9bd0-4dc6-b61d-9d350aea502f', NULL, 19, 1.00, 'INR', 'razorpay', 'order_S2AhcApgBkuiFc', NULL, NULL, NULL, NULL, 'pending', NULL, 0.00, NULL, NULL, NULL, NULL, '2026-01-10 12:13:17', '2026-01-10 12:13:17'),
(13, '2ea295e4-5a45-4b5d-8476-ee66e3c8ad48', NULL, 0, 1.00, 'INR', 'razorpay', 'order_S2r3HXgs675QOZ', 'pay_S2r3gXZ4blqPV6', '705e2486edc04794b7b974c55eb42f0c7f29bace52a33d15da48e8480aff2c71', NULL, NULL, 'success', NULL, 0.00, NULL, NULL, NULL, '2026-01-12 05:39:40', '2026-01-10 12:43:30', '2026-01-12 05:39:40'),
(14, 'f01f59d4-9262-4113-b612-be22e25b5cdd', NULL, 0, 1.00, 'INR', 'razorpay', 'order_S2BHvsWjk4IfVG', NULL, NULL, NULL, NULL, 'pending', NULL, 0.00, NULL, NULL, NULL, NULL, '2026-01-10 12:47:39', '2026-01-10 12:47:39'),
(15, '30934cba-48ab-464f-a68d-bce4dec924d5', NULL, 0, 1.00, 'INR', 'razorpay', 'order_S2BM4ZpDBbabZK', NULL, NULL, NULL, NULL, 'pending', NULL, 0.00, NULL, NULL, NULL, NULL, '2026-01-10 12:51:35', '2026-01-10 12:51:35'),
(16, 'd20a3f74-5076-4672-86ff-7dbce3d2a862', NULL, 0, 1.00, 'INR', 'razorpay', 'order_S2BQojIVcbNKhr', NULL, NULL, NULL, NULL, 'pending', NULL, 0.00, NULL, NULL, NULL, NULL, '2026-01-10 12:56:04', '2026-01-10 12:56:04'),
(17, '202deef4-44fa-4364-882c-ec340c56fe38', NULL, 0, 1.00, 'INR', 'razorpay', 'order_S2qWBTDnet5Tjw', NULL, NULL, NULL, NULL, 'pending', NULL, 0.00, NULL, NULL, NULL, NULL, '2026-01-12 05:07:35', '2026-01-12 05:07:35'),
(18, '86efcaf5-8dd6-4f8d-abc3-41c2dd5c81c4', NULL, 0, 1.00, 'INR', 'razorpay', 'order_S2qnVNp9InhjSg', 'pay_S2qoF85ujMPmoV', '2995118795b6d660505db56ca2754607397b9b0a035163276c3de1c1b59a1cb8', NULL, NULL, 'success', NULL, 0.00, NULL, NULL, NULL, '2026-01-12 05:25:03', '2026-01-12 05:23:59', '2026-01-12 05:25:03'),
(19, '8af17f9c-61e3-4d03-a458-dec024414756', NULL, 20, 1.00, 'INR', 'razorpay', 'order_S2rEZg7v5ylrIW', 'pay_S2rF5gXUwVBcyr', '77c0d9ca37f2ffb475c99cdb6905fc772ae719fd01dd18d5d74eb6b4d974a7b5', NULL, NULL, 'success', NULL, 0.00, NULL, NULL, NULL, '2026-01-12 05:50:28', '2026-01-12 05:49:37', '2026-01-12 05:50:29'),
(20, '7bf2385e-365a-40cf-a20f-aa7d7a0676aa', NULL, 0, 1.00, 'INR', 'razorpay', 'order_S2uqaY9WkQLHHw', NULL, NULL, NULL, NULL, 'pending', NULL, 0.00, NULL, NULL, NULL, NULL, '2026-01-12 09:21:41', '2026-01-12 09:21:41');

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `id` bigint UNSIGNED NOT NULL,
  `uuid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `vendor_id` bigint UNSIGNED NOT NULL,
  `category_id` bigint UNSIGNED NOT NULL,
  `subcategory_id` bigint UNSIGNED DEFAULT NULL,
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
  `is_approved` tinyint(1) DEFAULT '0',
  `approved_at` timestamp NULL DEFAULT NULL,
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`id`, `uuid`, `vendor_id`, `category_id`, `subcategory_id`, `name`, `slug`, `description`, `short_description`, `sku`, `barcode`, `hsn_code`, `mrp`, `selling_price`, `cost_price`, `tax_rate`, `tax_type`, `discount_type`, `discount_value`, `stock_quantity`, `low_stock_threshold`, `unit`, `weight`, `weight_unit`, `is_returnable`, `return_days`, `is_featured`, `is_bestseller`, `rating`, `total_reviews`, `total_sold`, `meta_title`, `meta_description`, `status`, `is_approved`, `approved_at`, `approved_by`, `deleted_at`, `created_at`, `updated_at`) VALUES
(37, 'b7b56d2f-ea1c-11f0-8469-0050565d8541', 1, 13, 15, 'Hydraulic Excavator', 'hydraulic-excavator', 'Heavy-duty excavator used for large construction projects.', 'Heavy-duty excavator', 'EXC-001', NULL, NULL, 3500000.00, 3200000.00, NULL, 18.00, 'exclusive', 'none', 0.00, 3, 5, 'piece', 21000.000, 'kg', 0, 0, 0, 0, 0.00, 0, 0, NULL, NULL, 'active', 1, NULL, NULL, NULL, '2026-01-05 09:55:51', '2026-01-29 07:57:39'),
(38, 'bc2bfe30-ea1c-11f0-8469-0050565d8541', 1, 13, 16, 'Portland Cement Bag (50kg)', 'portland-cement-50kg', 'High strength Portland cement for construction.', '50kg cement bag', 'CEM-002', NULL, NULL, 450.00, 420.00, NULL, 18.00, 'inclusive', 'none', 0.00, 500, 5, 'bag', 50.000, 'kg', 0, 0, 0, 0, 0.00, 0, 0, NULL, NULL, 'active', 1, NULL, NULL, NULL, '2026-01-05 09:55:58', '2026-01-29 07:57:42'),
(39, 'c03ccab5-ea1c-11f0-8469-0050565d8541', 1, 15, 21, 'Electric Concrete Mixer', 'electric-concrete-mixer', 'Portable concrete mixer for on-site construction.', 'Concrete mixer machine', 'TOOL-003', NULL, NULL, 98000.00, 92000.00, NULL, 18.00, 'exclusive', 'none', 0.00, 12, 5, 'piece', 350.000, 'kg', 0, 0, 0, 0, 0.00, 0, 0, NULL, NULL, 'active', 1, NULL, NULL, NULL, '2026-01-05 09:56:05', '2026-01-31 10:57:11'),
(40, 'c3fc59bd-ea1c-11f0-8469-0050565d8541', 1, 16, NULL, 'PVC Electrical Conduit Pipe', 'pvc-electrical-conduit-pipe', 'Durable PVC pipe for electrical wiring.', 'PVC conduit pipe', 'ELC-004', NULL, NULL, 120.00, 95.00, NULL, 18.00, 'inclusive', 'none', 0.00, 300, 5, 'piece', 2.500, 'kg', 0, 0, 0, 0, 0.00, 0, 0, NULL, NULL, 'active', 1, NULL, NULL, NULL, '2026-01-05 09:56:11', '2026-01-07 05:43:19'),
(41, 'c81073eb-ea1c-11f0-8469-0050565d8541', 1, 17, 27, 'Interior Wall Paint (20L)', 'interior-wall-paint-20l', 'Premium washable interior wall paint.', 'Interior paint bucket', 'INT-005', NULL, NULL, 4800.00, 4500.00, NULL, 18.00, 'inclusive', 'none', 0.00, 80, 5, 'bucket', 22.000, 'kg', 0, 0, 0, 0, 0.00, 0, 0, NULL, NULL, 'active', 1, NULL, NULL, NULL, '2026-01-05 09:56:18', '2026-01-31 10:57:11'),
(42, 'cc4314ca-ea1c-11f0-8469-0050565d8541', 1, 18, 30, 'Residential Construction Service', 'residential-construction-service', 'Complete residential building construction service.', 'End-to-end construction service', 'SER-006', NULL, NULL, 6979.00, 5000.00, NULL, 18.00, 'exclusive', 'none', 0.00, 9999, 5, 'service', NULL, 'g', 0, 0, 0, 0, 0.00, 0, 0, NULL, NULL, 'active', 1, NULL, NULL, NULL, '2026-01-05 09:56:25', '2026-01-31 10:57:11');

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
  `order_id` bigint UNSIGNED DEFAULT NULL,
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

--
-- Dumping data for table `reviews`
--

INSERT INTO `reviews` (`id`, `user_id`, `order_id`, `product_id`, `vendor_id`, `delivery_agent_id`, `review_type`, `rating`, `title`, `comment`, `images`, `is_verified_purchase`, `is_approved`, `admin_reply`, `replied_at`, `deleted_at`, `created_at`, `updated_at`) VALUES
(15, 22, 0, NULL, 1, NULL, 'vendor', 5, 'GOOODd', 'This was a good experience', NULL, 1, 1, NULL, NULL, NULL, '2026-01-13 08:12:39', '2026-01-13 08:12:39');

-- --------------------------------------------------------

--
-- Table structure for table `services`
--

CREATE TABLE `services` (
  `id` bigint UNSIGNED NOT NULL,
  `uuid` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `vendor_id` bigint UNSIGNED NOT NULL,
  `category_id` bigint UNSIGNED DEFAULT NULL,
  `subcategory_id` bigint UNSIGNED DEFAULT NULL,
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
  `is_approved` tinyint(1) DEFAULT '0',
  `approved_at` timestamp NULL DEFAULT NULL,
  `approved_by` bigint UNSIGNED DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `services`
--

INSERT INTO `services` (`id`, `uuid`, `vendor_id`, `category_id`, `subcategory_id`, `name`, `slug`, `description`, `short_description`, `price_type`, `min_price`, `max_price`, `duration_minutes`, `service_area`, `availability`, `is_featured`, `rating`, `total_reviews`, `status`, `is_approved`, `approved_at`, `approved_by`, `deleted_at`, `created_at`, `updated_at`) VALUES
(13, '57cf61a8-ea28-11f0-8469-0050565d8541', 1, 18, NULL, 'Residential Building Construction', 'residential-building-construction', 'End-to-end residential house construction including planning, material, labor, and execution.', 'Complete house construction service', 'quote', 2990.00, NULL, NULL, 'City & Suburban Areas', 'Mon–Sat', 1, 4.60, 28, 'active', 1, NULL, NULL, NULL, '2026-01-05 11:19:04', '2026-01-07 05:43:19'),
(14, '57cf676d-ea28-11f0-8469-0050565d8541', 1, 18, NULL, 'Commercial Construction Service', 'commercial-construction-service', 'Construction of offices, shops, warehouses, and commercial buildings.', 'Commercial construction service', 'quote', 9992.00, NULL, NULL, 'Metro & Industrial Zones', 'Mon–Sat', 1, 4.50, 19, 'active', 1, NULL, NULL, NULL, '2026-01-05 11:19:04', '2026-01-07 05:43:19'),
(15, '57cf6823-ea28-11f0-8469-0050565d8541', 1, 17, NULL, 'Interior Renovation & Remodeling', 'interior-renovation-remodeling', 'Home and office interior renovation including flooring, painting, and redesign.', 'Interior renovation service', 'fixed', 75000.00, NULL, 10080, 'City Limits', 'Mon–Fri', 1, 4.40, 34, 'active', 1, NULL, NULL, NULL, '2026-01-05 11:19:04', '2026-01-07 05:43:19'),
(16, '57cf68c3-ea28-11f0-8469-0050565d8541', 1, 16, NULL, 'Electrical Wiring Installation', 'electrical-wiring-installation', 'Complete electrical wiring installation for homes and commercial buildings.', 'Electrical wiring service', 'hourly', 800.00, 1200.00, 60, 'City Area', 'Mon–Sat', 0, 4.30, 22, 'active', 1, NULL, NULL, NULL, '2026-01-05 11:19:04', '2026-01-07 05:43:19'),
(17, '57cf69e8-ea28-11f0-8469-0050565d8541', 1, 16, NULL, 'Plumbing Installation & Repair', 'plumbing-installation-repair', 'Professional plumbing services including fittings, leakage repair, and installation.', 'Plumbing service', 'hourly', 700.00, 1000.00, 60, 'City Area', 'Mon–Sat', 0, 4.20, 18, 'active', 1, NULL, NULL, NULL, '2026-01-05 11:19:04', '2026-01-07 05:43:19'),
(18, '57cf6b50-ea28-11f0-8469-0050565d8541', 1, 17, NULL, 'Interior & Exterior Painting', 'interior-exterior-painting', 'Interior and exterior wall painting using premium quality paints.', 'Wall painting service', 'fixed', 25000.00, NULL, 2880, 'Urban & Semi-Urban Areas', 'Mon–Sat', 1, 4.50, 41, 'active', 1, NULL, NULL, NULL, '2026-01-05 11:19:04', '2026-01-07 05:43:19'),
(19, '57cf6c30-ea28-11f0-8469-0050565d8541', 1, 18, NULL, 'Construction Site Inspection', 'construction-site-inspection', 'Professional site inspection and consultation by experienced engineers.', 'Site inspection & consultation', 'fixed', 3000.00, NULL, 120, 'Within City', 'Mon–Fri', 0, 4.70, 12, 'active', 1, NULL, NULL, NULL, '2026-01-05 11:19:04', '2026-01-07 05:43:19'),
(22, '86e136c5-237e-46f7-9bc8-990a367ed904', 4, 18, NULL, 'qwerty', 'qwerty-087428', 'test', '', 'fixed', 1346.00, 1346.00, 2, NULL, NULL, 0, 0.00, 0, 'active', 1, NULL, NULL, NULL, '2026-01-07 05:58:40', '2026-01-07 06:00:25');

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
(14, 19, 'https://imgs.search.brave.com/02bvOiij9T1K5UolMAOPsQbH-m4q3qDR1vMTGkjhRlc/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly93d3cu/ZG9mb3Jtcy5jb20v/d3AtY29udGVudC91/cGxvYWRzLzIwMjQv/MDQvY29uc3RydWN0/aW9uLXNpdGUtc2Fm/ZXR5LWluc3BlY3Rp/b24tY2hlY2tsaXN0/LWltcG9ydGFuY2Uu/anBn', 1, '2026-01-04 16:59:08'),
(15, 20, '/app/askus/api/uploads/services/695cb137ae179_1767682359.png', 0, '2026-01-06 06:52:39'),
(16, 21, '/app/askus/api/uploads/services/695df39b9eb15_1767764891.jpg', 0, '2026-01-07 05:48:11'),
(17, 22, 'https://indiawebdesigns.in/app/askus/api/uploads/services/695df610886ba_1767765520.jpg', 0, '2026-01-07 05:58:40');

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
-- Table structure for table `subcategories`
--

CREATE TABLE `subcategories` (
  `id` bigint UNSIGNED NOT NULL,
  `category_id` bigint UNSIGNED NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `image` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sort_order` int DEFAULT '0',
  `status` enum('active','inactive') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `subcategories`
--

INSERT INTO `subcategories` (`id`, `category_id`, `name`, `slug`, `description`, `image`, `sort_order`, `status`, `created_at`, `updated_at`) VALUES
(15, 13, 'Excavators', 'excavators', 'Heavy excavating equipment', NULL, 1, 'active', '2026-01-29 07:47:45', '2026-01-29 07:47:45'),
(16, 13, 'Bulldozers', 'bulldozers', 'Bulldozer machinery', NULL, 2, 'active', '2026-01-29 07:47:45', '2026-01-29 07:47:45'),
(17, 13, 'Cranes', 'cranes', 'Heavy lifting cranes', NULL, 3, 'active', '2026-01-29 07:47:45', '2026-01-29 07:47:45'),
(18, 14, 'Fasteners', 'fasteners', 'Nuts, bolts, screws', NULL, 1, 'active', '2026-01-29 07:47:45', '2026-01-29 07:47:45'),
(19, 14, 'Tools', 'tools', 'Hand and power tools', NULL, 2, 'active', '2026-01-29 07:47:45', '2026-01-29 07:47:45'),
(20, 14, 'Door Hardware', 'door-hardware', 'Locks, handles, hinges', NULL, 3, 'active', '2026-01-29 07:47:45', '2026-01-29 07:47:45'),
(21, 15, 'Construction Workers', 'construction-workers', 'Construction labor services', NULL, 1, 'active', '2026-01-29 07:47:45', '2026-01-29 07:47:45'),
(22, 15, 'Skilled Technicians', 'skilled-technicians', 'Specialized technical workers', NULL, 2, 'active', '2026-01-29 07:47:45', '2026-01-29 07:47:45'),
(23, 15, 'Support Staff', 'support-staff', 'General support workers', NULL, 3, 'active', '2026-01-29 07:47:45', '2026-01-29 07:47:45'),
(24, 16, 'Residential Design', 'residential-design', 'Home interior design', NULL, 1, 'active', '2026-01-29 07:47:45', '2026-01-29 07:47:45'),
(25, 16, 'Commercial Design', 'commercial-design', 'Office and commercial design', NULL, 2, 'active', '2026-01-29 07:47:45', '2026-01-29 07:47:45'),
(26, 16, 'Space Planning', 'space-planning', 'Space optimization and planning', NULL, 3, 'active', '2026-01-29 07:47:45', '2026-01-29 07:47:45'),
(27, 17, 'Furniture Design', 'furniture-design', 'Custom furniture design', NULL, 1, 'active', '2026-01-29 07:47:45', '2026-01-29 07:47:45'),
(28, 17, 'Color Consultation', 'color-consultation', 'Color and theme consultation', NULL, 2, 'active', '2026-01-29 07:47:45', '2026-01-29 07:47:45'),
(29, 17, 'Lighting Design', 'lighting-design', 'Professional lighting solutions', NULL, 3, 'active', '2026-01-29 07:47:45', '2026-01-29 07:47:45'),
(30, 18, 'Wiring', 'wiring', 'Electrical wiring and cables', NULL, 1, 'active', '2026-01-29 07:47:45', '2026-01-29 07:47:45'),
(31, 18, 'Switches and Outlets', 'switches-outlets', 'Electrical switches and outlets', NULL, 2, 'active', '2026-01-29 07:47:45', '2026-01-29 07:47:45'),
(32, 18, 'Panels and Boards', 'panels-boards', 'Electrical panels and boards', NULL, 3, 'active', '2026-01-29 07:47:45', '2026-01-29 07:47:45');

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
(4, '3daa6548-684a-40f7-a4da-fc95636d88ba', 'Joalsp', 'zzubizggubi@gmail.com', '1234567890', NULL, NULL, '$2y$12$n2TnAp5DT7lSpsFZjXrBpebZq2MWzJ/zH6t3fgAj2rLh/Qy56anke', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-04 13:09:04', '2026-01-10 11:16:39'),
(5, '3185b403-e12e-4128-81b8-caf530e8267c', 'panan hh', 'zzubizgghubi@gmail.com', '9638527411', NULL, NULL, '$2y$12$DlxE90/WoNABt9V5lPomLOpn8FwfhjbCtOoLkF/fjk56ZCmF92je.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-04 13:22:16', '2026-01-04 13:22:16'),
(6, 'u1a2b3c4-d5e6-4f7a-8b9c-0d1e2f3a4b5c', 'Rajesh Kumar', 'rajesh@store.com', '9876543210', NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-04 13:25:24', '2026-01-04 13:25:24'),
(7, 'u2b3c4d5-e6f7-5a8b-9c0d-1e2f3a4b5c6d', 'Priya Sharma', 'priya@store.com', '9876543211', NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-04 13:25:24', '2026-01-04 13:25:24'),
(8, 'u3c4d5e6-f7a8-6b9c-0d1e-2f3a4b5c6d7e', 'Amit Verma', 'amit@example.com', '9876543212', NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-04 13:25:24', '2026-01-04 13:25:24'),
(9, 'u4d5e6f7-a8b9-7c0d-1e2f-3a4b5c6d7e8f', 'Sneha Patel', 'sneha@example.com', '9876543213', NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-04 13:25:24', '2026-01-04 13:25:24'),
(22, 'd2acfe15-c4b4-4c71-a290-3ebbd5b43081', 'Rajat Pradhan', 'forpaisa28@gmail.com', '6009580782', NULL, NULL, '$2y$12$TU9fv84KquF8ZICHLuspwukAhQIuHYLfn6iG3wgXM6sodgW7oTLDG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-05 09:12:22', '2026-01-05 09:12:22'),
(23, '42c2d186-8a64-473f-ad6c-3962f59f3d0e', 'paban bhuyan', 'zzu1bizubi@gmail.com', '9999999999', NULL, NULL, '$2y$12$o8o1XCZowMO1sd4CFSTQkuxfoMEiH52JcTvMzpVLQMwR7HezJRn5i', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-06 04:13:42', '2026-01-06 04:13:42'),
(24, '14391d62-b970-4b4f-b13c-0178c1e8b24f', 'Nihal Das', 'nihaldas18@gmail.com', '7002354836', NULL, NULL, '$2y$12$hVtsJaQFpgXfwZgPGcEHGO5lLZq4pCdfNRiXZuX3EprxeEoJL7Tm2', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-06 05:54:22', '2026-01-06 05:54:22'),
(27, '7d2b32f6-02bc-48e2-97aa-878242e9d867', 'Aman Ansari', 'amanansari081@gmail.com', '9905059591', NULL, NULL, '$2y$12$fEwL22wGCQMc.O56eaXF0O9bFSoJcny/VEF9KSshS7nTOKLd3FBBG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-07 04:54:39', '2026-01-07 04:54:39'),
(28, 'bcb1e8fd-22be-4c35-800d-c853ffce2d5d', 'hirak bhuyan', 'hirak011@gmail.com', '9678773518', NULL, NULL, '$2y$12$GKLFAoX1J.iMYVoXsIdTUutYUf4sDLyVFzSVGfjVZj58LeOqoe2s2', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-12 08:45:02', '2026-01-19 09:13:25'),
(29, '49c12f2d-f0d2-43d3-8740-213918a9e4a7', 'lop rajadu', 'vana@ns.cn', '9957628258', NULL, NULL, '$2y$12$rsKaxr0X1scrPrbbRfBBQ.kYgleXoAtV5oJa9v2DNpNKMD/QZCrum', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, NULL, '2026-01-20 08:45:01', '2026-01-20 08:45:01');

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
(2, 'v2b3c4d5-e6f7-5a8b-9c0d-1e2f3a4b5c6d', 'Priya Sharma', 'priya@store.com', '9876543221', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Priya Fashion House', 'priya-fashion-house-def456', NULL, NULL, 'Designer clothing, traditional wear, and modern fashion for all occasions.', '456 Brigade Road', 'Bangalore', 'Karnataka', '560001', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 12.00, 0.00, 5.00, 30, 4.80, 85, 0, 0, 1, 0, 1, NULL, NULL, NULL, 'approved', NULL, NULL, NULL, NULL, NULL, '2026-01-04 13:30:48', '2026-01-04 13:30:48'),
(3, '7e8ed54e-b4e0-4014-ae33-2399bae0c387', 'Rajatboss', 'rajatboss@gmail.com', '8794102703', '$2y$12$UT12iqxxs1a6K6z/1ea4C./vLMnYQumvpHvZJu8fO8Q7a1qtlTqdy', 'codemuji', 'codemuji-6bd002', NULL, NULL, NULL, 'downtown', 'guwahati', 'assam', '786001', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10.00, 0.00, 5.00, 30, 0.00, 0, 0, 0, 0, 0, 1, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, '2026-01-06 06:21:14', '2026-01-06 11:04:59'),
(4, '41b59ac9-d801-43b7-abc7-119cfeaf09ab', 'hirak', 'hirak@gmail.com', '1234567890', '$2y$12$gJrvyW7nzVGjgf1XNTPJw.kswP68.qGk0R03O/YEBH6VAOyTwTsim', 'hirak store', 'hirak-store-511d6c', NULL, NULL, NULL, 'downtown', 'Guwahati', 'Assam', '786110', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10.00, 0.00, 5.00, 30, 0.00, 0, 0, 0, 0, 0, 1, NULL, NULL, NULL, 'approved', NULL, NULL, NULL, NULL, NULL, '2026-01-06 06:41:10', '2026-01-12 09:02:21'),
(5, 'caaaba32-ac71-4b4f-9b62-e427013c99df', 'eyanur ahmed', 'eyanur@gmail.com', '0987654321', '$2y$12$HE5yIk9sNOgbtYGS0erb8.cno4TrFP4iasZobSuGJacW4DlwRDb3q', 'flyhihigg', 'flyhihigg-bb5758', NULL, NULL, NULL, 'sadfs', 'dfasdf', 'asdf', '123456', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10.00, 0.00, 5.00, 30, 0.00, 0, 0, 0, 0, 0, 1, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, '2026-01-09 09:58:11', '2026-01-09 09:58:11'),
(6, 'fede1549-5208-46a3-ad62-f32a6374ffd9', 'paban', 'paban@gmail.com', '8765456789', '$2y$12$SjIOpGNXMGacYunWYuC5EOny.0jEZd99ObQESSN3avp0xhRXimkPu', 'sadfsadsad', 'sadfsadsad-1013c2', NULL, NULL, NULL, 'asdf', 'asdf', 'asdf', '123456', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10.00, 0.00, 5.00, 30, 0.00, 0, 0, 0, 0, 0, 1, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, '2026-01-09 10:01:02', '2026-01-09 10:01:02'),
(7, 'bd9dae53-4805-439d-8b6c-ade4e93ef457', 'sadfsad', 'asdf@sdf.csd', '3523564571', '$2y$12$5WtHhz9R5johOokjU0rU4.nvEcjslp.HGU4cv.s1k7FY74kxYxWWO', 'asdfss', 'asdfss-15e05b', NULL, NULL, NULL, '3dewafsd', 'asdvxzcv', 'asdvxvc', '123456', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10.00, 0.00, 5.00, 30, 0.00, 0, 0, 0, 0, 0, 1, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, '2026-01-09 10:11:07', '2026-01-09 10:11:07'),
(8, '81050fbb-cf01-4d43-a22b-6dd18af24566', 'vxvbvxvvx', 'xcvz@sdvas.bf', '6543345678', '$2y$12$DfXjFpZZepvefMFsBVId7ekOzmTvdNUUQnbYOaamChFZNij4pf7e.', 'rwer', 'rwer-29d942', NULL, NULL, NULL, 'sdfa', 'sadf', 'sadf', '123456', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10.00, 0.00, 5.00, 30, 0.00, 0, 0, 0, 0, 0, 1, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, '2026-01-09 10:24:45', '2026-01-09 10:24:45'),
(9, '463f3359-8764-460d-806f-bcb2d5f43495', 'fsdbvcxnvs', 'sadnch@dsakf.sdh', '7628372913', '$2y$12$6dn21vZG9Kp3I1bbEGFl.Of9qZsyYRenEeLh2UCHIE7bsk4KJXsTO', 'adsf', 'adsf-057453', NULL, NULL, NULL, 'asdf', 'asdf', 'asdf', 'asdfas', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10.00, 0.00, 5.00, 30, 0.00, 0, 0, 0, 0, 0, 1, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, '2026-01-09 12:10:28', '2026-01-09 12:10:28'),
(10, '0241d5ad-09c1-421e-9b84-47671017e241', 'sdfasd', 'sadf@sdf.fg', '3452346724', '$2y$12$QfXPQF6XYZ.91KWLYjPIkeyq8xcaJauOR8Ss5/LGLvH6FVFFkRwBS', 'scvzx', 'scvzx-5953eb', NULL, NULL, NULL, 'vsadf as', 'werqw', 'asdcz', '123456', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10.00, 0.00, 5.00, 30, 0.00, 0, 0, 0, 0, 0, 1, NULL, NULL, NULL, 'approved', NULL, NULL, NULL, NULL, NULL, '2026-01-09 12:19:33', '2026-01-10 11:05:35'),
(11, '988e0bab-fc04-4667-b191-5a7e0f260022', 'xncbvmsguisjfnafjd', 'sdnvjsdbn@fsdkgj.vom', '5234672361', '$2y$12$KF0gFht8ukEneEHNfMBBjOITgPt/2hD18WKd6WvGbPWocKz1KxQTq', 'sadfhjsdnf', 'sadfhjsdnf-6f5214', NULL, NULL, NULL, 'sadnfbisn', 'sdhfian', 'alsdfnjas', '124123', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10.00, 0.00, 5.00, 30, 0.00, 0, 0, 0, 0, 0, 1, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, '2026-01-09 12:53:07', '2026-01-09 12:53:07'),
(12, '77f5b7bd-ae5b-4ee5-b7cb-540c3701dbca', 'jagahGb', 'hsoagqv@nwjw.xhsh', '7867645189', '$2y$12$bJewXE0Qbd506O.Hyzz8DOV55W/BN5sa9vZ5z4kyvZCHuA6cAK8gK', 'vajab', 'vajab-d71f4a', NULL, NULL, NULL, 'gaigvz', 'hag', 'bauh', '546788', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10.00, 0.00, 5.00, 30, 0.00, 0, 0, 0, 0, 0, 1, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, '2026-01-09 13:01:36', '2026-01-09 13:01:36'),
(13, '9908695e-e546-4f67-8751-9741c43d54cd', 'mldhw', 'mfjs@msdk.sdvm', '5694772452', '$2y$12$YyxC/d4PpvcjsmVjBfoP/ulZlJXcul2n7m/ZwuLdySWvJWaJmoo/6', ';sdpfjmsdvdsv', '-sdpfjmsdvdsv-b38fa1', NULL, NULL, NULL, 'safefas', 'asdfasd', 'asdf', '123456', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10.00, 0.00, 5.00, 30, 0.00, 0, 0, 0, 0, 0, 1, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, '2026-01-10 08:46:03', '2026-01-10 08:46:03'),
(14, 'd22a2a19-51b8-4a13-b047-079a1ef55d5f', 'gaiavaj', 'caig@vwjw.com', '8764352049', '$2y$12$q/Tq2mDOIyf3L.JfgyNNUOaM0WST04AKHnv8WT0/svqr79guGSPVe', 'haifakagab', 'haifakagab-1abb0e', NULL, NULL, NULL, 'iauaba', 'iagaj', 'jaga', '876754', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10.00, 0.00, 5.00, 30, 0.00, 0, 0, 0, 0, 0, 1, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, '2026-01-10 08:59:00', '2026-01-10 08:59:00'),
(15, 'f411ec97-ec8b-4e99-80fd-1cc06a7b729e', 'ndldnv', 'nvnv@nbn.bn', '6487894654', '$2y$12$Ubhtxr8oewRpHfCEGJ/VEeB20IGQ6nyhSf0WT3zJEc2fQMIkFZfOK', 'nvnv', 'nvnv-a43cdb', NULL, NULL, NULL, 'kdknc', 'nskdf', 'ksndfk', '123456', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10.00, 0.00, 5.00, 30, 0.00, 0, 0, 0, 0, 0, 1, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, '2026-01-10 09:06:12', '2026-01-10 09:06:12'),
(16, 'b2aa986e-3ded-468b-9743-da41413e3abb', 'vsdhf', 'ssd@dsaf.cma', '7438063690', '$2y$12$ChI1JynrYI2ZupjfKI/ExuX6k8NdhqmZpi3t3ZCgM.uYdRnbLw/Li', 'sdfa', 'sdfa-742d5d', NULL, NULL, NULL, 'asd', 'asdf', 'asdf', '123456', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10.00, 0.00, 5.00, 30, 0.00, 0, 0, 0, 0, 0, 1, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, '2026-01-10 09:17:32', '2026-01-10 09:17:32'),
(17, '879a319d-a3bf-402d-aea8-06c413460718', 'gajavajqkk', 'vakqg@hwow.cjsn', '8761282097', '$2y$12$/cbAI.bV0I83xz9cd0GyR.NKSzL4ZmMZPvEMJCbAfKbolR.pcyRn6', 'jagJa', 'jagja-b73338', NULL, NULL, NULL, 'jahava', 'haiav', 'jauV', '673797', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10.00, 0.00, 5.00, 30, 0.00, 0, 0, 0, 0, 0, 1, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, '2026-01-10 10:55:40', '2026-01-10 10:55:40'),
(18, '67d5c75c-b10b-4588-be27-57037139463e', 'jipas', 'sbdauf@sankd.com', '7546826497', '$2y$12$In0Q4i8K/6q5t0a6NbhZoeHjN/o8ziVqGMERYl0B4igkHn1.eJAdC', 'nvsjdoa', 'nvsjdoa-86eff2', NULL, NULL, NULL, 'sjdnafkns', 'jnbsadn', 'kansdfk', '489615', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10.00, 0.00, 5.00, 30, 0.00, 0, 0, 0, 0, 0, 1, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, '2026-01-10 11:48:19', '2026-01-10 11:48:19'),
(19, 'a2888834-91ce-41ae-8568-6605ee7d8280', 'charusaikia', 'sdhf@fsadjk.vsd', '5874653124', '$2y$12$KYV.8o/bexr0e34wKZVVmOA6Pq1fhMBsDSc8IA.4kzZL4h1UI7wvO', 'dsfg', 'dsfg-0f0733', NULL, NULL, NULL, 'fsadf', 'sadf', 'adf', '513563', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10.00, 0.00, 5.00, 30, 0.00, 0, 0, 0, 0, 0, 1, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, '2026-01-10 12:13:13', '2026-01-10 12:13:13'),
(20, '014b66b8-e8f7-41f1-b9de-7d3d0f85f25f', 'hjaie', 'sakl@fsdk.com', '7543361321', '$2y$12$/a6QGSXsbHC9jZR.dj6KyeguR6l7O0qlba82GofCR05JiVlZs2HYO', 'iwop', 'iwop-95a97a', NULL, NULL, NULL, 'spalw', 'jasdmfls', 'faspidjf', '123456', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10.00, 0.00, 5.00, 30, 0.00, 0, 0, 0, 1, 0, 1, NULL, NULL, NULL, 'approved', 'resrt', '2026-01-17 07:24:16', 1, NULL, NULL, '2026-01-12 05:50:29', '2026-01-17 07:24:16');

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

--
-- Dumping data for table `vendor_documents`
--

INSERT INTO `vendor_documents` (`id`, `vendor_id`, `document_type`, `document_number`, `document_url`, `status`, `rejection_reason`, `verified_at`, `verified_by`, `deleted_at`, `created_at`, `updated_at`) VALUES
(1, 3, 'pan_card', '12 2 10 61861t1', '/app/askus/api/uploads/vendor_documents/695cbd3cb8468_1767685436.jpg', 'pending', NULL, NULL, NULL, NULL, '2026-01-06 07:43:56', '2026-01-06 07:43:56');

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
  ADD KEY `idx_products_featured` (`is_featured`),
  ADD KEY `subcategory_id` (`subcategory_id`);

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
  ADD KEY `status` (`status`),
  ADD KEY `subcategory_id` (`subcategory_id`);

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
-- Indexes for table `subcategories`
--
ALTER TABLE `subcategories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `slug` (`slug`),
  ADD KEY `category_id` (`category_id`),
  ADD KEY `status` (`status`),
  ADD KEY `sort_order` (`sort_order`);

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
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

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
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

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
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=52;

--
-- AUTO_INCREMENT for table `product_images`
--
ALTER TABLE `product_images`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

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
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT for table `service_images`
--
ALTER TABLE `service_images`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `settlements`
--
ALTER TABLE `settlements`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `subcategories`
--
ALTER TABLE `subcategories`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT for table `user_addresses`
--
ALTER TABLE `user_addresses`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `vendors`
--
ALTER TABLE `vendors`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `vendor_documents`
--
ALTER TABLE `vendor_documents`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

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
  ADD CONSTRAINT `payments_ibfk_3` FOREIGN KEY (`wallet_transaction_id`) REFERENCES `wallet_transactions` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `fk_products_subcategory` FOREIGN KEY (`subcategory_id`) REFERENCES `subcategories` (`id`) ON DELETE SET NULL,
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
  ADD CONSTRAINT `reviews_ibfk_3` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reviews_ibfk_4` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reviews_ibfk_5` FOREIGN KEY (`delivery_agent_id`) REFERENCES `delivery_agents` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `services`
--
ALTER TABLE `services`
  ADD CONSTRAINT `fk_services_subcategory` FOREIGN KEY (`subcategory_id`) REFERENCES `subcategories` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `settlements`
--
ALTER TABLE `settlements`
  ADD CONSTRAINT `settlements_ibfk_1` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`),
  ADD CONSTRAINT `settlements_ibfk_2` FOREIGN KEY (`processed_by`) REFERENCES `admins` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `subcategories`
--
ALTER TABLE `subcategories`
  ADD CONSTRAINT `fk_subcategories_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE;

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
