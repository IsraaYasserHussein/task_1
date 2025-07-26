USE StoreDB;
GO

-- Task 1: Total amount spent by customer with VIP status
DECLARE @CustomerID INT = 1;
DECLARE @TotalSpent DECIMAL(18,2);
DECLARE @Status VARCHAR(20);

SELECT @TotalSpent = SUM(oi.quantity * oi.list_price)
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.customer_id = @CustomerID;

SET @Status = CASE WHEN @TotalSpent > 5000 THEN 'VIP' ELSE 'Regular' END;
PRINT CONCAT('Customer ID: ', @CustomerID, 
              ' | Total Spent: $', FORMAT(@TotalSpent, 'N2'), 
              ' | Status: ', @Status);
GO

-- Task 2: Product price threshold report
DECLARE @Threshold DECIMAL(18,2) = 1500;
DECLARE @ProductCount INT;

SELECT @ProductCount = COUNT(*)
FROM products
WHERE list_price > @Threshold;

PRINT CONCAT('Threshold Price: $', FORMAT(@Threshold, 'N2'),
              ' | Products Above Threshold: ', @ProductCount);
GO

-- Task 3: Staff performance calculator
DECLARE @StaffID INT = 2;
DECLARE @Year INT = 2023;  -- Using 2023 as sample year
DECLARE @TotalSales DECIMAL(18,2);

SELECT @TotalSales = SUM(oi.quantity * oi.list_price)
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.staff_id = @StaffID AND YEAR(o.order_date) = @Year;

PRINT CONCAT('Staff ID: ', @StaffID,
              ' | Year: ', @Year,
              ' | Total Sales: $', FORMAT(@TotalSales, 'N2'));
GO

-- Task 4: Global variables information
PRINT 'Server Name: ' + @@SERVERNAME;
PRINT 'SQL Server Version: ' + @@VERSION;
SELECT TOP 1 1 FROM products;  -- Sample statement
PRINT 'Rows Affected: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO

-- Task 5: Inventory level check with IF
DECLARE @ProductID INT = 1;
DECLARE @StoreID INT = 1;
DECLARE @Quantity INT;

SELECT @Quantity = quantity 
FROM stocks 
WHERE product_id = @ProductID AND store_id = @StoreID;

IF @Quantity > 20
    PRINT 'Well stocked';
ELSE IF @Quantity BETWEEN 10 AND 20
    PRINT 'Moderate stock';
ELSE
    PRINT 'Low stock - reorder needed';
GO

-- Task 6: WHILE loop for restocking
DECLARE @Counter INT = 1;
DECLARE @BatchSize INT = 3;

WHILE EXISTS(SELECT 1 FROM stocks WHERE quantity < 5)
BEGIN
    UPDATE TOP (@BatchSize) stocks
    SET quantity = quantity + 10
    WHERE quantity < 5;
    
    PRINT CONCAT('Batch ', @Counter, ' processed. ', @@ROWCOUNT, ' items restocked.');
    SET @Counter += 1;
END
GO

-- Task 7: Product price categorization
SELECT 
    product_name,
    list_price,
    CASE 
        WHEN list_price < 300 THEN 'Budget'
        WHEN list_price BETWEEN 300 AND 800 THEN 'Mid-Range'
        WHEN list_price BETWEEN 801 AND 2000 THEN 'Premium'
        ELSE 'Luxury'
    END AS PriceCategory
FROM products;
GO

-- Task 8: Customer order validation
DECLARE @CustomerID INT = 5;

IF EXISTS(SELECT 1 FROM customers WHERE customer_id = @CustomerID)
BEGIN
    DECLARE @OrderCount INT;
    SELECT @OrderCount = COUNT(*) 
    FROM orders 
    WHERE customer_id = @CustomerID;
    
    PRINT CONCAT('Customer has placed ', @OrderCount, ' orders.');
END
ELSE
    PRINT 'Customer does not exist';
GO

-- Task 9: Shipping cost calculator function
CREATE OR ALTER FUNCTION dbo.CalculateShipping (@OrderTotal DECIMAL(18,2))
RETURNS DECIMAL(18,2)
AS
BEGIN
    RETURN CASE 
        WHEN @OrderTotal > 100 THEN 0.00
        WHEN @OrderTotal BETWEEN 50 AND 100 THEN 5.99
        ELSE 12.99
    END;
END;
GO

-- Test function
SELECT dbo.CalculateShipping(75) AS ShippingCost;
GO

