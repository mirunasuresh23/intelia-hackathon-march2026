CREATE OR REPLACE MODEL `miruna-sandpit.dwh_silver.gemini_model`
REMOTE WITH CONNECTION `miruna-sandpit.us.vertex-ai-conn`
OPTIONS (ENDPOINT = 'gemini-2.5-flash');
