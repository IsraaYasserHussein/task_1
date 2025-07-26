USE StoreDB;
GO

CREATE TABLE order_items (
    order_id INT NOT NULL,
    item_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK(quantity > 0),
    list_price DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE stocks (
    store_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    PRIMARY KEY (store_id, product_id),
    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
--INSERT ITEMS
INSERT INTO order_items (order_id, item_id, product_id, quantity, list_price) VALUES
(1, 1, 1, 1, 1200.00),
(1, 2, 3, 2, 25.99),
(2, 1, 2, 1, 800.00),
(3, 1, 4, 1, 89.99),
(4, 1, 5, 3, 15.99),
(5, 1, 6, 2, 199.99),
(6, 1, 7, 1, 45.50),
(7, 1, 8, 1, 75.25),
(8, 1, 9, 1, 125.00),
(9, 1, 10, 1, 450.00),
(10, 1, 11, 1, 350.00),
(11, 1, 12, 2, 55.00),
(12, 1, 1, 1, 1200.00),
(13, 1, 2, 1, 800.00),
(14, 1, 3, 1, 25.99),
(15, 1, 4, 1, 89.99),
(16, 1, 5, 2, 15.99);

INSERT INTO stocks (store_id, product_id, quantity) VALUES
(1, 1, 10), (1, 2, 5), (1, 3, 15), (1, 4, 7), (1, 5, 0),
(2, 1, 8), (2, 2, 3), (2, 3, 10), (2, 4, 0), (2, 5, 20),
(3, 1, 0), (3, 2, 0), (3, 3, 5), (3, 4, 12), (3, 5, 3);
-- 1. Product Price Classification
SELECT 
    product_name,
    list_price,
    CASE 
        WHEN list_price < 300 THEN 'Economy'
        WHEN list_price BETWEEN 300 AND 999 THEN 'Standard'
        WHEN list_price BETWEEN 1000 AND 2499 THEN 'Premium'
        ELSE 'Luxury'
    END AS PriceCategory
FROM products;

-- 2. Order Status & Priority
SELECT 
    order_id,
    order_date,
    CASE order_status
        WHEN 1 THEN 'Order Received'
        WHEN 2 THEN 'In Preparation'
        WHEN 3 THEN 'Order Cancelled'
        WHEN 4 THEN 'Order Delivered'
    END AS StatusDescription,
    CASE 
        WHEN order_status = 1 AND DATEDIFF(DAY, order_date, GETDATE()) > 5 THEN 'URGENT'
        WHEN order_status = 2 AND DATEDIFF(DAY, order_date, GETDATE()) > 3 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS PriorityLevel
FROM orders;

-- 3. Staff Classification by Order Volume
WITH StaffOrders AS (
    SELECT 
        s.staff_id,
        s.first_name + ' ' + s.last_name AS StaffName,
        COUNT(o.order_id) AS OrderCount
    FROM staffs s
    LEFT JOIN orders o ON s.staff_id = o.staff_id
    GROUP BY s.staff_id, s.first_name, s.last_name
)
SELECT 
    StaffName,
    OrderCount,
    CASE 
        WHEN OrderCount = 0 THEN 'New Staff'
        WHEN OrderCount BETWEEN 1 AND 10 THEN 'Junior Staff'
        WHEN OrderCount BETWEEN 11 AND 25 THEN 'Senior Staff'
        ELSE 'Expert Staff'
    END AS StaffCategory
FROM StaffOrders;

-- 4. Customer Contact Information
SELECT 
    customer_id,
    first_name + ' ' + last_name AS CustomerName,
    ISNULL(phone, 'Phone Not Available') AS Phone,
    COALESCE(phone, email, 'No Contact Method') AS PreferredContact
FROM customers;

-- 5. Safe Price Calculation with Stock Handling
-- Assuming stocks table exists with (store_id, product_id, quantity)
SELECT 
    p.product_name,
    p.list_price,
    ISNULL(NULLIF(s.quantity, 0), 0) AS SafeQuantity,
    CASE 
        WHEN ISNULL(s.quantity, 0) = 0 THEN 'Out of Stock'
        WHEN s.quantity <= 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS StockStatus,
    p.list_price / NULLIF(s.quantity, 0) AS PricePerUnit  -- NULLIF prevents division by zero
FROM products p
JOIN Stocks s ON p.product_id = s.product_id
WHERE s.store_id = 1;

-- 6. Address Formatting
SELECT 
    customer_id,
    first_name + ' ' + last_name AS CustomerName,
    COALESCE(
        street + ', ' + city + ', ' + state + ' ' + zip_code,
        street + ', ' + city + ', ' + state,
        city + ', ' + state,
        state
    ) AS FormattedAddress
FROM customers;

-- 7. High-Spending Customers (CTE)
WITH CustomerSpending AS (
    SELECT 
        o.customer_id,
        SUM(oi.quantity * oi.list_price) AS TotalSpent
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.customer_id
    HAVING SUM(oi.quantity * oi.list_price) > 1500
)
SELECT 
    c.customer_id,
    c.first_name + ' ' + c.last_name AS CustomerName,
    cs.TotalSpent
FROM customers c
JOIN CustomerSpending cs ON c.customer_id = cs.customer_id
ORDER BY cs.TotalSpent DESC;

-- 8. Category Performance Analysis (Multi-CTE)
WITH CategoryRevenue AS (
    SELECT 
        p.category_id,
        SUM(oi.quantity * oi.list_price) AS TotalRevenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.category_id
),
CategoryAvgOrder AS (
    SELECT 
        p.category_id,
        AVG(oi.quantity * oi.list_price) AS AvgOrderValue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.category_id
)
SELECT 
    c.category_name,
    cr.TotalRevenue,
    cao.AvgOrderValue,
    CASE 
        WHEN cr.TotalRevenue > 50000 THEN 'Excellent'
        WHEN cr.TotalRevenue > 20000 THEN 'Good'
        ELSE 'Needs Improvement'
    END AS PerformanceRating
FROM categories c
JOIN CategoryRevenue cr ON c.category_id = cr.category_id
JOIN CategoryAvgOrder cao ON c.category_id = cao.category_id;

-- 9. Monthly Sales Trends (CTE Comparison)
WITH MonthlySales AS (
    SELECT 
        YEAR(order_date) AS OrderYear,
        MONTH(order_date) AS OrderMonth,
        SUM(oi.quantity * oi.list_price) AS MonthlyTotal
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY YEAR(order_date), MONTH(order_date)
),
SalesComparison AS (
    SELECT 
        OrderYear,
        OrderMonth,
        MonthlyTotal,
        LAG(MonthlyTotal) OVER (ORDER BY OrderYear, OrderMonth) AS PrevMonthTotal
    FROM MonthlySales
)
SELECT 
    OrderYear,
    OrderMonth,
    MonthlyTotal,
    PrevMonthTotal,
    ROUND((MonthlyTotal - PrevMonthTotal) * 100.0 / NULLIF(PrevMonthTotal, 0), 2) AS GrowthPercentage
FROM SalesComparison;

-- 10. Top Products per Category (Ranking Functions)
WITH RankedProducts AS (
    SELECT 
        c.category_name,
        p.product_name,
        p.list_price,
        ROW_NUMBER() OVER (PARTITION BY p.category_id ORDER BY p.list_price DESC) AS RowNumRank,
        RANK() OVER (PARTITION BY p.category_id ORDER BY p.list_price DESC) AS PriceRank,
        DENSE_RANK() OVER (PARTITION BY p.category_id ORDER BY p.list_price DESC) AS DensePriceRank
    FROM products p
    JOIN categories c ON p.category_id = c.category_id
)
SELECT *
FROM RankedProducts
WHERE RowNumRank <= 3;

-- 11. Customer Spending Tiers
WITH CustomerSpending AS (
    SELECT 
        c.customer_id,
        c.first_name + ' ' + c.last_name AS CustomerName,
        SUM(oi.quantity * oi.list_price) AS TotalSpent,
        RANK() OVER (ORDER BY SUM(oi.quantity * oi.list_price) DESC) AS SpendingRank,
        NTILE(5) OVER (ORDER BY SUM(oi.quantity * oi.list_price) DESC) AS SpendingGroup
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT 
    CustomerName,
    TotalSpent,
    CASE SpendingGroup
        WHEN 1 THEN 'VIP'
        WHEN 2 THEN 'Gold'
        WHEN 3 THEN 'Silver'
        WHEN 4 THEN 'Bronze'
        ELSE 'Standard'
    END AS CustomerTier
FROM CustomerSpending;

-- 12. Store Performance Ranking
WITH StoreMetrics AS (
    SELECT 
        s.store_id,
        s.store_name,
        COUNT(DISTINCT o.order_id) AS OrderCount,
        SUM(oi.quantity * oi.list_price) AS TotalRevenue
    FROM stores s
    JOIN orders o ON s.store_id = o.store_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY s.store_id, s.store_name
)
SELECT 
    store_name,
    OrderCount,
    TotalRevenue,
    RANK() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank,
    RANK() OVER (ORDER BY OrderCount DESC) AS OrderRank,
    PERCENT_RANK() OVER (ORDER BY TotalRevenue) AS PercentileRank
FROM StoreMetrics;

-- 13. Product Count by Category & Brand (PIVOT)
SELECT *
FROM (
    SELECT 
        c.category_name,
        COALESCE(b.brand_name, 'No Brand') AS brand_name,
        p.product_id
    FROM products p
    JOIN categories c ON p.category_id = c.category_id
    LEFT JOIN brands b ON p.brand_id = b.brand_id
) AS SourceTable
PIVOT (
    COUNT(product_id)
    FOR brand_name IN (
        [Brand A], 
        [Brand B], 
        [Brand C],
        [Brand D],
        [No Brand]
    )
) AS PivotTable;

-- 14. Monthly Sales by Store (PIVOT with Total)
SELECT *
FROM (
    SELECT 
        s.store_name,
        FORMAT(o.order_date, 'MMM') AS OrderMonth,
        oi.quantity * oi.list_price AS Revenue
    FROM stores s
    JOIN orders o ON s.store_id = o.store_id
    JOIN order_items oi ON o.order_id = oi.order_id
) AS SourceTable
PIVOT (
    SUM(Revenue)
    FOR OrderMonth IN (
        [Jan], [Feb], [Mar], [Apr], [May], [Jun],
        [Jul], [Aug], [Sep], [Oct], [Nov], [Dec]
    )
) AS PivotTable;

-- 15. Order Status by Store (PIVOT)
SELECT *
FROM (
    SELECT 
        s.store_name,
        CASE o.order_status
            WHEN 1 THEN 'Pending'
            WHEN 2 THEN 'Processing'
            WHEN 3 THEN 'Completed'
            WHEN 4 THEN 'Rejected'
        END AS OrderStatus,
        o.order_id
    FROM stores s
    JOIN orders o ON s.store_id = o.store_id
) AS SourceTable
PIVOT (
    COUNT(order_id)
    FOR OrderStatus IN (
        [Pending], 
        [Processing], 
        [Completed], 
        [Rejected]
    )
) AS PivotTable;

-- 16. Yearly Brand Sales Comparison (PIVOT with Growth)
WITH YearlyBrandSales AS (
    SELECT 
        b.brand_name,
        YEAR(o.order_date) AS OrderYear,
        SUM(oi.quantity * oi.list_price) AS YearlyRevenue
    FROM brands b
    JOIN products p ON b.brand_id = p.brand_id
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    GROUP BY b.brand_name, YEAR(o.order_date)
),
PivotedSales AS (
    SELECT *
    FROM YearlyBrandSales
    PIVOT (
        SUM(YearlyRevenue)
        FOR OrderYear IN ([2022], [2023], [2024])
    ) AS PivotTable
)
SELECT 
    brand_name,
    [2022], 
    [2023],
    [2024],
    ROUND(([2023] - [2022]) * 100.0 / NULLIF([2022], 0), 2) AS Growth2023,
    ROUND(([2024] - [2023]) * 100.0 / NULLIF([2023], 0), 2) AS Growth2024
FROM PivotedSales;

-- 17. Product Availability (UNION)
SELECT p.product_id, p.product_name, 'In Stock' AS Availability
FROM stocks s
JOIN products p ON s.product_id = p.product_id
WHERE s.quantity > 0

UNION

SELECT p.product_id, p.product_name, 'Out of Stock'
FROM stocks s
JOIN products p ON s.product_id = p.product_id
WHERE s.quantity = 0

UNION

SELECT p.product_id, p.product_name, 'Discontinued'
FROM products p
WHERE NOT EXISTS (SELECT 1 FROM stocks s WHERE s.product_id = p.product_id);
-- 18. Loyal Customers (INTERSECT)
SELECT c.customer_id, c.first_name + ' ' + c.last_name AS CustomerName
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE YEAR(o.order_date) = 2022

INTERSECT

SELECT c.customer_id, c.first_name + ' ' + c.last_name
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE YEAR(o.order_date) = 2023;

-- 19. Product Distribution Analysis (Multiple Set Operations)
-- Products in all stores
SELECT p.product_id, p.product_name, 'All Stores' AS Availability
FROM products p
WHERE NOT EXISTS (
    SELECT store_id FROM stores
    EXCEPT
    SELECT store_id FROM stocks s 
    WHERE s.product_id = p.product_id AND s.quantity > 0
)


-- Products in store 1 but not store 2
SELECT p.product_id, p.product_name, 'Store1 Only'
FROM products p
WHERE EXISTS (
    SELECT 1 FROM stocks s 
    WHERE s.product_id = p.product_id AND s.store_id = 1 AND s.quantity > 0
) AND NOT EXISTS (
    SELECT 1 FROM stocks s 
    WHERE s.product_id = p.product_id AND s.store_id = 2 AND s.quantity > 0
)


-- Products in store 2 but not store 1
SELECT p.product_id, p.product_name, 'Store2 Only'
FROM products p
WHERE EXISTS (
    SELECT 1 FROM stocks s 
    WHERE s.product_id = p.product_id AND s.store_id = 2 AND s.quantity > 0
) AND NOT EXISTS (
    SELECT 1 FROM stocks s 
    WHERE s.product_id = p.product_id AND s.store_id = 1 AND s.quantity > 0
);

-- 20. Customer Retention Analysis (UNION ALL)
-- Lost Customers (2022 but not 2023)
SELECT 
    c.customer_id, 
    c.first_name + ' ' + c.last_name AS CustomerName,
    'Lost' AS Status
FROM customers c
WHERE c.customer_id IN (
    SELECT customer_id FROM orders WHERE YEAR(order_date) = 2022
) AND c.customer_id NOT IN (
    SELECT customer_id FROM orders WHERE YEAR(order_date) = 2023
)


-- New Customers (2023 but not 2022)
SELECT 
    c.customer_id, 
    c.first_name + ' ' + c.last_name,
    'New'
FROM customers c
WHERE c.customer_id IN (
    SELECT customer_id FROM orders WHERE YEAR(order_date) = 2023
) AND c.customer_id NOT IN (
    SELECT customer_id FROM orders WHERE YEAR(order_date) = 2022
)


-- Retained Customers (both years)
SELECT 
    c.customer_id, 
    c.first_name + ' ' + c.last_name,
    'Retained'
FROM customers c
WHERE c.customer_id IN (
    SELECT customer_id FROM orders WHERE YEAR(order_date) = 2022
) AND c.customer_id IN (
    SELECT customer_id FROM orders WHERE YEAR(order_date) = 2023
);