-- Task 10: Product category function
CREATE OR ALTER FUNCTION dbo.GetProductsByPriceRange (
    @MinPrice DECIMAL(18,2),  --parameter name
    @MaxPrice DECIMAL(18,2)   --parameter name
)
RETURNS TABLE  -- Correct return type for inline table-valued function
AS
RETURN (  -- Parentheses required for inline TVF
    SELECT 
        p.product_name,
        b.brand_name,
        c.category_name,
        p.list_price
    FROM products p
    LEFT JOIN brands b ON p.brand_id = b.brand_id
    JOIN categories c ON p.category_id = c.category_id
    WHERE p.list_price BETWEEN @MinPrice AND @MaxPrice
);
GO

-- Test the function
SELECT * 
FROM dbo.GetProductsByPriceRange(100, 500)
ORDER BY list_price DESC;
GO
-- Task 11: Customer sales summary function
CREATE OR ALTER FUNCTION dbo.GetCustomerYearlySummary (@CustomerID INT)
RETURNS @Summary TABLE (
    OrderYear INT,
    TotalOrders INT,
    TotalSpent DECIMAL(18,2),
    AvgOrderValue DECIMAL(18,2)
)
AS
BEGIN
    INSERT INTO @Summary
    SELECT 
        YEAR(order_date),
        COUNT(DISTINCT o.order_id),
        SUM(oi.quantity * oi.list_price),
        AVG(oi.quantity * oi.list_price)
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = @CustomerID
    GROUP BY YEAR(order_date);
    
    RETURN;
END;
GO

-- Test function
SELECT * FROM dbo.GetCustomerYearlySummary(1);
GO

-- Task 12: Discount calculation function
CREATE OR ALTER FUNCTION dbo.CalculateBulkDiscount (@Quantity INT)
RETURNS DECIMAL(5,2)
AS
BEGIN
    RETURN CASE 
        WHEN @Quantity BETWEEN 1 AND 2 THEN 0
        WHEN @Quantity BETWEEN 3 AND 5 THEN 5
        WHEN @Quantity BETWEEN 6 AND 9 THEN 10
        ELSE 15
    END;
END;
GO

-- Test function
SELECT dbo.CalculateBulkDiscount(8) AS DiscountPercent;
GO

-- Task 13: Customer order history procedure
CREATE OR ALTER PROCEDURE dbo.sp_GetCustomerOrderHistory
    @CustomerID INT,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET @StartDate = COALESCE(@StartDate, '1900-01-01');
    SET @EndDate = COALESCE(@EndDate, GETDATE());
    
    SELECT 
        o.order_id,
        o.order_date,
        SUM(oi.quantity * oi.list_price) AS OrderTotal
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = @CustomerID
        AND o.order_date BETWEEN @StartDate AND @EndDate
    GROUP BY o.order_id, o.order_date;
END;
GO

-- Test procedure
EXEC dbo.sp_GetCustomerOrderHistory @CustomerID = 1;
GO

-- Task 14: Inventory restock procedure
CREATE OR ALTER PROCEDURE dbo.sp_RestockProduct
    @StoreID INT,
    @ProductID INT,
    @RestockQty INT,
    @OldQty INT OUTPUT,
    @NewQty INT OUTPUT,
    @Success BIT OUTPUT
AS
BEGIN
    SET @Success = 0;
    
    SELECT @OldQty = quantity 
    FROM stocks 
    WHERE store_id = @StoreID AND product_id = @ProductID;
    
    IF @OldQty IS NOT NULL
    BEGIN
        UPDATE stocks
        SET quantity = quantity + @RestockQty
        WHERE store_id = @StoreID AND product_id = @ProductID;
        
        SELECT @NewQty = quantity 
        FROM stocks 
        WHERE store_id = @StoreID AND product_id = @ProductID;
        
        SET @Success = 1;
    END
END;
GO

-- Test procedure
DECLARE @OldQty INT, @NewQty INT, @Success BIT;
EXEC dbo.sp_RestockProduct 1, 1, 10, @OldQty OUTPUT, @NewQty OUTPUT, @Success OUTPUT;
SELECT @OldQty AS OldQty, @NewQty AS NewQty, @Success AS Success;
GO

