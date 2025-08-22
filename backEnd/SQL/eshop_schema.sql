CREATE DATABASE IF NOT EXISTS shop_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_general_ci;

USE shop_db;

-- ========================
-- 1. Roles
-- ========================
CREATE TABLE IF NOT EXISTS roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci UNIQUE NOT NULL,
    description VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_general_ci;

-- ========================
-- 2. Users
-- ========================
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    role_id INT NOT NULL,
    username VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci UNIQUE NOT NULL,
    email VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci UNIQUE NOT NULL,
    password_hash VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
    full_name VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_general_ci;

-- ========================
-- 3. Categories
-- ========================
CREATE TABLE IF NOT EXISTS categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
    description VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_general_ci;

-- ========================
-- 4. Products
-- ========================
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT,
    name VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
    description TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
    price DECIMAL(10,2) NOT NULL,
    stock INT DEFAULT 0,
    status ENUM('active','inactive') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_general_ci;

-- ========================
-- 5. Inventory
-- ========================
CREATE TABLE IF NOT EXISTS inventory (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    change_type ENUM('in','out') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
    quantity INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_general_ci;

-- ========================
-- 6. Orders
-- ========================
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    status ENUM('pending','processing','shipped','completed','canceled') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'pending',
    total DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_general_ci;

-- ========================
-- 7. Order Items
-- ========================
CREATE TABLE IF NOT EXISTS order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_general_ci;

-- ========================
-- 8. Audit Log
-- ========================
CREATE TABLE IF NOT EXISTS audit_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
    entity VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
    entity_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_general_ci;

-- ========================
-- 9. Trigger
-- ========================
DELIMITER //
CREATE TRIGGER after_order_shipped
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF NEW.status = 'shipped' AND OLD.status != 'shipped' THEN
        -- Update product stock and insert inventory record
        INSERT INTO inventory (product_id, change_type, quantity, created_at)
        SELECT oi.product_id, 'out', oi.quantity, NOW()
        FROM order_items oi
        WHERE oi.order_id = NEW.id;

        UPDATE products p
        JOIN order_items oi ON p.id = oi.product_id
        SET p.stock = p.stock - oi.quantity
        WHERE oi.order_id = NEW.id;
    END IF;
END //
DELIMITER ;

-- ========================
-- 10. Initial Data
-- ========================
INSERT INTO roles (name, description) VALUES
('admin', 'مدیر سیستم'),
('sales_manager', 'مدیر فروش'),
('inventory_manager', 'مدیر انبار'),
('customer', 'مشتری');

INSERT INTO users (role_id, username, email, password_hash, full_name)
VALUES (
    (SELECT id FROM roles WHERE name='admin'),
    'admin_user',
    'admin@example.com',
    "$2b$10$gY0oe1PGbBfDDrqhFMEchO/4d/b95Rhmx56bxm7BTKzOiqRYVKgw.",
    'مدیر سیستم'
);

INSERT INTO users (role_id, username, email, password_hash, full_name)
VALUES (
    (SELECT id FROM roles WHERE name='sales_manager'),
    'sales_user',
    'sales@example.com',
    "$2b$10$qmMtsu4Dj5.CIxyC6zQ.NOEm0ayAEk8VqhljaAY.5E51qo4G1SIWW",
    'مدیر فروش'
);

INSERT INTO users (role_id, username, email, password_hash, full_name)
VALUES (
    (SELECT id FROM roles WHERE name='inventory_manager'),
    'inventory_user',
    'inventory@example.com',
    "$2b$10$zB0ZUpYh7l01SAErYAVkw.cifcJ0LIcEw3ysoC8pgbMnFPV1A3z0S",
    'مدیر انبار'
);

INSERT INTO users (role_id, username, email, password_hash, full_name)
VALUES (
    (SELECT id FROM roles WHERE name='customer'),
    'customer_user',
    'customer@example.com',
    "$2b$10$bpE1q4OL1.S.K2HotOBue.TlTvz0ZMM5tZURl79qmA2NUUdOjfzuy",
    'مشتری نمونه'
);
