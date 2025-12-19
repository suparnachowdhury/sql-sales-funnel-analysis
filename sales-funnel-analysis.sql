------------------------
-- 1. Pipeline metrics
------------------------
-- USE sales_funnel;
SELECT * FROM sales_pipeline
LIMIT 5;

-- 1.1 Calculate the number of sales opportunities created each month using "engage_date", and 
-- identify the month with the most opportunities


SELECT MONTH(engage_date) month ,
COUNT(opportunity_id) as total_opportunities
FROM sales_pipeline
GROUP BY MONTH(engage_date)
ORDER BY total_opportunities DESC;

-- 1.2 Find the average time deals stayed open (from "engage_date" to "close_date"), and compare closed deals versus won deals
WITH open_time AS(
SELECT deal_stage
    , DATEDIFF(close_date, engage_date) stayed_open
FROM sales_pipeline)
SELECT deal_stage
, AVG(stayed_open) as stayed_open
FROM open_time
GROUP BY deal_stage;

-- 1.3 Calculate the percentage of deals in each stage, and determine what share were lost
SELECT AVG(CASE WHEN deal_stage = 'Lost' THEN 1 ELSE 0  END)* 100 loss_rate
FROM sales_pipeline;

-- 1.4 Compute the win rate for each product, and identify which one had the highest win rate
SELECT product
, AVG(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0  END)*100 win_rate
FROM sales_pipeline
GROUP BY product
ORDER BY win_rate DESC;

------------------------------
-- 2. Sales agent performance
------------------------------

-- 2.1 Calculate the win rate for each sales agent, and find the top performer
SELECT sales_agent
, AVG(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0  END)*100 win_rate
FROM sales_pipeline
GROUP BY sales_agent
ORDER BY win_rate DESC;

-- 2.2 Calculate the total revenue by agent, and see who generated the most
SELECT sales_agent
, SUM(close_value) AS revenue
FROM sales_pipeline
GROUP BY sales_agent
ORDER BY revenue DESC;


-- 2.3 Calculate win rates by manager to determine which manager’s team performed best
SELECT t.manager
	, AVG(CASE WHEN s.deal_stage = 'Won' THEN 1 ELSE 0  END)*100 win_rate
FROM sales_pipeline s 
JOIN sales_teams t
ON t.sales_agent = s.sales_agent
GROUP BY t.manager
ORDER BY win_rate DESC;

-- 2.4 For the product GTX Plus Pro, find which regional office sold the most units
SELECT st.regional_office
, COUNT(*) as units
FROM sales_pipeline sp
LEFT JOIN sales_teams st
ON st.sales_agent = sp.sales_agent
WHERE deal_stage ='Won' AND product = 'GTX Plus Pro'
GROUP BY st.regional_office
ORDER BY 2 DESC;


------------------------
-- 3. Product analysis
------------------------

-- 3.1 For March deals, identify the top product by revenue and compare it to the top by units sold
SELECT product
, SUM(close_value) AS revenue
, COUNT(*) AS unit_solds
FROM sales_pipeline
WHERE MONTH(engage_date) = 3 AND  deal_stage = 'Won'
GROUP BY product
ORDER BY revenue DESC;

-- 3.2 Calculate the average difference between "sales_price" and "close_value" for each product, 
-- and note if the results suggest a data issue

SELECT sp.product 
	,AVG(p.sales_price - sp.close_value) AS difference
FROM sales_pipeline sp
LEFT JOIN products p
ON sp.product = p.product
WHERE sp.deal_stage = 'Won'
GROUP BY sp.product
ORDER BY 2 DESC;


-------------------------
-- 4. Account analysis
-------------------------

-- 4.1 Calculate revenue by office location, and identify the lowest performer
SELECT office_location
, SUM(revenue) AS total_revenue
FROM accounts
GROUP BY office_location
ORDER BY 2;

-- 4.2 Find the gap in years between the oldest and newest customer, and name those companies
SELECT * FROM accounts;

-- 4.3 Which accounts that were subsidiaries had the most lost sales opportunities?
SELECT a.account, COUNT(sp.opportunity_id) as lost_opportunities
FROM sales_pipeline sp
LEFT JOIN accounts a 
ON a.account = sp.account
WHERE a.subsidiary_of <> '' AND sp.deal_stage = 'Won'
GROUP BY a.account
ORDER BY 2 DESC;

-- 4.4 Join the companies to their subsidiaries. Which one had the highest total revenue?
WITH parent_companies AS(
SELECT 
	account
    , CASE WHEN subsidiary_of = '' THEN account ELSE subsidiary_of END AS parent_company
FROM accounts),
won_deals AS (
SELECT account, SUM(close_value) AS revenue
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY account)
SELECT pc.parent_company
, SUM(wd.revenue) total_revenue
FROM parent_companies pc 
LEFT JOIN won_deals wd 
ON pc.account = wd.account
GROUP BY pc.parent_company
ORDER BY 2 DESC;


