CREATE DATABASE Ecom_case_study;
USE Ecom_case_study;

SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM orders;
SELECT * FROM orderdetails;

-- analyze all the tables by describing their contents.
DESC customers;
DESC products;
DESC orders;
DESC orderDetails;


-- Identify the top 3 cities with the highest number of customers to determine key markets for targeted marketing and logistic optimization.
SELECT location, COUNT(*) AS number_of_customers
FROM customers
GROUP BY location
ORDER BY number_of_customers DESC
LIMIT 3;


/* Determine the distribution of customers by the number of orders placed.
This insight will help in segmenting customers into one-time buyers, occasional shoppers, and regular customers for tailored marketing strategies. */
SELECT NumberOfOrders, COUNT(customer_id) AS CustomerCount,
CASE WHEN NumberOfOrders =1 THEN "One-time buyer"
	 WHEN NumberOfOrders BETWEEN 2 AND 4 THEN "Occasional shoppers"
     WHEN NumberOfOrders>4 THEN "Regular customers"
     ELSE "None"
     END AS cust_segmentation
FROM(
SELECT customer_id, COUNT(ï»¿order_id) AS NumberOfOrders
FROM orders
GROUP BY customer_id) AS CustomerOrders
GROUP BY NumberOfOrders                       -- number of order increases and the cust count decreses
ORDER BY NumberOfOrders;                      -- company has the most experience with occasional shhoppers


/*Identify products where the average purchase quantity per order is 2 but with a high total revenue, suggesting premium product trends.*/
SELECT product_id, AVG(quantity) AS AvgQuantity, SUM(quantity*price_per_unit) AS TotalRevenue
FROM orderdetails
GROUP BY product_id
HAVING AVG(quantity)=2
ORDER BY TotalRevenue DESC;             -- productid 1 exhibits the highest total revenue


/* For each product category, calculate the unique number of customers purchasing from it.
This will help understand which categories have wider appeal across the customer base.*/
SELECT p.category, COUNT(DISTINCT o.customer_id) AS unique_customers
FROM products p
JOIN orderdetails od ON p.ï»¿product_id=od.product_id
JOIN orders o ON od.ï»¿order_id=o.ï»¿order_id
GROUP BY p.category
ORDER BY unique_customers DESC;    -- Electronics needs more focus as it is in high demand among the customers


/*Analyze the month-on-month percentage change in total sales to identify growth trends.*/
WITH monthlysales AS(
    SELECT DATE_FORMAT(order_date,'%Y-%m') AS Month,
    SUM(total_amount) AS TotalSales
    FROM orders
    GROUP BY DATE_FORMAT(order_date,'%Y-%m')
),
prev_monthsales AS(
    SELECT Month, TotalSales, LAG(TotalSales) OVER (ORDER BY Month) AS previousmonthsales
    FROM monthlysales
)
SELECT Month, TotalSales, ROUND(((TotalSales-previousmonthsales)/previousmonthsales)*100,2) AS PercentChange
FROM prev_monthsales
ORDER BY Month;                     -- Feb 2024 did the sales experience the largest decline?


/* Examine how the average order value changes month-on-month. Insights can guide pricing and promotional strategies to enhance order value.*/
WITH monthlyavgvalue AS(
    SELECT DATE_FORMAT(order_date,'%Y-%m') AS Month,
    AVG(total_amount) AS AvgOrderValue
    FROM orders
    GROUP BY DATE_FORMAT(order_date,'%Y-%m')
),
prev_monthavgvalue AS(
    SELECT Month, AvgOrderValue, LAG(AvgOrderValue) OVER (ORDER BY Month) AS previousmonthsavgvalue
    FROM monthlyavgvalue
)
SELECT Month, AvgOrderValue,
ROUND((AvgOrderValue-previousmonthsavgvalue),2) AS ChangeInValue
FROM prev_monthavgvalue
ORDER BY ChangeInValue DESC;                    -- December 2023 has the highest change in the average order value?


/* Based on sales data, identify products with the fastest turnover rates, suggesting high demand and the need for frequent restocking.*/
SELECT product_id, COUNT(ï»¿order_id) AS SalesFrequency
FROM orderdetails
GROUP BY product_id
ORDER BY SalesFrequency DESC
LIMIT 5;

/* List products purchased by less than 40% of the customer base, indicating potential mismatches between inventory and customer interest.*/
SELECT  p.ï»¿product_id, p.name, COUNT(DISTINCT c.ï»¿customer_id) AS UniqueCustomerCount
FROM  products p
JOIN orderdetails od ON p.ï»¿product_id = od.Product_id
JOIN orders o ON od.ï»¿order_id=o.ï»¿order_id
JOIN customers c ON o.customer_id = c.ï»¿customer_id
GROUP BY p.ï»¿product_id, p.name
HAVING 
    COUNT(DISTINCT c.ï»¿customer_id) < (
        SELECT 
            0.4 * total_customers
        FROM 
            (SELECT COUNT(DISTINCT ï»¿customer_id) AS total_customers FROM customers) AS subquery
    )
ORDER BY UniqueCustomerCount;
-- poor visibility on the platefrom might be the reason, so certain products have purchase rates below 40% of the total customer base


/* Evaluate the month-on-month growth rate in the customer base to understand the effectiveness of marketing campaigns and market expansion efforts.
Return the result table which will help you get the count of the number of customers who made the first purchase on monthly basis.*/
SELECT FirstPurchaseMonth, SUM(NewCustomers) AS TotalNewCustomers
FROM(
SELECT DATE_FORMAT(MIN(order_date),'%Y-%m') AS FirstPurchaseMonth,
COUNT(DISTINCT customer_id) AS NewCustomers
FROM orders
GROUP BY customer_id) subquery
GROUP BY FirstPurchaseMonth
ORDER BY FirstPurchaseMonth;            -- it is a downward trend which implies the marketing campaign are not much effective


/* Identify the months with the highest sales volume, aiding in planning for stock levels, marketing efforts, and staffing in anticipation of peak demand periods.*/
SELECT DATE_FORMAT(order_date,'%Y-%m') AS Month,
SUM(total_amount) AS TotalSales
FROm orders
GROUP BY DATE_FORMAT(order_date,'%Y-%m')
ORDER BY TotalSales DESC
LIMIT 3;                -- Sep and Dec will require major restocking of product and increased staffs?