-- Task 15: Order processing procedure
CREATE OR ALTER PROCEDURE dbo.sp_ProcessNewOrder
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT,
    @StoreID INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check inventory
        DECLARE @CurrentStock INT;
        SELECT @CurrentStock = quantity 
        FROM stocks 
        WHERE store_id = @StoreID AND product_id = @ProductID;
        
        IF @CurrentStock < @Quantity
            THROW 50001, 'Insufficient stock', 1;
        
        -- Create order
        DECLARE @OrderID INT;
        INSERT INTO orders (customer_id, order_date, order_status, store_id, staff_id)
        VALUES (@CustomerID, GETDATE(), 1, @StoreID, 1);
        
        SET @OrderID = SCOPE_IDENTITY();
        
        -- Add order item
        DECLARE @Price DECIMAL(18,2) = (SELECT list_price FROM products WHERE product_id = @ProductID);
        INSERT INTO order_items (order_id, item_id, product_id, quantity, list_price)
        VALUES (@OrderID, 1, @ProductID, @Quantity, @Price);
        
        -- Update inventory
        UPDATE stocks
        SET quantity = quantity - @Quantity
        WHERE store_id = @StoreID AND product_id = @ProductID;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- Test procedure
EXEC dbo.sp_ProcessNewOrder 1, 1, 1, 1;
GO

