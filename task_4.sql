-- Create the StoreDB database
CREATE DATABASE StoreDB;
GO

USE StoreDB;
GO

-- Create tables with relationships
CREATE TABLE brands (
    brand_id INT PRIMARY KEY IDENTITY,
    brand_name VARCHAR(255) NOT NULL
);

CREATE TABLE categories (
    category_id INT PRIMARY KEY IDENTITY,
    category_name VARCHAR(255) NOT NULL
);

CREATE TABLE products (
    product_id INT PRIMARY KEY IDENTITY,
    product_name VARCHAR(255) NOT NULL,
    brand_id INT NULL,
    category_id INT NOT NULL,
    list_price DECIMAL(10,2) NOT NULL CHECK(list_price > 0),
    FOREIGN KEY (brand_id) REFERENCES brands(brand_id) ON DELETE SET NULL,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY IDENTITY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(255) NULL,
    phone VARCHAR(20) NULL,
    street VARCHAR(255) NULL,
    city VARCHAR(50) NULL,
    state CHAR(2) NULL,
    zip_code VARCHAR(10) NULL
);

CREATE TABLE staffs (
    staff_id INT PRIMARY KEY IDENTITY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20) NULL,
    active BIT NOT NULL DEFAULT 1,
    store_id INT NOT NULL,
    manager_id INT NULL,
    FOREIGN KEY (manager_id) REFERENCES staffs(staff_id)
);

CREATE TABLE stores (
    store_id INT PRIMARY KEY IDENTITY,
    store_name VARCHAR(255) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state CHAR(2) NOT NULL
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY IDENTITY,
    customer_id INT NOT NULL,
    order_status TINYINT NOT NULL,
    order_date DATE NOT NULL,
    staff_id INT NOT NULL,
    store_id INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (staff_id) REFERENCES staffs(staff_id),
    FOREIGN KEY (store_id) REFERENCES stores(store_id)
);

-- Insert sample data
INSERT INTO brands (brand_name) VALUES 
('Brand A'), ('Brand B'), ('Brand C'), ('Brand D');

INSERT INTO categories (category_name) VALUES 
('Electronics'), ('Clothing'), ('Home & Kitchen'), ('Books');

INSERT INTO products (product_name, brand_id, category_id, list_price) VALUES
('Laptop', 1, 1, 1200.00),
('Smartphone', 1, 1, 800.00),
('T-Shirt', 2, 2, 25.99),
('Coffee Maker', 3, 3, 89.99),
('Novel', NULL, 4, 15.99),
('Headphones', 4, 1, 199.99),
('Jeans', 2, 2, 45.50),
('Blender', 3, 3, 75.25),
('Textbook', NULL, 4, 125.00),
('Tablet', 1, 1, 450.00),
('Smart Watch', 4, 1, 350.00),
('Dress Shirt', 2, 2, 55.00);

INSERT INTO customers (first_name, last_name, email, phone, city, state) VALUES
('Ahmed', 'Ali', 'john.doe@gmail.com', '1234567890', 'New York', 'NY'),
('Jana', 'Samir', 'jane.smith@yahoo.com', '2345678901', 'Los Angeles', 'CA'),
('Ayan', 'Karim', 'rob.j@hotmail.com', NULL, 'Chicago', 'IL'),
('Eman', 'Mohammed', 'emily.d@gmail.com', '3456789012', 'San Francisco', 'CA'),
('Mina', 'Jhon', 'm.brown@gmail.com', '4567890123', 'Seattle', 'WA'),
('Sarah', 'Wilson', 'sarah.w@outlook.com', NULL, 'Boston', 'MA'),
('David', 'Taylor', 'd.taylor@gmail.com', '5678901234', 'Austin', 'TX'),
('Jennifer', 'Thomas', 'jen.thomas@yahoo.com', '6789012345', 'San Diego', 'CA'),
('Mohammed', 'Ahmed', 'j.moore@gmail.com', '7890123456', 'Portland', 'OR'),
('Jessica', 'Anderson', 'jess.a@gmail.com', '8901234567', 'Denver', 'CO'),
('Israa', 'Yaseer', 'chris.lee@hotmail.com', NULL, 'Atlanta', 'GA'),
('Ayman', 'Mohammed', 'amanda.j@gmail.com', '9012345678', 'Miami', 'FL');

INSERT INTO stores (store_name, city, state) VALUES
('Main Store', 'New York', 'NY'),
('West Coast Store', 'Los Angeles', 'CA'),
('Downtown Store', 'Chicago', 'IL');

INSERT INTO staffs (first_name, last_name, email, phone, active, store_id, manager_id) VALUES
('Admin', 'User', 'admin@store.com', '1112223333', 1, 1, NULL),
('Manager', 'One', 'manager1@store.com', '2223334444', 1, 1, 1),
('Staff', 'One', 'staff1@store.com', '3334445555', 1, 1, 2),
('Staff', 'Two', 'staff2@store.com', '4445556666', 0, 1, 2),
('Manager', 'Two', 'manager2@store.com', '5556667777', 1, 2, 1),
('Staff', 'Three', 'staff3@store.com', NULL, 1, 2, 5),
('Staff', 'Four', 'staff4@store.com', '7778889999', 0, 3, 5);

