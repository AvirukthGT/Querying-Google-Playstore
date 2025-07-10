-- Retrieve all records from the playstore table
SELECT * 
FROM playstore;



/* =======================================================================================
 Task 1: Market Analyst - Identify Top 5 Promising Categories for Free Apps by Average Rating
 ======================================================================================= */
SELECT 
    category,
    ROUND(AVG(rating)::NUMERIC, 2) AS average_rating
FROM playstore
WHERE UPPER(type) = 'FREE'
GROUP BY category
ORDER BY average_rating DESC
LIMIT 5;



/* =======================================================================================
 Task 2: Business Strategist - Identify Top 3 Categories Generating Highest Revenue from Paid Apps
 Revenue = Price * Number of Installs
 ======================================================================================= */
SELECT 
    category,
    ROUND(SUM(installs * price)::NUMERIC, 2) AS total_revenue
FROM playstore
WHERE price > 0
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 3;



/* =======================================================================================
 Task 3: Data Analyst (Gaming) - Calculate Percentage of Apps in Each Category
 ======================================================================================= */
SELECT  
    category,
    CONCAT(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM playstore), 2), '%') AS percentage
FROM playstore
GROUP BY category
ORDER BY percentage DESC;



/* =======================================================================================
 Task 4: Recommend Free or Paid Apps per Category Based on Average Ratings
 ======================================================================================= */
WITH cte AS (
    SELECT 
        category,
        UPPER(type) AS type,
        ROUND(AVG(rating)::NUMERIC, 2) AS avg_rating
    FROM playstore
    GROUP BY category, type
),
pivot AS (
    SELECT 
        category,
        COALESCE(MAX(CASE WHEN type = 'FREE' THEN avg_rating END), 0) AS avg_rating_free,
        COALESCE(MAX(CASE WHEN type = 'PAID' THEN avg_rating END), 0) AS avg_rating_paid
    FROM cte
    GROUP BY category
)
SELECT *,
    CASE 
        WHEN avg_rating_free > avg_rating_paid THEN 'Free'
        ELSE 'Paid'
    END AS preferred_type
FROM pivot;



/* =======================================================================================
 Task 5: Database Administrator - Record Price Changes Automatically Using Trigger
 ======================================================================================= */

-- Step 1: Create table to log price changes
DROP TABLE IF EXISTS pricechangelog;

CREATE TABLE pricechangelog (
    app VARCHAR(200),
    old_price FLOAT,
    changed_price FLOAT,
    operation_type VARCHAR(200),
    date TIMESTAMP
);

-- Step 2: Create a copy of playstore table
CREATE TABLE play AS 
SELECT * FROM playstore;

-- Step 3: Create Trigger Function to log changes
CREATE OR REPLACE FUNCTION price_change_log_func()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO pricechangelog (
        app,
        old_price,
        changed_price,
        operation_type,
        date
    )
    VALUES (
        NEW.app,
        OLD.price,
        NEW.price,
        'update',
        CURRENT_TIMESTAMP
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Create the Trigger
CREATE TRIGGER price_change_log
AFTER UPDATE ON play
FOR EACH ROW
EXECUTE FUNCTION price_change_log_func();

-- Step 5: Perform Update (this will activate the trigger)
UPDATE play 
SET price = 10 
WHERE app = 'Photo Editor & Candy Camera & Grid & ScrapBook';

-- Step 6: Check the changelog table
SELECT * 
FROM pricechangelog;



/* =======================================================================================
 Task 6: Data Analyst - Calculate Correlation Between Ratings and Number of Reviews
 ======================================================================================= */
SELECT 
    ROUND(CORR(rating, reviews)::NUMERIC, 2) AS correlation
FROM playstore;



/* =======================================================================================
 Task 7: Data Cleaning - Split Multiple Genres into Two Separate Columns
 ======================================================================================= */
SELECT 
    *,
    -- Extract the first genre before the semicolon
    SPLIT_PART(genres, ';', 1) AS genre_1,
    
    -- Extract the second genre after the semicolon (if exists)
    SPLIT_PART(genres, ';', 2) AS genre_2
FROM playstore;
