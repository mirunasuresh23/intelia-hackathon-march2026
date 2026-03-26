-- BRONZE TO SILVER TRANSFORMATIONS
-- This script cleans and moves data from the Bronze layer to the Silver layer.

-- 1. Transform Customers
CREATE OR REPLACE TABLE `miruna-sandpit.dwh_silver.customers` AS
SELECT
  customer_id,
  TRIM(first_name) as first_name,
  TRIM(last_name) as last_name,
  LOWER(TRIM(email)) as email,
  phone,
  date_of_birth,
  gender,
  registration_date,
  country,
  city,
  acquisition_channel,
  customer_tier,
  is_email_subscribed,
  is_sms_subscribed,
  preferred_device,
  preferred_category,
  loyalty_points,
  account_status,
  last_login_date,
  referral_source_id,
  marketing_segment,
  CURRENT_TIMESTAMP() as load_timestamp
FROM
  `miruna-sandpit.dwh_bronze.customers`;

-- 2. Transform Products
CREATE OR REPLACE TABLE `miruna-sandpit.dwh_silver.products` AS
SELECT
  product_id,
  sku,
  TRIM(product_name) as product_name,
  category,
  subcategory,
  brand,
  CAST(unit_cost AS FLOAT64) as unit_cost,
  CAST(unit_price AS FLOAT64) as unit_price,
  discount_eligible,
  CAST(stock_quantity AS INT64) as stock_quantity,
  CAST(weight_kg AS FLOAT64) as weight_kg,
  supplier_id,
  is_active,
  created_date,
  last_updated_date,
  average_rating,
  review_count,
  return_rate,
  tags,
  CURRENT_TIMESTAMP() as load_timestamp
FROM
  `miruna-sandpit.dwh_bronze.products`;

-- 3. Transform Orders
CREATE OR REPLACE TABLE `miruna-sandpit.dwh_silver.orders` AS
SELECT
  order_id,
  customer_id,
  order_date,
  order_status,
  payment_method,
  payment_status,
  shipping_address_country,
  shipping_address_city,
  shipping_method,
  CAST(shipping_cost AS FLOAT64) as shipping_cost,
  CAST(subtotal AS FLOAT64) as subtotal,
  discount_code,
  CAST(discount_amount AS FLOAT64) as discount_amount,
  CAST(tax_amount AS FLOAT64) as tax_amount,
  CAST(total_amount AS FLOAT64) as total_amount,
  session_id,
  device_type,
  acquisition_channel_at_order,
  coupon_used,
  is_first_order,
  fulfillment_center,
  estimated_delivery_date,
  actual_delivery_date,
  CURRENT_TIMESTAMP() as load_timestamp
FROM
  `miruna-sandpit.dwh_bronze.orders`;

-- 4. Transform Order Items
CREATE OR REPLACE TABLE `miruna-sandpit.dwh_silver.order_items` AS
SELECT
  order_item_id,
  order_id,
  product_id,
  CAST(quantity AS INT64) as quantity,
  CAST(unit_price_at_purchase AS FLOAT64) as unit_price_at_purchase,
  CAST(discount_applied AS FLOAT64) as discount_applied,
  CAST(line_total AS FLOAT64) as line_total,
  is_returned,
  return_reason,
  return_date,
  CURRENT_TIMESTAMP() as load_timestamp
FROM
  `miruna-sandpit.dwh_bronze.order_items`;
