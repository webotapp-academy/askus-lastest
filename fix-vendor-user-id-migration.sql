-- =====================================================================
-- FIX: Add user_id to vendors table
-- Date: 2026-03-17
-- Purpose: Link vendors to users table so profile.php can authenticate
--          via users.id (JWT subject), and profile.php vendor query
--          using WHERE v.user_id = ? works correctly.
-- =====================================================================

-- Step 1: Add user_id column to vendors table (if not present)
ALTER TABLE `vendors`
  ADD COLUMN IF NOT EXISTS `user_id` bigint UNSIGNED DEFAULT NULL AFTER `uuid`;

-- Step 2: Add index for performance
ALTER TABLE `vendors`
  ADD INDEX IF NOT EXISTS `idx_vendor_user_id` (`user_id`);

-- Step 3 (optional): Add FK constraint
-- ALTER TABLE `vendors`
--   ADD CONSTRAINT `fk_vendor_user_id` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL;

-- =====================================================================
-- VERIFY: Check which vendors lack a user_id
-- Run this to see which old-style vendors need manual linking:
-- =====================================================================
-- SELECT v.id, v.owner_name, v.email, v.user_id 
-- FROM vendors v 
-- WHERE v.user_id IS NULL AND v.deleted_at IS NULL;

-- =====================================================================
-- MANUAL FIX for existing vendors: 
-- For vendors that were registered before this fix, you may need to
-- create user records for them manually or link existing users.
-- =====================================================================
-- Example: Link vendor email to matching user email
-- UPDATE vendors v
-- JOIN users u ON u.email = v.email
-- SET v.user_id = u.id
-- WHERE v.user_id IS NULL;