-- Task 16: Dynamic product search procedure
CREATE OR ALTER PROCEDURE dbo.sp_SearchProducts
    @ProductName VARCHAR(255) = NULL,
    @CategoryID INT = NULL,
    @MinPrice DECIMAL(18,2) = NULL,
    @MaxPrice DECIMAL(18,2) = NULL,
    @SortColumn VARCHAR(50) = 'product_name'
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = N'
        SELECT p.product_id, p.product_name, p.list_price, c.category_name, b.brand_name
        FROM products p
        JOIN categories c ON p.category_id = c.category_id
        LEFT JOIN brands b ON p.brand_id = b.brand_id
        WHERE 1=1';
    
    IF @ProductName IS NOT NULL
        SET @SQL += N' AND p.product_name LIKE ''%' + REPLACE(@ProductName, '''', '''''') + '%''';
    IF @CategoryID IS NOT NULL
        SET @SQL += N' AND p.category_id = ' + CAST(@CategoryID AS NVARCHAR);
    IF @MinPrice IS NOT NULL
        SET @SQL += N' AND p.list_price >= ' + CAST(@MinPrice AS NVARCHAR);
    IF @MaxPrice IS NOT NULL
        SET @SQL += N' AND p.list_price <= ' + CAST(@MaxPrice AS NVARCHAR);
    
    SET @SQL += N' ORDER BY ' + QUOTENAME(@SortColumn);
    
    EXEC sp_executesql @SQL;
END;
GO

-- Test procedure
EXEC dbo.sp_SearchProducts @ProductName = 'Laptop', @MinPrice = 1000;
GO

-- Task 17: Staff bonus calculation system
DECLARE @StartDate DATE = '2023-01-01';
DECLARE @EndDate DATE = '2023-03-31';
DECLARE @HighRate DECIMAL(5,3) = 0.10; -- 10%
DECLARE @MediumRate DECIMAL(5,3) = 0.07; -- 7%
DECLARE @LowRate DECIMAL(5,3) = 0.05; -- 5%

SELECT 
    s.staff_id,
    s.first_name + ' ' + s.last_name AS StaffName,
    SUM(oi.quantity * oi.list_price) AS TotalSales,
    CASE 
        WHEN SUM(oi.quantity * oi.list_price) > 10000 THEN SUM(oi.quantity * oi.list_price) * @HighRate
        WHEN SUM(oi.quantity * oi.list_price) > 5000 THEN SUM(oi.quantity * oi.list_price) * @MediumRate
        ELSE SUM(oi.quantity * oi.list_price) * @LowRate
    END AS Bonus
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN staffs s ON o.staff_id = s.staff_id
WHERE o.order_date BETWEEN @StartDate AND @EndDate
GROUP BY s.staff_id, s.first_name, s.last_name;
GO

-- Task 18: Smart inventory management
UPDATE s
SET s.quantity = s.quantity + 
    CASE 
        WHEN c.category_name = 'Electronics' AND s.quantity < 5 THEN 50
        WHEN c.category_name = 'Clothing' AND s.quantity < 10 THEN 100
        WHEN s.quantity < 8 THEN 30
        ELSE 20
    END
FROM stocks s
JOIN products p ON s.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
WHERE s.quantity < 15;
GO

-- Task 19: Customer loyalty tier assignment
SELECT 
    c.customer_id,
    c.first_name + ' ' + c.last_name AS CustomerName,
    SUM(oi.quantity * oi.list_price) AS TotalSpent,
    CASE 
        WHEN SUM(oi.quantity * oi.list_price) > 5000 THEN 'Platinum'
        WHEN SUM(oi.quantity * oi.list_price) > 2000 THEN 'Gold'
        WHEN SUM(oi.quantity * oi.list_price) > 500 THEN 'Silver'
        WHEN SUM(oi.quantity * oi.list_price) > 0 THEN 'Bronze'
        ELSE 'No Tier'
    END AS LoyaltyTier
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.first_name, c.last_name;
GO

-- Task 20: Product lifecycle management procedure
IF COL_LENGTH('products', 'discontinued') IS NULL
BEGIN
    ALTER TABLE products ADD discontinued BIT DEFAULT 0;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_ManageProductLifecycle
    @ProductID INT,
    @ReplacementProductID INT = NULL
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check for pending orders
        IF EXISTS (
            SELECT 1 
            FROM orders o
            JOIN order_items oi ON o.order_id = oi.order_id
            WHERE oi.product_id = @ProductID AND o.order_status IN (1, 2)
        )
        BEGIN
            IF @ReplacementProductID IS NOT NULL
            BEGIN
                -- Replace product in pending orders
                UPDATE oi
                SET product_id = @ReplacementProductID,
                    list_price = (SELECT list_price FROM products WHERE product_id = @ReplacementProductID)
                FROM order_items oi
                JOIN orders o ON oi.order_id = o.order_id
                WHERE oi.product_id = @ProductID
                    AND o.order_status IN (1, 2);
            END
            ELSE
            BEGIN
                RAISERROR('Pending orders exist and no replacement specified', 16, 1);
                RETURN;
            END
        END
        
        -- Remove inventory
        DELETE FROM stocks WHERE product_id = @ProductID;
        
        -- Discontinue product
        -- (Assuming we have a discontinued column in products table)
        ALTER TABLE products ADD discontinued BIT DEFAULT 0;
        UPDATE products SET discontinued = 1 WHERE product_id = @ProductID;
        
        PRINT 'Product discontinued successfully';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- Bonus Challenge 21: Advanced analytics query
WITH MonthlySales AS (
    SELECT
        YEAR(order_date) AS Year,
        MONTH(order_date) AS Month,
        SUM(oi.quantity * oi.list_price) AS TotalSales
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY YEAR(order_date), MONTH(order_date)
),
StaffPerformance AS (
    SELECT
        s.staff_id,
        s.first_name + ' ' + s.last_name AS StaffName,
        COUNT(o.order_id) AS OrdersProcessed,
        SUM(oi.quantity * oi.list_price) AS TotalSales
    FROM staffs s
    JOIN orders o ON s.staff_id = o.staff_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY s.staff_id, s.first_name, s.last_name
),
CategoryAnalysis AS (
    SELECT
        c.category_name,
        SUM(oi.quantity) AS UnitsSold,
        SUM(oi.quantity * oi.list_price) AS Revenue
    FROM categories c
    JOIN products p ON c.category_id = p.category_id
    JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY c.category_name
)
SELECT 'Monthly Sales' AS ReportType, * FROM MonthlySales
UNION ALL
SELECT 'Staff Performance' AS ReportType, * FROM StaffPerformance
UNION ALL
SELECT 'Category Analysis' AS ReportType, * FROM CategoryAnalysis;
GO

-- Bonus Challenge 22: Data validation system
CREATE OR ALTER PROCEDURE dbo.sp_ValidateAndCreateOrder
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT,
    @StoreID INT
AS
BEGIN
    BEGIN TRY
        -- Validate customer
        IF NOT EXISTS(SELECT 1 FROM customers WHERE customer_id = @CustomerID)
            THROW 50001, 'Invalid customer ID', 1;
        
        -- Validate product
        IF NOT EXISTS(SELECT 1 FROM products WHERE product_id = @ProductID)
            THROW 50002, 'Invalid product ID', 1;
        
        -- Validate store
        IF NOT EXISTS(SELECT 1 FROM stores WHERE store_id = @StoreID)
            THROW 50003, 'Invalid store ID', 1;
        
        -- Validate quantity
        IF @Quantity <= 0
            THROW 50004, 'Quantity must be positive', 1;
        
        -- Check inventory
        DECLARE @StockQty INT;
        SELECT @StockQty = quantity 
        FROM stocks 
        WHERE product_id = @ProductID AND store_id = @StoreID;
        
        IF @StockQty < @Quantity
            THROW 50005, 'Insufficient stock', 1;
        
        -- Process order
        EXEC dbo.sp_ProcessNewOrder @CustomerID, @ProductID, @Quantity, @StoreID;
        
        PRINT 'Order created successfully';
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO