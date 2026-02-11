-- Clean up existing subcategories for these specific categories to avoid duplicates
-- WARNING: This will set subcategory_id to NULL for any products currently assigned to these subcategories
DELETE FROM `subcategories` WHERE `category_id` IN (13, 14, 18);

-- Heavy Machinery (Category ID: 13)
INSERT INTO `subcategories` (`category_id`, `name`, `slug`, `description`, `image`, `sort_order`, `status`) VALUES
(13, 'Excavator', 'excavator', 'Excavator', 'https://images.unsplash.com/photo-1578326462799-a65c278c772e?auto=format&fit=crop&w=800&q=80', 1, 'active'),
(13, 'Bulldozer', 'bulldozer', 'Bulldozer', 'https://images.unsplash.com/photo-1596464522964-b9c7b912626e?auto=format&fit=crop&w=800&q=80', 2, 'active'),
(13, 'Dumper', 'dumper', 'Dumper', 'https://images.unsplash.com/photo-1591503387799-281b37b4c6e9?auto=format&fit=crop&w=800&q=80', 3, 'active'),
(13, 'Loaders', 'loaders', 'Loaders', 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&w=800&q=80', 4, 'active'),
(13, 'Forklift', 'forklift', 'Forklift', 'https://images.unsplash.com/photo-1587583648607-b3f2736b4a3c?auto=format&fit=crop&w=800&q=80', 5, 'active'),
(13, 'Road Rollers', 'road-rollers', 'Road Rollers', 'https://images.unsplash.com/photo-1621257406213-9fd6a81e3532?auto=format&fit=crop&w=800&q=80', 6, 'active'),
(13, 'Asphalt Pavers', 'asphalt-pavers', 'Asphalt Pavers', 'https://images.unsplash.com/photo-1625246333195-981d5339097e?auto=format&fit=crop&w=800&q=80', 7, 'active'),
(13, 'Concrete Mixers', 'concrete-mixers', 'Concrete Mixers', 'https://images.unsplash.com/photo-1590492837375-3c4800827255?auto=format&fit=crop&w=800&q=80', 8, 'active');

-- Hardwares (Category ID: 14)
INSERT INTO `subcategories` (`category_id`, `name`, `slug`, `description`, `image`, `sort_order`, `status`) VALUES
(14, 'Fasteners', 'fasteners', 'Fasteners', 'https://images.unsplash.com/photo-1605335805505-p250.jpeg?auto=format&fit=crop&w=800&q=80', 1, 'active'),
(14, 'Building Materials', 'building-materials', 'Building Materials', 'https://images.unsplash.com/photo-1592595896551-12b371d546d5?auto=format&fit=crop&w=800&q=80', 2, 'active'),
(14, 'Plumbing Materials', 'plumbing-materials', 'Plumbing Materials', 'https://images.unsplash.com/photo-1581242163695-19d0acde771f?auto=format&fit=crop&w=800&q=80', 3, 'active'),
(14, 'Painting Materials', 'painting-materials', 'Painting Materials', 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&w=800&q=80', 4, 'active'),
(14, 'Tools & Equipments', 'tools-equipments', 'Tools & Equipments', 'https://images.unsplash.com/photo-1581147036324-c17ac41d9c6c?auto=format&fit=crop&w=800&q=80', 5, 'active'),
(14, 'Doors, Windows & Fittings', 'doors-windows-fittings', 'Doors, Windows & Fittings', 'https://images.unsplash.com/photo-1503694987629-94f38d384d1e?auto=format&fit=crop&w=800&q=80', 6, 'active'),
(14, 'Steel, Metal & Iron Products', 'steel-metal-iron-products', 'Steel, Metal & Iron Products', 'https://images.unsplash.com/photo-1535905557558-afc4877a26fc?auto=format&fit=crop&w=800&q=80', 7, 'active'),
(14, 'Adhesive', 'adhesive', 'Adhesive', 'https://images.unsplash.com/photo-1616423664033-ec62c2f30029?auto=format&fit=crop&w=800&q=80', 8, 'active');

-- Electronics (Category ID: 18)
INSERT INTO `subcategories` (`category_id`, `name`, `slug`, `description`, `image`, `sort_order`, `status`) VALUES
(18, 'Wires & Cables', 'wires-cables', 'Wires & Cables', 'https://images.unsplash.com/photo-1544724569-5f546fd6dd2d?auto=format&fit=crop&w=800&q=80', 1, 'active'),
(18, 'Switches & Sockets', 'switches-sockets', 'Switches & Sockets', 'https://images.unsplash.com/photo-1556609894-3d965529f7f4?auto=format&fit=crop&w=800&q=80', 2, 'active'),
(18, 'MCBs, RCCBs, Distribution Boards', 'mcbs-rccbs-distribution-boards', 'MCBs, RCCBs, Distribution Boards', 'https://images.unsplash.com/photo-1555664424-778a18a93c87?auto=format&fit=crop&w=800&q=80', 3, 'active'),
(18, 'Conduits & Accessories', 'conduits-accessories', 'Conduits & Accessories', 'https://images.unsplash.com/photo-1563720223185-11003d516935?auto=format&fit=crop&w=800&q=80', 4, 'active'),
(18, 'Lighting Fixtures', 'lighting-fixtures', 'Lighting Fixtures', 'https://images.unsplash.com/photo-1513506003013-d30607dd9a98?auto=format&fit=crop&w=800&q=80', 5, 'active'),
(18, 'Electrical Tools', 'electrical-tools', 'Electrical Tools', 'https://images.unsplash.com/photo-1581092921461-eab62e97a783?auto=format&fit=crop&w=800&q=80', 6, 'active');