INSERT INTO orders (customer_id, order_status, order_date, staff_id, store_id) VALUES
(1, 1, '2023-01-15', 3, 1),
(2, 2, '2023-02-20', 6, 2),
(3, 3, '2023-03-10', 3, 1),
(4, 4, '2023-01-25', 6, 2),
(5, 1, '2023-04-05', 3, 1),
(1, 2, '2023-02-10', 6, 2),
(6, 3, '2023-03-15', 3, 1),
(7, 4, '2023-01-05', 6, 2),
(2, 1, '2023-04-12', 3, 1),
(8, 2, '2023-02-28', 6, 2),
(3, 3, '2023-03-20', 3, 1),
(9, 4, '2023-01-18', 6, 2),
(4, 1, '2023-04-22', 3, 1),
(10, 2, '2022-12-15', 6, 2),
(5, 3, '2022-11-10', 3, 1),
(1, 1, '2023-05-01', 6, 2);

-- 1. Count total products
SELECT COUNT(*) AS TotalProducts 
FROM products;

-- 2. Product price stats
SELECT 
    AVG(list_price) AS AveragePrice,
    MIN(list_price) AS MinimumPrice,
    MAX(list_price) AS MaximumPrice
FROM products;

-- 3. Products per category
SELECT 
    c.category_name,
    COUNT(p.product_id) AS ProductCount
FROM categories c
LEFT JOIN products p ON c.category_id = p.category_id
GROUP BY c.category_name;

-- 4. Orders per store
SELECT 
    s.store_name,
    COUNT(o.order_id) AS OrderCount
FROM stores s
LEFT JOIN orders o ON s.store_id = o.store_id
GROUP BY s.store_name;

-- 5. Customer name formatting
SELECT TOP 10
    UPPER(first_name) AS FirstNameUpper,
    LOWER(last_name) AS LastNameLower
FROM customers;

-- 6. Product name lengths
SELECT TOP 10
    product_name,
    LEN(product_name) AS NameLength
FROM products;

-- 7. Phone area codes
SELECT TOP 15
    customer_id,
    phone,
    LEFT(phone, 3) AS AreaCode
FROM customers
WHERE phone IS NOT NULL;

-- 8. Current date and order date parts
SELECT TOP 10
    order_id,
    GETDATE() AS CurrentDate,
    YEAR(order_date) AS OrderYear,
    MONTH(order_date) AS OrderMonth
FROM orders;

-- 9. Products with categories
SELECT TOP 10
    p.product_name,
    c.category_name
FROM products p
JOIN categories c ON p.category_id = c.category_id;

-- 10. Customers with orders
SELECT TOP 10
    c.first_name + ' ' + c.last_name AS CustomerName,
    o.order_date
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id;

-- 11. Products with brands (including null)
SELECT 
    p.product_name,
    COALESCE(b.brand_name, 'No Brand') AS BrandName
FROM products p
LEFT JOIN brands b ON p.brand_id = b.brand_id;

-- 12. Products above average price
SELECT 
    product_name,
    list_price
FROM products
WHERE list_price > (SELECT AVG(list_price) FROM products);

-- 13. Customers with orders (using IN)
SELECT 
    customer_id,
    first_name + ' ' + last_name AS CustomerName
FROM customers
WHERE customer_id IN (SELECT DISTINCT customer_id FROM orders);

-- 14. Orders per customer
SELECT 
    c.first_name + ' ' + c.last_name AS CustomerName,
    (SELECT COUNT(*) 
     FROM orders o 
     WHERE o.customer_id = c.customer_id) AS OrderCount
FROM customers c;

-- 15. Create product view and query
CREATE VIEW easy_product_list AS
SELECT 
    p.product_name,
    c.category_name,
    p.list_price AS price
FROM products p
JOIN categories c ON p.category_id = c.category_id;
GO

SELECT * 
FROM easy_product_list 
WHERE price > 100
ORDER BY price DESC;

-- 16. Create customer view and query
CREATE VIEW customer_info AS
SELECT 
    customer_id,
    first_name + ' ' + last_name AS FullName,
    email,
    city + ', ' + state AS CityState
FROM customers;
GO

SELECT * 
FROM customer_info 
WHERE CityState LIKE '%CA%';

-- 17. Products in price range
SELECT 
    product_name,
    list_price
FROM products
WHERE list_price BETWEEN 50 AND 200
ORDER BY list_price ASC;

-- 18. Customers per state
SELECT 
    state,
    COUNT(*) AS CustomerCount
FROM customers
GROUP BY state
ORDER BY CustomerCount DESC;

-- 19. Most expensive per category
WITH CategoryMax AS (
    SELECT 
        category_id,
        MAX(list_price) AS MaxPrice
    FROM products
    GROUP BY category_id
)
SELECT 
    c.category_name,
    p.product_name,
    p.list_price
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN CategoryMax cm ON p.category_id = cm.category_id AND p.list_price = cm.MaxPrice;

-- 20. Stores with order counts
SELECT 
    s.store_name,
    s.city,
    COUNT(o.order_id) AS OrderCount
FROM stores s
LEFT JOIN orders o ON s.store_id = o.store_id
GROUP BY s.store_name, s.city;


SELECT *
FROM CUSTOMERS