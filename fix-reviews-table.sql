-- Remove the foreign key constraint on order_id
ALTER TABLE reviews DROP FOREIGN KEY reviews_ibfk_2;

-- Make order_id nullable so we don't need to provide it
ALTER TABLE reviews MODIFY COLUMN order_id bigint unsigned NULL;

-- Optional: Set existing records to NULL if they have invalid order_id
UPDATE reviews SET order_id = NULL WHERE order_id = 0;