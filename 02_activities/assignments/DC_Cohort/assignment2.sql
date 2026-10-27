/* ASSIGNMENT 2 */
--Please write responses between the QUERY # and END QUERY blocks
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product


But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a blank for the first column with
nulls, and 'unit' for the second column with nulls. 

**HINT**: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same. */
--QUERY 1

SELECT 
product_name || ', ' || COALESCE(product_size, ' ')|| ' (' || COALESCE(product_qty_type, 'unit')|| ')'
FROM product;

--END QUERY


--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). 
Filter the visits to dates before April 29, 2022. */
--QUERY 2

-- Shows entire customer_purchase table with visit_number per customer. Each visit is tallied as a separate count (including same-day visits).

SELECT
	customer_id,
	market_date,
	CAST(STRFTIME('%Y', market_date) AS INTEGER) AS market_year,
	CAST(STRFTIME('%m', market_date) AS INTEGER) AS market_month,
	CAST(STRFTIME('%d', market_date) AS INTEGER) AS market_day,
	ROW_NUMBER () OVER (
		PARTITION BY customer_id --counting per unique customer
		ORDER BY 
			market_date ASC
	) as visit_number
FROM customer_purchases
WHERE
	market_year <= 2022 AND
	market_month <= 4 AND
	market_day < 29


--END QUERY


/* 2. Reverse the numbering of the query so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit.
HINT: Do not use the previous visit dates filter. */
--QUERY 3

SELECT
	customer_id,
	market_date
FROM
(
	SELECT
		*,
		CAST(STRFTIME('%Y', market_date) AS INTEGER) AS market_year,
		CAST(STRFTIME('%m', market_date) AS INTEGER) AS market_month,
		CAST(STRFTIME('%d', market_date) AS INTEGER) AS market_day,
		ROW_NUMBER () OVER (
			PARTITION BY customer_id
			ORDER BY 
				market_date DESC --Reverse market_date listing order
		) as visit_number
	FROM customer_purchases
)
WHERE
	visit_number = 1;


--END QUERY


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. 

You can make this a running count by including an ORDER BY within the PARTITION BY if desired.
Filter the visits to dates before April 29, 2022. */
--QUERY 4

SELECT
	DISTINCT customer_id, --Lock customer_id to show count results from unique pairs of customer_id and product_id
	product_id,
	purchase_count
FROM
(
	SELECT
		*,
		CAST(STRFTIME('%Y', market_date) AS INTEGER) AS market_year,
		CAST(STRFTIME('%m', market_date) AS INTEGER) AS market_month,
		CAST(STRFTIME('%d', market_date) AS INTEGER) AS market_day,
		COUNT(*) OVER (
			PARTITION BY customer_id, product_id
		) as purchase_count --returns the same tallied purchase_count for the corresponding pairs of customer_id and product_id 
	FROM customer_purchases
	WHERE
		market_year <= 2022 AND
		market_month <= 4 AND
		market_day < 29
);


--END QUERY


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */
--QUERY 5

SELECT
	product_name,
	CASE
		WHEN SUBSTR(product_name, 1, INSTR(product_name,'-')-1 ) != ''
			THEN LTRIM(SUBSTR(product_name, INSTR(product_name,'-')+1 )) 
		ELSE NULL
	END description
FROM product;


--END QUERY


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */
--QUERY 6

SELECT
	product_name,
	CASE
		WHEN SUBSTR(product_name, 1, INSTR(product_name,'-')-1 ) != ''
			THEN LTRIM(SUBSTR(product_name, INSTR(product_name,'-')+1 )) 
		ELSE NULL
	END description,
	product_size
FROM product
WHERE
	product_size REGEXP '\d';


--END QUERY


-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */
--QUERY 7

-- Create temp table that determines total sales values per market day
DROP TABLE IF EXISTS temp.sale_values;

CREATE TEMP TABLE IF NOT EXISTS temp.sale_values AS
SELECT 
	market_date,
	quantity * cost_per_quantity AS price,
	SUM(quantity * cost_per_quantity) AS total_sale_value
FROM customer_purchases
GROUP BY market_date
ORDER BY market_date ASC;

---- Check
-- SELECT *
-- FROM temp.sale_values;

-- Create separate temp table that ranks the sales values. Add column for best_day_rank and worst_day_rank for later filtering step
DROP TABLE IF EXISTS temp.ranked_market_dates;

CREATE TEMP TABLE IF NOT EXISTS temp.ranked_market_dates AS

SELECT 
	market_date,
	ROW_NUMBER() OVER (
	ORDER BY 
		total_sale_value DESC
	) AS best_day_rank,
	ROW_NUMBER() OVER (
	ORDER BY 
		total_sale_value ASC
	) AS worst_day_rank,
	total_sale_value
FROM temp.sale_values;

-- Select and combine the best and worst ranks to display as one table

-- Best rank
SELECT 
	market_date,
	total_sale_value
FROM temp.ranked_market_dates
WHERE best_day_rank = 1

UNION

--Worst rank
SELECT 
	market_date,
	total_sale_value
FROM temp.ranked_market_dates
WHERE worst_day_rank = 1;

--END QUERY



/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */
--QUERY 8

DROP TABLE IF EXISTS temp.vendor_product;

CREATE TEMP TABLE IF NOT EXISTS temp.vendor_product AS

SELECT
	vendor_id,
	product_id,
	original_price * count_sold AS sales_per_customer
FROM
(
	SELECT 
		DISTINCT vendor_id, product_id,
		original_price,
		5 AS count_sold -- 5 of each product to sell to customer
	FROM vendor_inventory
	ORDER BY 
		vendor_id ASC,
		product_id ASC
);

DROP TABLE IF EXISTS temp.customer_list;

CREATE TEMP TABLE IF NOT EXISTS temp.customer_list AS

SELECT
	customer_id
FROM customer;

SELECT
	vendor_name,
	product_name,
	SUM(sales_per_customer) as total_product_sales
FROM
(
SELECT 
	vendor_id,
	product_id,
	sales_per_customer,
	customer_id
FROM temp.vendor_product
CROSS JOIN temp.customer_list
)
JOIN vendor USING(vendor_id) -- Shorter form in place of using ON 
JOIN product USING(product_id)
GROUP BY product_id;

--END QUERY


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */
--QUERY 9

DROP TABLE IF EXISTS product_units;

CREATE TABLE IF NOT EXISTS product_units AS
SELECT 
	*,
	CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product
WHERE
	product.product_qty_type = 'unit';

--END QUERY


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */
--QUERY 10

INSERT INTO product_units (
	product_id,
	product_name,
	product_size,
	product_category_id,
	product_qty_type,
	snapshot_timestamp
	)
VALUES (
	7,
	'Apple Pie',
	'12"', -- 12" instead of 10"
	3,
	'unit',
	CURRENT_TIMESTAMP
	)

--END QUERY


-- DELETE
/* 1. Delete the older record for whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/
--QUERY 11

DELETE FROM product_units
WHERE
	product_id = 7 AND -- Delete only from Apple Pie product set 
	snapshot_timestamp < (SELECT MAX(snapshot_timestamp) FROM product_units); -- Delete all older entries and keep only the latest version

--END QUERY


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */
--QUERY 12

UPDATE product_units
SET current_quantity = quantity -- Updates the current_quantity column with the result query for latest quantities
FROM
(
	-- This query returns the coalesced latest quantity per product
	SELECT
		product_id,
		COALESCE(quantity,0) as quantity
	FROM product_units
	LEFT JOIN -- (Not all products from product units exist in vendor_inventory)
	(
		-- This query calls for the quantity from the latest version per prodcut
		SELECT
			product_id,
			quantity
		FROM
		(
			-- This query ranks all versions of different products based on market_date
			SELECT
				*,
				ROW_NUMBER() OVER (
				PARTITION BY product_id
				ORDER BY market_date DESC -- Latest version ranks 1st
				) AS version_number
			FROM vendor_inventory 
		) AS temp_vendor_inventory 
		WHERE
			temp_vendor_inventory.version_number = 1
	)
	USING(product_id)
	ORDER BY product_id
) as p
WHERE 
	product_units.product_id = p.product_id; --Update column by matching product_id

--END QUERY



