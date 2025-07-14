-- 1.1 
-- For each user, find the date of their first recorded event (cohort date)
 SELECT subscriber_id, MIN(event_date) AS cohort_date
 FROM user_payments
 GROUP BY subscriber_id
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
