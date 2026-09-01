
CREATE TABLE sales_store (
transaction_id VARCHAR(15),
customer_id VARCHAR(15),
customer_name VARCHAR(50),
customer_age VARCHAR(15),
gender VARCHAR(15),
product_id VARCHAR(15),
product_name VARCHAR(15),
product_category VARCHAR(15),
quantiy INT,
prce FLOAT,
payment_mode VARCHAR(15),
purchase_date DATE,
time_of_purchase TIME,
status VARCHAR (15)
);

SELECT * FROM sales_store

SET DATEFORMAT dmy
BULK INSERT sales_store
FROM 'C:\SQL2022\sales_store.csv'
	WITH(
		FIRSTROW=2,
		FIELDTERMINATOR=',',
		ROWTERMINATOR='\n'
	);

-- Creat a copy table--

SELECT * INTO sales FROM sales_store
SELECT * FROM sales_store
select * from sales

-- Data cleaning -- 
-- Remove Duplicate --
 
 SELECT transaction_id, COUNT(*)
 FROM sales
 GROUP BY transaction_id
 HAVING COUNT(transaction_id) > 1;

--TXN240646
--TXN342128
--TXN855235
--TXN981773

With CTE AS (
SELECT *, 
	ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_id) AS Row_Num
	FROM sales 
)
--DELETE FROM CTE 
--WHERE Row_Num = 2-- 
SELECT * FROM CTE
WHERE transaction_id IN ('TXN240646','TXN342128','TXN855235','TXN981773')

 -- Correction of Headers --
 EXEC sp_rename'sales.quantiy','quantity','COLUMN'

 EXEC sp_rename'sales.prce','price','COLUMN'

 select * from sales

 -- Check Datatype --
 SELECT COLUMN_NAME, DATA_TYPE
 FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_NAME='sales'

 -- Check Null Vallues --
 -- Check null count --
 DECLARE @SQL NVARCHAR(MAX) = '';

 SELECT @SQL = STRING_AGG(
	'SELECT ''' + COLUMN_NAME + ''' AS ColumnName,
	COUNT(*) AS NullCount
	FROM ' + QUOTENAME(TABLE_SCHEMA) + '.sales
	WHERE ' + QUOTENAME(COLUMN_NAME) + ' IS NULL',
	' UNION ALL '
)
WITHIN GROUP (ORDER BY COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales';

-- Execute the dynamic SQL -- 
EXEC sp_executesql @SQL

-- Treating null value -- 
SELECT *
FROM sales 
WHERE transaction_id IS NULL
OR customer_age IS NULL
OR customer_id IS NULL
OR customer_name IS NULL
OR gender IS NULL
OR payment_mode IS NULL
OR purchase_date IS NULL
OR status IS NULL
OR time_of_purchase IS NULL

-- Delete the outlier --
DELETE FROM sales 
WHERE transaction_id IS NULL    -- Đây là trường hợp giá trị null nằm ở cột transaction_id thì sẽ xóa dòng đó do transaction_id là Unique Key của bảng sales --

SELECT * FROM sales 
WHERE Customer_name='Ehsaan Ram'

UPDATE sales 
SET customer_id='CUST9494'
WHERE transaction_id='TXN977900'

SELECT * FROM sales 
WHERE Customer_name='Damini Raju'

UPDATE sales 
SET customer_id='CUST1401'
WHERE transaction_id='TXN977900'

SELECT * FROM sales 
WHERE customer_id='CUST1003'

UPDATE sales 
SET customer_id='CUST1003',
customer_name='Mahika Saini',
customer_age=35,
gender='Male'
WHERE transaction_id='TXN432798'

-- Data cleaning gender and payment_mode --

SELECT DISTINCT gender
FROM sales 

UPDATE sales 
SET gender='M'
WHERE gender='Male'

UPDATE sales 
SET gender='F'
WHERE gender='Female'

SELECT DISTINCT payment_mode
FROM sales 

UPDATE sales 
SET payment_mode='Credit Card'
WHERE payment_mode='CC'

-- Data Analyst --
-- 1.What are the top 5 most selling products by quantity? --

SELECT DISTINCT status
FROM sales

SELECT TOP 5 product_name, SUM(quantity) AS total_quantity_sold
FROM sales
WHERE status='delivered'
GROUP BY product_name
ORDER BY total_quantity_sold DESC  
 
 -- Business problem: don't know which products are most in demand? --
 -- Business impact: help priortize stock and boost sales through targeted promotions.

 -- 2. Which products are the most frequently canceled? --

SELECT TOP 5 product_name, COUNT(*) AS total_cancelled
FROM sales
WHERE status='cancelled'
GROUP BY product_name
ORDER BY total_cancelled DESC

-- Business problem: frequent cancellations affect revenue and customer trust. --
-- Business impact: identify poor-performing product to improve quality or remove from catalog. --

-- 3. What time of the day has the highest number of purchases? --

SELECT 
	CASE
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
	END AS time_of_day,
COUNT(*) AS total_order
FROM sales
GROUP BY 
	CASE
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
	END
ORDER BY total_order DESC
-- Business problem solved: find peak sales times. --
-- Business impact: Optimize staffing, promotions and server load. --

-- 4. Who are the top 5 highest spending customers? -- 

SELECT TOP 5 customer_name, SUM(quantity*price) AS total_spend
FROM sales
GROUP BY customer_name
ORDER BY total_spend DESC

SELECT TOP 5 customer_name, 
	FORMAT(SUM(quantity*price),'C0') AS total_spend
FROM sales
GROUP BY customer_name
ORDER BY total_spend DESC

-- Business problem solved: identify VIP customers. --
-- Business impact: personalized offers, loyalty rewards and retention. --

-- 5. Which product categories generate the highest revenue? --

SELECT 
	product_category,
	FORMAT(SUM(quantity*price), 'C0') AS revenue 
FROM sales
GROUP BY product_category
ORDER BY SUM(quantity*price) DESC

-- Business problem solved: refine product strategy, supply chain and promotions. --
-- Business impact: allowing the business to invest more in high-margin or high-demand categories.--

-- 6. What is the return/cancellation rate per product category? --
SELECT * FROM sales 
-- Cancellation --
SELECT product_category, 
	FORMAT(COUNT(CASE WHEN status='cancelled' THEN 1 END)*100.0/COUNT(*),'N3') + '%' AS cacelled_percent
FROM sales
GROUP BY product_category
ORDER BY cacelled_percent DESC

-- Return --
SELECT product_category, 
	FORMAT(COUNT(CASE WHEN status='returned' THEN 1 END)*100.0/COUNT(*),'N3') + '%' AS returned_percent
FROM sales
GROUP BY product_category
ORDER BY returned_percent DESC
-- Business problem: monitor dissatisfaction trends per category
-- Business impact: reduce returns, improve product descriptions/expectations. Helps identify and fix product or logistics issues. --

-- 7. What is the most preferred payment mode? --
SELECT payment_mode, COUNT(payment_mode) AS total_count
FROM sales
GROUP BY payment_mode
ORDER BY total_count DESC 
-- Business problem: know which payment options customer prefer.
-- Business impact: streamline payment processcing, prioritize modes. --

-- 8. How does age group affect purchasing behavior?
SELECT MIN(customer_age), MAX(customer_age)
FROM sales

SELECT 
	CASE 
		WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
		WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
		WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
		ELSE '51+'
	END AS customer_age,
	FORMAT(SUM(quantity*price),'C0') AS total_purchase
FROM sales
GROUP BY CASE 
		WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
		WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
		WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
		ELSE '51+'
	END
ORDER BY SUM(quantity*price) DESC
-- Business problem: understand customer demographics.
-- Business impact: targeted marketing and product recommendations by age group. --

-- 9. What the monthly sales trend? --
SELECT 
	FORMAT(purchase_date, 'yyyy-MM') AS Month_Year,
	FORMAT(SUM(quantity*price), 'C0') AS Total_sales,
	SUM(quantity) AS total_quantity
FROM sales
GROUP BY FORMAT(purchase_date, 'yyyy-MM')
-- Business problem: sales fluctuations go unnoticed.
-- Business impact: plan inventory and marketing according to seasonal trends. --

-- 10. Are certain genders buying and specific product categories? --
-- Method 1 --
SELECT gender, product_category, 
	COUNT(product_category) AS total_purchase
FROM sales
GROUP BY gender, product_category
ORDER BY gender DESC 

-- Method 2 --
SELECT *
FROM (
	SELECT gender, product_category
	FROM sales
	) AS source_table 
PIVOT (
	COUNT (gender)
	FOR gender IN ([M],[F])
	) AS pivot_table
ORDER BY product_category
-- Business problem: gender-based product preferences.
-- Business impact: personalized ads, gender-focused campaigns. --