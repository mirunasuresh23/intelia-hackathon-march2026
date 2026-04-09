-- GENAI INTEGRATION IN BIGQUERY
-- This script sets up the GenAI layer using BigQuery ML (Gemini).

-- 1. Create a Cloud Resource Connection
-- NOTE: This usually requires the 'BigQuery Connection Admin' role and must be done in the console or via CLI.
-- Command: bq mk --connection --location=US --project_id=miruna-sandpit --connection_type=CLOUD_RESOURCE vertex-ai-conn

-- 2. Create the Generative AI Model
CREATE OR REPLACE MODEL `miruna-sandpit.dwh_silver.gemini_model`
REMOTE WITH CONNECTION `miruna-sandpit.us.vertex-ai-conn`
OPTIONS (ENDPOINT = 'gemini-2.5-flash');

-- 3. Meaningful GenAI Application: Product Summary Enrichment
-- This creates a view in the Gold layer that uses AI to summarize product features.
CREATE OR REPLACE VIEW `miruna-sandpit.dwh_gold.ai_enriched_products` AS
SELECT
  product_id,
  product_name,
  category,
  unit_price,
  ml_generate_text_llm_result AS ai_summary
FROM
  ML.GENERATE_TEXT(
    MODEL `miruna-sandpit.dwh_silver.gemini_model`,
    (
      SELECT
        product_id,
        product_name,
        category,
        unit_price,
        CONCAT('Summarize this product in one catchy sentence for a marketing campaign based on its tags: ', tags) AS prompt
      FROM
        `miruna-sandpit.dwh_silver.products`
    ),
    STRUCT(
      0.2 AS temperature,
      100 AS max_output_tokens,
      TRUE AS flatten_json_output
    )
  );

-- 4. Analytical Gold View: Revenue by Category
CREATE OR REPLACE VIEW `miruna-sandpit.dwh_gold.revenue_by_category` AS
SELECT
  p.category,
  SUM(oi.quantity * oi.unit_price_at_purchase) as total_revenue,
  COUNT(DISTINCT o.order_id) as total_orders
FROM
  `miruna-sandpit.dwh_silver.orders` o
JOIN
  `miruna-sandpit.dwh_silver.order_items` oi ON o.order_id = oi.order_id
JOIN
  `miruna-sandpit.dwh_silver.products` p ON oi.product_id = p.product_id
GROUP BY
  1;
