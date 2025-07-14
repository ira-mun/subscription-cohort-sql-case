-- 1.1 
-- For each user, find the date of their first recorded event (cohort date)
 SELECT subscriber_id, MIN(event_date) AS cohort_date
 FROM user_payments
 GROUP BY subscriber_id;

--1.2
-- Select only valid transactions
SELECT *
FROM user_payments
WHERE customer_price > 0 AND refund = 'No';

--1.3
-- FINAL ANSWER
-- Define the cohort date for each user (1st query)
WITH user_cohorts AS (
  SELECT subscriber_id, MIN(event_date) AS cohort_date
  FROM user_payments
  GROUP BY subscriber_id
),
-- Select only valid transaction: non-trial and non-refunded (2nd query)
valid_payments AS (
  SELECT *
  FROM user_payments
  WHERE customer_price > 0 AND refund = 'No'
)
-- Join each valid payment with subscriber's cohort
-- to get the cohort date, date of the event, how many days have passed since (trial/transaction),
-- and gross revenue for each day in a cohort
SELECT
  uc.cohort_date,
  vp.event_date,
  (vp.event_date - uc.cohort_date) AS days_since_signup,
  SUM(vp.customer_price) AS gross_revenue
FROM valid_payments vp
JOIN user_cohorts uc 
ON vp.subscriber_id = uc.subscriber_id
GROUP BY uc.cohort_date, vp.event_date, days_since_signup
ORDER BY uc.cohort_date, vp.event_date;

--2.1
-- For each user, find the cohort date (same query as in 1st task)
SELECT subscriber_id, MIN(event_date) AS cohort_date
FROM user_payments
GROUP BY subscriber_id;

--2.2
-- Get all refund transactions
SELECT * 
FROM user_payments
WHERE refund = 'Yes';

--2.3
-- FINAL ANSWER
-- Define the cohort date for each user (1st query)
WITH user_cohorts AS (
  SELECT subscriber_id, MIN(event_date) AS cohort_date
  FROM user_payments
  GROUP BY subscriber_id
),
-- Get all refund transactions (2nd query)
refunds AS (
  SELECT *
  FROM user_payments
  WHERE refund = 'Yes'
)
-- Join refunds with subscriber's cohort and calculate refund avg day
SELECT ROUND(AVG(r.event_date - uc.cohort_date), 2) AS avg_days_to_refund
FROM refunds r
JOIN user_cohorts uc 
ON r.subscriber_id = uc.subscriber_id;

--3.1
-- Filter only valid monthly payments
SELECT *
FROM user_payments
WHERE subscription_name = 'monthly' AND customer_price > 0 AND refund = 'No';

--3.2
-- Calculate payments per user, their cohort month and number of payment
-- monthly_payments table is a result of previous query
SELECT
  subscriber_id,
  event_date,
  DATE_TRUNC('month', MIN(event_date) OVER (PARTITION BY subscriber_id)) AS cohort_month,
  ROW_NUMBER() OVER (PARTITION BY subscriber_id ORDER BY event_date) AS payment_number
FROM monthly_payments;

--3.3
--FINAL ANSWER
-- Filter only valid monthly payments (1st query)
WITH monthly_payments AS (
	SELECT *
	FROM user_payments
	WHERE subscription_name = 'monthly' AND customer_price > 0 AND refund = 'No'
),
-- Get first payment month and order of each payment (2nd query)
ranked_payments AS (
	SELECT
  		subscriber_id,
  		event_date,
  		DATE_TRUNC('month', MIN(event_date) OVER (PARTITION BY subscriber_id)) AS cohort_month,
  		ROW_NUMBER() OVER (PARTITION BY subscriber_id ORDER BY event_date) AS payment_number
	FROM monthly_payments
)
-- Count how many users from each cohort reached each payment number
-- Shows cohort month, payment step (2–6), and number of users at each step
SELECT
  TO_CHAR(cohort_month, 'Mon YYYY') AS cohort_month_label,
  payment_number,
  COUNT(DISTINCT subscriber_id) AS users_converted
FROM ranked_payments
WHERE payment_number BETWEEN 2 AND 6
GROUP BY cohort_month_label, payment_number
ORDER BY cohort_month_label, payment_number;
